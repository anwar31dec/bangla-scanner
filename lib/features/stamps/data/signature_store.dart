import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_paths.dart';
import '../../../core/storage/storage_providers.dart';

/// Saved signatures: transparent PNGs in [AppPaths.signaturesDir], newest
/// first. Drawn once, placed on any page later.
class SignatureStore {
  SignatureStore(this._paths);

  final AppPaths _paths;
  static const _uuid = Uuid();

  Future<List<File>> list() async {
    final dir = _paths.signaturesDir;
    if (!await dir.exists()) return const [];
    final files = await dir.list().where((e) => e is File && e.path.endsWith('.png')).cast<File>().toList();
    final modified = <String, DateTime>{};
    for (final f in files) {
      modified[f.path] = (await f.stat()).modified;
    }
    files.sort((a, b) => modified[b.path]!.compareTo(modified[a.path]!));
    return files;
  }

  Future<File> add(Uint8List png) async {
    final dir = _paths.signaturesDir;
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${_uuid.v4()}.png'));
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  Future<void> delete(File file) async {
    if (await file.exists()) await file.delete();
  }
}

final signatureStoreProvider = FutureProvider<SignatureStore>((ref) async {
  return SignatureStore(await ref.watch(appPathsProvider.future));
});

/// Saved signatures, newest first. Invalidate after adding or deleting.
final signaturesProvider = FutureProvider<List<File>>((ref) async {
  final store = await ref.watch(signatureStoreProvider.future);
  return store.list();
});
