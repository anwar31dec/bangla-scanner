# dev flavor overrides

Files in this folder are merged on top of `src/main` only for the `dev` flavor
(`flutter run --flavor dev`).

- `res/mipmap-*` — launcher icons with a red "DEV" band so testers can tell the two apps apart.
- `res/values*/strings.xml` — the "DEV" app label (English and Bangla).

There is no flavor-specific `google-services.json` here: `android/app/google-services.json`
(Firebase project `bangla-scanner`) contains clients for both
`com.codeinherit.banglascanner` and `com.codeinherit.banglascanner.dev`, and the Google
Services Gradle plugin picks the one matching the flavor's application id. The dev app id is
`1:670275906113:android:f91d203c33c36a019bb4c0` (`FIREBASE_APP_ID_DEV` in `release_script.sh`).
