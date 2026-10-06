import 'package:flutter/widgets.dart';

import '../models/enums.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Short-hand: `context.l10n.homeScan`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Current locale tag for number/date formatting ('bn' or 'en').
  String get localeTag => Localizations.localeOf(this).languageCode;
}

/// Localized labels for shared enums.
extension EnumLabels on AppLocalizations {
  String formatLabel(SaveFormat f) => switch (f) {
        SaveFormat.pdf => formatPdf,
        SaveFormat.jpeg => formatJpeg,
      };

  String qualityLabel(ExportQuality q) => switch (q) {
        ExportQuality.low => qualityLow,
        ExportQuality.medium => qualityMedium,
        ExportQuality.high => qualityHigh,
      };

  String ocrLanguageLabel(OcrLanguage l) => switch (l) {
        OcrLanguage.bangla => ocrLangBangla,
        OcrLanguage.english => ocrLangEnglish,
        OcrLanguage.both => ocrLangBoth,
      };

  String filterLabel(PageFilter f) => switch (f) {
        PageFilter.original => filterOriginal,
        PageFilter.grayscale => filterGrayscale,
        PageFilter.blackWhite => filterBlackWhite,
        PageFilter.enhanced => filterEnhanced,
      };
}
