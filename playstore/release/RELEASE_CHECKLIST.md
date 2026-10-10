# Google Play release checklist – Bangla Scanner

Package `com.codeinherit.banglascanner` · version 1.0.9 (versionCode 9) · minSdk 24 · targetSdk 36

## 0. One-time account setup

- [ ] Google Play Console developer account (one-time registration fee). Use the Google account you want to own the app long-term.
- [ ] Developer name shown on the store: **Code Inherit** (or your own name). Enter a support e-mail (`s.anwar369@gmail.com`) and, optionally, a website.
- [ ] **Personal (individual) accounts created after Nov 2023 must run a closed test with at least 12 testers for 14 continuous days before they can apply for production access.** Plan for this: upload the first build to Closed testing right away and invite the `scanner-testers` group plus friends/family.
- [ ] Identity verification in Play Console (ID + address). Do it early; it can take days.

## 1. Build the release bundle

```bash
# from the repo root
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --flavor prod
# -> build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

- [ ] `android/key.properties` and `android/app/bangla-scanner-release.jks` are present (they are git-ignored) so the bundle is signed with the upload key. Back both up somewhere safe; losing the key means you cannot update the app unless Play App Signing key reset is granted.
- [ ] Bump `version:` in `pubspec.yaml` for every upload (versionCode must increase: `1.0.9+9` → `1.0.10+10`). The release script does this automatically for App Distribution builds; for Play do it by hand or run `./release_script.sh prod` first.
- [ ] Choose **Play App Signing** on the first upload (recommended, default). Google holds the app signing key; your `.jks` becomes the upload key.
- [ ] Optional sanity check of the bundle on the device: `bundletool build-apks --bundle=... --output=app.apks --connected-device` then `bundletool install-apks --apks=app.apks`.

## 2. Create the app in Play Console

- [ ] **Create app**: name `Bangla Scanner – PDF & OCR`, default language **English (United States)**, type App, Free.
- [ ] Declarations: comply with Developer Program Policies and US export laws.

## 3. Store listing (Grow → Store presence → Main store listing)

Text files are in `../listing/`:

| Field | Limit | en-US | bn-BD |
| --- | --- | --- | --- |
| App name | 30 | `en-US/title.txt` | `bn-BD/title.txt` |
| Short description | 80 | `en-US/short_description.txt` | `bn-BD/short_description.txt` |
| Full description | 4000 | `en-US/full_description.txt` | `bn-BD/full_description.txt` |

- [ ] Add translation **Bengali (bn-BD)** under "Manage translations" and paste the Bangla texts. Also add **bn-IN** (copy of bn-BD) to reach West Bengal.
- [ ] Graphics from `../graphics/`:
  - App icon 512×512 PNG: `app_icon_512.png`
  - Feature graphic 1024×500 PNG/JPEG: `feature_graphic_1024x500.png`
  - Phone screenshots (2–8, 16:9 to 9:16, min 320 px, max 3840 px): `screenshots/phone_en/en_01…en_08.png` for the en-US listing and `screenshots/phone_bn/bn_01…bn_08.png` for bn-BD (1080×1920). Upload them in number order.
  - 7-inch and 10-inch tablet screenshots are optional unless you want the app promoted to tablets. The phone screenshots are accepted there too.
- [ ] Category: **Productivity**. Tags: Document scanner, PDF, OCR.
- [ ] Contact details: e-mail (required), phone / website optional.
- [ ] Store settings → Privacy policy URL: https://anwar31dec.github.io/bangla-scanner-docs/privacy-policy.html

## 4. App content (Policy → App content)

Every item must be completed before a production release can be rolled out.

| Item | Where to find the answers |
| --- | --- |
| Privacy policy | https://anwar31dec.github.io/bangla-scanner-docs/privacy-policy.html (already published from repo `anwar31dec/bangla-scanner-docs`; edit `privacy-policy.html` there to update) |
| Ads | No ads |
| App access | All functionality available without restrictions |
| Content ratings | `../policy/content_rating_questionnaire.md` |
| Target audience | 18+ (or 13+), not for children |
| News apps | No |
| Data safety | Import `../policy/data_safety_bangla_scanner.csv` (Data safety → Import from CSV); details in `../policy/data_safety_form.md` |
| Government apps | No |
| Financial features | None |
| Health | None |
| Advertising ID | Not used |

To update the policy later: edit `privacy-policy.html` in the `bangla-scanner-docs` repo and push to `main`; also update `../policy/privacy_policy.md` here.

## 5. Testing track first

- [ ] **Internal testing** (up to 100 testers, instant): upload `app-prod-release.aab`, add tester e-mails, share the opt-in link. Good for a last check of the real Play-signed build (Play App Signing re-signs it, so verify the scanner and biometrics still work).
- [ ] **Closed testing** (required 14-day / 12-tester period for new personal accounts): create a track, upload the same bundle, add the testers, publish, and keep it running for 14 days with testers opted in.
- [ ] Release notes: paste `release_notes_1.0.9.txt` (first-release summary; both language blocks are under the 500-char limit).
- [ ] After the test period: **Apply for production access** in the Dashboard and answer the questionnaire (what you tested, feedback received, how the app is ready).

## 6. Production

- [ ] Production → Create release → pick the bundle already tested (or upload a new one with a higher versionCode).
- [ ] Countries: start with **All countries** (or at least Bangladesh, India, United Kingdom, United States, Saudi Arabia, UAE, Malaysia, Italy, Qatar, Kuwait, Oman, Singapore, Australia, Canada, Germany).
- [ ] Review the "Errors / Warnings" panel. Expected warnings you can ignore: none; expected errors: none once App content is complete.
- [ ] Roll out. First review usually takes 1–7 days.

## 7. After publishing

- [ ] Add the Play listing link to the README and to the privacy policy page.
- [ ] Watch Play Console → Quality → Android vitals and Firebase Crashlytics for the first week.
- [ ] Reply to reviews in Bangla and English.
- [ ] Next release: bump version, update `release_note.txt` + a new `release_notes_x.y.z.txt`, rebuild the bundle, upload to the same production track.

## Pre-submission QA on a real phone

- [ ] Scan 1 page and 3 pages, save as PDF and JPEG, share to WhatsApp
- [ ] Flash Scan in a dark room
- [ ] Import from gallery and from a PDF
- [ ] OCR in Bangla, English and Both (first OCR unpacks the Tesseract data; make sure it finishes)
- [ ] Sign & stamp, ID card mode, merge, folders, favourites
- [ ] App lock: set PIN, enable fingerprint, background the app, reopen
- [ ] Backup, uninstall, reinstall, restore
- [ ] "Open with" a PDF from the Files app and "Share" a photo from the gallery into the app (this path was fixed in this release: `flutter_deeplinking_enabled=false` in the manifest)
- [ ] Airplane mode: everything except the first-time Play services scanner module download must work
- [ ] Android 7 or 8 device/emulator: storage permission prompt when saving to Downloads
