# Bangla Scanner (বাংলা স্ক্যানার)

An offline document scanner for Bengali speakers in Bangladesh, Kolkata and
around the world. Scan with automatic edge detection, edit pages, save as
PDF or JPEG, share in one tap, and extract **Bangla and English text (OCR)**
without an internet connection.

- Package / bundle ID: `com.codeinherit.banglascanner`
- Bangla UI by default, English in Settings
- Android 7.0+ (minSdk 24), iOS 15.5+
- Flutter 3.47 (stable), Dart 3, Riverpod, drift (SQLite), Material 3

## Features (MVP)

| Feature | How |
| --- | --- |
| Scan with auto-crop, multi-page | `cunning_document_scanner` → ML Kit Document Scanner (Android), VisionKit (iOS) |
| Flash Scan | In-app camera (`camera`) whose flash fires only when the photo is taken (ML Kit's scanner can only keep its light on). Live page outline and auto capture when the page is held still; own page detection and perspective crop in Dart, with draggable corners |
| Import | Photos from the gallery (`image_picker`, multi-select) or a **PDF file**: each page is rendered to a JPEG (Android `PdfRenderer`, iOS Core Graphics; first 100 pages) and can then be cropped, filtered, merged and OCR'd like a scan |
| Edit pages | Crop (`image_cropper`), rotate, drag-and-drop reorder, delete, add more pages (scanner, Flash Scan, gallery or PDF), **Book split** (cut a photo of an open book into two pages) |
| Sign & stamp | Draw a signature once (saved as a transparent PNG), place it on any page by dragging, pinching to resize and rotating; date stamp and rubber-stamp texts (Attested, True copy, Original seen, Paid, Received, custom) in blue, red or black. The stamp is burnt into the page together with its rotation and filter |
| Filters | Original, Auto color (white paper, shadows removed), Grayscale, Black & White (adaptive threshold), Whiteboard, Light text. Picked from live thumbnails of the page. **Adjust**: filter strength, brightness and contrast sliders |
| Save | PDF or JPEG; quality Low / Medium / High; PDF page size *Fit to scan* (page shaped like the scan) or A4 / Letter / Legal (scan fitted on real paper); optional **PDF open password** (AES-128, standard security handler, see below); default name `Doc-dd-MM-yyyy-HH-mm-ss` |
| Library | Thumbnail, name, pages, date, size; search, sort, rename, delete; **folders** (chips row, long-press a folder to rename/delete), **favourites**; multi-select to share, move, star, delete or merge several documents; metadata in drift |
| Document viewer | Swipe pages, pinch and double-tap to zoom (paging pauses while zoomed), thumbnail strip; **reorder or remove pages** of a saved document without re-processing (JPEGs are moved, the PDF is rebuilt) |
| Share / save copy | `share_plus`; Downloads/Bangla Scanner on Android, Files picker on iOS |
| OCR | Bangla: Tesseract `ben`; English: ML Kit; Both: Tesseract `ben+eng`; editable result, copy/share/.txt. The recognized text (with the position of every word) is kept with the document: the library search then finds documents by the words inside them (with an excerpt of the hit), and a PDF is rebuilt with an **invisible text layer** so it is searchable, and its text selectable, in any PDF viewer |
| Searchable PDF | Save sheet switch (default in Settings): the text is recognized while saving and drawn invisibly over each page (Hind Siliguri subset embedded for Bangla + Latin), and stored for the library search. Text follows its page when pages are reordered or removed; re-saving an edited document drops it (pages changed) |
| ID card mode | Document type: NID / smart card (ID-1, 85.6 × 53.98 mm, front and back) or passport (ID-3, 125 × 88 mm, photo page plus an optional second page), placed on one A4 page at real size |
| App lock | PIN (4–8 digits, stored as a salted hash) with optional fingerprint / face unlock (`local_auth`); locks on launch and after 0 / 1 / 5 minutes in the background |
| Backup & restore | Settings → Backup: the whole library (documents, folders, favourites) as one `.zip` to Downloads / Files or the share sheet; restore adds everything the library does not have yet (see below) |
| Receive files | Appears in the Android share sheet and "Open with" for images and PDFs (WhatsApp, Gmail, file managers) and as "Copy to Bangla Scanner" on iOS; the files open straight in the editor. Home screen **quick actions** (long-press the icon) for Scan and Flash Scan (`quick_actions`) |
| Settings | Language, theme, default format, quality and PDF page size, default OCR language, app lock, backup |

Everything runs on the device. No accounts, no cloud.

## Project structure

```
lib/
  main.dart, app.dart
  core/
    l10n/          app_bn.arb, app_en.arb (+ generated AppLocalizations)
    theme/         Material 3 light/dark theme, Hind Siliguri font
    router/        go_router routes
    storage/       drift database, app paths, startup cleanup
    permissions/   camera/storage rationale + "open settings" dialog
    models/        shared enums (format, quality, OCR language, filter)
    utils/         formatters, user-friendly errors
    widgets/       dialogs, empty state, progress overlay
  features/
    backup/        backup manifest + zip service, Backup & restore screen
    home/          home screen
    intents/       files received from other apps, home screen quick actions
    scan/          scanner + gallery + PDF import, draft document state
    stamps/        signature pad, stamp renderer, placement screen, compositor
    editor/        page list, page editor, filter previews
    export/        image pipeline, PDF builder, save service, share/save to device
    library/       document repository (folders, favourites, page rewrite), list, viewer, pages screen
    lock/          app lock controller (PIN, biometrics, background delay) and lock screen
    ocr/           preprocessing, Tesseract/ML Kit engine, OCR screen
    id_card/       A4 layout for ID-1 / ID-3 cards, guided front/back screen
    settings/      settings model, repository (incl. PIN hash), screen
packages/flutter_tesseract_ocr/   vendored + patched plugin (see below)
assets/fonts/      Hind Siliguri (OFL)
assets/tessdata/   ben/eng traineddata, gzip-compressed
```

Each feature separates `data/` (I/O, pure logic), `application/` (Riverpod
state) and `presentation/` (widgets).

## Setup

Requirements: Flutter 3.47+ stable, Android Studio / Android SDK 36,
Xcode 16+ with CocoaPods for iOS.

```bash
flutter pub get          # also generates the localization classes
flutter analyze
flutter test
```

The drift code (`lib/core/storage/app_database.g.dart`) is committed. The
schema is at version 3 (v2 added folders, favourites and the protected flag;
v3 added the `page_texts` table of recognized text + word boxes and the
`has_text` flag, see `AppDatabase.migration`). After changing the database
schema, bump `schemaVersion`, add a migration step and regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Android

```bash
flutter run --flavor dev   # with a device or emulator connected
```

Android has two flavors that install side by side: `dev`
(`com.codeinherit.banglascanner.dev`, label "DEV Bangla Scanner", DEV-badged
icon) and `prod` (`com.codeinherit.banglascanner`). Every Android `flutter run`
/ `flutter build` needs `--flavor dev` or `--flavor prod`.

- `minSdk` is 24: the Flutter engine and several plugins require it.
- Permissions (`android/app/src/main/AndroidManifest.xml`): `CAMERA`,
  `USE_BIOMETRIC` (app lock), and `WRITE_EXTERNAL_STORAGE` only up to
  Android 9 (Android 10+ saves to Downloads through MediaStore, no permission
  needed).
- `MainActivity` extends `FlutterFragmentActivity`, which `local_auth` needs
  for the biometric prompt. It also hosts three small method channels:
  `…/storage` (save to Downloads), `…/pdf` (`PdfPageRenderer.kt`, renders
  PDF pages with `android.graphics.pdf.PdfRenderer`) and `…/received`
  (`ReceivedFiles.kt`: copies the URIs of `ACTION_SEND`, `SEND_MULTIPLE` and
  `VIEW` intents into the cache and hands the paths to Dart).
- Quick action icons are the vector drawables `ic_shortcut_scan` /
  `ic_shortcut_flash` in `res/drawable`.
- The document scanner UI is provided by Google Play services. On a device
  that has never used it, Play services may download the scanner module
  once (requires internet the first time). Devices without Play services
  fall back to the plugin's built-in scanner with manual cropping.
- The ML Kit English text model is bundled in the app, so English OCR works
  offline from the first launch.

### iOS

```bash
cd ios && pod install && cd ..
flutter run
```

- `ios/Podfile` sets `platform :ios, '15.5'` (required by Google ML Kit) and
  the permission_handler macros `PERMISSION_CAMERA`, `PERMISSION_PHOTOS` and
  `PERMISSION_PHOTOS_ADD_ONLY`.
- `Info.plist` contains Bangla + English texts for
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSPhotoLibraryAddUsageDescription` and `NSFaceIDUsageDescription` (app
  lock).
- SwiftyTesseract excludes the arm64 simulator architecture. On Apple
  Silicon Macs, run the simulator under Rosetta or test on a real device.
- `AppDelegate.swift` registers three in-app plugins: `FileExporter` (Files
  picker for "Save to phone"), `PdfPageRenderer.swift` (Core Graphics PDF
  rendering) and `ReceivedFilesPlugin.swift`, which receives files through
  the scene delegate (`CFBundleDocumentTypes` lists PDF and images, so the
  app shows up under "Copy to Bangla Scanner" / "Open in"). There is no
  share extension; the share sheet entry on iOS is the "Copy to" action.
- Quick action icons are the template image sets `ic_shortcut_scan` /
  `ic_shortcut_flash` in `Assets.xcassets`.

## How the Tesseract Bangla data is bundled

1. Models come from [tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast)
   (the small, fast LSTM models): `ben.traineddata` (≈0.86 MB) and
   `eng.traineddata` (≈4.1 MB).
2. They are stored gzip-compressed in `assets/tessdata/*.traineddata.gz`
   (≈0.55 MB + ≈2 MB), which roughly halves their size in the app bundle.
3. On the first OCR, `TessdataInstaller` decompresses them once, in a
   background isolate, into `<app documents>/tessdata/`, where
   flutter_tesseract_ocr reads them. `assets/tessdata_config.json` lists the
   files the plugin expects.
4. English-only OCR uses ML Kit, so `eng.traineddata` is only used for the
   "Both" (`ben+eng`) mode.

To use the larger, more accurate `tessdata_best` models, replace the files:

```bash
gzip -9 -c ben.traineddata > assets/tessdata/ben.traineddata.gz
```

Existing installs keep the old model until the app data is cleared (delete
`<documents>/tessdata/` or bump a version check in `TessdataInstaller`).

### Why the plugin is vendored

`packages/flutter_tesseract_ocr` is flutter_tesseract_ocr 0.4.31 with small
fixes (listed in its `BANGLA_SCANNER_PATCHES.md`): Gradle 9 / AGP 9
compatibility (the published version uses `jcenter()`), R8 keep rules for
release builds, error reporting instead of crashes or hangs, and reading
models from the documents folder on iOS instead of the read-only bundle.

## PDF password

A protected PDF uses the PDF standard security handler, revision 4, with
AES-128 (`/V 4 /R 4`, crypt filter `AESV2`) implemented in
`lib/features/export/data/pdf_encryption.dart` on top of the `pdf` package's
`PdfEncryption` hook: MD5 from `crypto`, RC4 (only for the `/O` and `/U`
password hashes the format requires) and AES-CBC written in Dart. The owner
password is random, so only the user password matters. Readers such as Adobe
Reader, Chrome, iOS Preview and pypdf open the file with that password; the
password itself is never stored (`isProtected` only flags the document, and
re-saving or reordering pages asks for it again). The page JPEGs inside the
app folder are not encrypted; the app lock covers them.

## Backup format

A backup is a plain zip (`BanglaScanner-Backup-dd-MM-yyyy-HH-mm.zip`) with
`manifest.json` at the root and the document folders under `library/<id>/`
exactly as they are stored in the app (`pages/page_001.jpg …`, `document.pdf`,
`thumb.jpg`). JPEGs and PDFs are *stored* (not deflated), so a backup is as
fast as a copy. The manifest (`BackupManifest`, `format:
"banglascanner-backup"`, `version: 1`) carries the document rows (name,
format, page count, size, dates, favourite, folder, protected flag) and the
folders. The zip is written and read in a background isolate.

Restore is additive: documents whose id is already in the library are left
untouched, everything else is unpacked into a staging folder, checked
(pages or PDF present, entry names may not leave `library/`) and moved into
place. Folders are restored by id, so a document keeps its folder. The PIN
and settings are not part of the backup.

## OCR pipeline

1. Each page image is pre-processed in a background isolate
   (`OcrPreprocessor`): resized so the long edge is 1800–2600 px, converted
   to grayscale, brightness stretched (auto-levels) and contrast boosted,
   then written as PNG.
2. Recognition runs on the native engines' background threads (Tesseract
   via AsyncTask on Android and a GCD queue on iOS; ML Kit is async), so the
   UI stays responsive and shows per-page progress.
3. The text is cleaned (trailing spaces, extra blank lines) and shown in an
   editable field with Copy, Share and Save .txt.

## Release builds

### Android APK / App Bundle

1. Create a keystore (once):
   ```bash
   keytool -genkeypair -v -keystore android/app/bangla-scanner-release.jks \
     -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias banglascanner
   ```
2. Create `android/key.properties` (git-ignored, like the keystore):
   ```properties
   storeFile=bangla-scanner-release.jks
   storePassword=...
   keyAlias=banglascanner
   keyPassword=...
   ```
   `android/app/build.gradle.kts` picks it up automatically and signs debug
   builds with the same key, so a local run and a tester build of the same
   flavor replace each other. Without it, every build is signed with the debug
   key (fine for testing only). Back up both files: with a different key,
   testers must uninstall before they can update.
3. Build:
   ```bash
   flutter build appbundle --release --flavor prod            # for Google Play (.aab)
   flutter build apk --release --flavor prod --split-per-abi  # smaller APKs per CPU type
   ```
   Outputs: `build/app/outputs/bundle/prodRelease/app-prod-release.aab` and
   `build/app/outputs/flutter-apk/app-*-prod-release.apk`.

Tesseract ships native libraries for four ABIs (~8 MB each); the App Bundle
or `--split-per-abi` makes each user download only one.

### Tester builds (Firebase App Distribution)

```bash
./release_script.sh dev    # bump version, test, build the dev APK, upload to testers
./release_script.sh prod   # same for the prod flavor
```

The script bumps the patch version in `pubspec.yaml` on every run (`prod` also
bumps the build number; `dev` uses its own counter in `dev_build_number.txt`),
keeps a stamped copy of each APK in `build/releases/` and sends
`release_note.txt` as the "What's new" text. Edit `release_note.txt` before
each release.

| | |
|---|---|
| Firebase project | `bangla-scanner` (owner `anwarcs36@gmail.com`) |
| prod app | `com.codeinherit.banglascanner` — `1:670275906113:android:b35db59c5d291e399bb4c0` |
| dev app | `com.codeinherit.banglascanner.dev` — `1:670275906113:android:f91d203c33c36a019bb4c0` |
| Tester group | `scanner-testers` |

Both clients live in the single `android/app/google-services.json`. Add
testers with `firebase appdistribution:testers:add <email> --group-alias
scanner-testers --project bangla-scanner --account anwarcs36@gmail.com`; they
must accept the invitation e-mail before builds show up in the Firebase App
Tester app.

Crashlytics and Analytics are initialised on Android only (`lib/main.dart`).
Scanning, OCR and export stay fully offline; crash reports are sent when the
device is next online.

### iOS archive

1. Open `ios/Runner.xcworkspace` in Xcode, select the Runner target, and set
   your Team and signing under *Signing & Capabilities*.
2. Build the archive:
   ```bash
   flutter build ipa --release
   ```
   Output: `build/ios/archive/Runner.xcarchive` and
   `build/ios/ipa/*.ipa`. Upload with Xcode's Organizer or Transporter.

## Error handling

- Scan cancelled → short message, nothing saved.
- Permission denied → explanation dialog; permanently denied → "Open
  Settings" button.
- Storage full (`ENOSPC`) → clear message; documents are written to a
  staging folder first, so a failed save never damages an existing document.
- Corrupt or missing image files → "file is damaged" / "files missing".
- OCR failure or no text found → explained, with a retry button.

## Not in this version

Cloud sync, accounts, free-hand annotations and AI features are planned for
later versions.

## Licenses

- Hind Siliguri font: SIL Open Font License (`assets/fonts/OFL.txt`).
- Tesseract models: Apache 2.0.
- flutter_tesseract_ocr: BSD-3-Clause (`packages/flutter_tesseract_ocr/LICENSE`).
