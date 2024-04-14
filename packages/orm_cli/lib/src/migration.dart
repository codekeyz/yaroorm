// ignore_for_file: non_constant_identifier_names

import 'package:yaroorm/yaroorm.dart';

part 'migration.g.dart';

@Table('migrations')
class MigrationEntity extends Entity {
  @primaryKey
  final int id;

  final String migration;

  final int batch;

  MigrationEntity(this.id, this.migration, this.batch);
}
