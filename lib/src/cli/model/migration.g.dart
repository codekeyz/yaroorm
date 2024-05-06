// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration.dart';

// **************************************************************************
// YaroormGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

Query<MigrationEntity> get MigrationEntityQuery => DB.query<MigrationEntity>();
CreateSchema get MigrationEntitySchema => Schema.fromEntity<MigrationEntity>();
EntityTypeDefinition<MigrationEntity> get migration_entityTypeData => EntityTypeDefinition<MigrationEntity>(
      "migrations",
      timestampsEnabled: false,
      columns: [
        DBEntityField.primaryKey("id", int, #id, autoIncrement: true),
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

class OrderMigrationEntityBy extends OrderBy<MigrationEntity> {
  const OrderMigrationEntityBy.migration({OrderDirection order = OrderDirection.asc}) : super("migration", order);

  const OrderMigrationEntityBy.batch({OrderDirection order = OrderDirection.desc}) : super("batch", order);
}

extension MigrationEntityQueryExtension on Query<MigrationEntity> {
  Future<MigrationEntity?> findById(int val) => findOne(where: (q) => q.id(val));
  Future<MigrationEntity?> findByMigration(String val) => findOne(where: (q) => q.migration(val));
  Future<MigrationEntity?> findByBatch(int val) => findOne(where: (q) => q.batch(val));
}

extension MigrationEntityWhereBuilderExtension on WhereClauseBuilder<MigrationEntity> {
  WhereClauseValue id(int value) => $equal<int>("id", value);
  WhereClauseValue migration(String value) => $equal<String>("migration", value);
  WhereClauseValue batch(int value) => $equal<int>("batch", value);
}

class NewMigrationEntity extends CreateEntity<MigrationEntity> {
  const NewMigrationEntity({
    required this.migration,
    required this.batch,
  });

  final String migration;

  final int batch;

  @override
  Map<Symbol, dynamic> get toMap => {#migration: migration, #batch: batch};
}

class UpdateMigrationEntity extends UpdateEntity<MigrationEntity> {
  const UpdateMigrationEntity({
    this.migration = const NoValue(),
    this.batch = const NoValue(),
  });

  final value<String> migration;

  final value<int> batch;

  @override
  Map<Symbol, dynamic> get toMap => {
        if (migration is! NoValue) #migration: migration.val!,
        if (batch is! NoValue) #batch: batch.val!,
      };
}
