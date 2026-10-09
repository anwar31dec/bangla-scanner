import '../../../core/models/enums.dart';

/// What a backup zip says about itself (`manifest.json` at the zip root).
///
/// Layout of a backup:
/// ```
/// manifest.json
/// library/<documentId>/pages/page_001.jpg …
/// library/<documentId>/document.pdf      (PDF documents)
/// library/<documentId>/thumb.jpg
/// ```
class BackupManifest {
  const BackupManifest({
    required this.createdAt,
    required this.appVersion,
    required this.folders,
    required this.documents,
  });

  /// Value of the `format` field that marks a file as one of ours.
  static const format = 'banglascanner-backup';

  /// Bumped when the layout changes in a way old apps cannot read.
  static const version = 1;

  /// Folder inside the zip that holds the document folders.
  static const libraryFolder = 'library';
  static const fileName = 'manifest.json';

  final DateTime createdAt;
  final String appVersion;
  final List<BackupFolder> folders;
  final List<BackupDocument> documents;

  Map<String, Object?> toJson() => {
    'format': format,
    'version': version,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'folders': [for (final f in folders) f.toJson()],
    'documents': [for (final d in documents) d.toJson()],
  };

  /// Throws [FormatException] when [json] is not a manifest we understand.
  factory BackupManifest.fromJson(Map<String, Object?> json) {
    if (json['format'] != format) throw const FormatException('Not a Bangla Scanner backup');
    final version = json['version'];
    if (version is! int || version > BackupManifest.version) {
      throw FormatException('Unsupported backup version $version');
    }
    final folders = json['folders'], documents = json['documents'];
    return BackupManifest(
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      appVersion: json['appVersion'] as String? ?? '',
      folders: [
        if (folders is List)
          for (final f in folders)
            if (f is Map<String, Object?>) BackupFolder.fromJson(f),
      ],
      documents: [
        if (documents is List)
          for (final d in documents)
            if (d is Map<String, Object?>) BackupDocument.fromJson(d),
      ],
    );
  }
}

class BackupFolder {
  const BackupFolder({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'createdAt': createdAt.toUtc().toIso8601String()};

  factory BackupFolder.fromJson(Map<String, Object?> json) => BackupFolder(
    id: _requireString(json, 'id'),
    name: _requireString(json, 'name'),
    createdAt: _date(json['createdAt']),
  );
}

class BackupDocument {
  const BackupDocument({
    required this.id,
    required this.name,
    required this.format,
    required this.pageCount,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    required this.folderId,
    required this.isProtected,
  });

  final String id;
  final String name;
  final SaveFormat format;
  final int pageCount;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? folderId;
  final bool isProtected;

  /// Where the document's files are inside the zip.
  String get zipFolder => '${BackupManifest.libraryFolder}/$id';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'format': format.name,
    'pageCount': pageCount,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'isFavorite': isFavorite,
    'folderId': folderId,
    'isProtected': isProtected,
  };

  factory BackupDocument.fromJson(Map<String, Object?> json) {
    final id = _requireString(json, 'id');
    // Ids become folder names on disk; keep them boring.
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id)) throw FormatException('Bad document id $id');
    return BackupDocument(
      id: id,
      name: _requireString(json, 'name'),
      format: SaveFormat.values.firstWhere((f) => f.name == json['format'], orElse: () => SaveFormat.pdf),
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      isFavorite: json['isFavorite'] == true,
      folderId: json['folderId'] as String?,
      isProtected: json['isProtected'] == true,
    );
  }
}

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Missing $key');
  return value;
}

DateTime _date(Object? value) => DateTime.tryParse(value as String? ?? '')?.toLocal() ?? DateTime.now();
