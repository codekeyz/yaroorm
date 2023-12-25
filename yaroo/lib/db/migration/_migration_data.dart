import 'package:yaroo/db/db.dart';

class MigrationDbData extends Entity<int> {
  final String migration;
  final int batch;

  MigrationDbData(this.migration, this.batch);

  static MigrationDbData from(Map<String, dynamic> json) => MigrationDbData(
        json['migration'] as String,
        json['batch'] as int,
      )..id = PrimaryKey.thisFromJson(json['id']);

  @override
  Map<String, dynamic> toJson() => {
        'id': PrimaryKey.thisToJson(id),
        'migration': migration,
        'batch': batch,
      };

  @override
  bool get enableTimestamps => false;
}
