import 'package:banglascanner/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('bn');
    await initializeDateFormatting('en');
  });

  test('default document name is Doc-dd-MM-yyyy-HH-mm-ss in local time', () {
    expect(Formatters.defaultScanName(DateTime(2026, 10, 6, 14, 5, 9)), 'Doc-06-10-2026-14-05-09');
  });

  test('file sizes', () {
    expect(Formatters.fileSize(512, 'en'), '512 B');
    expect(Formatters.fileSize(1536, 'en'), '1.5 KB');
    expect(Formatters.fileSize(1536, 'bn'), '১.৫ KB');
  });

  test('dates use Bangla digits in Bangla', () {
    expect(Formatters.date(DateTime(2026, 10, 6), 'bn'), '০৬-১০-২০২৬');
  });

  test('unsafe characters are removed from file names', () {
    expect(Formatters.safeFileName('a/b:c*?"<>|'), 'a_b_c______');
    expect(Formatters.safeFileName('   '), 'Doc');
    expect(Formatters.safeFileName('আমার ডকুমেন্ট'), 'আমার ডকুমেন্ট');
  });
}
