import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bangla Scanner'**
  String get appTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Scan documents easily'**
  String get homeGreeting;

  /// No description provided for @homeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get homeScan;

  /// No description provided for @homeScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the camera to scan pages'**
  String get homeScanSubtitle;

  /// No description provided for @homeImport.
  ///
  /// In en, this message translates to:
  /// **'Import from Gallery'**
  String get homeImport;

  /// No description provided for @homeFlashScan.
  ///
  /// In en, this message translates to:
  /// **'Flash Scan'**
  String get homeFlashScan;

  /// No description provided for @homeFlashScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The flash lights up only when the photo is taken'**
  String get homeFlashScanSubtitle;

  /// No description provided for @homeIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get homeIdCard;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent documents'**
  String get homeRecent;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get homeEmpty;

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the Scan button to scan your first document.'**
  String get homeEmptyHint;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @scanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scan cancelled'**
  String get scanCancelled;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not scan. Please try again.'**
  String get scanFailed;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import the images.'**
  String get importFailed;

  /// No description provided for @flashOn.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get flashOn;

  /// No description provided for @flashAuto.
  ///
  /// In en, this message translates to:
  /// **'Flash auto'**
  String get flashAuto;

  /// No description provided for @flashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get flashOff;

  /// No description provided for @captureAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get captureAuto;

  /// No description provided for @captureManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get captureManual;

  /// No description provided for @cameraNextPageHint.
  ///
  /// In en, this message translates to:
  /// **'Page saved. Show the next page, or press Done.'**
  String get cameraNextPageHint;

  /// No description provided for @cameraTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get cameraTakePhoto;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera.'**
  String get cameraUnavailable;

  /// No description provided for @cameraRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cameraRetake;

  /// No description provided for @cameraUsePage.
  ///
  /// In en, this message translates to:
  /// **'Use page'**
  String get cameraUsePage;

  /// No description provided for @cropCornersTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust corners'**
  String get cropCornersTitle;

  /// No description provided for @cropCornersHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the corners to the edges of the page.'**
  String get cropCornersHint;

  /// No description provided for @cropWholePhoto.
  ///
  /// In en, this message translates to:
  /// **'Whole photo'**
  String get cropWholePhoto;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera permission'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Bangla Scanner needs the camera to scan your documents. Photos stay on your phone.'**
  String get permissionCameraBody;

  /// No description provided for @permissionStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage permission'**
  String get permissionStorageTitle;

  /// No description provided for @permissionStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Bangla Scanner needs storage access to save a copy of your file in the Downloads folder.'**
  String get permissionStorageBody;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Permission was denied. Open Settings and allow it to use this feature.'**
  String get permissionDeniedBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit pages'**
  String get editorTitle;

  /// No description provided for @editorPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String editorPages(int count);

  /// No description provided for @editorAddPages.
  ///
  /// In en, this message translates to:
  /// **'Add pages'**
  String get editorAddPages;

  /// No description provided for @addFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get addFromCamera;

  /// No description provided for @addFromFlashCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with flash camera'**
  String get addFromFlashCamera;

  /// No description provided for @addFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get addFromGallery;

  /// No description provided for @editorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorSave;

  /// No description provided for @editorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this scan?'**
  String get editorDiscardTitle;

  /// No description provided for @editorDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Pages you scanned will be lost.'**
  String get editorDiscardBody;

  /// No description provided for @editorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pages. Add pages to continue.'**
  String get editorEmpty;

  /// No description provided for @editorDragHint.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag a page to change its order. Tap a page to edit it.'**
  String get editorDragHint;

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageLabel(int number);

  /// No description provided for @pageEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Page {number} of {total}'**
  String pageEditTitle(int number, int total);

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get filterOriginal;

  /// No description provided for @filterAutoColor.
  ///
  /// In en, this message translates to:
  /// **'Auto color'**
  String get filterAutoColor;

  /// No description provided for @filterGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get filterGrayscale;

  /// No description provided for @filterBlackWhite.
  ///
  /// In en, this message translates to:
  /// **'Black & White'**
  String get filterBlackWhite;

  /// No description provided for @filterWhiteboard.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get filterWhiteboard;

  /// No description provided for @filterLightText.
  ///
  /// In en, this message translates to:
  /// **'Light text'**
  String get filterLightText;

  /// No description provided for @applyToAllPages.
  ///
  /// In en, this message translates to:
  /// **'Apply to all pages'**
  String get applyToAllPages;

  /// No description provided for @appliedToAll.
  ///
  /// In en, this message translates to:
  /// **'Filter applied to all pages'**
  String get appliedToAll;

  /// No description provided for @deletePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this page?'**
  String get deletePageTitle;

  /// No description provided for @deletePageBody.
  ///
  /// In en, this message translates to:
  /// **'This page will be removed from the document.'**
  String get deletePageBody;

  /// No description provided for @cropFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not crop this page.'**
  String get cropFailed;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save document'**
  String get saveTitle;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @fileNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get fileNameEmpty;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @formatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get formatPdf;

  /// No description provided for @formatJpeg.
  ///
  /// In en, this message translates to:
  /// **'JPEG'**
  String get formatJpeg;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @qualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get qualityLow;

  /// No description provided for @qualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get qualityMedium;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityHigh;

  /// No description provided for @qualityHint.
  ///
  /// In en, this message translates to:
  /// **'Higher quality makes larger files.'**
  String get qualityHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @savingProgress.
  ///
  /// In en, this message translates to:
  /// **'Processing page {current} of {total}'**
  String savingProgress(int current, int total);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My documents'**
  String get libraryTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchHint;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortNameAz.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get sortNameAz;

  /// No description provided for @sortNameZa.
  ///
  /// In en, this message translates to:
  /// **'Name (Z–A)'**
  String get sortNameZa;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your scanned documents will appear here.'**
  String get libraryEmpty;

  /// No description provided for @librarySearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No document found with this name.'**
  String get librarySearchEmpty;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename document'**
  String get renameTitle;

  /// No description provided for @deleteDocTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get deleteDocTitle;

  /// No description provided for @deleteDocBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted permanently.'**
  String deleteDocBody(String name);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted'**
  String get deleted;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to phone'**
  String get saveToDevice;

  /// No description provided for @savedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads/Bangla Scanner'**
  String get savedToDownloads;

  /// No description provided for @savedToFiles.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedToFiles;

  /// No description provided for @extractText.
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get extractText;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @documentMissing.
  ///
  /// In en, this message translates to:
  /// **'This document\'s files are missing or damaged.'**
  String get documentMissing;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @mergeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Merge documents'**
  String get mergeTooltip;

  /// No description provided for @mergeSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Select documents to merge} =1{1 selected} other{{count} selected}}'**
  String mergeSelected(int count);

  /// No description provided for @mergeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap documents in the order you want them. Then press Merge to combine them into one new PDF or image set.'**
  String get mergeHint;

  /// No description provided for @mergeNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 documents to merge.'**
  String get mergeNeedTwo;

  /// No description provided for @mergeSkippedMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document was skipped because its files are missing.} other{{count} documents were skipped because their files are missing.}}'**
  String mergeSkippedMissing(int count);

  /// No description provided for @mergePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing pages…'**
  String get mergePreparing;

  /// No description provided for @errorCorruptFile.
  ///
  /// In en, this message translates to:
  /// **'This file is damaged and cannot be opened.'**
  String get errorCorruptFile;

  /// No description provided for @errorLowStorage.
  ///
  /// In en, this message translates to:
  /// **'Your phone storage is full. Free up some space and try again.'**
  String get errorLowStorage;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @ocrTitle.
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get ocrTitle;

  /// No description provided for @ocrLanguage.
  ///
  /// In en, this message translates to:
  /// **'Text language'**
  String get ocrLanguage;

  /// No description provided for @ocrLangBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get ocrLangBangla;

  /// No description provided for @ocrLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get ocrLangEnglish;

  /// No description provided for @ocrLangBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get ocrLangBoth;

  /// No description provided for @ocrStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get ocrStart;

  /// No description provided for @ocrPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get ocrPreparing;

  /// No description provided for @ocrPreprocessing.
  ///
  /// In en, this message translates to:
  /// **'Improving image (page {current} of {total})'**
  String ocrPreprocessing(int current, int total);

  /// No description provided for @ocrRecognizing.
  ///
  /// In en, this message translates to:
  /// **'Reading text (page {current} of {total})'**
  String ocrRecognizing(int current, int total);

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the text. Try a clearer scan.'**
  String get ocrFailed;

  /// No description provided for @ocrNoText.
  ///
  /// In en, this message translates to:
  /// **'No text was found on these pages.'**
  String get ocrNoText;

  /// No description provided for @ocrResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Extracted text'**
  String get ocrResultTitle;

  /// No description provided for @ocrHint.
  ///
  /// In en, this message translates to:
  /// **'You can edit the text before copying or sharing it.'**
  String get ocrHint;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @saveTxt.
  ///
  /// In en, this message translates to:
  /// **'Save .txt'**
  String get saveTxt;

  /// No description provided for @idCardTitle.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idCardTitle;

  /// No description provided for @idCardFront.
  ///
  /// In en, this message translates to:
  /// **'Front side'**
  String get idCardFront;

  /// No description provided for @idCardBack.
  ///
  /// In en, this message translates to:
  /// **'Back side'**
  String get idCardBack;

  /// No description provided for @idCardHintFront.
  ///
  /// In en, this message translates to:
  /// **'Place the FRONT side of the card on a dark, flat surface and scan it.'**
  String get idCardHintFront;

  /// No description provided for @idCardHintBack.
  ///
  /// In en, this message translates to:
  /// **'Now turn the card over and scan the BACK side.'**
  String get idCardHintBack;

  /// No description provided for @idCardScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get idCardScan;

  /// No description provided for @idCardFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get idCardFromGallery;

  /// No description provided for @idCardRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get idCardRetake;

  /// No description provided for @idCardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get idCardNext;

  /// No description provided for @idCardCreate.
  ///
  /// In en, this message translates to:
  /// **'Create A4 page'**
  String get idCardCreate;

  /// No description provided for @idCardReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Both sides will be placed on one A4 page at real card size.'**
  String get idCardReadyHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsDefaultFormat.
  ///
  /// In en, this message translates to:
  /// **'Default save format'**
  String get settingsDefaultFormat;

  /// No description provided for @settingsDefaultQuality.
  ///
  /// In en, this message translates to:
  /// **'Default PDF quality'**
  String get settingsDefaultQuality;

  /// No description provided for @settingsDefaultOcr.
  ///
  /// In en, this message translates to:
  /// **'Default OCR language'**
  String get settingsDefaultOcr;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsOffline.
  ///
  /// In en, this message translates to:
  /// **'Everything works offline. Your documents never leave your phone.'**
  String get settingsOffline;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favorites;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @renameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get renameFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get deleteFolder;

  /// No description provided for @deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete folder?'**
  String get deleteFolderTitle;

  /// No description provided for @deleteFolderBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted. Its documents stay in the library.'**
  String deleteFolderBody(String name);

  /// No description provided for @folderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get folderCreated;

  /// No description provided for @moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get moveToFolder;

  /// No description provided for @noFolder.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get noFolder;

  /// No description provided for @movedToFolder.
  ///
  /// In en, this message translates to:
  /// **'Moved to \"{name}\"'**
  String movedToFolder(String name);

  /// No description provided for @removedFromFolder.
  ///
  /// In en, this message translates to:
  /// **'Removed from folder'**
  String get removedFromFolder;

  /// No description provided for @noFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders yet. Create one to organise your documents.'**
  String get noFoldersYet;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFromFavorites;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Star a document to find it here quickly.'**
  String get favoritesEmpty;

  /// No description provided for @folderEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty. Move documents here from their menu.'**
  String get folderEmpty;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Select documents} =1{1 selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap documents to select them. Merge joins them in the order you tapped.'**
  String get selectionHint;

  /// No description provided for @deleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 document?} other{Delete {count} documents?}}'**
  String deleteSelectedTitle(int count);

  /// No description provided for @deleteSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'They will be deleted permanently.'**
  String get deleteSelectedBody;

  /// No description provided for @deletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document deleted} other{{count} documents deleted}}'**
  String deletedCount(int count);

  /// No description provided for @protectWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Protect with a password'**
  String get protectWithPassword;

  /// No description provided for @pdfPassword.
  ///
  /// In en, this message translates to:
  /// **'PDF password'**
  String get pdfPassword;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'The PDF opens only with this password. Keep it safe: it cannot be recovered.'**
  String get passwordHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 4 characters'**
  String get passwordTooShort;

  /// No description provided for @enterPdfPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the PDF password'**
  String get enterPdfPassword;

  /// No description provided for @enterPdfPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'This PDF is protected. Enter its password so it can be rebuilt with the new pages.'**
  String get enterPdfPasswordBody;

  /// No description provided for @protectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Password protected'**
  String get protectedBadge;

  /// No description provided for @pageSize.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get pageSize;

  /// No description provided for @pageSizeAuto.
  ///
  /// In en, this message translates to:
  /// **'Fit to scan'**
  String get pageSizeAuto;

  /// No description provided for @pageSizeA4.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get pageSizeA4;

  /// No description provided for @pageSizeLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get pageSizeLetter;

  /// No description provided for @pageSizeLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get pageSizeLegal;

  /// No description provided for @pageSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Fit to scan keeps each page the shape of the scan. A4, Letter and Legal place the scan on real paper for printing.'**
  String get pageSizeHint;

  /// No description provided for @settingsDefaultPageSize.
  ///
  /// In en, this message translates to:
  /// **'Default PDF page size'**
  String get settingsDefaultPageSize;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @appLockEnable.
  ///
  /// In en, this message translates to:
  /// **'Lock the app with a PIN'**
  String get appLockEnable;

  /// No description provided for @appLockBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint or face'**
  String get appLockBiometric;

  /// No description provided for @appLockDelay.
  ///
  /// In en, this message translates to:
  /// **'Lock after leaving the app'**
  String get appLockDelay;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockImmediately;

  /// No description provided for @lockAfterOneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get lockAfterOneMinute;

  /// No description provided for @lockAfterFiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get lockAfterFiveMinutes;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get setPinTitle;

  /// No description provided for @setPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 to 8 digits. You will need it to open the app.'**
  String get setPinHint;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get confirmPinTitle;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get enterCurrentPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'The PIN needs at least 4 digits.'**
  String get pinTooShort;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bangla Scanner is locked'**
  String get lockedTitle;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face'**
  String get unlockWithBiometrics;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Bangla Scanner'**
  String get biometricReason;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or face unlock is set up on this phone.'**
  String get biometricUnavailable;

  /// No description provided for @appLockOn.
  ///
  /// In en, this message translates to:
  /// **'App lock is on'**
  String get appLockOn;

  /// No description provided for @appLockOff.
  ///
  /// In en, this message translates to:
  /// **'App lock is off'**
  String get appLockOff;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @filterStrength.
  ///
  /// In en, this message translates to:
  /// **'Filter strength'**
  String get filterStrength;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @resetAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAdjustments;

  /// No description provided for @bookSplit.
  ///
  /// In en, this message translates to:
  /// **'Book split'**
  String get bookSplit;

  /// No description provided for @bookSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split this page in two?'**
  String get bookSplitTitle;

  /// No description provided for @bookSplitBody.
  ///
  /// In en, this message translates to:
  /// **'For a photo of an open book: the page is cut into a left and a right page (top and bottom for a tall photo).'**
  String get bookSplitBody;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @pageSplitDone.
  ///
  /// In en, this message translates to:
  /// **'Page split into two pages'**
  String get pageSplitDone;

  /// No description provided for @reorderPages.
  ///
  /// In en, this message translates to:
  /// **'Reorder pages'**
  String get reorderPages;

  /// No description provided for @pagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesTitle;

  /// No description provided for @pagesHint.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag to reorder. Tap the bin to remove a page.'**
  String get pagesHint;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @pagesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pages updated'**
  String get pagesUpdated;

  /// No description provided for @pagesNeedOne.
  ///
  /// In en, this message translates to:
  /// **'A document needs at least one page.'**
  String get pagesNeedOne;

  /// No description provided for @zoomHint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to zoom. Pinch to zoom in and out.'**
  String get zoomHint;

  /// No description provided for @cardKind.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get cardKind;

  /// No description provided for @cardKindId.
  ///
  /// In en, this message translates to:
  /// **'NID / Smart card'**
  String get cardKindId;

  /// No description provided for @cardKindPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get cardKindPassport;

  /// No description provided for @idCardHintPassport.
  ///
  /// In en, this message translates to:
  /// **'Place the passport\'s photo page on a dark, flat surface and scan it.'**
  String get idCardHintPassport;

  /// No description provided for @idCardPassportSecond.
  ///
  /// In en, this message translates to:
  /// **'Second page (optional)'**
  String get idCardPassportSecond;

  /// No description provided for @idCardPassportReady.
  ///
  /// In en, this message translates to:
  /// **'The page will be placed on A4 at real passport size.'**
  String get idCardPassportReady;

  /// No description provided for @idCardOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get idCardOptional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
