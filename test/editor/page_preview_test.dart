import 'dart:io';

import 'package:banglascanner/core/l10n/l10n.dart';
import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/features/editor/application/page_preview_providers.dart';
import 'package:banglascanner/features/editor/presentation/page_edit_screen.dart';
import 'package:banglascanner/features/scan/application/draft_controller.dart';
import 'package:banglascanner/features/scan/data/draft_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late Directory root;
  late String imagePath;

  setUp(() {
    root = Directory.systemTemp.createTempSync('bs_preview');
    imagePath = (File(p.join(root.path, 'page.jpg'))..writeAsBytesSync(fakeDocumentJpeg())).path;
  });

  tearDown(() => root.deleteSync(recursive: true));

  testWidgets('filtered preview is rendered at preview size with the save-time filter', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final request = (source: (path: imagePath, revision: 0, maxEdge: 200), filter: PageFilter.blackWhite, adjustments: PageAdjustments.none);
    // Real file and codec work does not complete inside the fake-async zone.
    final jpeg = await tester.runAsync(() async {
      final sub = container.listen(filteredPreviewProvider(request), (_, _) {});
      try {
        return await container.read(filteredPreviewProvider(request).future);
      } finally {
        sub.close();
      }
    });

    final preview = img.decodeJpg(jpeg!)!;
    expect([preview.width, preview.height], [150, 200]);
    // Black & white: nothing but near-black and near-white (JPEG ringing aside).
    final mid = preview.where((px) => px.r > 60 && px.r < 195).length;
    expect(mid / (preview.width * preview.height), lessThan(0.05));
  });

  testWidgets('filter strip offers every filter and selects on tap', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // ignore: invalid_use_of_protected_member
    container.read(draftProvider.notifier).state = DraftDocument(
      workDirPath: root.path,
      pages: [DraftPage(id: 'a', imagePath: imagePath)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: PageEditScreen(initialIndex: 0),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(tester.element(find.byType(PageEditScreen)));
    for (final f in PageFilter.values) {
      expect(find.text(l10n.filterLabel(f)), findsOneWidget);
    }

    await tester.ensureVisible(find.text(l10n.filterWhiteboard));
    await tester.tap(find.text(l10n.filterWhiteboard));
    await tester.pump();
    expect(container.read(draftProvider)!.pages.single.filter, PageFilter.whiteboard);
  });
}
