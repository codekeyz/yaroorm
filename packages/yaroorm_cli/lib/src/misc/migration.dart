// ignore_for_file: non_constant_identifier_names

import 'package:yaroorm/yaroorm.dart';

part 'migration.g.dart';

@Table(name: 'migrations')
class MigrationEntity with Entity<MigrationEntity> {
  @primaryKey
  final int id;

  final String migration;

  final int batch;

  MigrationEntity(this.id, this.migration, this.batch) {
    super.initialize();
  }
}
