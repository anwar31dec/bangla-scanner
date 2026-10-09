# Local patches

This is a vendored copy of `flutter_tesseract_ocr` 0.4.31 (BSD-3-Clause,
see LICENSE) with the following changes so it builds and runs with the
current Flutter toolchain:

- `android/build.gradle`: removed the AGP 7 `buildscript` block and
  `jcenter()` (removed in Gradle 9), replaced `lintOptions` with `lint`,
  set Java 17, added R8 keep rules (`proguard-rules.pro`) for the JNI
  classes so release builds don't break OCR.
- Android plugin: recycles the previous engine, reports init/OCR failures as
  `PlatformException` instead of crashing or hanging.
- iOS plugin: reads traineddata from `<Documents>/tessdata` (populated by the
  Dart side) instead of symlinking into the read-only app bundle; always
  completes the method call (errors included); uses the SwiftyTesseract 3 API.
- Removed the web implementation, example app and demo assets.
- iOS plugin: implements `extractHocr` (the Dart API already had it; only
  Android answered). It runs `performOCR` and then SwiftyTesseract's
  `recognizedBlocks(for:)` at line and word level, and writes a minimal hOCR
  document (`ocr_line` / `ocrx_word` spans with `bbox` in image pixels) in
  the same shape as Tesseract's own output on Android, so the Dart parser
  (`HocrParser`) is shared.
