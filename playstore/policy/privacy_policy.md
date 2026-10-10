# Privacy Policy – Bangla Scanner

**Effective date:** 10 October 2026
**App:** Bangla Scanner (বাংলা স্ক্যানার), package `com.codeinherit.banglascanner`
**Developer:** Code Inherit (Anwar Hossain)
**Contact:** s.anwar369@gmail.com

Bangla Scanner is an offline document scanner. This policy explains what the app does with your data. The short version: **your documents never leave your phone**, there are no accounts, no advertising and no tracking of what you scan.

## 1. Data that stays on your device

Everything you create in the app is stored only in the app's private storage on your phone:

- Scanned pages, photos and PDFs you import, and the documents you save (JPEG and PDF files)
- Text recognised by OCR, which is kept with the document so that you can search your library and make searchable PDFs
- Your signature drawing and stamp texts
- Folder names, favourites and document names
- Settings such as language, theme, default format and OCR language
- The app-lock PIN, stored only as a salted hash (the PIN itself is never stored)

Scanning, image processing, PDF creation and OCR (Tesseract for Bangla, Google ML Kit for English with the model bundled in the app) all run on the device. The app does not upload documents, images or recognised text to any server operated by us or by anyone else.

When you choose to **share** or **save a copy** of a document, the file is handed to the app or location you pick (for example WhatsApp, Gmail, Google Drive or the Downloads folder). From that point it is governed by that app's or service's privacy policy.

A **backup** is a .zip file that you create on purpose and store or share wherever you choose. It contains your documents and folders. It is not encrypted; keep it somewhere you trust.

## 2. Data that is collected automatically

The Android version of the app includes **Firebase Crashlytics** and **Firebase Analytics** (Google LLC) so that we can find and fix crashes and understand which features are used.

- **Crash reports** (Crashlytics): when the app crashes, a report is sent that contains the stack trace, the app version, the Android version, the device model, the device orientation, free memory and disk space, a Crashlytics-generated installation identifier and the time of the crash. Crash reports do not contain your documents, images, recognised text, file names or PIN.
- **Usage statistics** (Analytics): aggregated events such as app opens, screen views and session length, together with coarse device information (model, OS version, language, country derived from IP address) and an app-instance identifier. The app does not log custom events that describe the content of your documents.

Crash reports and analytics are sent only when the device is online, using Google's SDKs. Google processes this data on our behalf under the Firebase terms: https://firebase.google.com/support/privacy. We do not sell this data and we do not use it for advertising.

The iOS version does not include Crashlytics or Analytics.

## 3. Data we do not collect

- No account, e-mail address, phone number or name is required or collected
- No location data
- No contacts, messages or call logs
- No advertising identifiers, no third-party advertising SDKs
- No copies of your scanned documents or recognised text

## 4. Permissions the app asks for

| Permission | Why |
| --- | --- |
| Camera | To scan pages and ID cards. Photos are processed on the device. |
| Biometrics (fingerprint / face) | Only if you turn on the optional app lock. Biometric data is handled by Android; the app only receives "unlocked" or "not unlocked". |
| Storage (Android 9 and below only) | To save copies of documents into the Downloads folder. Android 10 and later needs no permission for this. |
| Photos / gallery | Used through the system picker when you import a photo; the app only receives the photos you select. |

## 5. Google Play services document scanner

On Android, the scanning screen with automatic edge detection is provided by the Google ML Kit Document Scanner, which is part of Google Play services. On a phone that has never used it, Play services may download the scanner module once. The scanner processes images on the device.

## 6. Children

The app is intended for a general audience and is not directed at children under 13. We do not knowingly collect personal data from children.

## 7. Data retention and deletion

Your documents stay on your phone until you delete them in the app or uninstall the app. Uninstalling removes all app data, including documents, settings and the PIN hash. Crash and analytics data held by Firebase is retained according to Firebase's retention settings (crash data up to 90 days; analytics data up to 14 months) and can be deleted on request by e-mailing the contact address above with your approximate install date and device model.

## 8. Security

Documents are stored in the app's private directory, which other apps cannot read. The optional app lock protects the app behind a PIN or biometrics. A PDF password you set is used to encrypt that PDF (AES-128) and is never stored by the app.

## 9. Changes to this policy

If the policy changes, the new version will be published at the same address and the effective date updated. Material changes will also be mentioned in the app's release notes.

## 10. Contact

Questions or deletion requests: s.anwar369@gmail.com
