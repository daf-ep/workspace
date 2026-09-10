// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RuleFilesTable extends RuleFiles with TableInfo<$RuleFilesTable, RuleFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, type, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_files';
  @override
  VerificationContext validateIntegrity(Insertable<RuleFile> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name, type};
  @override
  RuleFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleFile(
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  $RuleFilesTable createAlias(String alias) {
    return $RuleFilesTable(attachedDatabase, alias);
  }
}

class RuleFile extends DataClass implements Insertable<RuleFile> {
  /// The file's name, without its `.md` extension.
  final String name;

  /// The corpus directory this file ships under, or `rules` for the entry
  /// point.
  final String type;

  /// The file's full text.
  final String content;
  const RuleFile({required this.name, required this.type, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['content'] = Variable<String>(content);
    return map;
  }

  RuleFilesCompanion toCompanion(bool nullToAbsent) {
    return RuleFilesCompanion(name: Value(name), type: Value(type), content: Value(content));
  }

  factory RuleFile.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleFile(
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String>(content),
    };
  }

  RuleFile copyWith({String? name, String? type, String? content}) =>
      RuleFile(name: name ?? this.name, type: type ?? this.type, content: content ?? this.content);
  RuleFile copyWithCompanion(RuleFilesCompanion data) {
    return RuleFile(
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleFile(')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, type, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleFile && other.name == this.name && other.type == this.type && other.content == this.content);
}

class RuleFilesCompanion extends UpdateCompanion<RuleFile> {
  final Value<String> name;
  final Value<String> type;
  final Value<String> content;
  final Value<int> rowid;
  const RuleFilesCompanion({
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleFilesCompanion.insert({
    required String name,
    required String type,
    required String content,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       content = Value(content);
  static Insertable<RuleFile> custom({
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleFilesCompanion copyWith({Value<String>? name, Value<String>? type, Value<String>? content, Value<int>? rowid}) {
    return RuleFilesCompanion(
      name: name ?? this.name,
      type: type ?? this.type,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleFilesCompanion(')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteSyncStateTable extends RemoteSyncState with TableInfo<$RemoteSyncStateTable, RemoteSyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta('lastCheckedAt');
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt = GeneratedColumn<DateTime>(
    'last_checked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastCheckedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<RemoteSyncStateData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(data['last_checked_at']!, _lastCheckedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lastCheckedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteSyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteSyncStateData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      )!,
    );
  }

  @override
  $RemoteSyncStateTable createAlias(String alias) {
    return $RemoteSyncStateTable(attachedDatabase, alias);
  }
}

class RemoteSyncStateData extends DataClass implements Insertable<RemoteSyncStateData> {
  /// Always `0`: this table never carries more than one row.
  final int id;

  /// When the last check happened, whether or not it found the corpus
  /// reachable.
  final DateTime lastCheckedAt;
  const RemoteSyncStateData({required this.id, required this.lastCheckedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    return map;
  }

  RemoteSyncStateCompanion toCompanion(bool nullToAbsent) {
    return RemoteSyncStateCompanion(id: Value(id), lastCheckedAt: Value(lastCheckedAt));
  }

  factory RemoteSyncStateData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteSyncStateData(
      id: serializer.fromJson<int>(json['id']),
      lastCheckedAt: serializer.fromJson<DateTime>(json['lastCheckedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastCheckedAt': serializer.toJson<DateTime>(lastCheckedAt),
    };
  }

  RemoteSyncStateData copyWith({int? id, DateTime? lastCheckedAt}) =>
      RemoteSyncStateData(id: id ?? this.id, lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt);
  RemoteSyncStateData copyWithCompanion(RemoteSyncStateCompanion data) {
    return RemoteSyncStateData(
      id: data.id.present ? data.id.value : this.id,
      lastCheckedAt: data.lastCheckedAt.present ? data.lastCheckedAt.value : this.lastCheckedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteSyncStateData(')
          ..write('id: $id, ')
          ..write('lastCheckedAt: $lastCheckedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastCheckedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteSyncStateData && other.id == this.id && other.lastCheckedAt == this.lastCheckedAt);
}

class RemoteSyncStateCompanion extends UpdateCompanion<RemoteSyncStateData> {
  final Value<int> id;
  final Value<DateTime> lastCheckedAt;
  const RemoteSyncStateCompanion({this.id = const Value.absent(), this.lastCheckedAt = const Value.absent()});
  RemoteSyncStateCompanion.insert({this.id = const Value.absent(), required DateTime lastCheckedAt})
    : lastCheckedAt = Value(lastCheckedAt);
  static Insertable<RemoteSyncStateData> custom({Expression<int>? id, Expression<DateTime>? lastCheckedAt}) {
    return RawValuesInsertable({if (id != null) 'id': id, if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt});
  }

  RemoteSyncStateCompanion copyWith({Value<int>? id, Value<DateTime>? lastCheckedAt}) {
    return RemoteSyncStateCompanion(id: id ?? this.id, lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteSyncStateCompanion(')
          ..write('id: $id, ')
          ..write('lastCheckedAt: $lastCheckedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$RulesDatabase extends GeneratedDatabase {
  _$RulesDatabase(QueryExecutor e) : super(e);
  $RulesDatabaseManager get managers => $RulesDatabaseManager(this);
  late final $RuleFilesTable ruleFiles = $RuleFilesTable(this);
  late final $RemoteSyncStateTable remoteSyncState = $RemoteSyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [ruleFiles, remoteSyncState];
}

typedef $$RuleFilesTableCreateCompanionBuilder =
    RuleFilesCompanion Function({
      required String name,
      required String type,
      required String content,
      Value<int> rowid,
    });
typedef $$RuleFilesTableUpdateCompanionBuilder =
    RuleFilesCompanion Function({Value<String> name, Value<String> type, Value<String> content, Value<int> rowid});

class $$RuleFilesTableFilterComposer extends Composer<_$RulesDatabase, $RuleFilesTable> {
  $$RuleFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));
}

class $$RuleFilesTableOrderingComposer extends Composer<_$RulesDatabase, $RuleFilesTable> {
  $$RuleFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$RuleFilesTableAnnotationComposer extends Composer<_$RulesDatabase, $RuleFilesTable> {
  $$RuleFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content => $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$RuleFilesTableTableManager
    extends
        RootTableManager<
          _$RulesDatabase,
          $RuleFilesTable,
          RuleFile,
          $$RuleFilesTableFilterComposer,
          $$RuleFilesTableOrderingComposer,
          $$RuleFilesTableAnnotationComposer,
          $$RuleFilesTableCreateCompanionBuilder,
          $$RuleFilesTableUpdateCompanionBuilder,
          (RuleFile, BaseReferences<_$RulesDatabase, $RuleFilesTable, RuleFile>),
          RuleFile,
          PrefetchHooks Function()
        > {
  $$RuleFilesTableTableManager(_$RulesDatabase db, $RuleFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RuleFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RuleFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RuleFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleFilesCompanion(name: name, type: type, content: content, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String type,
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => RuleFilesCompanion.insert(name: name, type: type, content: content, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RuleFilesTable, RuleFile>(table),
                  BaseReferences<_$RulesDatabase, $RuleFilesTable, RuleFile>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$RulesDatabase,
      $RuleFilesTable,
      RuleFile,
      $$RuleFilesTableFilterComposer,
      $$RuleFilesTableOrderingComposer,
      $$RuleFilesTableAnnotationComposer,
      $$RuleFilesTableCreateCompanionBuilder,
      $$RuleFilesTableUpdateCompanionBuilder,
      (RuleFile, BaseReferences<_$RulesDatabase, $RuleFilesTable, RuleFile>),
      RuleFile,
      PrefetchHooks Function()
    >;
typedef $$RemoteSyncStateTableCreateCompanionBuilder =
    RemoteSyncStateCompanion Function({Value<int> id, required DateTime lastCheckedAt});
typedef $$RemoteSyncStateTableUpdateCompanionBuilder =
    RemoteSyncStateCompanion Function({Value<int> id, Value<DateTime> lastCheckedAt});

class $$RemoteSyncStateTableFilterComposer extends Composer<_$RulesDatabase, $RemoteSyncStateTable> {
  $$RemoteSyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCheckedAt =>
      $composableBuilder(column: $table.lastCheckedAt, builder: (column) => ColumnFilters(column));
}

class $$RemoteSyncStateTableOrderingComposer extends Composer<_$RulesDatabase, $RemoteSyncStateTable> {
  $$RemoteSyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCheckedAt =>
      $composableBuilder(column: $table.lastCheckedAt, builder: (column) => ColumnOrderings(column));
}

class $$RemoteSyncStateTableAnnotationComposer extends Composer<_$RulesDatabase, $RemoteSyncStateTable> {
  $$RemoteSyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckedAt =>
      $composableBuilder(column: $table.lastCheckedAt, builder: (column) => column);
}

class $$RemoteSyncStateTableTableManager
    extends
        RootTableManager<
          _$RulesDatabase,
          $RemoteSyncStateTable,
          RemoteSyncStateData,
          $$RemoteSyncStateTableFilterComposer,
          $$RemoteSyncStateTableOrderingComposer,
          $$RemoteSyncStateTableAnnotationComposer,
          $$RemoteSyncStateTableCreateCompanionBuilder,
          $$RemoteSyncStateTableUpdateCompanionBuilder,
          (RemoteSyncStateData, BaseReferences<_$RulesDatabase, $RemoteSyncStateTable, RemoteSyncStateData>),
          RemoteSyncStateData,
          PrefetchHooks Function()
        > {
  $$RemoteSyncStateTableTableManager(_$RulesDatabase db, $RemoteSyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RemoteSyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RemoteSyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RemoteSyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({Value<int> id = const Value.absent(), Value<DateTime> lastCheckedAt = const Value.absent()}) =>
                  RemoteSyncStateCompanion(id: id, lastCheckedAt: lastCheckedAt),
          createCompanionCallback: ({Value<int> id = const Value.absent(), required DateTime lastCheckedAt}) =>
              RemoteSyncStateCompanion.insert(id: id, lastCheckedAt: lastCheckedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemoteSyncStateTable, RemoteSyncStateData>(table),
                  BaseReferences<_$RulesDatabase, $RemoteSyncStateTable, RemoteSyncStateData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteSyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$RulesDatabase,
      $RemoteSyncStateTable,
      RemoteSyncStateData,
      $$RemoteSyncStateTableFilterComposer,
      $$RemoteSyncStateTableOrderingComposer,
      $$RemoteSyncStateTableAnnotationComposer,
      $$RemoteSyncStateTableCreateCompanionBuilder,
      $$RemoteSyncStateTableUpdateCompanionBuilder,
      (RemoteSyncStateData, BaseReferences<_$RulesDatabase, $RemoteSyncStateTable, RemoteSyncStateData>),
      RemoteSyncStateData,
      PrefetchHooks Function()
    >;

class $RulesDatabaseManager {
  final _$RulesDatabase _db;
  $RulesDatabaseManager(this._db);
  $$RuleFilesTableTableManager get ruleFiles => $$RuleFilesTableTableManager(_db, _db.ruleFiles);
  $$RemoteSyncStateTableTableManager get remoteSyncState =>
      $$RemoteSyncStateTableTableManager(_db, _db.remoteSyncState);
}
