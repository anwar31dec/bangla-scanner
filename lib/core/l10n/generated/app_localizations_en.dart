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
  String get homeImport => 'Import';

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
  String get searchHint => 'Search by name or text';

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
  String get librarySearchEmpty => 'No document found with this name or text.';

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

  @override
  String get folders => 'Folders';

  @override
  String get filterAll => 'All';

  @override
  String get favorites => 'Favourites';

  @override
  String get newFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get renameFolder => 'Rename folder';

  @override
  String get deleteFolder => 'Delete folder';

  @override
  String get deleteFolderTitle => 'Delete folder?';

  @override
  String deleteFolderBody(String name) {
    return '\"$name\" will be deleted. Its documents stay in the library.';
  }

  @override
  String get folderCreated => 'Folder created';

  @override
  String get moveToFolder => 'Move to folder';

  @override
  String get noFolder => 'No folder';

  @override
  String movedToFolder(String name) {
    return 'Moved to \"$name\"';
  }

  @override
  String get removedFromFolder => 'Removed from folder';

  @override
  String get noFoldersYet =>
      'No folders yet. Create one to organise your documents.';

  @override
  String get addToFavorites => 'Add to favourites';

  @override
  String get removeFromFavorites => 'Remove from favourites';

  @override
  String get favoritesEmpty => 'Star a document to find it here quickly.';

  @override
  String get folderEmpty =>
      'This folder is empty. Move documents here from their menu.';

  @override
  String get select => 'Select';

  @override
  String selectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
      one: '1 selected',
      zero: 'Select documents',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get selectionHint =>
      'Tap documents to select them. Merge joins them in the order you tapped.';

  @override
  String deleteSelectedTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString documents?',
      one: 'Delete 1 document?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'They will be deleted permanently.';

  @override
  String deletedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString documents deleted',
      one: '1 document deleted',
    );
    return '$_temp0';
  }

  @override
  String get protectWithPassword => 'Protect with a password';

  @override
  String get pdfPassword => 'PDF password';

  @override
  String get passwordHint =>
      'The PDF opens only with this password. Keep it safe: it cannot be recovered.';

  @override
  String get passwordTooShort => 'Use at least 4 characters';

  @override
  String get enterPdfPassword => 'Enter the PDF password';

  @override
  String get enterPdfPasswordBody =>
      'This PDF is protected. Enter its password so it can be rebuilt with the new pages.';

  @override
  String get protectedBadge => 'Password protected';

  @override
  String get searchableBadge => 'Searchable (text recognized)';

  @override
  String textMatch(String snippet) {
    return 'In text: $snippet';
  }

  @override
  String get searchablePdf => 'Searchable PDF (recognize text)';

  @override
  String get searchablePdfHint =>
      'Reads the text while saving, so you can search inside the PDF in any viewer and find the document by its words in the library. Takes longer.';

  @override
  String get settingsSearchablePdf => 'Make PDFs searchable';

  @override
  String get settingsSearchablePdfHint =>
      'Recognize the text whenever a PDF is saved (can be changed per document).';

  @override
  String get ocrTextSaved =>
      'Text saved. The document can now be found by its words.';

  @override
  String get ocrPdfNotUpdated =>
      'Text saved for search, but the PDF was left as it is without its password.';

  @override
  String get enterPdfPasswordOcrBody =>
      'This PDF is protected. Enter its password to add the recognized text to it.';

  @override
  String get pageSize => 'Page size';

  @override
  String get pageSizeAuto => 'Fit to scan';

  @override
  String get pageSizeA4 => 'A4';

  @override
  String get pageSizeLetter => 'Letter';

  @override
  String get pageSizeLegal => 'Legal';

  @override
  String get pageSizeHint =>
      'Fit to scan keeps each page the shape of the scan. A4, Letter and Legal place the scan on real paper for printing.';

  @override
  String get settingsDefaultPageSize => 'Default PDF page size';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get appLockEnable => 'Lock the app with a PIN';

  @override
  String get appLockBiometric => 'Unlock with fingerprint or face';

  @override
  String get appLockDelay => 'Lock after leaving the app';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String get lockAfterOneMinute => '1 minute';

  @override
  String get lockAfterFiveMinutes => '5 minutes';

  @override
  String get changePin => 'Change PIN';

  @override
  String get setPinTitle => 'Set a PIN';

  @override
  String get setPinHint =>
      'Enter 4 to 8 digits. You will need it to open the app.';

  @override
  String get confirmPinTitle => 'Enter the PIN again';

  @override
  String get enterCurrentPin => 'Enter your current PIN';

  @override
  String get pinMismatch => 'The PINs do not match. Try again.';

  @override
  String get pinTooShort => 'The PIN needs at least 4 digits.';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get lockedTitle => 'Bangla Scanner is locked';

  @override
  String get unlockWithBiometrics => 'Use fingerprint or face';

  @override
  String get biometricReason => 'Unlock Bangla Scanner';

  @override
  String get biometricUnavailable =>
      'No fingerprint or face unlock is set up on this phone.';

  @override
  String get appLockOn => 'App lock is on';

  @override
  String get appLockOff => 'App lock is off';

  @override
  String get adjust => 'Adjust';

  @override
  String get filterStrength => 'Filter strength';

  @override
  String get brightness => 'Brightness';

  @override
  String get contrast => 'Contrast';

  @override
  String get resetAdjustments => 'Reset';

  @override
  String get bookSplit => 'Book split';

  @override
  String get bookSplitTitle => 'Split this page in two?';

  @override
  String get bookSplitBody =>
      'For a photo of an open book: the page is cut into a left and a right page (top and bottom for a tall photo).';

  @override
  String get split => 'Split';

  @override
  String get pageSplitDone => 'Page split into two pages';

  @override
  String get reorderPages => 'Reorder pages';

  @override
  String get pagesTitle => 'Pages';

  @override
  String get pagesHint =>
      'Hold and drag to reorder. Tap the bin to remove a page.';

  @override
  String get apply => 'Apply';

  @override
  String get pagesUpdated => 'Pages updated';

  @override
  String get pagesNeedOne => 'A document needs at least one page.';

  @override
  String get zoomHint => 'Double-tap to zoom. Pinch to zoom in and out.';

  @override
  String get cardKind => 'Document type';

  @override
  String get cardKindId => 'NID / Smart card';

  @override
  String get cardKindPassport => 'Passport';

  @override
  String get idCardHintPassport =>
      'Place the passport\'s photo page on a dark, flat surface and scan it.';

  @override
  String get idCardPassportSecond => 'Second page (optional)';

  @override
  String get idCardPassportReady =>
      'The page will be placed on A4 at real passport size.';

  @override
  String get idCardOptional => 'Optional';

  @override
  String get importFromGallery => 'Photos from gallery';

  @override
  String get importPdf => 'PDF file';

  @override
  String get importPdfHint =>
      'Each page of the PDF becomes a page you can crop, filter and OCR.';

  @override
  String get addFromPdf => 'From a PDF file';

  @override
  String get importingPdf => 'Reading PDF…';

  @override
  String importingPdfProgress(int done, int total) {
    return 'Page $done of $total';
  }

  @override
  String pdfTooManyPages(int max) {
    return 'Only the first $max pages were imported.';
  }

  @override
  String get errorPdfLocked =>
      'This PDF has a password. Remove the password first, then import it.';

  @override
  String get receivedTitle => 'Files received';

  @override
  String get receivedAddOrNewBody =>
      'A document is already open. Add these pages to it, or start a new document?';

  @override
  String get receivedAddToCurrent => 'Add to current';

  @override
  String get receivedNewDocument => 'New document';

  @override
  String get receivedUnsupported =>
      'That file type is not supported. Send photos or a PDF.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupSettingsHint =>
      'Save all documents to one file, or bring them back';

  @override
  String get backupIntro =>
      'Your documents live only on this phone. Make a backup before changing phones or clearing the app, and restore it on the new phone.';

  @override
  String get backupCreate => 'Create backup';

  @override
  String get backupCreateHint =>
      'Saves every document and folder in one .zip file.';

  @override
  String backupStats(int count, String size) {
    return '$count documents, $size';
  }

  @override
  String get backupRestore => 'Restore from backup';

  @override
  String get backupRestoreHint =>
      'Pick a .zip backup file. Documents already in the library are kept.';

  @override
  String get backupCreating => 'Creating backup…';

  @override
  String backupProgress(int done, int total) {
    return 'Document $done of $total';
  }

  @override
  String backupReady(String size) {
    return 'Backup ready ($size)';
  }

  @override
  String get backupSave => 'Save to phone';

  @override
  String get backupSaveHintAndroid => 'Downloads/Bangla Scanner';

  @override
  String get backupSaveHintIos => 'Choose a place in the Files app';

  @override
  String get backupShare => 'Share';

  @override
  String get backupShareHint => 'Send to Google Drive, WhatsApp, e-mail…';

  @override
  String get backupEmpty => 'There are no documents to back up.';

  @override
  String get backupRestoring => 'Restoring…';

  @override
  String get backupRestoreConfirmTitle => 'Restore this backup?';

  @override
  String backupRestoreConfirmBody(int count, String date) {
    return '$count documents, made on $date. Documents already in the library are kept; the others are added.';
  }

  @override
  String get restore => 'Restore';

  @override
  String backupRestored(int added, int skipped) {
    return '$added documents restored, $skipped already present';
  }

  @override
  String get backupInvalid => 'This is not a Bangla Scanner backup file.';

  @override
  String get signTool => 'Sign';

  @override
  String get stampSheetTitle => 'Signature or stamp';

  @override
  String get signatures => 'Signatures';

  @override
  String get drawSignature => 'Draw new';

  @override
  String get noSignatures =>
      'No saved signatures yet. Draw one and use it on any page.';

  @override
  String get stamps => 'Stamps';

  @override
  String get stampAttested => 'Attested';

  @override
  String get stampTrueCopy => 'True copy';

  @override
  String get stampOriginalSeen => 'Original seen';

  @override
  String get stampPaid => 'Paid';

  @override
  String get stampReceived => 'Received';

  @override
  String get stampCustom => 'Custom text…';

  @override
  String get stampCustomTitle => 'Stamp text';

  @override
  String get stampText => 'Text';

  @override
  String get stampColorBlue => 'Blue';

  @override
  String get stampColorRed => 'Red';

  @override
  String get stampColorBlack => 'Black';

  @override
  String get stampBakeNote =>
      'The page\'s rotation and filter are applied permanently when a signature or stamp is added.';

  @override
  String get signaturePadTitle => 'Draw your signature';

  @override
  String get signaturePadHint =>
      'Sign with your finger inside the box. It is saved for later use.';

  @override
  String get saveSignature => 'Use signature';

  @override
  String get penThickness => 'Pen';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Clear';

  @override
  String get signatureEmpty => 'Draw something first.';

  @override
  String get deleteSignatureTitle => 'Delete this signature?';

  @override
  String get deleteSignatureBody =>
      'It is removed from the saved signatures. Pages already signed are not affected.';

  @override
  String get placeStampTitle => 'Place on page';

  @override
  String get placeStampHint => 'Drag to move. Pinch to resize or rotate.';

  @override
  String get stampSize => 'Size';

  @override
  String get resetRotation => 'Straighten';

  @override
  String get stampApplied => 'Added to the page';
}
