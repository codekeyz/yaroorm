// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration.dart';

// **************************************************************************
// YaroormGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

Query<MigrationEntity> get MigrationEntityQuery => DB.query<MigrationEntity>();
CreateSchema get MigrationEntitySchema => Schema.fromEntity<MigrationEntity>();
DBEntity<MigrationEntity> get migration_entityTypeData => DBEntity<MigrationEntity>(
      "migrations",
      timestampsEnabled: false,
      columns: [
        DBEntityField.primaryKey("id", int, #id, autoIncrement: true),
        DBEntityField("migration", String, #migration),
        DBEntityField("batch", int, #batch)
      ],
      mirror: _$MigrationEntityEntityMirror.new,
      build: (args) => MigrationEntity(args[#id], args[#migration], args[#batch]),
    );

class _$MigrationEntityEntityMirror extends EntityMirror<MigrationEntity> {
  const _$MigrationEntityEntityMirror(super.instance);

  @override
  Object? get(Symbol field) {
    return switch (field) {
      #id => instance.id,
      #migration => instance.migration,
      #batch => instance.batch,
      _ => throw Exception('Unknown property $field'),
    };
  }
}

class OrderMigrationEntityBy extends OrderBy<MigrationEntity> {
  const OrderMigrationEntityBy.migration(OrderDirection direction) : super("migration", direction);

  const OrderMigrationEntityBy.batch(OrderDirection direction) : super("batch", direction);
}

extension MigrationEntityQueryExtension on Query<MigrationEntity> {
  Future<MigrationEntity?> findById(int val) => findOne(where: (q) => q.id(val));
  Future<MigrationEntity?> findByMigration(String val) => findOne(where: (q) => q.migration(val));
  Future<MigrationEntity?> findByBatch(int val) => findOne(where: (q) => q.batch(val));
  Future<MigrationEntity> create({
    required String migration,
    required int batch,
  }) {
    return $insert({#migration: migration, #batch: batch});
  }
}

extension MigrationEntityWhereBuilderExtension on WhereClauseBuilder<MigrationEntity> {
  WhereClauseValue id(int value) => $equal<int>("id", value);
  WhereClauseValue migration(String value) => $equal<String>("migration", value);
  WhereClauseValue batch(int value) => $equal<int>("batch", value);
}

extension MigrationEntityUpdateExtension on ReadQuery<MigrationEntity> {
  Future<void> update({
    value<String> migration = const NoValue(),
    value<int> batch = const NoValue(),
  }) async {
    await $query.$update(where: (_) => whereClause!, values: {
      if (migration is! NoValue) #migration: migration.val,
      if (batch is! NoValue) #batch: batch.val,
    }).execute();
  }
}
