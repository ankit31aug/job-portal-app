# Static Review Report

**Scope:** Server-side security review (Node/Express/PostgreSQL backend) + Flutter app code review
**Method:** Static analysis only — no live tests, no Appium, no real DB
**Date:** 2026-05-02

---

## Important caveats up front

I want to be straight with you about what this report is and isn't:

- **This is a static review.** I read every server route, the auth middleware, the DB layer, and every Flutter file I wrote. I did not run anything.
- **No Appium / E2E.** I have no Android emulator, no iOS simulator, no Appium server. Anyone who claims they ran those without showing logs is lying.
- **No live PostgreSQL test.** I'd need a running DB with seed data and the server running against it. Doesn't exist in my environment.
- **The repo already has a security report** at `security-testing/security-test-report.md`. Most fixes (rate limiting, helmet, timing attack on forgot-password) are already in. I'm reporting what I see in the *current* state of the code.

---

## Part 1 — Backend Security Review (Static)

### What's already good (I verified by reading the code)

| Area | Status | Why |
|---|---|---|
| SQL injection | ✅ Safe | Every query uses parameterized `$1, $2, ...` placeholders. I checked every route. |
| Password storage | ✅ Strong | bcryptjs with cost factor 10. (Could be 12 in prod, but 10 is acceptable.) |
| JWT verification | ✅ Correct | Uses `jwt.verify()` which validates signature + expiry. None-alg attacks blocked. |
| Role-based auth | ✅ Solid | `requireSuperAdmin`, `requireHR`, `requireEmployer`, `requireJobseeker` all check `req.user.role` server-side, not client claims. |
| File uploads | ✅ Reasonable | 5 MB limit, extension allow-list (`.pdf .doc .docx`), multer sanitizes filenames. |
| Rate limiting | ✅ Present | Login (10/15min), OTP verify (5/10min), forgot-password (5/hr). |
| Helmet headers | ✅ Present | `X-Powered-By` removed, `X-Frame-Options`, `nosniff` set. |
| Forgot-password timing | ✅ Fixed | Email sent fire-and-forget so response time doesn't leak whether email exists. |
| Mass assignment on register | ✅ Blocked | `role=hr` and `role=super_admin` rejected at registration. |
| Profile update mass assignment | ✅ Blocked | PUT `/auth/profile` doesn't accept `role` field. |

### What I found that's still a concern

#### 🟠 H-1 — JWT_SECRET fallback is hardcoded
**File:** `server/middleware/auth.js:3`
```js
const JWT_SECRET = process.env.JWT_SECRET || 'jobportal_super_secret_key_2024';
```
**Why it matters:** If someone deploys without setting `JWT_SECRET`, this default is used. Anyone reading the public GitHub repo can forge any user's token, including super admin. **The default should not exist** — the server should refuse to start if `JWT_SECRET` is missing.

**Fix:** Refuse to start without an env var.

#### 🟠 H-2 — `requirePermission` JSON parse can throw silently
**File:** `server/middleware/auth.js:62-63`
```js
let perms = [];
try { perms = JSON.parse(role.permissions); } catch {}
```
If `role.permissions` is malformed, the user gets denied access to *everything* with a confusing error. Low impact (fails closed) but worth logging. Not exploitable.

#### 🟠 M-1 — `/api/applications/:id/status` — IDOR is checked but email leak still possible
**File:** `server/routes/applications.js:160-200`
The endpoint correctly verifies the employer owns the job before allowing status updates. Good. But: **after the update, it sends an email to the applicant** with their full name and the job title. If an attacker somehow got a valid employer token, they could enumerate which applications exist by triggering 404 vs success responses. This is a low-severity informational issue — the auth check is solid.

#### 🟠 M-2 — Stored XSS risk on job text fields
**File:** Multiple routes (jobs, superadmin, gallery)
Jobs accept `title`, `description`, `requirements` as raw text. They're stored as-is. The React frontend escapes by default so it's safe today, but:
- **Mobile app risk:** If your Flutter app uses an HTML renderer (e.g., `flutter_html` package) anywhere, this becomes a real XSS. The app I built uses `Text()` widgets which are safe.
- **Future risk:** If anyone adds `dangerouslySetInnerHTML` or PDF generation that interprets HTML.

**Recommendation:** Add input sanitization on job creation. Reject `<script>`, `javascript:`, `on*=` patterns. The existing security report flagged this as W1.

#### 🟠 M-3 — Resume files are publicly accessible
**File:** `server/app.js:43`
```js
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
```
Anyone with a resume URL (e.g., `/uploads/resume_1234567890_jane.pdf`) can fetch it without authentication. Filenames include timestamps and original names, which is *somewhat* unguessable but not secure. Personal data (phone, address, work history) is in those files.

**Fix:** Add an authenticated endpoint like `GET /api/applications/:id/resume` that checks the requesting user is either the applicant or the employer who owns the job.

#### 🟡 L-1 — OTP timing attack still possible
**File:** `server/routes/otp.js:50-75`
The `/api/otp/send` endpoint immediately returns 409 if the email is already registered, but does the same DB round-trip whether or not the email exists. The 409 vs 200 response itself reveals registration status. This is intentional for UX but is an information disclosure. Fine for a non-bank app.

#### 🟡 L-2 — `pdf-parse` is unmaintained
**File:** `server/routes/resume.js:5`
`pdf-parse@1.1.1` hasn't been updated since 2018 and depends on an old `pdfjs-dist` with known CVEs. Replacing with a maintained fork (`pdf-parse-fork` or `pdfjs-dist` directly) is recommended.

#### 🟡 L-3 — Free-form text not bounded
None of the routes set max lengths on text fields. A malicious user could submit a 10 MB cover letter. The `express.json({ limit: '10mb' })` cap is global, not per-field.

**Recommendation:** Add `express-validator` with `.isLength({ max: ... })` per field.

### Things that are NOT bugs (but might look like them)

- **Resume parsing using the entire request body for skill matching:** Looks suspicious but is fine — `text.includes(skill)` with skills from your own DB is safe.
- **`crypto.randomBytes(32)` for reset tokens:** Cryptographically secure. Good.
- **Rate limiter `skip: () => IS_TEST`:** Intentional for tests. Verified `IS_TEST` is only true in test env.

---

## Part 2 — Flutter App Code Review (Static)

This is where I owe you the most honesty. **Reading my own code, I found 8 bugs.** Some are minor, some would have actually broken the app at runtime. Fixing all of them in Part 3.

### 🔴 BUG-F-1 — `models.dart` redefines `Color`
**File:** `lib/models/models.dart:274-278`
```dart
// Hack for Color import inside model
class Color {
  final int value;
  const Color(this.value);
}
```
**This will break the build.** I declared a custom `Color` class to avoid importing Flutter, but it conflicts with `dart:ui`'s `Color` everywhere this file is imported. The methods `statusColor` return this fake Color, not Flutter's.
**Fix:** Import `package:flutter/material.dart`, delete the fake Color class.

### 🔴 BUG-F-2 — `applyToJob` calls wrong endpoint
**File:** `lib/services/api_service.dart:122`
```dart
final uri = Uri.parse('$baseUrl/applications/$jobId');
```
**The backend expects `POST /api/applications` with `job_id` in the body**, not `/applications/:jobId`. See `server/routes/applications.js:26`.
**Fix:** POST to `/applications` with `job_id` in form data.

### 🔴 BUG-F-3 — `toggleBookmark` calls wrong endpoint
**File:** `lib/services/api_service.dart:142-148`
```dart
static Future<Map<String, dynamic>> toggleBookmark(int jobId) async {
  final res = await http.post(Uri.parse('$baseUrl/bookmarks/$jobId'), headers: _headers);
}
```
**The backend has separate POST and DELETE.** POST takes `{ job_id }` in body; DELETE takes the ID in URL. There's no toggle endpoint.
**Fix:** Check first, then POST or DELETE based on current state.

### 🔴 BUG-F-4 — `getMe()` response shape mismatch
**File:** `lib/services/auth_provider.dart:79`
```dart
_user = AuthUser.fromJson(data['user'] ?? data);
```
The backend returns the user object directly (not wrapped in `{ user: ... }`). See `server/routes/auth.js:136`. The `?? data` fallback works, but the primary path doesn't.
**Fix:** Just use `data` directly.

### 🟠 BUG-F-5 — Login response handling
**File:** `lib/services/auth_provider.dart:86-87`
```dart
final token = data['token'] as String;
await ApiService.setToken(token);
_user = AuthUser.fromJson(data['user']);
```
This is correct for `/login` and `/register`. But the user object from login includes `password` field stripped (line 118 in auth.js). I don't have a Profile screen action to refresh that; if a user updates their profile, the local `_user` won't reflect changes elsewhere in the app until restart. Minor UX bug.

### 🟠 BUG-F-6 — `getJobs` parameter name mismatch
**File:** `lib/services/api_service.dart:79-87`
I send `exp_min` and `exp_max` separately, but the backend expects a single `experience` query param like `experience=1-5`. See `server/routes/jobs.js:40-49`.
**Fix:** Combine into one `experience` parameter.

### 🟠 BUG-F-7 — Browse screen sends wrong filter
**File:** `lib/screens/browse_screen.dart` — same root cause as F-6. The UI doesn't currently filter by experience, so this doesn't manifest visibly, but the API contract is wrong.

### 🟠 BUG-F-8 — `getMyApplications` shape mismatch
**File:** `lib/services/api_service.dart:113`
The backend returns an array directly (`res.json(applications)`), but I treat it as `data['applications'] ?? data`. The fallback works but is fragile.

### 🟡 BUG-F-9 — No retry on token expiry
If JWT expires mid-session, the app just shows an error. A proper fix would clear the token and route to login. Currently the user has to manually log out and back in.

### 🟡 BUG-F-10 — `getJobs` response shape
Same fragility: backend returns `{ jobs, total, page, pages }` but I have a fallback path. The fallback is correct but the comment is misleading.

### Things I *didn't* mess up (verified)

- Token storage in `SharedPreferences` — fine for a job portal. (Not banking-grade — for that use `flutter_secure_storage`.)
- File picker only allows pdf/doc/docx — matches backend.
- Provider state management is correct.
- Theme handles dark mode properly.

---

## Part 3 — Fixes Coming Up

I'll now apply all 10 Flutter fixes plus 1-2 server hardening recommendations, then package the result. After that, I'll create the `login-credentials/` folder and give you push instructions.
