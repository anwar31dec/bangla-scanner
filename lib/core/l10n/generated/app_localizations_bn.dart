// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'বাংলা স্ক্যানার';

  @override
  String get homeGreeting => 'সহজেই ডকুমেন্ট স্ক্যান করুন';

  @override
  String get homeScan => 'স্ক্যান';

  @override
  String get homeScanSubtitle => 'ক্যামেরা দিয়ে পাতা স্ক্যান করুন';

  @override
  String get homeImport => 'ইমপোর্ট';

  @override
  String get homeFlashScan => 'ফ্ল্যাশ স্ক্যান';

  @override
  String get homeFlashScanSubtitle => 'শুধু ছবি তোলার মুহূর্তে ফ্ল্যাশ জ্বলবে';

  @override
  String get homeIdCard => 'আইডি কার্ড';

  @override
  String get homeRecent => 'সাম্প্রতিক ডকুমেন্ট';

  @override
  String get homeSeeAll => 'সব দেখুন';

  @override
  String get homeEmpty => 'এখনো কোনো ডকুমেন্ট নেই';

  @override
  String get homeEmptyHint =>
      'প্রথম ডকুমেন্ট স্ক্যান করতে স্ক্যান বোতামে চাপুন।';

  @override
  String get navLibrary => 'লাইব্রেরি';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get scanCancelled => 'স্ক্যান বাতিল করা হয়েছে';

  @override
  String get scanFailed => 'স্ক্যান করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get importFailed => 'ছবিগুলো আনা যায়নি।';

  @override
  String get flashOn => 'ফ্ল্যাশ চালু';

  @override
  String get flashAuto => 'ফ্ল্যাশ অটো';

  @override
  String get flashOff => 'ফ্ল্যাশ বন্ধ';

  @override
  String get captureAuto => 'অটো';

  @override
  String get captureManual => 'ম্যানুয়াল';

  @override
  String get cameraNextPageHint =>
      'পাতা রাখা হয়েছে। পরের পাতা দেখান, অথবা সম্পন্ন চাপুন।';

  @override
  String get cameraTakePhoto => 'ছবি তুলুন';

  @override
  String get cameraUnavailable => 'ক্যামেরা খোলা যায়নি।';

  @override
  String get cameraRetake => 'আবার তুলুন';

  @override
  String get cameraUsePage => 'পাতা রাখুন';

  @override
  String get cropCornersTitle => 'কোণা ঠিক করুন';

  @override
  String get cropCornersHint => 'কোণাগুলো টেনে পাতার কিনারায় আনুন।';

  @override
  String get cropWholePhoto => 'পুরো ছবি';

  @override
  String get permissionCameraTitle => 'ক্যামেরার অনুমতি';

  @override
  String get permissionCameraBody =>
      'ডকুমেন্ট স্ক্যান করতে বাংলা স্ক্যানারের ক্যামেরা ব্যবহারের অনুমতি দরকার। ছবি আপনার ফোনেই থাকবে।';

  @override
  String get permissionStorageTitle => 'স্টোরেজের অনুমতি';

  @override
  String get permissionStorageBody =>
      'ফাইলের একটি কপি ডাউনলোড ফোল্ডারে রাখতে বাংলা স্ক্যানারের স্টোরেজ ব্যবহারের অনুমতি দরকার।';

  @override
  String get permissionDeniedTitle => 'অনুমতি দরকার';

  @override
  String get permissionDeniedBody =>
      'অনুমতি দেওয়া হয়নি। এই সুবিধাটি ব্যবহার করতে সেটিংসে গিয়ে অনুমতি দিন।';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get allow => 'অনুমতি দিন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get notNow => 'এখন না';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get done => 'সম্পন্ন';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get discard => 'বাদ দিন';

  @override
  String get editorTitle => 'পাতা সম্পাদনা';

  @override
  String editorPages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি পাতা',
    );
    return '$_temp0';
  }

  @override
  String get editorAddPages => 'পাতা যোগ করুন';

  @override
  String get addFromCamera => 'ক্যামেরা দিয়ে স্ক্যান';

  @override
  String get addFromFlashCamera => 'ফ্ল্যাশ ক্যামেরা দিয়ে স্ক্যান';

  @override
  String get addFromGallery => 'গ্যালারি থেকে বাছুন';

  @override
  String get editorSave => 'সংরক্ষণ';

  @override
  String get editorDiscardTitle => 'এই স্ক্যান বাদ দেবেন?';

  @override
  String get editorDiscardBody => 'স্ক্যান করা পাতাগুলো হারিয়ে যাবে।';

  @override
  String get editorEmpty => 'কোনো পাতা নেই। চালিয়ে যেতে পাতা যোগ করুন।';

  @override
  String get editorDragHint =>
      'পাতার ক্রম বদলাতে চেপে ধরে টেনে আনুন। সম্পাদনা করতে পাতায় চাপুন।';

  @override
  String pageLabel(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'পাতা $numberString';
  }

  @override
  String pageEditTitle(int number, int total) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'পাতা $numberString / $totalString';
  }

  @override
  String get crop => 'কাটুন';

  @override
  String get rotate => 'ঘোরান';

  @override
  String get delete => 'মুছুন';

  @override
  String get filter => 'ফিল্টার';

  @override
  String get filterOriginal => 'আসল';

  @override
  String get filterAutoColor => 'অটো কালার';

  @override
  String get filterGrayscale => 'ধূসর';

  @override
  String get filterBlackWhite => 'সাদা-কালো';

  @override
  String get filterWhiteboard => 'হোয়াইটবোর্ড';

  @override
  String get filterLightText => 'হালকা লেখা';

  @override
  String get applyToAllPages => 'সব পাতায় প্রয়োগ করুন';

  @override
  String get appliedToAll => 'সব পাতায় ফিল্টার প্রয়োগ করা হয়েছে';

  @override
  String get deletePageTitle => 'এই পাতাটি মুছবেন?';

  @override
  String get deletePageBody => 'পাতাটি ডকুমেন্ট থেকে সরিয়ে ফেলা হবে।';

  @override
  String get cropFailed => 'এই পাতাটি কাটা যায়নি।';

  @override
  String get saveTitle => 'ডকুমেন্ট সংরক্ষণ';

  @override
  String get fileName => 'ফাইলের নাম';

  @override
  String get fileNameEmpty => 'একটি নাম লিখুন';

  @override
  String get format => 'ফরম্যাট';

  @override
  String get formatPdf => 'পিডিএফ';

  @override
  String get formatJpeg => 'জেপিইজি';

  @override
  String get quality => 'মান';

  @override
  String get qualityLow => 'কম';

  @override
  String get qualityMedium => 'মাঝারি';

  @override
  String get qualityHigh => 'উচ্চ';

  @override
  String get qualityHint => 'মান বেশি হলে ফাইলের আকারও বড় হয়।';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get saving => 'সংরক্ষণ হচ্ছে…';

  @override
  String savingProgress(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalStringটির মধ্যে $currentString নম্বর পাতা প্রস্তুত হচ্ছে';
  }

  @override
  String get saved => 'সংরক্ষিত হয়েছে';

  @override
  String get libraryTitle => 'আমার ডকুমেন্ট';

  @override
  String get searchHint => 'নাম দিয়ে খুঁজুন';

  @override
  String get sortBy => 'সাজান';

  @override
  String get sortNewest => 'নতুন আগে';

  @override
  String get sortOldest => 'পুরনো আগে';

  @override
  String get sortNameAz => 'নাম (ক–হ / A–Z)';

  @override
  String get sortNameZa => 'নাম (হ–ক / Z–A)';

  @override
  String get libraryEmpty => 'আপনার স্ক্যান করা ডকুমেন্ট এখানে দেখা যাবে।';

  @override
  String get librarySearchEmpty => 'এই নামে কোনো ডকুমেন্ট পাওয়া যায়নি।';

  @override
  String get rename => 'নাম বদলান';

  @override
  String get renameTitle => 'ডকুমেন্টের নাম বদলান';

  @override
  String get deleteDocTitle => 'ডকুমেন্ট মুছবেন?';

  @override
  String deleteDocBody(String name) {
    return '\"$name\" স্থায়ীভাবে মুছে যাবে।';
  }

  @override
  String get deleted => 'ডকুমেন্ট মুছে ফেলা হয়েছে';

  @override
  String get share => 'শেয়ার';

  @override
  String get saveToDevice => 'ফোনে সংরক্ষণ';

  @override
  String get savedToDownloads =>
      'Downloads/Bangla Scanner ফোল্ডারে সংরক্ষিত হয়েছে';

  @override
  String get savedToFiles => 'সংরক্ষিত হয়েছে';

  @override
  String get extractText => 'লেখা বের করুন';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get documentMissing =>
      'এই ডকুমেন্টের ফাইল পাওয়া যাচ্ছে না বা নষ্ট হয়ে গেছে।';

  @override
  String get merge => 'একত্র করুন';

  @override
  String get mergeTooltip => 'ডকুমেন্ট একত্র করুন';

  @override
  String mergeSelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি বাছাই করা হয়েছে',
      zero: 'একত্র করতে ডকুমেন্ট বাছুন',
    );
    return '$_temp0';
  }

  @override
  String get mergeHint =>
      'যে ক্রমে চান সেই ক্রমে ডকুমেন্টগুলোতে চাপুন। তারপর একত্র করুন চাপলে একটি নতুন PDF বা ছবির সেট তৈরি হবে।';

  @override
  String get mergeNeedTwo => 'একত্র করতে কমপক্ষে ২টি ডকুমেন্ট বাছুন।';

  @override
  String mergeSkippedMissing(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি ডকুমেন্ট বাদ পড়েছে, কারণ এর ফাইল পাওয়া যায়নি।',
    );
    return '$_temp0';
  }

  @override
  String get mergePreparing => 'পাতা প্রস্তুত হচ্ছে…';

  @override
  String get errorCorruptFile => 'ফাইলটি নষ্ট, খোলা যাচ্ছে না।';

  @override
  String get errorLowStorage =>
      'ফোনের স্টোরেজ পূর্ণ। কিছু জায়গা খালি করে আবার চেষ্টা করুন।';

  @override
  String get errorGeneric => 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get ocrTitle => 'লেখা বের করুন';

  @override
  String get ocrLanguage => 'লেখার ভাষা';

  @override
  String get ocrLangBangla => 'বাংলা';

  @override
  String get ocrLangEnglish => 'English';

  @override
  String get ocrLangBoth => 'দুটোই';

  @override
  String get ocrStart => 'শুরু করুন';

  @override
  String get ocrPreparing => 'প্রস্তুত হচ্ছে…';

  @override
  String ocrPreprocessing(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'ছবি পরিষ্কার করা হচ্ছে (পাতা $currentString / $totalString)';
  }

  @override
  String ocrRecognizing(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'লেখা পড়া হচ্ছে (পাতা $currentString / $totalString)';
  }

  @override
  String get ocrFailed =>
      'লেখা পড়া যায়নি। আরও পরিষ্কার করে স্ক্যান করে দেখুন।';

  @override
  String get ocrNoText => 'এই পাতাগুলোতে কোনো লেখা পাওয়া যায়নি।';

  @override
  String get ocrResultTitle => 'বের করা লেখা';

  @override
  String get ocrHint => 'কপি বা শেয়ার করার আগে লেখাটি ঠিক করে নিতে পারেন।';

  @override
  String get copy => 'কপি';

  @override
  String get copied => 'কপি হয়েছে';

  @override
  String get saveTxt => '.txt সংরক্ষণ';

  @override
  String get idCardTitle => 'আইডি কার্ড';

  @override
  String get idCardFront => 'সামনের দিক';

  @override
  String get idCardBack => 'পেছনের দিক';

  @override
  String get idCardHintFront =>
      'কার্ডের সামনের দিক একটি গাঢ় রঙের সমতল জায়গায় রেখে স্ক্যান করুন।';

  @override
  String get idCardHintBack => 'এবার কার্ডটি উল্টে পেছনের দিক স্ক্যান করুন।';

  @override
  String get idCardScan => 'স্ক্যান';

  @override
  String get idCardFromGallery => 'গ্যালারি থেকে';

  @override
  String get idCardRetake => 'আবার তুলুন';

  @override
  String get idCardNext => 'পরবর্তী';

  @override
  String get idCardCreate => 'A4 পাতা তৈরি করুন';

  @override
  String get idCardReadyHint =>
      'দুই দিকই আসল কার্ডের মাপে একটি A4 পাতায় বসানো হবে।';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsLanguage => 'ভাষা';

  @override
  String get settingsTheme => 'থিম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get themeSystem => 'ফোনের মতো';

  @override
  String get settingsDefaultFormat => 'ডিফল্ট সংরক্ষণ ফরম্যাট';

  @override
  String get settingsDefaultQuality => 'ডিফল্ট পিডিএফ মান';

  @override
  String get settingsDefaultOcr => 'ডিফল্ট OCR ভাষা';

  @override
  String get settingsAbout => 'অ্যাপ সম্পর্কে';

  @override
  String get settingsOffline =>
      'সবকিছু ইন্টারনেট ছাড়াই কাজ করে। আপনার ডকুমেন্ট ফোনের বাইরে যায় না।';

  @override
  String settingsVersion(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get folders => 'ফোল্ডার';

  @override
  String get filterAll => 'সব';

  @override
  String get favorites => 'প্রিয়';

  @override
  String get newFolder => 'নতুন ফোল্ডার';

  @override
  String get folderName => 'ফোল্ডারের নাম';

  @override
  String get renameFolder => 'ফোল্ডারের নাম বদলান';

  @override
  String get deleteFolder => 'ফোল্ডার মুছুন';

  @override
  String get deleteFolderTitle => 'ফোল্ডার মুছবেন?';

  @override
  String deleteFolderBody(String name) {
    return '\"$name\" মুছে যাবে। এর ডকুমেন্টগুলো লাইব্রেরিতে থেকে যাবে।';
  }

  @override
  String get folderCreated => 'ফোল্ডার তৈরি হয়েছে';

  @override
  String get moveToFolder => 'ফোল্ডারে সরান';

  @override
  String get noFolder => 'কোনো ফোল্ডারে নয়';

  @override
  String movedToFolder(String name) {
    return '\"$name\" ফোল্ডারে সরানো হয়েছে';
  }

  @override
  String get removedFromFolder => 'ফোল্ডার থেকে সরানো হয়েছে';

  @override
  String get noFoldersYet =>
      'এখনো কোনো ফোল্ডার নেই। ডকুমেন্ট গুছিয়ে রাখতে একটি তৈরি করুন।';

  @override
  String get addToFavorites => 'প্রিয়তে যোগ করুন';

  @override
  String get removeFromFavorites => 'প্রিয় থেকে সরান';

  @override
  String get favoritesEmpty => 'দ্রুত খুঁজে পেতে ডকুমেন্টে তারা চিহ্ন দিন।';

  @override
  String get folderEmpty => 'এই ফোল্ডার খালি। ডকুমেন্টের মেনু থেকে এখানে সরান।';

  @override
  String get select => 'নির্বাচন';

  @override
  String selectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি নির্বাচিত',
      one: '১টি নির্বাচিত',
      zero: 'ডকুমেন্ট নির্বাচন করুন',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'সব নির্বাচন';

  @override
  String get selectionHint =>
      'ডকুমেন্টে ট্যাপ করে নির্বাচন করুন। একত্র করলে যে ক্রমে ট্যাপ করেছেন সেই ক্রমে জোড়া লাগবে।';

  @override
  String deleteSelectedTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি ডকুমেন্ট মুছবেন?',
      one: '১টি ডকুমেন্ট মুছবেন?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'এগুলো স্থায়ীভাবে মুছে যাবে।';

  @override
  String deletedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি ডকুমেন্ট মুছে ফেলা হয়েছে',
      one: '১টি ডকুমেন্ট মুছে ফেলা হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String get protectWithPassword => 'পাসওয়ার্ড দিয়ে সুরক্ষিত করুন';

  @override
  String get pdfPassword => 'PDF পাসওয়ার্ড';

  @override
  String get passwordHint =>
      'এই পাসওয়ার্ড ছাড়া PDF খুলবে না। সাবধানে রাখুন: হারালে ফেরত পাওয়া যাবে না।';

  @override
  String get passwordTooShort => 'কমপক্ষে ৪ অক্ষর দিন';

  @override
  String get enterPdfPassword => 'PDF-এর পাসওয়ার্ড দিন';

  @override
  String get enterPdfPasswordBody =>
      'এই PDF সুরক্ষিত। নতুন পাতা দিয়ে আবার তৈরি করতে এর পাসওয়ার্ড দিন।';

  @override
  String get protectedBadge => 'পাসওয়ার্ড সুরক্ষিত';

  @override
  String get pageSize => 'পাতার আকার';

  @override
  String get pageSizeAuto => 'স্ক্যান অনুযায়ী';

  @override
  String get pageSizeA4 => 'A4';

  @override
  String get pageSizeLetter => 'Letter';

  @override
  String get pageSizeLegal => 'Legal';

  @override
  String get pageSizeHint =>
      'স্ক্যান অনুযায়ী হলে প্রতিটি পাতা স্ক্যানের আকৃতি পায়। A4, Letter ও Legal প্রিন্টের জন্য আসল কাগজের মাপে বসায়।';

  @override
  String get settingsDefaultPageSize => 'PDF-এর ডিফল্ট পাতার আকার';

  @override
  String get settingsAppLock => 'অ্যাপ লক';

  @override
  String get appLockEnable => 'PIN দিয়ে অ্যাপ লক করুন';

  @override
  String get appLockBiometric => 'আঙুলের ছাপ বা মুখ দিয়ে খুলুন';

  @override
  String get appLockDelay => 'অ্যাপ ছাড়ার কতক্ষণ পরে লক হবে';

  @override
  String get lockImmediately => 'সাথে সাথে';

  @override
  String get lockAfterOneMinute => '১ মিনিট';

  @override
  String get lockAfterFiveMinutes => '৫ মিনিট';

  @override
  String get changePin => 'PIN বদলান';

  @override
  String get setPinTitle => 'PIN সেট করুন';

  @override
  String get setPinHint => '৪ থেকে ৮ সংখ্যা দিন। অ্যাপ খুলতে এটি লাগবে।';

  @override
  String get confirmPinTitle => 'PIN আবার দিন';

  @override
  String get enterCurrentPin => 'বর্তমান PIN দিন';

  @override
  String get pinMismatch => 'PIN দুটি মেলেনি। আবার চেষ্টা করুন।';

  @override
  String get pinTooShort => 'PIN-এ কমপক্ষে ৪ সংখ্যা লাগবে।';

  @override
  String get enterPin => 'আপনার PIN দিন';

  @override
  String get wrongPin => 'ভুল PIN';

  @override
  String get lockedTitle => 'বাংলা স্ক্যানার লক করা আছে';

  @override
  String get unlockWithBiometrics => 'আঙুলের ছাপ বা মুখ ব্যবহার করুন';

  @override
  String get biometricReason => 'বাংলা স্ক্যানার খুলুন';

  @override
  String get biometricUnavailable =>
      'এই ফোনে আঙুলের ছাপ বা মুখ দিয়ে খোলার ব্যবস্থা নেই।';

  @override
  String get appLockOn => 'অ্যাপ লক চালু হয়েছে';

  @override
  String get appLockOff => 'অ্যাপ লক বন্ধ হয়েছে';

  @override
  String get adjust => 'সমন্বয়';

  @override
  String get filterStrength => 'ফিল্টারের মাত্রা';

  @override
  String get brightness => 'উজ্জ্বলতা';

  @override
  String get contrast => 'কনট্রাস্ট';

  @override
  String get resetAdjustments => 'রিসেট';

  @override
  String get bookSplit => 'বই ভাগ';

  @override
  String get bookSplitTitle => 'এই পাতাটি দুই ভাগ করবেন?';

  @override
  String get bookSplitBody =>
      'খোলা বইয়ের ছবির জন্য: পাতাটি বাম ও ডান পাতায় কাটা হবে (লম্বা ছবিতে উপর ও নিচে)।';

  @override
  String get split => 'ভাগ করুন';

  @override
  String get pageSplitDone => 'পাতাটি দুটি পাতায় ভাগ হয়েছে';

  @override
  String get reorderPages => 'পাতার ক্রম বদলান';

  @override
  String get pagesTitle => 'পাতা';

  @override
  String get pagesHint =>
      'চেপে ধরে টেনে ক্রম বদলান। পাতা সরাতে বিন আইকনে ট্যাপ করুন।';

  @override
  String get apply => 'প্রয়োগ';

  @override
  String get pagesUpdated => 'পাতা আপডেট হয়েছে';

  @override
  String get pagesNeedOne => 'ডকুমেন্টে অন্তত একটি পাতা থাকতে হবে।';

  @override
  String get zoomHint => 'জুম করতে দুইবার ট্যাপ করুন। দুই আঙুলে ছোট-বড় করুন।';

  @override
  String get cardKind => 'ডকুমেন্টের ধরন';

  @override
  String get cardKindId => 'NID / স্মার্ট কার্ড';

  @override
  String get cardKindPassport => 'পাসপোর্ট';

  @override
  String get idCardHintPassport =>
      'পাসপোর্টের ছবির পাতাটি গাঢ় রঙের সমতল জায়গায় রেখে স্ক্যান করুন।';

  @override
  String get idCardPassportSecond => 'দ্বিতীয় পাতা (ঐচ্ছিক)';

  @override
  String get idCardPassportReady =>
      'পাতাটি আসল পাসপোর্টের মাপে A4 কাগজে বসানো হবে।';

  @override
  String get idCardOptional => 'ঐচ্ছিক';

  @override
  String get importFromGallery => 'গ্যালারি থেকে ছবি';

  @override
  String get importPdf => 'PDF ফাইল';

  @override
  String get importPdfHint =>
      'PDF-এর প্রতিটি পাতা আলাদা পাতা হয়ে আসবে, যা ক্রপ, ফিল্টার ও OCR করা যাবে।';

  @override
  String get addFromPdf => 'PDF ফাইল থেকে';

  @override
  String get importingPdf => 'PDF পড়া হচ্ছে…';

  @override
  String importingPdfProgress(int done, int total) {
    return '$total পাতার মধ্যে $done';
  }

  @override
  String pdfTooManyPages(int max) {
    return 'শুধু প্রথম $max পাতা ইমপোর্ট করা হয়েছে।';
  }

  @override
  String get errorPdfLocked =>
      'এই PDF-এ পাসওয়ার্ড আছে। আগে পাসওয়ার্ড সরিয়ে তারপর ইমপোর্ট করুন।';

  @override
  String get receivedTitle => 'ফাইল এসেছে';

  @override
  String get receivedAddOrNewBody =>
      'একটি ডকুমেন্ট ইতিমধ্যে খোলা আছে। পাতাগুলো সেটিতে যোগ করবেন, নাকি নতুন ডকুমেন্ট শুরু করবেন?';

  @override
  String get receivedAddToCurrent => 'এটিতে যোগ করুন';

  @override
  String get receivedNewDocument => 'নতুন ডকুমেন্ট';

  @override
  String get receivedUnsupported =>
      'এই ধরনের ফাইল সাপোর্ট করে না। ছবি বা PDF পাঠান।';

  @override
  String get settingsBackup => 'ব্যাকআপ';

  @override
  String get backupTitle => 'ব্যাকআপ ও রিস্টোর';

  @override
  String get backupSettingsHint =>
      'সব ডকুমেন্ট এক ফাইলে রাখুন, বা ফিরিয়ে আনুন';

  @override
  String get backupIntro =>
      'আপনার ডকুমেন্ট শুধু এই ফোনেই থাকে। ফোন বদলানো বা অ্যাপের ডেটা মুছার আগে ব্যাকআপ নিন, আর নতুন ফোনে রিস্টোর করুন।';

  @override
  String get backupCreate => 'ব্যাকআপ তৈরি করুন';

  @override
  String get backupCreateHint =>
      'সব ডকুমেন্ট ও ফোল্ডার একটি .zip ফাইলে সংরক্ষণ হবে।';

  @override
  String backupStats(int count, String size) {
    return '$countটি ডকুমেন্ট, $size';
  }

  @override
  String get backupRestore => 'ব্যাকআপ থেকে রিস্টোর';

  @override
  String get backupRestoreHint =>
      'একটি .zip ব্যাকআপ ফাইল বেছে নিন। লাইব্রেরিতে থাকা ডকুমেন্ট যেমন আছে তেমনই থাকবে।';

  @override
  String get backupCreating => 'ব্যাকআপ তৈরি হচ্ছে…';

  @override
  String backupProgress(int done, int total) {
    return '$totalটির মধ্যে $done নম্বর ডকুমেন্ট';
  }

  @override
  String backupReady(String size) {
    return 'ব্যাকআপ তৈরি ($size)';
  }

  @override
  String get backupSave => 'ফোনে সংরক্ষণ';

  @override
  String get backupSaveHintAndroid => 'Downloads/Bangla Scanner';

  @override
  String get backupSaveHintIos => 'Files অ্যাপে জায়গা বেছে নিন';

  @override
  String get backupShare => 'শেয়ার';

  @override
  String get backupShareHint => 'Google Drive, WhatsApp, ই-মেইল… এ পাঠান';

  @override
  String get backupEmpty => 'ব্যাকআপ নেওয়ার মতো কোনো ডকুমেন্ট নেই।';

  @override
  String get backupRestoring => 'রিস্টোর হচ্ছে…';

  @override
  String get backupRestoreConfirmTitle => 'এই ব্যাকআপ রিস্টোর করবেন?';

  @override
  String backupRestoreConfirmBody(int count, String date) {
    return '$countটি ডকুমেন্ট, তৈরি $date। লাইব্রেরিতে যেগুলো আছে সেগুলো থাকবে; বাকিগুলো যোগ হবে।';
  }

  @override
  String get restore => 'রিস্টোর';

  @override
  String backupRestored(int added, int skipped) {
    return '$addedটি ডকুমেন্ট রিস্টোর হয়েছে, $skippedটি আগে থেকেই ছিল';
  }

  @override
  String get backupInvalid => 'এটি বাংলা স্ক্যানারের ব্যাকআপ ফাইল নয়।';

  @override
  String get signTool => 'সই';

  @override
  String get stampSheetTitle => 'সই বা সিল';

  @override
  String get signatures => 'সই';

  @override
  String get drawSignature => 'নতুন সই আঁকুন';

  @override
  String get noSignatures =>
      'এখনো কোনো সই সংরক্ষিত নেই। একবার এঁকে রাখলে যেকোনো পাতায় বসানো যাবে।';

  @override
  String get stamps => 'সিল';

  @override
  String get stampAttested => 'সত্যায়িত';

  @override
  String get stampTrueCopy => 'সত্য অনুলিপি';

  @override
  String get stampOriginalSeen => 'মূল কপি দেখা হয়েছে';

  @override
  String get stampPaid => 'পরিশোধিত';

  @override
  String get stampReceived => 'গৃহীত';

  @override
  String get stampCustom => 'নিজের লেখা…';

  @override
  String get stampCustomTitle => 'সিলের লেখা';

  @override
  String get stampText => 'লেখা';

  @override
  String get stampColorBlue => 'নীল';

  @override
  String get stampColorRed => 'লাল';

  @override
  String get stampColorBlack => 'কালো';

  @override
  String get stampBakeNote =>
      'সই বা সিল বসালে পাতার ঘোরানো ও ফিল্টার স্থায়ীভাবে প্রয়োগ হয়ে যায়।';

  @override
  String get signaturePadTitle => 'আপনার সই আঁকুন';

  @override
  String get signaturePadHint =>
      'বক্সের ভেতরে আঙুল দিয়ে সই করুন। পরে ব্যবহারের জন্য এটি সংরক্ষিত থাকবে।';

  @override
  String get saveSignature => 'সই ব্যবহার করুন';

  @override
  String get penThickness => 'কলম';

  @override
  String get undo => 'আগেরটা মুছুন';

  @override
  String get clear => 'সব মুছুন';

  @override
  String get signatureEmpty => 'আগে কিছু আঁকুন।';

  @override
  String get deleteSignatureTitle => 'এই সই মুছবেন?';

  @override
  String get deleteSignatureBody =>
      'সংরক্ষিত সইয়ের তালিকা থেকে এটি মুছে যাবে। আগে সই করা পাতাগুলোর কিছু হবে না।';

  @override
  String get placeStampTitle => 'পাতায় বসান';

  @override
  String get placeStampHint => 'টেনে সরান। দুই আঙুলে ছোট-বড় বা ঘোরান।';

  @override
  String get stampSize => 'আকার';

  @override
  String get resetRotation => 'সোজা করুন';

  @override
  String get stampApplied => 'পাতায় যোগ হয়েছে';
}
