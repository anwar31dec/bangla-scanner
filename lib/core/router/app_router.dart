import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/editor/presentation/editor_screen.dart';
import '../../features/editor/presentation/page_edit_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/id_card/presentation/id_card_screen.dart';
import '../../features/library/presentation/document_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/ocr/presentation/ocr_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Route paths used across the app.
abstract final class Routes {
  static const home = '/';
  static const settings = '/settings';
  static const editor = '/editor';
  static const library = '/library';
  static const idCard = '/id-card';
  static const document = '/document/:id';

  static String documentPath(String id) => '/document/$id';
  static String ocrPath(String id) => '/document/$id/ocr';
  static String pageEditPath(int index) => '/editor/page/$index';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(path: Routes.idCard, builder: (context, state) => const IdCardScreen()),
      GoRoute(path: Routes.library, builder: (context, state) => const LibraryScreen()),
      GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: Routes.editor,
        builder: (context, state) => const EditorScreen(),
        routes: [
          GoRoute(
            path: 'page/:index',
            builder: (context, state) =>
                PageEditScreen(initialIndex: int.tryParse(state.pathParameters['index'] ?? '') ?? 0),
          ),
        ],
      ),
      GoRoute(
        path: Routes.document,
        builder: (context, state) => DocumentScreen(documentId: state.pathParameters['id']!),
        routes: [
          GoRoute(path: 'ocr', builder: (context, state) => OcrScreen(documentId: state.pathParameters['id']!)),
        ],
      ),
    ],
  );
});
