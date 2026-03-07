# Play Store Prep TODO

The following tasks should be completed or reviewed before submitting the app to the Google Play Store. Cross items off as you finish them.

## Code & Build

- [x] Update `versionCode`/`versionName` in `pubspec.yaml` (now 1.0.1+2).
- [ ] Bump version before each release.
- [ ] Configure a release signing keystore (create `key.properties` and keystore file).  
  - See `PlayStore_Docs/key.properties.example` for template.
- [ ] Update `android/app/build.gradle.kts` to use the release signing config instead of debug.  
  (placeholder comment added).
- [x] Replace applicationId with the real package name (e.g., `com.pota.app`).
- [x] Run `flutter analyze` and fix any warnings/errors (analysis cycle was run; 28 issues reported).
- [x] Execute `flutter test` (widget/unit tests) and add more coverage if possible.  
  (existing tests passed.)
- [ ] Build a release AAB to verify (e.g. `flutter build appbundle --release`).
- [x] Verify network access works in release (INTERNET permission is present).  
- [ ] Validate the bundle with `bundletool` or by sideloading to a device.

## Assets & Metadata

- [ ] Produce Play Store icon (`ic_launcher_playstore.png`) and feature graphic.
- [ ] Capture screenshots for phones/tablets in portrait/landscape.
- [ ] Save screenshots and graphics under `PlayStore_Docs/assets/`.
- [ ] Draft and finalize store listing text (title, short/full description, whatsnew).
- [ ] Confirm privacy policy page is live and link is correct.
- [ ] Prepare release notes for the upcoming version.

## Play Console Setup

- [ ] Ensure Play Console developer account is active.
- [ ] Set pricing & distribution countries.
- [ ] Fill out content rating questionnaire.
- [ ] Declare app permissions and use of user data (GDPR/CCPA).
- [ ] Add contact info (email, website).

## Post-Upload

- [ ] Monitor internal testing; fix issues.
- [ ] Roll out to production.
- [ ] Respond to crash reports and reviews.
- [ ] Plan next update and iterate.

> ⚠️ Keep this list up-to-date with each release; treat it as a living document.
