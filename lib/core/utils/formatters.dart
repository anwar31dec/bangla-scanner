import 'package:intl/intl.dart';

/// Formatting helpers that respect the current UI locale (Bangla digits
/// when the app language is Bangla).
class Formatters {
  Formatters._();

  /// Human readable file size, e.g. "1.2 MB" / "১.২ MB".
  static String fileSize(int bytes, String locale) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final pattern = unit == 0 ? '#,##0' : '#,##0.#';
    return '${NumberFormat(pattern, locale).format(size)} ${units[unit]}';
  }

  /// Date shown in lists, e.g. "06-10-2026" (with Bangla digits in Bangla).
  static String date(DateTime date, String locale) =>
      DateFormat('dd-MM-yyyy', locale).format(date);

  /// Date and time shown in details.
  static String dateTime(DateTime date, String locale) =>
      DateFormat('dd-MM-yyyy, h:mm a', locale).format(date);

  /// Default document name: "Scan 06-10-2026". Always uses Latin digits so
  /// that file names stay portable when shared.
  static String defaultScanName(DateTime now) =>
      'Scan ${DateFormat('dd-MM-yyyy', 'en').format(now)}';

  /// Removes characters that are not allowed in file names on Android/iOS.
  static String safeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'Scan' : cleaned;
  }
}
