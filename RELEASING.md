# Releasing KisanSetu

One command from the repo root (on `main`, clean working tree):

```bash
./scripts/release.sh patch      # 1.0.7 -> 1.0.8
./scripts/release.sh minor      # 1.0.8 -> 1.1.0
./scripts/release.sh major      # 1.1.0 -> 2.0.0
./scripts/release.sh 1.2.3      # exact version
```

Windows (PowerShell): `./scripts/release.ps1 patch`

What happens:
1. The script bumps `version:` in `pubspec.yaml`, commits, tags `vX.Y.Z` and pushes.
2. GitHub Actions builds the signed release APK using the tag as version name (build number = `MAJOR*10000 + MINOR*100 + PATCH`).
3. The APK is published as `app-release.apk` on the GitHub Release with auto-generated notes.
4. Installed apps check `releases/latest` on start and show the update popup, then download and install the APK.

Requires the repo secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
All releases must be signed with the same keystore, otherwise Android refuses the update.
