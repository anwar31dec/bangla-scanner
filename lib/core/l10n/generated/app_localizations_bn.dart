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
  String get homeImport => 'গ্যালারি থেকে আনুন';

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
}
