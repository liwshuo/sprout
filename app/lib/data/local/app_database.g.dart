// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SeriesTable extends Series with TableInfo<$SeriesTable, SeriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalVolumesMeta =
      const VerificationMeta('totalVolumes');
  @override
  late final GeneratedColumn<int> totalVolumes = GeneratedColumn<int>(
      'total_volumes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, uuid, name, totalVolumes, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(Insertable<SeriesData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_volumes')) {
      context.handle(
          _totalVolumesMeta,
          totalVolumes.isAcceptableOrUnknown(
              data['total_volumes']!, _totalVolumesMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      totalVolumes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_volumes'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $SeriesTable createAlias(String alias) {
    return $SeriesTable(attachedDatabase, alias);
  }
}

class SeriesData extends DataClass implements Insertable<SeriesData> {
  final int id;
  final String uuid;
  final String name;
  final int totalVolumes;
  final DateTime updatedAt;
  final bool isDeleted;
  const SeriesData(
      {required this.id,
      required this.uuid,
      required this.name,
      required this.totalVolumes,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['total_volumes'] = Variable<int>(totalVolumes);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  SeriesCompanion toCompanion(bool nullToAbsent) {
    return SeriesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      totalVolumes: Value(totalVolumes),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory SeriesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      totalVolumes: serializer.fromJson<int>(json['totalVolumes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'totalVolumes': serializer.toJson<int>(totalVolumes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  SeriesData copyWith(
          {int? id,
          String? uuid,
          String? name,
          int? totalVolumes,
          DateTime? updatedAt,
          bool? isDeleted}) =>
      SeriesData(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        totalVolumes: totalVolumes ?? this.totalVolumes,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  SeriesData copyWithCompanion(SeriesCompanion data) {
    return SeriesData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      totalVolumes: data.totalVolumes.present
          ? data.totalVolumes.value
          : this.totalVolumes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('totalVolumes: $totalVolumes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, name, totalVolumes, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.totalVolumes == this.totalVolumes &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class SeriesCompanion extends UpdateCompanion<SeriesData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> totalVolumes;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const SeriesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.totalVolumes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  SeriesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    this.totalVolumes = const Value.absent(),
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<SeriesData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? totalVolumes,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (totalVolumes != null) 'total_volumes': totalVolumes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  SeriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<int>? totalVolumes,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return SeriesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      totalVolumes: totalVolumes ?? this.totalVolumes,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalVolumes.present) {
      map['total_volumes'] = Variable<int>(totalVolumes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('totalVolumes: $totalVolumes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
      'cover', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
      'isbn', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('want'));
  static const VerificationMeta _totalPagesMeta =
      const VerificationMeta('totalPages');
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
      'total_pages', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalChaptersMeta =
      const VerificationMeta('totalChapters');
  @override
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
      'total_chapters', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
      'series_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES series (id) ON DELETE SET NULL'));
  static const VerificationMeta _seriesIndexMeta =
      const VerificationMeta('seriesIndex');
  @override
  late final GeneratedColumn<int> seriesIndex = GeneratedColumn<int>(
      'series_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        title,
        author,
        cover,
        isbn,
        status,
        totalPages,
        totalChapters,
        seriesId,
        seriesIndex,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(Insertable<Book> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('cover')) {
      context.handle(
          _coverMeta, cover.isAcceptableOrUnknown(data['cover']!, _coverMeta));
    }
    if (data.containsKey('isbn')) {
      context.handle(
          _isbnMeta, isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('total_pages')) {
      context.handle(
          _totalPagesMeta,
          totalPages.isAcceptableOrUnknown(
              data['total_pages']!, _totalPagesMeta));
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
          _totalChaptersMeta,
          totalChapters.isAcceptableOrUnknown(
              data['total_chapters']!, _totalChaptersMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    }
    if (data.containsKey('series_index')) {
      context.handle(
          _seriesIndexMeta,
          seriesIndex.isAcceptableOrUnknown(
              data['series_index']!, _seriesIndexMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      cover: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover']),
      isbn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}isbn']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalPages: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_pages']),
      totalChapters: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_chapters']),
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}series_id']),
      seriesIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}series_index']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final int id;
  final String uuid;
  final String title;
  final String? author;
  final String? cover;
  final String? isbn;
  final String status;
  final int? totalPages;
  final int? totalChapters;
  final int? seriesId;
  final int? seriesIndex;
  final DateTime updatedAt;
  final bool isDeleted;
  const Book(
      {required this.id,
      required this.uuid,
      required this.title,
      this.author,
      this.cover,
      this.isbn,
      required this.status,
      this.totalPages,
      this.totalChapters,
      this.seriesId,
      this.seriesIndex,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || isbn != null) {
      map['isbn'] = Variable<String>(isbn);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || totalPages != null) {
      map['total_pages'] = Variable<int>(totalPages);
    }
    if (!nullToAbsent || totalChapters != null) {
      map['total_chapters'] = Variable<int>(totalChapters);
    }
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    if (!nullToAbsent || seriesIndex != null) {
      map['series_index'] = Variable<int>(seriesIndex);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      cover:
          cover == null && nullToAbsent ? const Value.absent() : Value(cover),
      isbn: isbn == null && nullToAbsent ? const Value.absent() : Value(isbn),
      status: Value(status),
      totalPages: totalPages == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPages),
      totalChapters: totalChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(totalChapters),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      seriesIndex: seriesIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesIndex),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Book.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      cover: serializer.fromJson<String?>(json['cover']),
      isbn: serializer.fromJson<String?>(json['isbn']),
      status: serializer.fromJson<String>(json['status']),
      totalPages: serializer.fromJson<int?>(json['totalPages']),
      totalChapters: serializer.fromJson<int?>(json['totalChapters']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      seriesIndex: serializer.fromJson<int?>(json['seriesIndex']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'cover': serializer.toJson<String?>(cover),
      'isbn': serializer.toJson<String?>(isbn),
      'status': serializer.toJson<String>(status),
      'totalPages': serializer.toJson<int?>(totalPages),
      'totalChapters': serializer.toJson<int?>(totalChapters),
      'seriesId': serializer.toJson<int?>(seriesId),
      'seriesIndex': serializer.toJson<int?>(seriesIndex),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Book copyWith(
          {int? id,
          String? uuid,
          String? title,
          Value<String?> author = const Value.absent(),
          Value<String?> cover = const Value.absent(),
          Value<String?> isbn = const Value.absent(),
          String? status,
          Value<int?> totalPages = const Value.absent(),
          Value<int?> totalChapters = const Value.absent(),
          Value<int?> seriesId = const Value.absent(),
          Value<int?> seriesIndex = const Value.absent(),
          DateTime? updatedAt,
          bool? isDeleted}) =>
      Book(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        cover: cover.present ? cover.value : this.cover,
        isbn: isbn.present ? isbn.value : this.isbn,
        status: status ?? this.status,
        totalPages: totalPages.present ? totalPages.value : this.totalPages,
        totalChapters:
            totalChapters.present ? totalChapters.value : this.totalChapters,
        seriesId: seriesId.present ? seriesId.value : this.seriesId,
        seriesIndex: seriesIndex.present ? seriesIndex.value : this.seriesIndex,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      cover: data.cover.present ? data.cover.value : this.cover,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      status: data.status.present ? data.status.value : this.status,
      totalPages:
          data.totalPages.present ? data.totalPages.value : this.totalPages,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seriesIndex:
          data.seriesIndex.present ? data.seriesIndex.value : this.seriesIndex,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('cover: $cover, ')
          ..write('isbn: $isbn, ')
          ..write('status: $status, ')
          ..write('totalPages: $totalPages, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('seriesId: $seriesId, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, title, author, cover, isbn, status,
      totalPages, totalChapters, seriesId, seriesIndex, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.author == this.author &&
          other.cover == this.cover &&
          other.isbn == this.isbn &&
          other.status == this.status &&
          other.totalPages == this.totalPages &&
          other.totalChapters == this.totalChapters &&
          other.seriesId == this.seriesId &&
          other.seriesIndex == this.seriesIndex &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> cover;
  final Value<String?> isbn;
  final Value<String> status;
  final Value<int?> totalPages;
  final Value<int?> totalChapters;
  final Value<int?> seriesId;
  final Value<int?> seriesIndex;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.cover = const Value.absent(),
    this.isbn = const Value.absent(),
    this.status = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String title,
    this.author = const Value.absent(),
    this.cover = const Value.absent(),
    this.isbn = const Value.absent(),
    this.status = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        title = Value(title),
        updatedAt = Value(updatedAt);
  static Insertable<Book> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? cover,
    Expression<String>? isbn,
    Expression<String>? status,
    Expression<int>? totalPages,
    Expression<int>? totalChapters,
    Expression<int>? seriesId,
    Expression<int>? seriesIndex,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (cover != null) 'cover': cover,
      if (isbn != null) 'isbn': isbn,
      if (status != null) 'status': status,
      if (totalPages != null) 'total_pages': totalPages,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (seriesId != null) 'series_id': seriesId,
      if (seriesIndex != null) 'series_index': seriesIndex,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  BooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? title,
      Value<String?>? author,
      Value<String?>? cover,
      Value<String?>? isbn,
      Value<String>? status,
      Value<int?>? totalPages,
      Value<int?>? totalChapters,
      Value<int?>? seriesId,
      Value<int?>? seriesIndex,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return BooksCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      author: author ?? this.author,
      cover: cover ?? this.cover,
      isbn: isbn ?? this.isbn,
      status: status ?? this.status,
      totalPages: totalPages ?? this.totalPages,
      totalChapters: totalChapters ?? this.totalChapters,
      seriesId: seriesId ?? this.seriesId,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (seriesIndex.present) {
      map['series_index'] = Variable<int>(seriesIndex.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('cover: $cover, ')
          ..write('isbn: $isbn, ')
          ..write('status: $status, ')
          ..write('totalPages: $totalPages, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('seriesId: $seriesId, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $ReadingLogsTable extends ReadingLogs
    with TableInfo<$ReadingLogsTable, ReadingLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
      'book_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES books (id) ON DELETE CASCADE'));
  static const VerificationMeta _readDateMeta =
      const VerificationMeta('readDate');
  @override
  late final GeneratedColumn<DateTime> readDate = GeneratedColumn<DateTime>(
      'read_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _chapterMeta =
      const VerificationMeta('chapter');
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
      'chapter', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chapterIndexMeta =
      const VerificationMeta('chapterIndex');
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
      'chapter_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageFromMeta =
      const VerificationMeta('pageFrom');
  @override
  late final GeneratedColumn<int> pageFrom = GeneratedColumn<int>(
      'page_from', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageToMeta = const VerificationMeta('pageTo');
  @override
  late final GeneratedColumn<int> pageTo = GeneratedColumn<int>(
      'page_to', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        bookId,
        readDate,
        chapter,
        chapterIndex,
        pageFrom,
        pageTo,
        durationMinutes,
        mood,
        note,
        source,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReadingLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('read_date')) {
      context.handle(_readDateMeta,
          readDate.isAcceptableOrUnknown(data['read_date']!, _readDateMeta));
    } else if (isInserting) {
      context.missing(_readDateMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(_chapterMeta,
          chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta));
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
          _chapterIndexMeta,
          chapterIndex.isAcceptableOrUnknown(
              data['chapter_index']!, _chapterIndexMeta));
    }
    if (data.containsKey('page_from')) {
      context.handle(_pageFromMeta,
          pageFrom.isAcceptableOrUnknown(data['page_from']!, _pageFromMeta));
    }
    if (data.containsKey('page_to')) {
      context.handle(_pageToMeta,
          pageTo.isAcceptableOrUnknown(data['page_to']!, _pageToMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}book_id'])!,
      readDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}read_date'])!,
      chapter: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter']),
      chapterIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_index']),
      pageFrom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_from']),
      pageTo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_to']),
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ReadingLogsTable createAlias(String alias) {
    return $ReadingLogsTable(attachedDatabase, alias);
  }
}

class ReadingLog extends DataClass implements Insertable<ReadingLog> {
  final int id;
  final String uuid;
  final int bookId;
  final DateTime readDate;
  final String? chapter;
  final int? chapterIndex;
  final int? pageFrom;
  final int? pageTo;
  final int durationMinutes;
  final String? mood;
  final String? note;
  final String source;
  final DateTime updatedAt;
  final bool isDeleted;
  const ReadingLog(
      {required this.id,
      required this.uuid,
      required this.bookId,
      required this.readDate,
      this.chapter,
      this.chapterIndex,
      this.pageFrom,
      this.pageTo,
      required this.durationMinutes,
      this.mood,
      this.note,
      required this.source,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['book_id'] = Variable<int>(bookId);
    map['read_date'] = Variable<DateTime>(readDate);
    if (!nullToAbsent || chapter != null) {
      map['chapter'] = Variable<String>(chapter);
    }
    if (!nullToAbsent || chapterIndex != null) {
      map['chapter_index'] = Variable<int>(chapterIndex);
    }
    if (!nullToAbsent || pageFrom != null) {
      map['page_from'] = Variable<int>(pageFrom);
    }
    if (!nullToAbsent || pageTo != null) {
      map['page_to'] = Variable<int>(pageTo);
    }
    map['duration_minutes'] = Variable<int>(durationMinutes);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['source'] = Variable<String>(source);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ReadingLogsCompanion toCompanion(bool nullToAbsent) {
    return ReadingLogsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      bookId: Value(bookId),
      readDate: Value(readDate),
      chapter: chapter == null && nullToAbsent
          ? const Value.absent()
          : Value(chapter),
      chapterIndex: chapterIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterIndex),
      pageFrom: pageFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(pageFrom),
      pageTo:
          pageTo == null && nullToAbsent ? const Value.absent() : Value(pageTo),
      durationMinutes: Value(durationMinutes),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      source: Value(source),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory ReadingLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingLog(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      bookId: serializer.fromJson<int>(json['bookId']),
      readDate: serializer.fromJson<DateTime>(json['readDate']),
      chapter: serializer.fromJson<String?>(json['chapter']),
      chapterIndex: serializer.fromJson<int?>(json['chapterIndex']),
      pageFrom: serializer.fromJson<int?>(json['pageFrom']),
      pageTo: serializer.fromJson<int?>(json['pageTo']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      mood: serializer.fromJson<String?>(json['mood']),
      note: serializer.fromJson<String?>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'bookId': serializer.toJson<int>(bookId),
      'readDate': serializer.toJson<DateTime>(readDate),
      'chapter': serializer.toJson<String?>(chapter),
      'chapterIndex': serializer.toJson<int?>(chapterIndex),
      'pageFrom': serializer.toJson<int?>(pageFrom),
      'pageTo': serializer.toJson<int?>(pageTo),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'mood': serializer.toJson<String?>(mood),
      'note': serializer.toJson<String?>(note),
      'source': serializer.toJson<String>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ReadingLog copyWith(
          {int? id,
          String? uuid,
          int? bookId,
          DateTime? readDate,
          Value<String?> chapter = const Value.absent(),
          Value<int?> chapterIndex = const Value.absent(),
          Value<int?> pageFrom = const Value.absent(),
          Value<int?> pageTo = const Value.absent(),
          int? durationMinutes,
          Value<String?> mood = const Value.absent(),
          Value<String?> note = const Value.absent(),
          String? source,
          DateTime? updatedAt,
          bool? isDeleted}) =>
      ReadingLog(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        bookId: bookId ?? this.bookId,
        readDate: readDate ?? this.readDate,
        chapter: chapter.present ? chapter.value : this.chapter,
        chapterIndex:
            chapterIndex.present ? chapterIndex.value : this.chapterIndex,
        pageFrom: pageFrom.present ? pageFrom.value : this.pageFrom,
        pageTo: pageTo.present ? pageTo.value : this.pageTo,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        mood: mood.present ? mood.value : this.mood,
        note: note.present ? note.value : this.note,
        source: source ?? this.source,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  ReadingLog copyWithCompanion(ReadingLogsCompanion data) {
    return ReadingLog(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      readDate: data.readDate.present ? data.readDate.value : this.readDate,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      pageFrom: data.pageFrom.present ? data.pageFrom.value : this.pageFrom,
      pageTo: data.pageTo.present ? data.pageTo.value : this.pageTo,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      mood: data.mood.present ? data.mood.value : this.mood,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingLog(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('readDate: $readDate, ')
          ..write('chapter: $chapter, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('pageFrom: $pageFrom, ')
          ..write('pageTo: $pageTo, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      bookId,
      readDate,
      chapter,
      chapterIndex,
      pageFrom,
      pageTo,
      durationMinutes,
      mood,
      note,
      source,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingLog &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.bookId == this.bookId &&
          other.readDate == this.readDate &&
          other.chapter == this.chapter &&
          other.chapterIndex == this.chapterIndex &&
          other.pageFrom == this.pageFrom &&
          other.pageTo == this.pageTo &&
          other.durationMinutes == this.durationMinutes &&
          other.mood == this.mood &&
          other.note == this.note &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class ReadingLogsCompanion extends UpdateCompanion<ReadingLog> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> bookId;
  final Value<DateTime> readDate;
  final Value<String?> chapter;
  final Value<int?> chapterIndex;
  final Value<int?> pageFrom;
  final Value<int?> pageTo;
  final Value<int> durationMinutes;
  final Value<String?> mood;
  final Value<String?> note;
  final Value<String> source;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const ReadingLogsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.bookId = const Value.absent(),
    this.readDate = const Value.absent(),
    this.chapter = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.pageFrom = const Value.absent(),
    this.pageTo = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ReadingLogsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int bookId,
    required DateTime readDate,
    this.chapter = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.pageFrom = const Value.absent(),
    this.pageTo = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        bookId = Value(bookId),
        readDate = Value(readDate),
        updatedAt = Value(updatedAt);
  static Insertable<ReadingLog> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? bookId,
    Expression<DateTime>? readDate,
    Expression<String>? chapter,
    Expression<int>? chapterIndex,
    Expression<int>? pageFrom,
    Expression<int>? pageTo,
    Expression<int>? durationMinutes,
    Expression<String>? mood,
    Expression<String>? note,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (bookId != null) 'book_id': bookId,
      if (readDate != null) 'read_date': readDate,
      if (chapter != null) 'chapter': chapter,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (pageFrom != null) 'page_from': pageFrom,
      if (pageTo != null) 'page_to': pageTo,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (mood != null) 'mood': mood,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ReadingLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<int>? bookId,
      Value<DateTime>? readDate,
      Value<String?>? chapter,
      Value<int?>? chapterIndex,
      Value<int?>? pageFrom,
      Value<int?>? pageTo,
      Value<int>? durationMinutes,
      Value<String?>? mood,
      Value<String?>? note,
      Value<String>? source,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return ReadingLogsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      readDate: readDate ?? this.readDate,
      chapter: chapter ?? this.chapter,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      pageFrom: pageFrom ?? this.pageFrom,
      pageTo: pageTo ?? this.pageTo,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (readDate.present) {
      map['read_date'] = Variable<DateTime>(readDate.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (pageFrom.present) {
      map['page_from'] = Variable<int>(pageFrom.value);
    }
    if (pageTo.present) {
      map['page_to'] = Variable<int>(pageTo.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingLogsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('readDate: $readDate, ')
          ..write('chapter: $chapter, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('pageFrom: $pageFrom, ')
          ..write('pageTo: $pageTo, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $DailyRecordsTable extends DailyRecords
    with TableInfo<$DailyRecordsTable, DailyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathsMeta =
      const VerificationMeta('imagePaths');
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
      'image_paths', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _eventDateMeta =
      const VerificationMeta('eventDate');
  @override
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
      'event_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        title,
        note,
        tags,
        imagePaths,
        category,
        mood,
        source,
        eventDate,
        durationMinutes,
        createdAt,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_records';
  @override
  VerificationContext validateIntegrity(Insertable<DailyRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('image_paths')) {
      context.handle(
          _imagePathsMeta,
          imagePaths.isAcceptableOrUnknown(
              data['image_paths']!, _imagePathsMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('event_date')) {
      context.handle(_eventDateMeta,
          eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta));
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      imagePaths: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_paths']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      eventDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}event_date'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $DailyRecordsTable createAlias(String alias) {
    return $DailyRecordsTable(attachedDatabase, alias);
  }
}

class DailyRecord extends DataClass implements Insertable<DailyRecord> {
  final int id;
  final String uuid;
  final String title;
  final String? note;
  final String? tags;
  final String? imagePaths;
  final String? category;
  final String? mood;
  final String source;
  final DateTime eventDate;
  final int? durationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const DailyRecord(
      {required this.id,
      required this.uuid,
      required this.title,
      this.note,
      this.tags,
      this.imagePaths,
      this.category,
      this.mood,
      required this.source,
      required this.eventDate,
      this.durationMinutes,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['source'] = Variable<String>(source);
    map['event_date'] = Variable<DateTime>(eventDate);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  DailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyRecordsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      source: Value(source),
      eventDate: Value(eventDate),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRecord(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      tags: serializer.fromJson<String?>(json['tags']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      category: serializer.fromJson<String?>(json['category']),
      mood: serializer.fromJson<String?>(json['mood']),
      source: serializer.fromJson<String>(json['source']),
      eventDate: serializer.fromJson<DateTime>(json['eventDate']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'tags': serializer.toJson<String?>(tags),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'category': serializer.toJson<String?>(category),
      'mood': serializer.toJson<String?>(mood),
      'source': serializer.toJson<String>(source),
      'eventDate': serializer.toJson<DateTime>(eventDate),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  DailyRecord copyWith(
          {int? id,
          String? uuid,
          String? title,
          Value<String?> note = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          Value<String?> imagePaths = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> mood = const Value.absent(),
          String? source,
          DateTime? eventDate,
          Value<int?> durationMinutes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isDeleted}) =>
      DailyRecord(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        title: title ?? this.title,
        note: note.present ? note.value : this.note,
        tags: tags.present ? tags.value : this.tags,
        imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
        category: category.present ? category.value : this.category,
        mood: mood.present ? mood.value : this.mood,
        source: source ?? this.source,
        eventDate: eventDate ?? this.eventDate,
        durationMinutes: durationMinutes.present
            ? durationMinutes.value
            : this.durationMinutes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  DailyRecord copyWithCompanion(DailyRecordsCompanion data) {
    return DailyRecord(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      tags: data.tags.present ? data.tags.value : this.tags,
      imagePaths:
          data.imagePaths.present ? data.imagePaths.value : this.imagePaths,
      category: data.category.present ? data.category.value : this.category,
      mood: data.mood.present ? data.mood.value : this.mood,
      source: data.source.present ? data.source.value : this.source,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecord(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('category: $category, ')
          ..write('mood: $mood, ')
          ..write('source: $source, ')
          ..write('eventDate: $eventDate, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      title,
      note,
      tags,
      imagePaths,
      category,
      mood,
      source,
      eventDate,
      durationMinutes,
      createdAt,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRecord &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.note == this.note &&
          other.tags == this.tags &&
          other.imagePaths == this.imagePaths &&
          other.category == this.category &&
          other.mood == this.mood &&
          other.source == this.source &&
          other.eventDate == this.eventDate &&
          other.durationMinutes == this.durationMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class DailyRecordsCompanion extends UpdateCompanion<DailyRecord> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String?> note;
  final Value<String?> tags;
  final Value<String?> imagePaths;
  final Value<String?> category;
  final Value<String?> mood;
  final Value<String> source;
  final Value<DateTime> eventDate;
  final Value<int?> durationMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const DailyRecordsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.category = const Value.absent(),
    this.mood = const Value.absent(),
    this.source = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  DailyRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String title,
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.category = const Value.absent(),
    this.mood = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime eventDate,
    this.durationMinutes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        title = Value(title),
        eventDate = Value(eventDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DailyRecord> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? tags,
    Expression<String>? imagePaths,
    Expression<String>? category,
    Expression<String>? mood,
    Expression<String>? source,
    Expression<DateTime>? eventDate,
    Expression<int>? durationMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (tags != null) 'tags': tags,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (category != null) 'category': category,
      if (mood != null) 'mood': mood,
      if (source != null) 'source': source,
      if (eventDate != null) 'event_date': eventDate,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  DailyRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? title,
      Value<String?>? note,
      Value<String?>? tags,
      Value<String?>? imagePaths,
      Value<String?>? category,
      Value<String?>? mood,
      Value<String>? source,
      Value<DateTime>? eventDate,
      Value<int?>? durationMinutes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return DailyRecordsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      imagePaths: imagePaths ?? this.imagePaths,
      category: category ?? this.category,
      mood: mood ?? this.mood,
      source: source ?? this.source,
      eventDate: eventDate ?? this.eventDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('category: $category, ')
          ..write('mood: $mood, ')
          ..write('source: $source, ')
          ..write('eventDate: $eventDate, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $ScheduleItemsTable extends ScheduleItems
    with TableInfo<$ScheduleItemsTable, ScheduleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courseNameMeta =
      const VerificationMeta('courseName');
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
      'course_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('school'));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teacherMeta =
      const VerificationMeta('teacher');
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
      'teacher', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weekdayMeta =
      const VerificationMeta('weekday');
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
      'weekday', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recurrenceMeta =
      const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
      'recurrence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('weekly'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        courseName,
        type,
        location,
        teacher,
        weekday,
        recurrence,
        startTime,
        endTime,
        startDate,
        endDate,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_items';
  @override
  VerificationContext validateIntegrity(Insertable<ScheduleItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
          _courseNameMeta,
          courseName.isAcceptableOrUnknown(
              data['course_name']!, _courseNameMeta));
    } else if (isInserting) {
      context.missing(_courseNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('teacher')) {
      context.handle(_teacherMeta,
          teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta));
    }
    if (data.containsKey('weekday')) {
      context.handle(_weekdayMeta,
          weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta));
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('recurrence')) {
      context.handle(
          _recurrenceMeta,
          recurrence.isAcceptableOrUnknown(
              data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      courseName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      teacher: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher']),
      weekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekday'])!,
      recurrence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ScheduleItemsTable createAlias(String alias) {
    return $ScheduleItemsTable(attachedDatabase, alias);
  }
}

class ScheduleItem extends DataClass implements Insertable<ScheduleItem> {
  final int id;
  final String uuid;
  final String courseName;
  final String type;
  final String? location;
  final String? teacher;
  final int weekday;
  final String recurrence;
  final String startTime;
  final String endTime;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime updatedAt;
  final bool isDeleted;
  const ScheduleItem(
      {required this.id,
      required this.uuid,
      required this.courseName,
      required this.type,
      this.location,
      this.teacher,
      required this.weekday,
      required this.recurrence,
      required this.startTime,
      required this.endTime,
      this.startDate,
      this.endDate,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['course_name'] = Variable<String>(courseName);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    map['weekday'] = Variable<int>(weekday);
    map['recurrence'] = Variable<String>(recurrence);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ScheduleItemsCompanion toCompanion(bool nullToAbsent) {
    return ScheduleItemsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      courseName: Value(courseName),
      type: Value(type),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      teacher: teacher == null && nullToAbsent
          ? const Value.absent()
          : Value(teacher),
      weekday: Value(weekday),
      recurrence: Value(recurrence),
      startTime: Value(startTime),
      endTime: Value(endTime),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleItem(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      courseName: serializer.fromJson<String>(json['courseName']),
      type: serializer.fromJson<String>(json['type']),
      location: serializer.fromJson<String?>(json['location']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      weekday: serializer.fromJson<int>(json['weekday']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'courseName': serializer.toJson<String>(courseName),
      'type': serializer.toJson<String>(type),
      'location': serializer.toJson<String?>(location),
      'teacher': serializer.toJson<String?>(teacher),
      'weekday': serializer.toJson<int>(weekday),
      'recurrence': serializer.toJson<String>(recurrence),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ScheduleItem copyWith(
          {int? id,
          String? uuid,
          String? courseName,
          String? type,
          Value<String?> location = const Value.absent(),
          Value<String?> teacher = const Value.absent(),
          int? weekday,
          String? recurrence,
          String? startTime,
          String? endTime,
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          DateTime? updatedAt,
          bool? isDeleted}) =>
      ScheduleItem(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        courseName: courseName ?? this.courseName,
        type: type ?? this.type,
        location: location.present ? location.value : this.location,
        teacher: teacher.present ? teacher.value : this.teacher,
        weekday: weekday ?? this.weekday,
        recurrence: recurrence ?? this.recurrence,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  ScheduleItem copyWithCompanion(ScheduleItemsCompanion data) {
    return ScheduleItem(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      courseName:
          data.courseName.present ? data.courseName.value : this.courseName,
      type: data.type.present ? data.type.value : this.type,
      location: data.location.present ? data.location.value : this.location,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      recurrence:
          data.recurrence.present ? data.recurrence.value : this.recurrence,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleItem(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('courseName: $courseName, ')
          ..write('type: $type, ')
          ..write('location: $location, ')
          ..write('teacher: $teacher, ')
          ..write('weekday: $weekday, ')
          ..write('recurrence: $recurrence, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      courseName,
      type,
      location,
      teacher,
      weekday,
      recurrence,
      startTime,
      endTime,
      startDate,
      endDate,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleItem &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.courseName == this.courseName &&
          other.type == this.type &&
          other.location == this.location &&
          other.teacher == this.teacher &&
          other.weekday == this.weekday &&
          other.recurrence == this.recurrence &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class ScheduleItemsCompanion extends UpdateCompanion<ScheduleItem> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> courseName;
  final Value<String> type;
  final Value<String?> location;
  final Value<String?> teacher;
  final Value<int> weekday;
  final Value<String> recurrence;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const ScheduleItemsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.courseName = const Value.absent(),
    this.type = const Value.absent(),
    this.location = const Value.absent(),
    this.teacher = const Value.absent(),
    this.weekday = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ScheduleItemsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String courseName,
    this.type = const Value.absent(),
    this.location = const Value.absent(),
    this.teacher = const Value.absent(),
    required int weekday,
    this.recurrence = const Value.absent(),
    required String startTime,
    required String endTime,
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        courseName = Value(courseName),
        weekday = Value(weekday),
        startTime = Value(startTime),
        endTime = Value(endTime),
        updatedAt = Value(updatedAt);
  static Insertable<ScheduleItem> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? courseName,
    Expression<String>? type,
    Expression<String>? location,
    Expression<String>? teacher,
    Expression<int>? weekday,
    Expression<String>? recurrence,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (courseName != null) 'course_name': courseName,
      if (type != null) 'type': type,
      if (location != null) 'location': location,
      if (teacher != null) 'teacher': teacher,
      if (weekday != null) 'weekday': weekday,
      if (recurrence != null) 'recurrence': recurrence,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ScheduleItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? courseName,
      Value<String>? type,
      Value<String?>? location,
      Value<String?>? teacher,
      Value<int>? weekday,
      Value<String>? recurrence,
      Value<String>? startTime,
      Value<String>? endTime,
      Value<DateTime?>? startDate,
      Value<DateTime?>? endDate,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return ScheduleItemsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      courseName: courseName ?? this.courseName,
      type: type ?? this.type,
      location: location ?? this.location,
      teacher: teacher ?? this.teacher,
      weekday: weekday ?? this.weekday,
      recurrence: recurrence ?? this.recurrence,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleItemsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('courseName: $courseName, ')
          ..write('type: $type, ')
          ..write('location: $location, ')
          ..write('teacher: $teacher, ')
          ..write('weekday: $weekday, ')
          ..write('recurrence: $recurrence, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $WeeklyReportsTable extends WeeklyReports
    with TableInfo<$WeeklyReportsTable, WeeklyReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<DateTime> weekStart = GeneratedColumn<DateTime>(
      'week_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _weekEndMeta =
      const VerificationMeta('weekEnd');
  @override
  late final GeneratedColumn<DateTime> weekEnd = GeneratedColumn<DateTime>(
      'week_end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aiTextMeta = const VerificationMeta('aiText');
  @override
  late final GeneratedColumn<String> aiText = GeneratedColumn<String>(
      'ai_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _editedTextMeta =
      const VerificationMeta('editedText');
  @override
  late final GeneratedColumn<String> editedText = GeneratedColumn<String>(
      'edited_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _dailyCountMeta =
      const VerificationMeta('dailyCount');
  @override
  late final GeneratedColumn<int> dailyCount = GeneratedColumn<int>(
      'daily_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _readingCountMeta =
      const VerificationMeta('readingCount');
  @override
  late final GeneratedColumn<int> readingCount = GeneratedColumn<int>(
      'reading_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _readingMinutesMeta =
      const VerificationMeta('readingMinutes');
  @override
  late final GeneratedColumn<int> readingMinutes = GeneratedColumn<int>(
      'reading_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _extraClassCountMeta =
      const VerificationMeta('extraClassCount');
  @override
  late final GeneratedColumn<int> extraClassCount = GeneratedColumn<int>(
      'extra_class_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _activeDaysMeta =
      const VerificationMeta('activeDays');
  @override
  late final GeneratedColumn<int> activeDays = GeneratedColumn<int>(
      'active_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        weekStart,
        weekEnd,
        summary,
        aiText,
        editedText,
        status,
        dailyCount,
        readingCount,
        readingMinutes,
        extraClassCount,
        activeDays,
        generatedAt,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_reports';
  @override
  VerificationContext validateIntegrity(Insertable<WeeklyReport> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('week_end')) {
      context.handle(_weekEndMeta,
          weekEnd.isAcceptableOrUnknown(data['week_end']!, _weekEndMeta));
    } else if (isInserting) {
      context.missing(_weekEndMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('ai_text')) {
      context.handle(_aiTextMeta,
          aiText.isAcceptableOrUnknown(data['ai_text']!, _aiTextMeta));
    }
    if (data.containsKey('edited_text')) {
      context.handle(
          _editedTextMeta,
          editedText.isAcceptableOrUnknown(
              data['edited_text']!, _editedTextMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('daily_count')) {
      context.handle(
          _dailyCountMeta,
          dailyCount.isAcceptableOrUnknown(
              data['daily_count']!, _dailyCountMeta));
    }
    if (data.containsKey('reading_count')) {
      context.handle(
          _readingCountMeta,
          readingCount.isAcceptableOrUnknown(
              data['reading_count']!, _readingCountMeta));
    }
    if (data.containsKey('reading_minutes')) {
      context.handle(
          _readingMinutesMeta,
          readingMinutes.isAcceptableOrUnknown(
              data['reading_minutes']!, _readingMinutesMeta));
    }
    if (data.containsKey('extra_class_count')) {
      context.handle(
          _extraClassCountMeta,
          extraClassCount.isAcceptableOrUnknown(
              data['extra_class_count']!, _extraClassCountMeta));
    }
    if (data.containsKey('active_days')) {
      context.handle(
          _activeDaysMeta,
          activeDays.isAcceptableOrUnknown(
              data['active_days']!, _activeDaysMeta));
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyReport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}week_start'])!,
      weekEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}week_end'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      aiText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_text']),
      editedText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}edited_text']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      dailyCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_count'])!,
      readingCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reading_count'])!,
      readingMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reading_minutes'])!,
      extraClassCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}extra_class_count'])!,
      activeDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}active_days'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $WeeklyReportsTable createAlias(String alias) {
    return $WeeklyReportsTable(attachedDatabase, alias);
  }
}

class WeeklyReport extends DataClass implements Insertable<WeeklyReport> {
  final int id;
  final String uuid;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String summary;
  final String? aiText;
  final String? editedText;
  final String status;
  final int dailyCount;
  final int readingCount;
  final int readingMinutes;
  final int extraClassCount;
  final int activeDays;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const WeeklyReport(
      {required this.id,
      required this.uuid,
      required this.weekStart,
      required this.weekEnd,
      required this.summary,
      this.aiText,
      this.editedText,
      required this.status,
      required this.dailyCount,
      required this.readingCount,
      required this.readingMinutes,
      required this.extraClassCount,
      required this.activeDays,
      required this.generatedAt,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['week_start'] = Variable<DateTime>(weekStart);
    map['week_end'] = Variable<DateTime>(weekEnd);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || aiText != null) {
      map['ai_text'] = Variable<String>(aiText);
    }
    if (!nullToAbsent || editedText != null) {
      map['edited_text'] = Variable<String>(editedText);
    }
    map['status'] = Variable<String>(status);
    map['daily_count'] = Variable<int>(dailyCount);
    map['reading_count'] = Variable<int>(readingCount);
    map['reading_minutes'] = Variable<int>(readingMinutes);
    map['extra_class_count'] = Variable<int>(extraClassCount);
    map['active_days'] = Variable<int>(activeDays);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  WeeklyReportsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyReportsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      weekStart: Value(weekStart),
      weekEnd: Value(weekEnd),
      summary: Value(summary),
      aiText:
          aiText == null && nullToAbsent ? const Value.absent() : Value(aiText),
      editedText: editedText == null && nullToAbsent
          ? const Value.absent()
          : Value(editedText),
      status: Value(status),
      dailyCount: Value(dailyCount),
      readingCount: Value(readingCount),
      readingMinutes: Value(readingMinutes),
      extraClassCount: Value(extraClassCount),
      activeDays: Value(activeDays),
      generatedAt: Value(generatedAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory WeeklyReport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyReport(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      weekStart: serializer.fromJson<DateTime>(json['weekStart']),
      weekEnd: serializer.fromJson<DateTime>(json['weekEnd']),
      summary: serializer.fromJson<String>(json['summary']),
      aiText: serializer.fromJson<String?>(json['aiText']),
      editedText: serializer.fromJson<String?>(json['editedText']),
      status: serializer.fromJson<String>(json['status']),
      dailyCount: serializer.fromJson<int>(json['dailyCount']),
      readingCount: serializer.fromJson<int>(json['readingCount']),
      readingMinutes: serializer.fromJson<int>(json['readingMinutes']),
      extraClassCount: serializer.fromJson<int>(json['extraClassCount']),
      activeDays: serializer.fromJson<int>(json['activeDays']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'weekStart': serializer.toJson<DateTime>(weekStart),
      'weekEnd': serializer.toJson<DateTime>(weekEnd),
      'summary': serializer.toJson<String>(summary),
      'aiText': serializer.toJson<String?>(aiText),
      'editedText': serializer.toJson<String?>(editedText),
      'status': serializer.toJson<String>(status),
      'dailyCount': serializer.toJson<int>(dailyCount),
      'readingCount': serializer.toJson<int>(readingCount),
      'readingMinutes': serializer.toJson<int>(readingMinutes),
      'extraClassCount': serializer.toJson<int>(extraClassCount),
      'activeDays': serializer.toJson<int>(activeDays),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  WeeklyReport copyWith(
          {int? id,
          String? uuid,
          DateTime? weekStart,
          DateTime? weekEnd,
          String? summary,
          Value<String?> aiText = const Value.absent(),
          Value<String?> editedText = const Value.absent(),
          String? status,
          int? dailyCount,
          int? readingCount,
          int? readingMinutes,
          int? extraClassCount,
          int? activeDays,
          DateTime? generatedAt,
          DateTime? updatedAt,
          bool? isDeleted}) =>
      WeeklyReport(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        weekStart: weekStart ?? this.weekStart,
        weekEnd: weekEnd ?? this.weekEnd,
        summary: summary ?? this.summary,
        aiText: aiText.present ? aiText.value : this.aiText,
        editedText: editedText.present ? editedText.value : this.editedText,
        status: status ?? this.status,
        dailyCount: dailyCount ?? this.dailyCount,
        readingCount: readingCount ?? this.readingCount,
        readingMinutes: readingMinutes ?? this.readingMinutes,
        extraClassCount: extraClassCount ?? this.extraClassCount,
        activeDays: activeDays ?? this.activeDays,
        generatedAt: generatedAt ?? this.generatedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  WeeklyReport copyWithCompanion(WeeklyReportsCompanion data) {
    return WeeklyReport(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      weekEnd: data.weekEnd.present ? data.weekEnd.value : this.weekEnd,
      summary: data.summary.present ? data.summary.value : this.summary,
      aiText: data.aiText.present ? data.aiText.value : this.aiText,
      editedText:
          data.editedText.present ? data.editedText.value : this.editedText,
      status: data.status.present ? data.status.value : this.status,
      dailyCount:
          data.dailyCount.present ? data.dailyCount.value : this.dailyCount,
      readingCount: data.readingCount.present
          ? data.readingCount.value
          : this.readingCount,
      readingMinutes: data.readingMinutes.present
          ? data.readingMinutes.value
          : this.readingMinutes,
      extraClassCount: data.extraClassCount.present
          ? data.extraClassCount.value
          : this.extraClassCount,
      activeDays:
          data.activeDays.present ? data.activeDays.value : this.activeDays,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReport(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('summary: $summary, ')
          ..write('aiText: $aiText, ')
          ..write('editedText: $editedText, ')
          ..write('status: $status, ')
          ..write('dailyCount: $dailyCount, ')
          ..write('readingCount: $readingCount, ')
          ..write('readingMinutes: $readingMinutes, ')
          ..write('extraClassCount: $extraClassCount, ')
          ..write('activeDays: $activeDays, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      uuid,
      weekStart,
      weekEnd,
      summary,
      aiText,
      editedText,
      status,
      dailyCount,
      readingCount,
      readingMinutes,
      extraClassCount,
      activeDays,
      generatedAt,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyReport &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.weekStart == this.weekStart &&
          other.weekEnd == this.weekEnd &&
          other.summary == this.summary &&
          other.aiText == this.aiText &&
          other.editedText == this.editedText &&
          other.status == this.status &&
          other.dailyCount == this.dailyCount &&
          other.readingCount == this.readingCount &&
          other.readingMinutes == this.readingMinutes &&
          other.extraClassCount == this.extraClassCount &&
          other.activeDays == this.activeDays &&
          other.generatedAt == this.generatedAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class WeeklyReportsCompanion extends UpdateCompanion<WeeklyReport> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<DateTime> weekStart;
  final Value<DateTime> weekEnd;
  final Value<String> summary;
  final Value<String?> aiText;
  final Value<String?> editedText;
  final Value<String> status;
  final Value<int> dailyCount;
  final Value<int> readingCount;
  final Value<int> readingMinutes;
  final Value<int> extraClassCount;
  final Value<int> activeDays;
  final Value<DateTime> generatedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const WeeklyReportsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.weekEnd = const Value.absent(),
    this.summary = const Value.absent(),
    this.aiText = const Value.absent(),
    this.editedText = const Value.absent(),
    this.status = const Value.absent(),
    this.dailyCount = const Value.absent(),
    this.readingCount = const Value.absent(),
    this.readingMinutes = const Value.absent(),
    this.extraClassCount = const Value.absent(),
    this.activeDays = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  WeeklyReportsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required DateTime weekStart,
    required DateTime weekEnd,
    required String summary,
    this.aiText = const Value.absent(),
    this.editedText = const Value.absent(),
    this.status = const Value.absent(),
    this.dailyCount = const Value.absent(),
    this.readingCount = const Value.absent(),
    this.readingMinutes = const Value.absent(),
    this.extraClassCount = const Value.absent(),
    this.activeDays = const Value.absent(),
    required DateTime generatedAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        weekStart = Value(weekStart),
        weekEnd = Value(weekEnd),
        summary = Value(summary),
        generatedAt = Value(generatedAt),
        updatedAt = Value(updatedAt);
  static Insertable<WeeklyReport> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<DateTime>? weekStart,
    Expression<DateTime>? weekEnd,
    Expression<String>? summary,
    Expression<String>? aiText,
    Expression<String>? editedText,
    Expression<String>? status,
    Expression<int>? dailyCount,
    Expression<int>? readingCount,
    Expression<int>? readingMinutes,
    Expression<int>? extraClassCount,
    Expression<int>? activeDays,
    Expression<DateTime>? generatedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (weekStart != null) 'week_start': weekStart,
      if (weekEnd != null) 'week_end': weekEnd,
      if (summary != null) 'summary': summary,
      if (aiText != null) 'ai_text': aiText,
      if (editedText != null) 'edited_text': editedText,
      if (status != null) 'status': status,
      if (dailyCount != null) 'daily_count': dailyCount,
      if (readingCount != null) 'reading_count': readingCount,
      if (readingMinutes != null) 'reading_minutes': readingMinutes,
      if (extraClassCount != null) 'extra_class_count': extraClassCount,
      if (activeDays != null) 'active_days': activeDays,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  WeeklyReportsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<DateTime>? weekStart,
      Value<DateTime>? weekEnd,
      Value<String>? summary,
      Value<String?>? aiText,
      Value<String?>? editedText,
      Value<String>? status,
      Value<int>? dailyCount,
      Value<int>? readingCount,
      Value<int>? readingMinutes,
      Value<int>? extraClassCount,
      Value<int>? activeDays,
      Value<DateTime>? generatedAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return WeeklyReportsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      summary: summary ?? this.summary,
      aiText: aiText ?? this.aiText,
      editedText: editedText ?? this.editedText,
      status: status ?? this.status,
      dailyCount: dailyCount ?? this.dailyCount,
      readingCount: readingCount ?? this.readingCount,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      extraClassCount: extraClassCount ?? this.extraClassCount,
      activeDays: activeDays ?? this.activeDays,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<DateTime>(weekStart.value);
    }
    if (weekEnd.present) {
      map['week_end'] = Variable<DateTime>(weekEnd.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (aiText.present) {
      map['ai_text'] = Variable<String>(aiText.value);
    }
    if (editedText.present) {
      map['edited_text'] = Variable<String>(editedText.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dailyCount.present) {
      map['daily_count'] = Variable<int>(dailyCount.value);
    }
    if (readingCount.present) {
      map['reading_count'] = Variable<int>(readingCount.value);
    }
    if (readingMinutes.present) {
      map['reading_minutes'] = Variable<int>(readingMinutes.value);
    }
    if (extraClassCount.present) {
      map['extra_class_count'] = Variable<int>(extraClassCount.value);
    }
    if (activeDays.present) {
      map['active_days'] = Variable<int>(activeDays.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReportsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('summary: $summary, ')
          ..write('aiText: $aiText, ')
          ..write('editedText: $editedText, ')
          ..write('status: $status, ')
          ..write('dailyCount: $dailyCount, ')
          ..write('readingCount: $readingCount, ')
          ..write('readingMinutes: $readingMinutes, ')
          ..write('extraClassCount: $extraClassCount, ')
          ..write('activeDays: $activeDays, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $ChildTable extends Child with TableInfo<$ChildTable, ChildData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
      'birth_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, uuid, name, birthDate, avatarPath, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'child';
  @override
  VerificationContext validateIntegrity(Insertable<ChildData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChildData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date']),
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ChildTable createAlias(String alias) {
    return $ChildTable(attachedDatabase, alias);
  }
}

class ChildData extends DataClass implements Insertable<ChildData> {
  final int id;
  final String uuid;
  final String name;
  final DateTime? birthDate;
  final String? avatarPath;
  final DateTime updatedAt;
  final bool isDeleted;
  const ChildData(
      {required this.id,
      required this.uuid,
      required this.name,
      this.birthDate,
      this.avatarPath,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ChildCompanion toCompanion(bool nullToAbsent) {
    return ChildCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory ChildData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ChildData copyWith(
          {int? id,
          String? uuid,
          String? name,
          Value<DateTime?> birthDate = const Value.absent(),
          Value<String?> avatarPath = const Value.absent(),
          DateTime? updatedAt,
          bool? isDeleted}) =>
      ChildData(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        birthDate: birthDate.present ? birthDate.value : this.birthDate,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  ChildData copyWithCompanion(ChildCompanion data) {
    return ChildData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, name, birthDate, avatarPath, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.avatarPath == this.avatarPath &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class ChildCompanion extends UpdateCompanion<ChildData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<DateTime?> birthDate;
  final Value<String?> avatarPath;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const ChildCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ChildCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String name,
    this.birthDate = const Value.absent(),
    this.avatarPath = const Value.absent(),
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<ChildData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<DateTime>? birthDate,
    Expression<String>? avatarPath,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ChildCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? name,
      Value<DateTime?>? birthDate,
      Value<String?>? avatarPath,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted}) {
    return ChildCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      avatarPath: avatarPath ?? this.avatarPath,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SeriesTable series = $SeriesTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $ReadingLogsTable readingLogs = $ReadingLogsTable(this);
  late final $DailyRecordsTable dailyRecords = $DailyRecordsTable(this);
  late final $ScheduleItemsTable scheduleItems = $ScheduleItemsTable(this);
  late final $WeeklyReportsTable weeklyReports = $WeeklyReportsTable(this);
  late final $ChildTable child = $ChildTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        series,
        books,
        readingLogs,
        dailyRecords,
        scheduleItems,
        weeklyReports,
        child
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('series',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('books', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('books',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reading_logs', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$SeriesTableCreateCompanionBuilder = SeriesCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  Value<int> totalVolumes,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$SeriesTableUpdateCompanionBuilder = SeriesCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<int> totalVolumes,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$SeriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SeriesTable,
    SeriesData,
    $$SeriesTableFilterComposer,
    $$SeriesTableOrderingComposer,
    $$SeriesTableCreateCompanionBuilder,
    $$SeriesTableUpdateCompanionBuilder> {
  $$SeriesTableTableManager(_$AppDatabase db, $SeriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SeriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SeriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> totalVolumes = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              SeriesCompanion(
            id: id,
            uuid: uuid,
            name: name,
            totalVolumes: totalVolumes,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            Value<int> totalVolumes = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              SeriesCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            totalVolumes: totalVolumes,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$SeriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SeriesTable> {
  $$SeriesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalVolumes => $state.composableBuilder(
      column: $state.table.totalVolumes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter booksRefs(
      ComposableFilter Function($$BooksTableFilterComposer f) f) {
    final $$BooksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.books,
        getReferencedColumn: (t) => t.seriesId,
        builder: (joinBuilder, parentComposers) => $$BooksTableFilterComposer(
            ComposerState(
                $state.db, $state.db.books, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$SeriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SeriesTable> {
  $$SeriesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalVolumes => $state.composableBuilder(
      column: $state.table.totalVolumes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  required String uuid,
  required String title,
  Value<String?> author,
  Value<String?> cover,
  Value<String?> isbn,
  Value<String> status,
  Value<int?> totalPages,
  Value<int?> totalChapters,
  Value<int?> seriesId,
  Value<int?> seriesIndex,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> title,
  Value<String?> author,
  Value<String?> cover,
  Value<String?> isbn,
  Value<String> status,
  Value<int?> totalPages,
  Value<int?> totalChapters,
  Value<int?> seriesId,
  Value<int?> seriesIndex,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$BooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BooksTable,
    Book,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder> {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BooksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BooksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> cover = const Value.absent(),
            Value<String?> isbn = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> totalPages = const Value.absent(),
            Value<int?> totalChapters = const Value.absent(),
            Value<int?> seriesId = const Value.absent(),
            Value<int?> seriesIndex = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              BooksCompanion(
            id: id,
            uuid: uuid,
            title: title,
            author: author,
            cover: cover,
            isbn: isbn,
            status: status,
            totalPages: totalPages,
            totalChapters: totalChapters,
            seriesId: seriesId,
            seriesIndex: seriesIndex,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String title,
            Value<String?> author = const Value.absent(),
            Value<String?> cover = const Value.absent(),
            Value<String?> isbn = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> totalPages = const Value.absent(),
            Value<int?> totalChapters = const Value.absent(),
            Value<int?> seriesId = const Value.absent(),
            Value<int?> seriesIndex = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              BooksCompanion.insert(
            id: id,
            uuid: uuid,
            title: title,
            author: author,
            cover: cover,
            isbn: isbn,
            status: status,
            totalPages: totalPages,
            totalChapters: totalChapters,
            seriesId: seriesId,
            seriesIndex: seriesIndex,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$BooksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get author => $state.composableBuilder(
      column: $state.table.author,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cover => $state.composableBuilder(
      column: $state.table.cover,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get isbn => $state.composableBuilder(
      column: $state.table.isbn,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalPages => $state.composableBuilder(
      column: $state.table.totalPages,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalChapters => $state.composableBuilder(
      column: $state.table.totalChapters,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get seriesIndex => $state.composableBuilder(
      column: $state.table.seriesIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$SeriesTableFilterComposer get seriesId {
    final $$SeriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $state.db.series,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$SeriesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.series, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter readingLogsRefs(
      ComposableFilter Function($$ReadingLogsTableFilterComposer f) f) {
    final $$ReadingLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.readingLogs,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder, parentComposers) =>
            $$ReadingLogsTableFilterComposer(ComposerState($state.db,
                $state.db.readingLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get author => $state.composableBuilder(
      column: $state.table.author,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cover => $state.composableBuilder(
      column: $state.table.cover,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get isbn => $state.composableBuilder(
      column: $state.table.isbn,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalPages => $state.composableBuilder(
      column: $state.table.totalPages,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalChapters => $state.composableBuilder(
      column: $state.table.totalChapters,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get seriesIndex => $state.composableBuilder(
      column: $state.table.seriesIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$SeriesTableOrderingComposer get seriesId {
    final $$SeriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $state.db.series,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SeriesTableOrderingComposer(ComposerState(
                $state.db, $state.db.series, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$ReadingLogsTableCreateCompanionBuilder = ReadingLogsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required int bookId,
  required DateTime readDate,
  Value<String?> chapter,
  Value<int?> chapterIndex,
  Value<int?> pageFrom,
  Value<int?> pageTo,
  Value<int> durationMinutes,
  Value<String?> mood,
  Value<String?> note,
  Value<String> source,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$ReadingLogsTableUpdateCompanionBuilder = ReadingLogsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> bookId,
  Value<DateTime> readDate,
  Value<String?> chapter,
  Value<int?> chapterIndex,
  Value<int?> pageFrom,
  Value<int?> pageTo,
  Value<int> durationMinutes,
  Value<String?> mood,
  Value<String?> note,
  Value<String> source,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$ReadingLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingLogsTable,
    ReadingLog,
    $$ReadingLogsTableFilterComposer,
    $$ReadingLogsTableOrderingComposer,
    $$ReadingLogsTableCreateCompanionBuilder,
    $$ReadingLogsTableUpdateCompanionBuilder> {
  $$ReadingLogsTableTableManager(_$AppDatabase db, $ReadingLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ReadingLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ReadingLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<int> bookId = const Value.absent(),
            Value<DateTime> readDate = const Value.absent(),
            Value<String?> chapter = const Value.absent(),
            Value<int?> chapterIndex = const Value.absent(),
            Value<int?> pageFrom = const Value.absent(),
            Value<int?> pageTo = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ReadingLogsCompanion(
            id: id,
            uuid: uuid,
            bookId: bookId,
            readDate: readDate,
            chapter: chapter,
            chapterIndex: chapterIndex,
            pageFrom: pageFrom,
            pageTo: pageTo,
            durationMinutes: durationMinutes,
            mood: mood,
            note: note,
            source: source,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required int bookId,
            required DateTime readDate,
            Value<String?> chapter = const Value.absent(),
            Value<int?> chapterIndex = const Value.absent(),
            Value<int?> pageFrom = const Value.absent(),
            Value<int?> pageTo = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> source = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ReadingLogsCompanion.insert(
            id: id,
            uuid: uuid,
            bookId: bookId,
            readDate: readDate,
            chapter: chapter,
            chapterIndex: chapterIndex,
            pageFrom: pageFrom,
            pageTo: pageTo,
            durationMinutes: durationMinutes,
            mood: mood,
            note: note,
            source: source,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$ReadingLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ReadingLogsTable> {
  $$ReadingLogsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get readDate => $state.composableBuilder(
      column: $state.table.readDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get chapter => $state.composableBuilder(
      column: $state.table.chapter,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get chapterIndex => $state.composableBuilder(
      column: $state.table.chapterIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get pageFrom => $state.composableBuilder(
      column: $state.table.pageFrom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get pageTo => $state.composableBuilder(
      column: $state.table.pageTo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mood => $state.composableBuilder(
      column: $state.table.mood,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $state.db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BooksTableFilterComposer(
            ComposerState(
                $state.db, $state.db.books, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ReadingLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ReadingLogsTable> {
  $$ReadingLogsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get readDate => $state.composableBuilder(
      column: $state.table.readDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get chapter => $state.composableBuilder(
      column: $state.table.chapter,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get chapterIndex => $state.composableBuilder(
      column: $state.table.chapterIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get pageFrom => $state.composableBuilder(
      column: $state.table.pageFrom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get pageTo => $state.composableBuilder(
      column: $state.table.pageTo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mood => $state.composableBuilder(
      column: $state.table.mood,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $state.db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BooksTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.books, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$DailyRecordsTableCreateCompanionBuilder = DailyRecordsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required String title,
  Value<String?> note,
  Value<String?> tags,
  Value<String?> imagePaths,
  Value<String?> category,
  Value<String?> mood,
  Value<String> source,
  required DateTime eventDate,
  Value<int?> durationMinutes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$DailyRecordsTableUpdateCompanionBuilder = DailyRecordsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> title,
  Value<String?> note,
  Value<String?> tags,
  Value<String?> imagePaths,
  Value<String?> category,
  Value<String?> mood,
  Value<String> source,
  Value<DateTime> eventDate,
  Value<int?> durationMinutes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$DailyRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyRecordsTable,
    DailyRecord,
    $$DailyRecordsTableFilterComposer,
    $$DailyRecordsTableOrderingComposer,
    $$DailyRecordsTableCreateCompanionBuilder,
    $$DailyRecordsTableUpdateCompanionBuilder> {
  $$DailyRecordsTableTableManager(_$AppDatabase db, $DailyRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DailyRecordsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DailyRecordsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> imagePaths = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> eventDate = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              DailyRecordsCompanion(
            id: id,
            uuid: uuid,
            title: title,
            note: note,
            tags: tags,
            imagePaths: imagePaths,
            category: category,
            mood: mood,
            source: source,
            eventDate: eventDate,
            durationMinutes: durationMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String title,
            Value<String?> note = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> imagePaths = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<String> source = const Value.absent(),
            required DateTime eventDate,
            Value<int?> durationMinutes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              DailyRecordsCompanion.insert(
            id: id,
            uuid: uuid,
            title: title,
            note: note,
            tags: tags,
            imagePaths: imagePaths,
            category: category,
            mood: mood,
            source: source,
            eventDate: eventDate,
            durationMinutes: durationMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$DailyRecordsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tags => $state.composableBuilder(
      column: $state.table.tags,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imagePaths => $state.composableBuilder(
      column: $state.table.imagePaths,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mood => $state.composableBuilder(
      column: $state.table.mood,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get eventDate => $state.composableBuilder(
      column: $state.table.eventDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DailyRecordsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tags => $state.composableBuilder(
      column: $state.table.tags,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imagePaths => $state.composableBuilder(
      column: $state.table.imagePaths,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mood => $state.composableBuilder(
      column: $state.table.mood,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get eventDate => $state.composableBuilder(
      column: $state.table.eventDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ScheduleItemsTableCreateCompanionBuilder = ScheduleItemsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required String courseName,
  Value<String> type,
  Value<String?> location,
  Value<String?> teacher,
  required int weekday,
  Value<String> recurrence,
  required String startTime,
  required String endTime,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$ScheduleItemsTableUpdateCompanionBuilder = ScheduleItemsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> courseName,
  Value<String> type,
  Value<String?> location,
  Value<String?> teacher,
  Value<int> weekday,
  Value<String> recurrence,
  Value<String> startTime,
  Value<String> endTime,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$ScheduleItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduleItemsTable,
    ScheduleItem,
    $$ScheduleItemsTableFilterComposer,
    $$ScheduleItemsTableOrderingComposer,
    $$ScheduleItemsTableCreateCompanionBuilder,
    $$ScheduleItemsTableUpdateCompanionBuilder> {
  $$ScheduleItemsTableTableManager(_$AppDatabase db, $ScheduleItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ScheduleItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ScheduleItemsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> courseName = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> teacher = const Value.absent(),
            Value<int> weekday = const Value.absent(),
            Value<String> recurrence = const Value.absent(),
            Value<String> startTime = const Value.absent(),
            Value<String> endTime = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ScheduleItemsCompanion(
            id: id,
            uuid: uuid,
            courseName: courseName,
            type: type,
            location: location,
            teacher: teacher,
            weekday: weekday,
            recurrence: recurrence,
            startTime: startTime,
            endTime: endTime,
            startDate: startDate,
            endDate: endDate,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String courseName,
            Value<String> type = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> teacher = const Value.absent(),
            required int weekday,
            Value<String> recurrence = const Value.absent(),
            required String startTime,
            required String endTime,
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ScheduleItemsCompanion.insert(
            id: id,
            uuid: uuid,
            courseName: courseName,
            type: type,
            location: location,
            teacher: teacher,
            weekday: weekday,
            recurrence: recurrence,
            startTime: startTime,
            endTime: endTime,
            startDate: startDate,
            endDate: endDate,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$ScheduleItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ScheduleItemsTable> {
  $$ScheduleItemsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get courseName => $state.composableBuilder(
      column: $state.table.courseName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get location => $state.composableBuilder(
      column: $state.table.location,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teacher => $state.composableBuilder(
      column: $state.table.teacher,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get weekday => $state.composableBuilder(
      column: $state.table.weekday,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recurrence => $state.composableBuilder(
      column: $state.table.recurrence,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get startTime => $state.composableBuilder(
      column: $state.table.startTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get endTime => $state.composableBuilder(
      column: $state.table.endTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ScheduleItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ScheduleItemsTable> {
  $$ScheduleItemsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get courseName => $state.composableBuilder(
      column: $state.table.courseName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get location => $state.composableBuilder(
      column: $state.table.location,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teacher => $state.composableBuilder(
      column: $state.table.teacher,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get weekday => $state.composableBuilder(
      column: $state.table.weekday,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recurrence => $state.composableBuilder(
      column: $state.table.recurrence,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get startTime => $state.composableBuilder(
      column: $state.table.startTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get endTime => $state.composableBuilder(
      column: $state.table.endTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$WeeklyReportsTableCreateCompanionBuilder = WeeklyReportsCompanion
    Function({
  Value<int> id,
  required String uuid,
  required DateTime weekStart,
  required DateTime weekEnd,
  required String summary,
  Value<String?> aiText,
  Value<String?> editedText,
  Value<String> status,
  Value<int> dailyCount,
  Value<int> readingCount,
  Value<int> readingMinutes,
  Value<int> extraClassCount,
  Value<int> activeDays,
  required DateTime generatedAt,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$WeeklyReportsTableUpdateCompanionBuilder = WeeklyReportsCompanion
    Function({
  Value<int> id,
  Value<String> uuid,
  Value<DateTime> weekStart,
  Value<DateTime> weekEnd,
  Value<String> summary,
  Value<String?> aiText,
  Value<String?> editedText,
  Value<String> status,
  Value<int> dailyCount,
  Value<int> readingCount,
  Value<int> readingMinutes,
  Value<int> extraClassCount,
  Value<int> activeDays,
  Value<DateTime> generatedAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$WeeklyReportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeeklyReportsTable,
    WeeklyReport,
    $$WeeklyReportsTableFilterComposer,
    $$WeeklyReportsTableOrderingComposer,
    $$WeeklyReportsTableCreateCompanionBuilder,
    $$WeeklyReportsTableUpdateCompanionBuilder> {
  $$WeeklyReportsTableTableManager(_$AppDatabase db, $WeeklyReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$WeeklyReportsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$WeeklyReportsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<DateTime> weekStart = const Value.absent(),
            Value<DateTime> weekEnd = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String?> aiText = const Value.absent(),
            Value<String?> editedText = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> dailyCount = const Value.absent(),
            Value<int> readingCount = const Value.absent(),
            Value<int> readingMinutes = const Value.absent(),
            Value<int> extraClassCount = const Value.absent(),
            Value<int> activeDays = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              WeeklyReportsCompanion(
            id: id,
            uuid: uuid,
            weekStart: weekStart,
            weekEnd: weekEnd,
            summary: summary,
            aiText: aiText,
            editedText: editedText,
            status: status,
            dailyCount: dailyCount,
            readingCount: readingCount,
            readingMinutes: readingMinutes,
            extraClassCount: extraClassCount,
            activeDays: activeDays,
            generatedAt: generatedAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required DateTime weekStart,
            required DateTime weekEnd,
            required String summary,
            Value<String?> aiText = const Value.absent(),
            Value<String?> editedText = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> dailyCount = const Value.absent(),
            Value<int> readingCount = const Value.absent(),
            Value<int> readingMinutes = const Value.absent(),
            Value<int> extraClassCount = const Value.absent(),
            Value<int> activeDays = const Value.absent(),
            required DateTime generatedAt,
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              WeeklyReportsCompanion.insert(
            id: id,
            uuid: uuid,
            weekStart: weekStart,
            weekEnd: weekEnd,
            summary: summary,
            aiText: aiText,
            editedText: editedText,
            status: status,
            dailyCount: dailyCount,
            readingCount: readingCount,
            readingMinutes: readingMinutes,
            extraClassCount: extraClassCount,
            activeDays: activeDays,
            generatedAt: generatedAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$WeeklyReportsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $WeeklyReportsTable> {
  $$WeeklyReportsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get weekStart => $state.composableBuilder(
      column: $state.table.weekStart,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get weekEnd => $state.composableBuilder(
      column: $state.table.weekEnd,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get summary => $state.composableBuilder(
      column: $state.table.summary,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get aiText => $state.composableBuilder(
      column: $state.table.aiText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get editedText => $state.composableBuilder(
      column: $state.table.editedText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get dailyCount => $state.composableBuilder(
      column: $state.table.dailyCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get readingCount => $state.composableBuilder(
      column: $state.table.readingCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get readingMinutes => $state.composableBuilder(
      column: $state.table.readingMinutes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get extraClassCount => $state.composableBuilder(
      column: $state.table.extraClassCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get activeDays => $state.composableBuilder(
      column: $state.table.activeDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get generatedAt => $state.composableBuilder(
      column: $state.table.generatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$WeeklyReportsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $WeeklyReportsTable> {
  $$WeeklyReportsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get weekStart => $state.composableBuilder(
      column: $state.table.weekStart,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get weekEnd => $state.composableBuilder(
      column: $state.table.weekEnd,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get summary => $state.composableBuilder(
      column: $state.table.summary,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get aiText => $state.composableBuilder(
      column: $state.table.aiText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get editedText => $state.composableBuilder(
      column: $state.table.editedText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get dailyCount => $state.composableBuilder(
      column: $state.table.dailyCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get readingCount => $state.composableBuilder(
      column: $state.table.readingCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get readingMinutes => $state.composableBuilder(
      column: $state.table.readingMinutes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get extraClassCount => $state.composableBuilder(
      column: $state.table.extraClassCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get activeDays => $state.composableBuilder(
      column: $state.table.activeDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get generatedAt => $state.composableBuilder(
      column: $state.table.generatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ChildTableCreateCompanionBuilder = ChildCompanion Function({
  Value<int> id,
  required String uuid,
  required String name,
  Value<DateTime?> birthDate,
  Value<String?> avatarPath,
  required DateTime updatedAt,
  Value<bool> isDeleted,
});
typedef $$ChildTableUpdateCompanionBuilder = ChildCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<DateTime?> birthDate,
  Value<String?> avatarPath,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
});

class $$ChildTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChildTable,
    ChildData,
    $$ChildTableFilterComposer,
    $$ChildTableOrderingComposer,
    $$ChildTableCreateCompanionBuilder,
    $$ChildTableUpdateCompanionBuilder> {
  $$ChildTableTableManager(_$AppDatabase db, $ChildTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ChildTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ChildTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime?> birthDate = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ChildCompanion(
            id: id,
            uuid: uuid,
            name: name,
            birthDate: birthDate,
            avatarPath: avatarPath,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String name,
            Value<DateTime?> birthDate = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ChildCompanion.insert(
            id: id,
            uuid: uuid,
            name: name,
            birthDate: birthDate,
            avatarPath: avatarPath,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
          ),
        ));
}

class $$ChildTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ChildTable> {
  $$ChildTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get birthDate => $state.composableBuilder(
      column: $state.table.birthDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get avatarPath => $state.composableBuilder(
      column: $state.table.avatarPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ChildTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ChildTable> {
  $$ChildTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uuid => $state.composableBuilder(
      column: $state.table.uuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get birthDate => $state.composableBuilder(
      column: $state.table.birthDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get avatarPath => $state.composableBuilder(
      column: $state.table.avatarPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SeriesTableTableManager get series =>
      $$SeriesTableTableManager(_db, _db.series);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ReadingLogsTableTableManager get readingLogs =>
      $$ReadingLogsTableTableManager(_db, _db.readingLogs);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db, _db.dailyRecords);
  $$ScheduleItemsTableTableManager get scheduleItems =>
      $$ScheduleItemsTableTableManager(_db, _db.scheduleItems);
  $$WeeklyReportsTableTableManager get weeklyReports =>
      $$WeeklyReportsTableTableManager(_db, _db.weeklyReports);
  $$ChildTableTableManager get child =>
      $$ChildTableTableManager(_db, _db.child);
}
