# How to Push to GitHub & Share the APK

This guide walks you through pushing this Flutter project to your own GitHub repo and distributing an APK to your friends for testing.

---

## Part 1 — Pushing to GitHub

I cannot push to your GitHub for you (and you should never give an AI write access to your repos — even with a token, it's a bad idea). Here's how to do it yourself in about 5 minutes.

### 1.1 — Create a new GitHub repo

1. Go to https://github.com/new
2. Name it something like `job-portal-flutter`
3. **Leave it empty** — do NOT initialize with README, .gitignore, or license. Your local project already has those.
4. Choose **Public** or **Private** (Private recommended until you're ready to show it off)
5. Click "Create repository"

### 1.2 — Verify .gitignore is working

Before pushing, double-check that secrets are excluded:

```bash
cd job_portal_flutter
git init
git add .
git status
```

The output should NOT include:
- `login-credentials/.env.development`
- `login-credentials/.env.production`
- `login-credentials/test-accounts.md`

It SHOULD include:
- `login-credentials/README.md`
- `login-credentials/.gitignore`

If secrets are showing up, **stop and fix the .gitignore before committing.** Use:
```bash
git rm --cached login-credentials/.env.development
git rm --cached login-credentials/test-accounts.md
```

### 1.3 — First commit

```bash
git add .
git commit -m "Initial commit: Flutter job portal app"
```

### 1.4 — Connect to your GitHub repo

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/job-portal-flutter.git
git push -u origin main
```

When prompted for password, **GitHub no longer accepts your account password.** You need a Personal Access Token:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name like "job-portal-push"
4. Set expiration (90 days is fine)
5. Tick the **`repo`** scope
6. Click "Generate token"
7. **Copy the token immediately** (you won't see it again)
8. Use it as the password when git prompts

### 1.5 — Subsequent pushes

```bash
git add .
git commit -m "Describe your change"
git push
```

---

## Part 2 — Building & Sharing the APK

### 2.1 — Build a release APK

```bash
cd job_portal_flutter
flutter clean
flutter pub get
flutter build apk --release
```

The APK lands at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Typical size: 25–40 MB.

#### For smaller APKs (recommended)

Build separate APKs per CPU architecture — Android picks the right one:
```bash
flutter build apk --split-per-abi --release
```

This creates 3 APKs in `build/app/outputs/flutter-apk/`:
- `app-armeabi-v7a-release.apk` (~8 MB) — older 32-bit phones
- `app-arm64-v8a-release.apk` (~9 MB) — most modern phones (ship this one)
- `app-x86_64-release.apk` (~9 MB) — emulators / x86 tablets

### 2.2 — Sharing options (ranked best to worst)

#### Option 1 — Firebase App Distribution (best for serious testing)

Free, professional, sends update notifications when you ship a new version, tracks installations, lets testers report bugs.

1. Create a Firebase project at https://console.firebase.google.com
2. Add your Android app (package name from `android/app/build.gradle`)
3. Install the Firebase CLI:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
4. From the project folder:
   ```bash
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_FIREBASE_APP_ID \
     --release-notes "First test build" \
     --testers "friend1@email.com,friend2@email.com"
   ```
5. Friends get an email with install instructions.

#### Option 2 — Diawi (easiest, no setup)

Free service that hosts your APK and gives you a QR code.

1. Go to https://www.diawi.com
2. Drag in `app-release.apk`
3. Wait ~30 seconds
4. You get a short link + QR code
5. Send the link / show the QR to your friends
6. Free tier: 30-day expiry, 100 downloads

#### Option 3 — Google Drive / Dropbox (easiest if you already use them)

1. Upload the APK to Drive
2. Right-click → Share → "Anyone with the link"
3. Copy link, send to friends

Simple but no install metrics, no easy update path.

#### Option 4 — WhatsApp / Telegram / Signal

Just attach the APK as a file. WhatsApp will warn the recipient about installing apps from unknown sources, which is fine.

#### Option 5 — Google Play Console (Internal Testing track)

Most professional, but requires a $25 one-time Google Play developer fee. If your friend's project is going to a real audience eventually, this is worth the investment. Internal testing track:
- Up to 100 testers
- They install via Play Store (no "unknown sources" warning)
- You can promote to closed/open beta later
- Crash reports and analytics built in

### 2.3 — What your friends need to do (Android)

The APK is unsigned by Google Play, so Android will warn before installing.

**Modern Android (10+):**
1. Tap the APK to install
2. If blocked, tap "Settings" in the warning dialog
3. Toggle on "Allow from this source" for the file manager / browser they used
4. Go back and tap install again

**The first install is awkward, updates are smoother.** Each new APK install becomes seamless.

### 2.4 — Versioning between builds

Open `pubspec.yaml` and bump the version:
```yaml
version: 1.0.1+2   # 1.0.1 = display version, +2 = build number
```

Always increment the build number (`+2`, `+3`, etc.) or Android will refuse to update.

---

## Part 3 — When something breaks in testing

Tell your friends to:
1. Take a screenshot of the error
2. Note what they were doing when it happened
3. Send you the device model + Android version

You can also enable crash reporting via Firebase Crashlytics (requires Firebase setup) — automatically sends stack traces.
