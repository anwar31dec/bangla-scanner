import 'dart:io';

import 'package:banglascanner/core/l10n/l10n.dart';
import 'package:banglascanner/features/scan/data/document_detector.dart';
import 'package:banglascanner/features/scan/presentation/crop_corners_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late Directory root;
  late String imagePath;

  setUp(() {
    root = Directory.systemTemp.createTempSync('bs_corners');
    imagePath = (File(p.join(root.path, 'shot.jpg'))..writeAsBytesSync(fakeDocumentJpeg())).path;
  });

  tearDown(() => root.deleteSync(recursive: true));

  /// Opens the screen from a button and records what it pops with.
  Future<List<DocumentQuad?>> open(WidgetTester tester) async {
    final results = <DocumentQuad?>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<DocumentQuad>(
                MaterialPageRoute(
                  builder: (context) => CropCornersScreen(
                    imagePath: imagePath,
                    aspectRatio: 600 / 800,
                    initialQuad: DocumentQuad.inset,
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  /// Where the photo is drawn on screen.
  Rect photoRect(WidgetTester tester) => tester.getRect(find.byType(Image));

  testWidgets('dragging a corner changes the returned quad', (tester) async {
    final results = await open(tester);
    final photo = photoRect(tester);
    final topLeft = Offset(photo.left + 0.08 * photo.width, photo.top + 0.08 * photo.height);

    await tester.dragFrom(topLeft, Offset(0.2 * photo.width, 0.1 * photo.height));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use page'));
    await tester.pumpAndSettle();

    final quad = results.single!;
    // The drag starts after the touch slop, so allow a little less travel.
    expect(quad.topLeft.x, inInclusiveRange(0.2, 0.29));
    expect(quad.topLeft.y, inInclusiveRange(0.1, 0.19));
    expect(quad.bottomRight, DocumentQuad.inset.bottomRight);
  });

  testWidgets('a corner cannot be dragged across the page', (tester) async {
    final results = await open(tester);
    final photo = photoRect(tester);
    final topLeft = Offset(photo.left + 0.08 * photo.width, photo.top + 0.08 * photo.height);

    await tester.dragFrom(topLeft, Offset(photo.width, photo.height));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use page'));
    await tester.pumpAndSettle();

    expect(results.single!.isConvex, isTrue);
  });

  testWidgets('whole photo and retake', (tester) async {
    var results = await open(tester);
    await tester.tap(find.byTooltip('Whole photo'));
    await tester.pump();
    await tester.tap(find.text('Use page'));
    await tester.pumpAndSettle();
    expect(results.single!.isFullPhoto, isTrue);

    results = await open(tester);
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    expect(results.single, isNull);
  });
}
