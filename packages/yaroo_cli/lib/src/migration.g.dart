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
        PrimaryKeyField("id", int, #id),
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
  Future<MigrationEntity> create({
    required String migration,
    required int batch,
  }) =>
      insert({
        #migration: migration,
        #batch: batch,
      });
  Future<void> update({
    required WhereBuilder<MigrationEntity> where,
    required MigrationEntity value,
  }) async {
    final mirror = migration_entityTypeData.mirror(value);
    final props = {
      for (final column in migration_entityTypeData.columns)
        column.dartName: mirror.get(column.dartName),
    };

    final update = UpdateQuery(
      entity.tableName,
      whereClause: where(this),
      data: conformToDbTypes(props, converters),
    );

    await accept<UpdateQuery>(update);
  }
}
