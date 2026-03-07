# Overview

This document describes the overall process of preparing the POTAontheGO Android application for release on the Google Play Store.

## Key Steps

1. **Build a release APK/AAB**
   - Ensure `android/app/build.gradle.kts` has correct applicationId and versionCode/versionName.
   - Run `flutter build appbundle` (or `apk`) from the project root.

2. **Sign the app**
   - Configure key.properties and provide keystore file.
   - Update Gradle signingConfig for release.

3. **Prepare assets and metadata**
   - Create icons, feature graphics, screenshots, and promotional images.
   - Write description, title, and other listing information.

4. **Complete Play Console setup**
   - Create a developer account if not already.
   - Set up pricing & distribution, content rating, and privacy policy.

5. **Upload and roll out**
   - Upload the AAB or APK.
   - Run internal testing, then production rollout.

6. **Monitor and maintain**
   - Respond to user reviews and crashes.
   - Update on schedule and adapt to Play Store policy changes.
