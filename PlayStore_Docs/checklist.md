# Play Store Submission Checklist

Use this checklist before uploading a new version to the Play Store.

- [ ] Update `versionCode` and `versionName` in `android/app/build.gradle.kts`.
- [ ] Confirm `INTERNET` permission in AndroidManifest (required for map tiles).
- [ ] Run `flutter analyze` and fix any errors.
- [ ] Run unit/widget tests (e.g. `flutter test`).
- [ ] Build release AAB: `flutter build appbundle --release`.
- [ ] Sign the bundle with the production keystore.
- [ ] Verify the bundle with `bundletool` or by installing on a device.
- [ ] Prepare PRD notes and release notes for Play Console.
- [ ] Generate all required graphics (icons, screenshots, feature graphic).
- [ ] Draft store listing text: title, short description, full description.
- [ ] Review privacy policy and include a link.
- [ ] Set compliance for ads and GDPR/CCPA as needed.
- [ ] Validate content rating questionnaire.
