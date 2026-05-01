# Job Portal — Flutter Mobile App

Flutter mobile app for the [job-portal](https://github.com/ankit31aug/job-portal) backend (Express + PostgreSQL).

## Features

- 🏠 Home with featured jobs and department boards (NABH, NABL, NABCB, etc.)
- 🔍 Browse with filters, search, infinite scroll
- 📋 Job details with apply flow + resume upload
- 📊 Dashboard tracking applications and saved jobs
- 👤 Profile with edit support
- 🔐 Login + Register (Jobseeker / Employer roles)
- 🌙 System-aware dark mode

## Project Layout

```
job_portal_flutter/
├── lib/
│   ├── main.dart                          # Entry + bottom nav shell
│   ├── theme/app_theme.dart               # Light/dark themes
│   ├── services/
│   │   ├── api_service.dart               # HTTP client, all endpoints
│   │   └── auth_provider.dart             # Auth state (Provider)
│   ├── models/models.dart                 # User, Job, Application
│   ├── widgets/widgets.dart               # JobCard, EmptyState, etc.
│   └── screens/
│       ├── home_screen.dart
│       ├── browse_screen.dart
│       ├── job_detail_screen.dart
│       ├── apply_screen.dart
│       ├── auth_screens.dart              # Login + Register
│       └── dashboard_profile_screens.dart # Dashboard + Profile
├── docs/
│   ├── STATIC_REVIEW.md                   # Code review report
│   ├── DEPLOY_AND_SHARE.md                # GitHub push + APK sharing
│   └── server-security-patches/           # Backend hardening patches
├── login-credentials/                     # Gitignored secrets folder
│   ├── README.md                          # (committed)
│   ├── .gitignore                         # (committed)
│   ├── test-accounts.md                   # (NOT committed)
│   ├── .env.example                       # (NOT committed)
│   ├── .env.development                   # (NOT committed)
│   └── .env.production                    # (NOT committed)
├── pubspec.yaml
├── .gitignore
└── README.md
```

## Setup

### 1. Install Flutter
Get Flutter 3.10+ from https://docs.flutter.dev/get-started/install

```bash
flutter --version
```

### 2. Install dependencies
```bash
cd job_portal_flutter
flutter pub get
```

### 3. Configure API URL
Edit `lib/services/api_service.dart`:
```dart
// Production
static const String baseUrl = 'https://your-api.com/api';

// Android emulator (local)
static const String baseUrl = 'http://10.0.2.2:5000/api';

// iOS simulator (local)
static const String baseUrl = 'http://localhost:5000/api';

// Real device + local server: use your machine's LAN IP
static const String baseUrl = 'http://192.168.1.X:5000/api';
```

### 4. Android permissions
Already required for HTTP. Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

For local HTTP (cleartext) during development, add to `<application>`:
```xml
android:usesCleartextTraffic="true"
```

### 5. Run
```bash
flutter run
```

## Bug Fixes Applied

This codebase had several bugs in the first draft. They've been fixed and documented in `docs/STATIC_REVIEW.md`. Summary:

- **F-1:** `models.dart` had a fake `Color` class shadowing Flutter's. Removed.
- **F-2:** Apply endpoint was wrong (`/applications/:id` instead of `/applications`). Fixed.
- **F-3:** Bookmark toggle didn't exist on backend — split into POST/DELETE. Fixed.
- **F-4:** `getMe()` response wasn't wrapped — was treating it as `{ user: ... }`. Fixed.
- **F-5:** Profile updates didn't refresh local user state. Fixed via `refreshUser()`.
- **F-6, F-7:** Experience filter sent wrong query params. Fixed.
- **F-8:** Applications endpoint returned array, code expected object. Fixed.
- **F-9, F-10:** Various response-shape fragility. Fixed.

## Backend Security Notes

The backend has its own security report at `server/security-testing/security-test-report.md`. Most issues there are already fixed. Three additional concerns I found during this review have patch templates in `docs/server-security-patches/`:

- **JWT_SECRET hardcoded fallback** — server should refuse to start without env var
- **Resume files publicly served** — needs an authenticated download endpoint
- **No max length on text fields** — add validator middleware

These are **patches written but not applied** to the original repo (it's not mine to commit to). Apply them yourself if you want to harden the backend.

## What I Couldn't Test

I was honest about this earlier and worth repeating:

- **Appium / E2E** — no emulator in my environment
- **Live PostgreSQL** — no DB instance
- **Real device testing** — physical device required

Code is reviewed statically. Run it on a real device + emulator before shipping to friends.

## Next Steps

1. Read `docs/STATIC_REVIEW.md` — full review with findings
2. Read `docs/DEPLOY_AND_SHARE.md` — push to GitHub + share APK
3. Fill in `login-credentials/.env.development` for local testing
4. Run `flutter pub get && flutter run` against an emulator
5. Build APK and share via Firebase / Diawi / Drive

## License

Same as the parent project.
# job-portal-app
# job-portal-app
