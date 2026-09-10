// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules_database.dart';

// ignore_for_file: type=lint
class $RuleFilesTable extends RuleFiles with TableInfo<$RuleFilesTable, RuleFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
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
  List<GeneratedColumn> get $columns => [path, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_files';
  @override
  VerificationContext validateIntegrity(Insertable<RuleFile> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  RuleFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleFile(
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  $RuleFilesTable createAlias(String alias) {
    return $RuleFilesTable(attachedDatabase, alias);
  }
}

class RuleFile extends DataClass implements Insertable<RuleFile> {
  /// The file's path, relative to the corpus root, forward-slash separated.
  final String path;

  /// The file's full text.
  final String content;
  const RuleFile({required this.path, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['content'] = Variable<String>(content);
    return map;
  }

  RuleFilesCompanion toCompanion(bool nullToAbsent) {
    return RuleFilesCompanion(path: Value(path), content: Value(content));
  }

  factory RuleFile.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleFile(
      path: serializer.fromJson<String>(json['path']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'path': serializer.toJson<String>(path), 'content': serializer.toJson<String>(content)};
  }

  RuleFile copyWith({String? path, String? content}) =>
      RuleFile(path: path ?? this.path, content: content ?? this.content);
  RuleFile copyWithCompanion(RuleFilesCompanion data) {
    return RuleFile(
      path: data.path.present ? data.path.value : this.path,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleFile(')
          ..write('path: $path, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RuleFile && other.path == this.path && other.content == this.content);
}

class RuleFilesCompanion extends UpdateCompanion<RuleFile> {
  final Value<String> path;
  final Value<String> content;
  final Value<int> rowid;
  const RuleFilesCompanion({
    this.path = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleFilesCompanion.insert({required String path, required String content, this.rowid = const Value.absent()})
    : path = Value(path),
      content = Value(content);
  static Insertable<RuleFile> custom({Expression<String>? path, Expression<String>? content, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleFilesCompanion copyWith({Value<String>? path, Value<String>? content, Value<int>? rowid}) {
    return RuleFilesCompanion(path: path ?? this.path, content: content ?? this.content, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
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
          ..write('path: $path, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RulesDatabase extends GeneratedDatabase {
  _$RulesDatabase(QueryExecutor e) : super(e);
  $RulesDatabaseManager get managers => $RulesDatabaseManager(this);
  late final $RuleFilesTable ruleFiles = $RuleFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [ruleFiles];
}

typedef $$RuleFilesTableCreateCompanionBuilder =
    RuleFilesCompanion Function({required String path, required String content, Value<int> rowid});
typedef $$RuleFilesTableUpdateCompanionBuilder =
    RuleFilesCompanion Function({Value<String> path, Value<String> content, Value<int> rowid});

class $$RuleFilesTableFilterComposer extends Composer<_$RulesDatabase, $RuleFilesTable> {
  $$RuleFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

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
  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

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
  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

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
                Value<String> path = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleFilesCompanion(path: path, content: content, rowid: rowid),
          createCompanionCallback:
              ({required String path, required String content, Value<int> rowid = const Value.absent()}) =>
                  RuleFilesCompanion.insert(path: path, content: content, rowid: rowid),
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

class $RulesDatabaseManager {
  final _$RulesDatabase _db;
  $RulesDatabaseManager(this._db);
  $$RuleFilesTableTableManager get ruleFiles => $$RuleFilesTableTableManager(_db, _db.ruleFiles);
}
