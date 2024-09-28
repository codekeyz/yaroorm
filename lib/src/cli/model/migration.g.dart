// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration.dart';

// **************************************************************************
// EntityGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

Query<MigrationEntity> get MigrationEntityQuery => DB.query<MigrationEntity>();
CreateSchema get MigrationEntitySchema => Schema.fromEntity<MigrationEntity>();
EntityTypeDefinition<MigrationEntity> get migrationentityTypeDef => EntityTypeDefinition<MigrationEntity>(
      "migrations",
      timestampsEnabled: false,
      columns: [
        DBEntityField.primaryKey("id", int, #id, autoIncrement: true),
        DBEntityField("migration", String, #migration),
        DBEntityField("batch", int, #batch)
      ],
      mirror: (instance, field) => switch (field) {
        #id => instance.id,
        #migration => instance.migration,
        #batch => instance.batch,
        _ => throw Exception('Unknown property $field'),
      },
      builder: (args) => MigrationEntity(
        args[#id],
        args[#migration],
        args[#batch],
      ),
    );

class OrderMigrationEntityBy extends OrderBy<MigrationEntity> {
  const OrderMigrationEntityBy.migration({OrderDirection order = OrderDirection.asc}) : super("migration", order);

  const OrderMigrationEntityBy.batch({OrderDirection order = OrderDirection.asc}) : super("batch", order);
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
    this.migration,
    this.batch,
  });

  final value<String>? migration;

  final value<int>? batch;

  @override
  Map<Symbol, dynamic> get toMap => {
        if (migration != null) #migration: migration!.val,
        if (batch != null) #batch: batch!.val,
      };
}

extension MigrationEntityWhereBuilderExtension on WhereClauseBuilder<MigrationEntity> {
  WhereClauseValue id(int value) => $equal<int>("id", value);
  WhereClauseValue migration(String value) => $equal<String>("migration", value);
  WhereClauseValue batch(int value) => $equal<int>("batch", value);
}

extension MigrationEntityWhereHelperExtension on Query<MigrationEntity> {
  Future<MigrationEntity?> findById(int val) => findOne(where: (migrationentity) => migrationentity.id(val));
  Future<MigrationEntity?> findByMigration(String val) =>
      findOne(where: (migrationentity) => migrationentity.migration(val));
  Future<MigrationEntity?> findByBatch(int val) => findOne(where: (migrationentity) => migrationentity.batch(val));
}

extension MigrationEntityRelationsBuilder on JoinBuilder<MigrationEntity> {}
