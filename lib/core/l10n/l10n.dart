import 'package:flutter/widgets.dart';

import '../../features/stamps/data/stamp_renderer.dart';
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

  String pageSizeLabel(PdfPageSize s) => switch (s) {
        PdfPageSize.auto => pageSizeAuto,
        PdfPageSize.a4 => pageSizeA4,
        PdfPageSize.letter => pageSizeLetter,
        PdfPageSize.legal => pageSizeLegal,
      };

  String ocrLanguageLabel(OcrLanguage l) => switch (l) {
        OcrLanguage.bangla => ocrLangBangla,
        OcrLanguage.english => ocrLangEnglish,
        OcrLanguage.both => ocrLangBoth,
      };

  String filterLabel(PageFilter f) => switch (f) {
        PageFilter.original => filterOriginal,
        PageFilter.autoColor => filterAutoColor,
        PageFilter.grayscale => filterGrayscale,
        PageFilter.blackWhite => filterBlackWhite,
        PageFilter.whiteboard => filterWhiteboard,
        PageFilter.lightText => filterLightText,
      };

  String lockDelayLabel(LockDelay d) => switch (d) {
        LockDelay.immediately => lockImmediately,
        LockDelay.oneMinute => lockAfterOneMinute,
        LockDelay.fiveMinutes => lockAfterFiveMinutes,
      };

  String stampColorLabel(StampColor c) => switch (c) {
        StampColor.blue => stampColorBlue,
        StampColor.red => stampColorRed,
        StampColor.black => stampColorBlack,
      };

  String cardKindLabel(CardKind k) => switch (k) {
        CardKind.idCard => cardKindId,
        CardKind.passport => cardKindPassport,
      };
}
