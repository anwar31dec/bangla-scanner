import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One recognized word and where it sits on the page.
///
/// The box is given as fractions (0..1) of the page image's width and
/// height, measured from the top-left corner, so it stays valid whatever
/// size the page is rendered or printed at.
@immutable
class OcrWord {
  const OcrWord(this.text, {required this.left, required this.top, required this.right, required this.bottom});

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  /// Compact JSON form: `[text, left, top, right, bottom]`.
  List<Object> toJson() => [text, _round(left), _round(top), _round(right), _round(bottom)];

  static OcrWord? fromJson(Object? json) {
    if (json is! List || json.length < 5 || json[0] is! String) return null;
    final n = [for (var i = 1; i < 5; i++) (json[i] as num?)?.toDouble()];
    if (n.any((v) => v == null)) return null;
    return OcrWord(json[0] as String, left: n[0]!, top: n[1]!, right: n[2]!, bottom: n[3]!);
  }

  static double _round(double v) => (v * 10000).roundToDouble() / 10000;

  @override
  bool operator ==(Object other) =>
      other is OcrWord &&
      other.text == text &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(text, left, top, right, bottom);

  @override
  String toString() => 'OcrWord($text, $left, $top, $right, $bottom)';
}

/// The text of one page plus the position of every word, as stored in the
/// database and drawn into the PDF's invisible text layer.
@immutable
class PageText {
  const PageText({required this.text, this.words = const []});

  static const empty = PageText(text: '');

  /// Plain text in reading order (lines separated by `\n`, paragraphs by a
  /// blank line).
  final String text;

  /// Words with their boxes as fractions of the page. Empty when the engine
  /// gave no positions.
  final List<OcrWord> words;

  bool get isEmpty => text.trim().isEmpty;

  /// Serialized word list for the database.
  String get wordsJson => jsonEncode([for (final w in words) w.toJson()]);

  static List<OcrWord> wordsFromJson(String json) {
    if (json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded) ?OcrWord.fromJson(item),
      ];
    } on FormatException {
      return const [];
    }
  }
}

/// What an OCR engine returns for one image: the text and the word boxes in
/// pixels of that image (top-left origin).
@immutable
class RecognizedPage {
  const RecognizedPage({required this.text, this.words = const []});

  final String text;

  /// Boxes in pixels of the image that was recognized.
  final List<OcrWord> words;

  /// Converts the pixel boxes into fractions of a [width] × [height] image.
  /// Boxes outside the image are clamped; empty or inverted ones dropped.
  PageText normalized(int width, int height) {
    if (width <= 0 || height <= 0) return PageText(text: text);
    final out = <OcrWord>[];
    for (final w in words) {
      if (w.text.trim().isEmpty) continue;
      final l = (w.left / width).clamp(0.0, 1.0), r = (w.right / width).clamp(0.0, 1.0);
      final t = (w.top / height).clamp(0.0, 1.0), b = (w.bottom / height).clamp(0.0, 1.0);
      if (r <= l || b <= t) continue;
      out.add(OcrWord(w.text, left: l, top: t, right: r, bottom: b));
    }
    return PageText(text: text, words: out);
  }
}

/// Reads the hOCR (HTML) output of Tesseract: the text in reading order
/// and one box per word.
///
/// Tesseract writes `<span class='ocrx_word' title='bbox x0 y0 x1 y1; …'>`
/// for each word, inside `ocr_line` and `ocr_par` spans. Bold or italic
/// words may be wrapped in `<strong>` / `<em>`, and the text is HTML
/// escaped.
class HocrParser {
  HocrParser._();

  static final _tag = RegExp(r'<(/?)([a-zA-Z0-9]+)([^>]*)>');
  static final _class = RegExp('''class=["']([^"']*)["']''');
  static final _bbox = RegExp(r'bbox\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)');

  static RecognizedPage parse(String hocr) {
    final words = <OcrWord>[];
    final text = StringBuffer();
    var lineHasWords = false;
    var paragraphOpen = false;

    // The word being collected, if any.
    List<int>? box;
    StringBuffer? wordText;
    var wordDepth = 0;

    void endWord() {
      final buffer = wordText;
      if (buffer != null) {
        final t = _unescape(buffer.toString()).trim();
        if (t.isNotEmpty) {
          if (lineHasWords) text.write(' ');
          text.write(t);
          lineHasWords = true;
          final b = box;
          if (b != null) {
            words.add(OcrWord(t, left: b[0].toDouble(), top: b[1].toDouble(), right: b[2].toDouble(), bottom: b[3].toDouble()));
          }
        }
      }
      wordText = null;
      box = null;
      wordDepth = 0;
    }

    void endLine() {
      if (lineHasWords) text.write('\n');
      lineHasWords = false;
    }

    var index = 0;
    for (final m in _tag.allMatches(hocr)) {
      if (wordText != null) wordText!.write(hocr.substring(index, m.start));
      index = m.end;
      final closing = m.group(1) == '/';
      final name = m.group(2)!.toLowerCase();
      final attrs = m.group(3) ?? '';
      final cls = closing ? null : _class.firstMatch(attrs)?.group(1);

      if (wordText != null) {
        // Inside a word: only track nesting to find its closing span.
        if (name == 'span') {
          wordDepth += closing ? -1 : 1;
          if (wordDepth <= 0) endWord();
        }
        continue;
      }
      if (closing) {
        if (name == 'span') endLine(); // closes a line (words already ended)
        if (name == 'p' && paragraphOpen) {
          endLine();
          if (text.isNotEmpty) text.write('\n');
          paragraphOpen = false;
        }
        continue;
      }
      if (cls == null) continue;
      if (cls.contains('ocrx_word')) {
        wordText = StringBuffer();
        wordDepth = 1;
        final b = _bbox.firstMatch(attrs);
        box = b == null ? null : [for (var i = 1; i <= 4; i++) int.parse(b.group(i)!)];
      } else if (cls.contains('ocr_par')) {
        paragraphOpen = true;
      }
    }
    endWord();
    endLine();
    return RecognizedPage(text: text.toString(), words: words);
  }

  static String _unescape(String s) {
    if (!s.contains('&')) return s;
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
        .replaceAll('&amp;', '&');
  }
}
