// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration.dart';

// **************************************************************************
// YaroormGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

Query<MigrationEntity> get MigrationEntityQuery => DB.query<MigrationEntity>();
CreateSchema get MigrationEntitySchema => Schema.fromEntity<MigrationEntity>();
DBEntity<MigrationEntity> get migration_entityTypeData =>
    DBEntity<MigrationEntity>(
      "migrations",
      timestampsEnabled: false,
      columns: [
        DBEntityField.primaryKey("id", int, #id),
        DBEntityField("migration", String, #migration),
        DBEntityField("batch", int, #batch)
      ],
      mirror: _$MigrationEntityEntityMirror.new,
      build: (args) => MigrationEntity(
        args[#id],
        args[#migration],
        args[#batch],
      ),
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

extension MigrationEntityQueryExtension on Query<MigrationEntity> {
  WhereClause<MigrationEntity> whereId(int value) => equal<int>("id", value);
  WhereClause<MigrationEntity> whereMigration(String value) =>
      equal<String>("migration", value);
  WhereClause<MigrationEntity> whereBatch(int value) =>
      equal<int>("batch", value);
  Future<MigrationEntity?> findById(int value) => whereId(value).findOne();
  Future<MigrationEntity?> findByMigration(String value) =>
      whereMigration(value).findOne();
  Future<MigrationEntity?> findByBatch(int value) =>
      whereBatch(value).findOne();
  Future<MigrationEntity> create({
    required String migration,
    required int batch,
  }) {
    return $insert({#migration: migration, #batch: batch});
  }
}

extension MigrationEntityUpdateQueryExtension on WhereClause<MigrationEntity> {
  Future<void> update({
    value<String> migration = const NoValue(),
    value<int> batch = const NoValue(),
  }) async {
    await query.$update(where: (_) => this, values: {
      if (migration is! NoValue) #migration: migration.val,
      if (batch is! NoValue) #batch: batch.val,
    }).execute();
  }
}
