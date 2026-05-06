# BullsEye Pro — Developer Context

## Project
Flutter darts scoring app. Bundle ID: `com.integraldot.bullseyepro`

## Branches
| Branch | Purpose |
|---|---|
| `main` | Production — deployed to GitHub Pages |
| `release/google-play` | Android / Google Play setup (current work) |
| `release/ios-appstore` | iOS App Store (future) |
| `claude/darts-scoring-app-9m0ZV` | Feature development branch |

## App features (all implemented, all on main)
- Standard 01 mode (301/501/custom starting score, double-out toggle)
- Count-Up mode (score up, highest wins after N turns)
- Turn limit per leg (optional in standard, required in count-up)
- Dart-by-dart input with S/D/T multiplier
- Turn total input
- Checkout route suggestions (≤170 remaining)
- Live projected score as darts entered
- Bust detection (auto-revert)
- 2–8 players, leg rotation (different player starts each leg)
- Swap who starts a leg (before first dart)
- Round counter
- Match history (local storage)
- Leg-won celebration screen

## Stack
- Flutter 3.16+ / Dart 3.1+
- Riverpod (flutter_riverpod ^2.4.9)
- go_router ^13.0.1
- shared_preferences for persistence

## Current status: Phase 1 — Google Play

### What's done (on release/google-play branch)
- [x] Icons and splash source assets generated (`assets/icon/`, `assets/splash/`)
- [x] Web PWA icons committed (`web/icons/`)
- [x] `android/` folder created with full config:
  - `android/app/build.gradle` — applicationId `com.integraldot.bullseyepro`, minSdk 21, targetSdk 35
  - `android/app/src/main/AndroidManifest.xml` — label "BullsEye Pro"
  - `android/app/src/main/kotlin/com/integraldot/bullseyepro/MainActivity.kt`
  - Gradle 8.3, AGP 8.1.0, Kotlin 1.8.22
  - Dark launch background (#121212)
  - Release signing scaffold (reads android/key.properties — gitignored)
- [x] `pubspec.yaml` updated — Android enabled in flutter_launcher_icons + flutter_native_splash
- [x] `.gitignore` updated — android/ unblocked; key.properties / *.jks gitignored
- [x] `.github/workflows/build-android.yml` — CI builds unsigned AAB on push to branch

### What still needs to run ON YOUR MAC (needs Flutter SDK)

**Step 1 — Add gradle wrapper jar (binary, can't be created on server):**
```bash
git checkout release/google-play && git pull origin release/google-play
flutter create --platforms=android .   # say "n" to any conflict prompts
git add android/gradle/wrapper/gradle-wrapper.jar
git commit -m "Add gradle wrapper jar"
git push origin release/google-play
```

**Step 2 — Generate Android icons and splash:**
```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
git add android/app/src/main/res/
git commit -m "Generate Android icons and splash"
git push origin release/google-play
```

**Step 3 — Create release keystore (once, never commit):**
```bash
keytool -genkey -v -keystore ~/bullseye-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias bullseye
```
Then create `android/key.properties` (already gitignored):
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=bullseye
storeFile=/Users/YOURNAME/bullseye-release.jks
```

**Step 4 — Build release AAB:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
# Upload this file to Google Play Console
```

## Google Play store listing copy (ready to paste)

**Short description (79 chars):**
Track darts scores for up to 8 players. 501, 301, Count-Up — offline.

**Full description:** See plan file at `/root/.claude/plans/binary-floating-hippo.md`

## Upcoming phases
- Phase 2: Google Play Console setup (screenshots, privacy policy, data safety)
- Phase 3: iOS App Store branch (`release/ios-appstore`)
- Phase 4: Landing page HTML (single file, FTP deploy)
