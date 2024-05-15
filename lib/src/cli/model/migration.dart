// ignore_for_file: non_constant_identifier_names

import '../../../yaroorm.dart';

part 'migration.g.dart';

@Table(name: 'migrations')
class MigrationEntity extends Entity<MigrationEntity> {
  @autoIncrementPrimary
  final int id;

  final String migration;

  final int batch;

  MigrationEntity(this.id, this.migration, this.batch);
}
