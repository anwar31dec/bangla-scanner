// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SaveFormat, String> format =
      GeneratedColumn<String>(
        'format',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SaveFormat>($DocumentsTable.$converterformat);
  static const VerificationMeta _dirPathMeta = const VerificationMeta(
    'dirPath',
  );
  @override
  late final GeneratedColumn<String> dirPath = GeneratedColumn<String>(
    'dir_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isProtectedMeta = const VerificationMeta(
    'isProtected',
  );
  @override
  late final GeneratedColumn<bool> isProtected = GeneratedColumn<bool>(
    'is_protected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_protected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasTextMeta = const VerificationMeta(
    'hasText',
  );
  @override
  late final GeneratedColumn<bool> hasText = GeneratedColumn<bool>(
    'has_text',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_text" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    format,
    dirPath,
    pageCount,
    sizeBytes,
    createdAt,
    updatedAt,
    isFavorite,
    folderId,
    isProtected,
    hasText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dir_path')) {
      context.handle(
        _dirPathMeta,
        dirPath.isAcceptableOrUnknown(data['dir_path']!, _dirPathMeta),
      );
    } else if (isInserting) {
      context.missing(_dirPathMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pageCountMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('is_protected')) {
      context.handle(
        _isProtectedMeta,
        isProtected.isAcceptableOrUnknown(
          data['is_protected']!,
          _isProtectedMeta,
        ),
      );
    }
    if (data.containsKey('has_text')) {
      context.handle(
        _hasTextMeta,
        hasText.isAcceptableOrUnknown(data['has_text']!, _hasTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      format: $DocumentsTable.$converterformat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}format'],
        )!,
      ),
      dirPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dir_path'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      isProtected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_protected'],
      )!,
      hasText: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_text'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SaveFormat, String, String> $converterformat =
      const EnumNameConverter<SaveFormat>(SaveFormat.values);
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String name;
  final SaveFormat format;

  /// Folder of the document, relative to the app documents directory.
  final String dirPath;
  final int pageCount;

  /// Size of the output (PDF file, or all JPEG pages) in bytes.
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Starred by the user.
  final bool isFavorite;

  /// Library folder the document is filed in (null = no folder).
  final String? folderId;

  /// True when the PDF was saved with an open password. The password itself
  /// is never stored.
  final bool isProtected;

  /// True when OCR text is stored for the document (see [PageTexts]), so the
  /// library search looks inside it and a PDF carries a text layer.
  final bool hasText;
  const DocumentRow({
    required this.id,
    required this.name,
    required this.format,
    required this.dirPath,
    required this.pageCount,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    this.folderId,
    required this.isProtected,
    required this.hasText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['format'] = Variable<String>(
        $DocumentsTable.$converterformat.toSql(format),
      );
    }
    map['dir_path'] = Variable<String>(dirPath);
    map['page_count'] = Variable<int>(pageCount);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['is_protected'] = Variable<bool>(isProtected);
    map['has_text'] = Variable<bool>(hasText);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      name: Value(name),
      format: Value(format),
      dirPath: Value(dirPath),
      pageCount: Value(pageCount),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isFavorite: Value(isFavorite),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      isProtected: Value(isProtected),
      hasText: Value(hasText),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      format: $DocumentsTable.$converterformat.fromJson(
        serializer.fromJson<String>(json['format']),
      ),
      dirPath: serializer.fromJson<String>(json['dirPath']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      isProtected: serializer.fromJson<bool>(json['isProtected']),
      hasText: serializer.fromJson<bool>(json['hasText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'format': serializer.toJson<String>(
        $DocumentsTable.$converterformat.toJson(format),
      ),
      'dirPath': serializer.toJson<String>(dirPath),
      'pageCount': serializer.toJson<int>(pageCount),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'folderId': serializer.toJson<String?>(folderId),
      'isProtected': serializer.toJson<bool>(isProtected),
      'hasText': serializer.toJson<bool>(hasText),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? name,
    SaveFormat? format,
    String? dirPath,
    int? pageCount,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    Value<String?> folderId = const Value.absent(),
    bool? isProtected,
    bool? hasText,
  }) => DocumentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    format: format ?? this.format,
    dirPath: dirPath ?? this.dirPath,
    pageCount: pageCount ?? this.pageCount,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    folderId: folderId.present ? folderId.value : this.folderId,
    isProtected: isProtected ?? this.isProtected,
    hasText: hasText ?? this.hasText,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      format: data.format.present ? data.format.value : this.format,
      dirPath: data.dirPath.present ? data.dirPath.value : this.dirPath,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      isProtected: data.isProtected.present
          ? data.isProtected.value
          : this.isProtected,
      hasText: data.hasText.present ? data.hasText.value : this.hasText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('format: $format, ')
          ..write('dirPath: $dirPath, ')
          ..write('pageCount: $pageCount, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('folderId: $folderId, ')
          ..write('isProtected: $isProtected, ')
          ..write('hasText: $hasText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    format,
    dirPath,
    pageCount,
    sizeBytes,
    createdAt,
    updatedAt,
    isFavorite,
    folderId,
    isProtected,
    hasText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.format == this.format &&
          other.dirPath == this.dirPath &&
          other.pageCount == this.pageCount &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isFavorite == this.isFavorite &&
          other.folderId == this.folderId &&
          other.isProtected == this.isProtected &&
          other.hasText == this.hasText);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<SaveFormat> format;
  final Value<String> dirPath;
  final Value<int> pageCount;
  final Value<int> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isFavorite;
  final Value<String?> folderId;
  final Value<bool> isProtected;
  final Value<bool> hasText;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.format = const Value.absent(),
    this.dirPath = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.folderId = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.hasText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String name,
    required SaveFormat format,
    required String dirPath,
    required int pageCount,
    required int sizeBytes,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isFavorite = const Value.absent(),
    this.folderId = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.hasText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       format = Value(format),
       dirPath = Value(dirPath),
       pageCount = Value(pageCount),
       sizeBytes = Value(sizeBytes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? format,
    Expression<String>? dirPath,
    Expression<int>? pageCount,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isFavorite,
    Expression<String>? folderId,
    Expression<bool>? isProtected,
    Expression<bool>? hasText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (format != null) 'format': format,
      if (dirPath != null) 'dir_path': dirPath,
      if (pageCount != null) 'page_count': pageCount,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (folderId != null) 'folder_id': folderId,
      if (isProtected != null) 'is_protected': isProtected,
      if (hasText != null) 'has_text': hasText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<SaveFormat>? format,
    Value<String>? dirPath,
    Value<int>? pageCount,
    Value<int>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isFavorite,
    Value<String?>? folderId,
    Value<bool>? isProtected,
    Value<bool>? hasText,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      dirPath: dirPath ?? this.dirPath,
      pageCount: pageCount ?? this.pageCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: folderId ?? this.folderId,
      isProtected: isProtected ?? this.isProtected,
      hasText: hasText ?? this.hasText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(
        $DocumentsTable.$converterformat.toSql(format.value),
      );
    }
    if (dirPath.present) {
      map['dir_path'] = Variable<String>(dirPath.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (isProtected.present) {
      map['is_protected'] = Variable<bool>(isProtected.value);
    }
    if (hasText.present) {
      map['has_text'] = Variable<bool>(hasText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('format: $format, ')
          ..write('dirPath: $dirPath, ')
          ..write('pageCount: $pageCount, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('folderId: $folderId, ')
          ..write('isProtected: $isProtected, ')
          ..write('hasText: $hasText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, FolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class FolderRow extends DataClass implements Insertable<FolderRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  const FolderRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory FolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FolderRow copyWith({String? id, String? name, DateTime? createdAt}) =>
      FolderRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  FolderRow copyWithCompanion(FoldersCompanion data) {
    return FolderRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<FolderRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<FolderRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageTextsTable extends PageTexts
    with TableInfo<$PageTextsTable, PageTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageTextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordsMeta = const VerificationMeta('words');
  @override
  late final GeneratedColumn<String> words = GeneratedColumn<String>(
    'words',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<OcrLanguage, String> language =
      GeneratedColumn<String>(
        'language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OcrLanguage>($PageTextsTable.$converterlanguage);
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    pageIndex,
    content,
    words,
    language,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_texts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageTextRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('words')) {
      context.handle(
        _wordsMeta,
        words.isAcceptableOrUnknown(data['words']!, _wordsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, pageIndex};
  @override
  PageTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageTextRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      words: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}words'],
      )!,
      language: $PageTextsTable.$converterlanguage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}language'],
        )!,
      ),
    );
  }

  @override
  $PageTextsTable createAlias(String alias) {
    return $PageTextsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OcrLanguage, String, String> $converterlanguage =
      const EnumNameConverter<OcrLanguage>(OcrLanguage.values);
}

class PageTextRow extends DataClass implements Insertable<PageTextRow> {
  final String documentId;

  /// 0-based page number.
  final int pageIndex;
  final String content;

  /// JSON list of `[word, left, top, right, bottom]` (fractions of the page).
  final String words;
  final OcrLanguage language;
  const PageTextRow({
    required this.documentId,
    required this.pageIndex,
    required this.content,
    required this.words,
    required this.language,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['page_index'] = Variable<int>(pageIndex);
    map['content'] = Variable<String>(content);
    map['words'] = Variable<String>(words);
    {
      map['language'] = Variable<String>(
        $PageTextsTable.$converterlanguage.toSql(language),
      );
    }
    return map;
  }

  PageTextsCompanion toCompanion(bool nullToAbsent) {
    return PageTextsCompanion(
      documentId: Value(documentId),
      pageIndex: Value(pageIndex),
      content: Value(content),
      words: Value(words),
      language: Value(language),
    );
  }

  factory PageTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageTextRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      content: serializer.fromJson<String>(json['content']),
      words: serializer.fromJson<String>(json['words']),
      language: $PageTextsTable.$converterlanguage.fromJson(
        serializer.fromJson<String>(json['language']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'content': serializer.toJson<String>(content),
      'words': serializer.toJson<String>(words),
      'language': serializer.toJson<String>(
        $PageTextsTable.$converterlanguage.toJson(language),
      ),
    };
  }

  PageTextRow copyWith({
    String? documentId,
    int? pageIndex,
    String? content,
    String? words,
    OcrLanguage? language,
  }) => PageTextRow(
    documentId: documentId ?? this.documentId,
    pageIndex: pageIndex ?? this.pageIndex,
    content: content ?? this.content,
    words: words ?? this.words,
    language: language ?? this.language,
  );
  PageTextRow copyWithCompanion(PageTextsCompanion data) {
    return PageTextRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      content: data.content.present ? data.content.value : this.content,
      words: data.words.present ? data.words.value : this.words,
      language: data.language.present ? data.language.value : this.language,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageTextRow(')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('content: $content, ')
          ..write('words: $words, ')
          ..write('language: $language')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(documentId, pageIndex, content, words, language);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageTextRow &&
          other.documentId == this.documentId &&
          other.pageIndex == this.pageIndex &&
          other.content == this.content &&
          other.words == this.words &&
          other.language == this.language);
}

class PageTextsCompanion extends UpdateCompanion<PageTextRow> {
  final Value<String> documentId;
  final Value<int> pageIndex;
  final Value<String> content;
  final Value<String> words;
  final Value<OcrLanguage> language;
  final Value<int> rowid;
  const PageTextsCompanion({
    this.documentId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.content = const Value.absent(),
    this.words = const Value.absent(),
    this.language = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageTextsCompanion.insert({
    required String documentId,
    required int pageIndex,
    required String content,
    this.words = const Value.absent(),
    required OcrLanguage language,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       pageIndex = Value(pageIndex),
       content = Value(content),
       language = Value(language);
  static Insertable<PageTextRow> custom({
    Expression<String>? documentId,
    Expression<int>? pageIndex,
    Expression<String>? content,
    Expression<String>? words,
    Expression<String>? language,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (content != null) 'content': content,
      if (words != null) 'words': words,
      if (language != null) 'language': language,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageTextsCompanion copyWith({
    Value<String>? documentId,
    Value<int>? pageIndex,
    Value<String>? content,
    Value<String>? words,
    Value<OcrLanguage>? language,
    Value<int>? rowid,
  }) {
    return PageTextsCompanion(
      documentId: documentId ?? this.documentId,
      pageIndex: pageIndex ?? this.pageIndex,
      content: content ?? this.content,
      words: words ?? this.words,
      language: language ?? this.language,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (words.present) {
      map['words'] = Variable<String>(words.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(
        $PageTextsTable.$converterlanguage.toSql(language.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageTextsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('content: $content, ')
          ..write('words: $words, ')
          ..write('language: $language, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $PageTextsTable pageTexts = $PageTextsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    folders,
    pageTexts,
  ];
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String name,
      required SaveFormat format,
      required String dirPath,
      required int pageCount,
      required int sizeBytes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isFavorite,
      Value<String?> folderId,
      Value<bool> isProtected,
      Value<bool> hasText,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<SaveFormat> format,
      Value<String> dirPath,
      Value<int> pageCount,
      Value<int> sizeBytes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isFavorite,
      Value<String?> folderId,
      Value<bool> isProtected,
      Value<bool> hasText,
      Value<int> rowid,
    });

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SaveFormat, SaveFormat, String> get format =>
      $composableBuilder(
        column: $table.format,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get dirPath => $composableBuilder(
    column: $table.dirPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasText => $composableBuilder(
    column: $table.hasText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dirPath => $composableBuilder(
    column: $table.dirPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasText => $composableBuilder(
    column: $table.hasText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SaveFormat, String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get dirPath =>
      $composableBuilder(column: $table.dirPath, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasText =>
      $composableBuilder(column: $table.hasText, builder: (column) => column);
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (
            DocumentRow,
            BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
          ),
          DocumentRow,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SaveFormat> format = const Value.absent(),
                Value<String> dirPath = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<bool> isProtected = const Value.absent(),
                Value<bool> hasText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                name: name,
                format: format,
                dirPath: dirPath,
                pageCount: pageCount,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isFavorite: isFavorite,
                folderId: folderId,
                isProtected: isProtected,
                hasText: hasText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required SaveFormat format,
                required String dirPath,
                required int pageCount,
                required int sizeBytes,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<bool> isProtected = const Value.absent(),
                Value<bool> hasText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                name: name,
                format: format,
                dirPath: dirPath,
                pageCount: pageCount,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isFavorite: isFavorite,
                folderId: folderId,
                isProtected: isProtected,
                hasText: hasText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, DocumentRow>(table),
                  BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (
        DocumentRow,
        BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
      ),
      DocumentRow,
      PrefetchHooks Function()
    >;
typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          FolderRow,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (FolderRow, BaseReferences<_$AppDatabase, $FoldersTable, FolderRow>),
          FolderRow,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTable, FolderRow>(table),
                  BaseReferences<_$AppDatabase, $FoldersTable, FolderRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      FolderRow,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (FolderRow, BaseReferences<_$AppDatabase, $FoldersTable, FolderRow>),
      FolderRow,
      PrefetchHooks Function()
    >;
typedef $$PageTextsTableCreateCompanionBuilder =
    PageTextsCompanion Function({
      required String documentId,
      required int pageIndex,
      required String content,
      Value<String> words,
      required OcrLanguage language,
      Value<int> rowid,
    });
typedef $$PageTextsTableUpdateCompanionBuilder =
    PageTextsCompanion Function({
      Value<String> documentId,
      Value<int> pageIndex,
      Value<String> content,
      Value<String> words,
      Value<OcrLanguage> language,
      Value<int> rowid,
    });

class $$PageTextsTableFilterComposer
    extends Composer<_$AppDatabase, $PageTextsTable> {
  $$PageTextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get words => $composableBuilder(
    column: $table.words,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OcrLanguage, OcrLanguage, String>
  get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$PageTextsTableOrderingComposer
    extends Composer<_$AppDatabase, $PageTextsTable> {
  $$PageTextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get words => $composableBuilder(
    column: $table.words,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PageTextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageTextsTable> {
  $$PageTextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get words =>
      $composableBuilder(column: $table.words, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OcrLanguage, String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);
}

class $$PageTextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageTextsTable,
          PageTextRow,
          $$PageTextsTableFilterComposer,
          $$PageTextsTableOrderingComposer,
          $$PageTextsTableAnnotationComposer,
          $$PageTextsTableCreateCompanionBuilder,
          $$PageTextsTableUpdateCompanionBuilder,
          (
            PageTextRow,
            BaseReferences<_$AppDatabase, $PageTextsTable, PageTextRow>,
          ),
          PageTextRow,
          PrefetchHooks Function()
        > {
  $$PageTextsTableTableManager(_$AppDatabase db, $PageTextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageTextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageTextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageTextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> pageIndex = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> words = const Value.absent(),
                Value<OcrLanguage> language = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageTextsCompanion(
                documentId: documentId,
                pageIndex: pageIndex,
                content: content,
                words: words,
                language: language,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int pageIndex,
                required String content,
                Value<String> words = const Value.absent(),
                required OcrLanguage language,
                Value<int> rowid = const Value.absent(),
              }) => PageTextsCompanion.insert(
                documentId: documentId,
                pageIndex: pageIndex,
                content: content,
                words: words,
                language: language,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PageTextsTable, PageTextRow>(table),
                  BaseReferences<_$AppDatabase, $PageTextsTable, PageTextRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PageTextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageTextsTable,
      PageTextRow,
      $$PageTextsTableFilterComposer,
      $$PageTextsTableOrderingComposer,
      $$PageTextsTableAnnotationComposer,
      $$PageTextsTableCreateCompanionBuilder,
      $$PageTextsTableUpdateCompanionBuilder,
      (
        PageTextRow,
        BaseReferences<_$AppDatabase, $PageTextsTable, PageTextRow>,
      ),
      PageTextRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$PageTextsTableTableManager get pageTexts =>
      $$PageTextsTableTableManager(_db, _db.pageTexts);
}
