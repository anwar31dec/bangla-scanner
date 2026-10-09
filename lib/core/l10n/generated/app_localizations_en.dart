// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bangla Scanner';

  @override
  String get homeGreeting => 'Scan documents easily';

  @override
  String get homeScan => 'Scan';

  @override
  String get homeScanSubtitle => 'Use the camera to scan pages';

  @override
  String get homeImport => 'Import from Gallery';

  @override
  String get homeFlashScan => 'Flash Scan';

  @override
  String get homeFlashScanSubtitle =>
      'The flash lights up only when the photo is taken';

  @override
  String get homeIdCard => 'ID Card';

  @override
  String get homeRecent => 'Recent documents';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmpty => 'No documents yet';

  @override
  String get homeEmptyHint =>
      'Tap the Scan button to scan your first document.';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get scanCancelled => 'Scan cancelled';

  @override
  String get scanFailed => 'Could not scan. Please try again.';

  @override
  String get importFailed => 'Could not import the images.';

  @override
  String get flashOn => 'Flash on';

  @override
  String get flashAuto => 'Flash auto';

  @override
  String get flashOff => 'Flash off';

  @override
  String get captureAuto => 'Auto';

  @override
  String get captureManual => 'Manual';

  @override
  String get cameraNextPageHint =>
      'Page saved. Show the next page, or press Done.';

  @override
  String get cameraTakePhoto => 'Take photo';

  @override
  String get cameraUnavailable => 'Could not open the camera.';

  @override
  String get cameraRetake => 'Retake';

  @override
  String get cameraUsePage => 'Use page';

  @override
  String get cropCornersTitle => 'Adjust corners';

  @override
  String get cropCornersHint => 'Drag the corners to the edges of the page.';

  @override
  String get cropWholePhoto => 'Whole photo';

  @override
  String get permissionCameraTitle => 'Camera permission';

  @override
  String get permissionCameraBody =>
      'Bangla Scanner needs the camera to scan your documents. Photos stay on your phone.';

  @override
  String get permissionStorageTitle => 'Storage permission';

  @override
  String get permissionStorageBody =>
      'Bangla Scanner needs storage access to save a copy of your file in the Downloads folder.';

  @override
  String get permissionDeniedTitle => 'Permission needed';

  @override
  String get permissionDeniedBody =>
      'Permission was denied. Open Settings and allow it to use this feature.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get allow => 'Allow';

  @override
  String get cancel => 'Cancel';

  @override
  String get notNow => 'Not now';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Try again';

  @override
  String get discard => 'Discard';

  @override
  String get editorTitle => 'Edit pages';

  @override
  String editorPages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get editorAddPages => 'Add pages';

  @override
  String get addFromCamera => 'Scan with camera';

  @override
  String get addFromFlashCamera => 'Scan with flash camera';

  @override
  String get addFromGallery => 'Choose from gallery';

  @override
  String get editorSave => 'Save';

  @override
  String get editorDiscardTitle => 'Discard this scan?';

  @override
  String get editorDiscardBody => 'Pages you scanned will be lost.';

  @override
  String get editorEmpty => 'No pages. Add pages to continue.';

  @override
  String get editorDragHint =>
      'Hold and drag a page to change its order. Tap a page to edit it.';

  @override
  String pageLabel(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Page $numberString';
  }

  @override
  String pageEditTitle(int number, int total) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Page $numberString of $totalString';
  }

  @override
  String get crop => 'Crop';

  @override
  String get rotate => 'Rotate';

  @override
  String get delete => 'Delete';

  @override
  String get filter => 'Filter';

  @override
  String get filterOriginal => 'Original';

  @override
  String get filterAutoColor => 'Auto color';

  @override
  String get filterGrayscale => 'Grayscale';

  @override
  String get filterBlackWhite => 'Black & White';

  @override
  String get filterWhiteboard => 'Whiteboard';

  @override
  String get filterLightText => 'Light text';

  @override
  String get applyToAllPages => 'Apply to all pages';

  @override
  String get appliedToAll => 'Filter applied to all pages';

  @override
  String get deletePageTitle => 'Delete this page?';

  @override
  String get deletePageBody => 'This page will be removed from the document.';

  @override
  String get cropFailed => 'Could not crop this page.';

  @override
  String get saveTitle => 'Save document';

  @override
  String get fileName => 'File name';

  @override
  String get fileNameEmpty => 'Please enter a name';

  @override
  String get format => 'Format';

  @override
  String get formatPdf => 'PDF';

  @override
  String get formatJpeg => 'JPEG';

  @override
  String get quality => 'Quality';

  @override
  String get qualityLow => 'Low';

  @override
  String get qualityMedium => 'Medium';

  @override
  String get qualityHigh => 'High';

  @override
  String get qualityHint => 'Higher quality makes larger files.';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String savingProgress(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Processing page $currentString of $totalString';
  }

  @override
  String get saved => 'Saved';

  @override
  String get libraryTitle => 'My documents';

  @override
  String get searchHint => 'Search by name';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortNameAz => 'Name (A–Z)';

  @override
  String get sortNameZa => 'Name (Z–A)';

  @override
  String get libraryEmpty => 'Your scanned documents will appear here.';

  @override
  String get librarySearchEmpty => 'No document found with this name.';

  @override
  String get rename => 'Rename';

  @override
  String get renameTitle => 'Rename document';

  @override
  String get deleteDocTitle => 'Delete document?';

  @override
  String deleteDocBody(String name) {
    return '\"$name\" will be deleted permanently.';
  }

  @override
  String get deleted => 'Document deleted';

  @override
  String get share => 'Share';

  @override
  String get saveToDevice => 'Save to phone';

  @override
  String get savedToDownloads => 'Saved to Downloads/Bangla Scanner';

  @override
  String get savedToFiles => 'Saved';

  @override
  String get extractText => 'Extract text';

  @override
  String get edit => 'Edit';

  @override
  String get documentMissing =>
      'This document\'s files are missing or damaged.';

  @override
  String get merge => 'Merge';

  @override
  String get mergeTooltip => 'Merge documents';

  @override
  String mergeSelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
      one: '1 selected',
      zero: 'Select documents to merge',
    );
    return '$_temp0';
  }

  @override
  String get mergeHint =>
      'Tap documents in the order you want them. Then press Merge to combine them into one new PDF or image set.';

  @override
  String get mergeNeedTwo => 'Select at least 2 documents to merge.';

  @override
  String mergeSkippedMissing(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString documents were skipped because their files are missing.',
      one: '1 document was skipped because its files are missing.',
    );
    return '$_temp0';
  }

  @override
  String get mergePreparing => 'Preparing pages…';

  @override
  String get errorCorruptFile => 'This file is damaged and cannot be opened.';

  @override
  String get errorLowStorage =>
      'Your phone storage is full. Free up some space and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get ocrTitle => 'Extract text';

  @override
  String get ocrLanguage => 'Text language';

  @override
  String get ocrLangBangla => 'বাংলা';

  @override
  String get ocrLangEnglish => 'English';

  @override
  String get ocrLangBoth => 'Both';

  @override
  String get ocrStart => 'Start';

  @override
  String get ocrPreparing => 'Getting ready…';

  @override
  String ocrPreprocessing(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Improving image (page $currentString of $totalString)';
  }

  @override
  String ocrRecognizing(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Reading text (page $currentString of $totalString)';
  }

  @override
  String get ocrFailed => 'Could not read the text. Try a clearer scan.';

  @override
  String get ocrNoText => 'No text was found on these pages.';

  @override
  String get ocrResultTitle => 'Extracted text';

  @override
  String get ocrHint => 'You can edit the text before copying or sharing it.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get saveTxt => 'Save .txt';

  @override
  String get idCardTitle => 'ID Card';

  @override
  String get idCardFront => 'Front side';

  @override
  String get idCardBack => 'Back side';

  @override
  String get idCardHintFront =>
      'Place the FRONT side of the card on a dark, flat surface and scan it.';

  @override
  String get idCardHintBack => 'Now turn the card over and scan the BACK side.';

  @override
  String get idCardScan => 'Scan';

  @override
  String get idCardFromGallery => 'From gallery';

  @override
  String get idCardRetake => 'Retake';

  @override
  String get idCardNext => 'Next';

  @override
  String get idCardCreate => 'Create A4 page';

  @override
  String get idCardReadyHint =>
      'Both sides will be placed on one A4 page at real card size.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsDefaultFormat => 'Default save format';

  @override
  String get settingsDefaultQuality => 'Default PDF quality';

  @override
  String get settingsDefaultOcr => 'Default OCR language';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsOffline =>
      'Everything works offline. Your documents never leave your phone.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }
}
