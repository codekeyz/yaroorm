import 'package:yaroo/db/db.dart';

class MigrationDbData extends Entity<int> {
  final String migration;
  final int batch;

  MigrationDbData(this.migration, this.batch);

  static MigrationDbData from(Map<String, dynamic> json) =>
      MigrationDbData(json['migration'] as String, json['batch'] as int)
        ..id = PrimaryKey.thisFromJson(json['id'])
        ..createdAt = DateTime.parse(json['created_at'] as String)
        ..updatedAt = DateTime.parse(json['updated_at'] as String);

  @override
  Map<String, dynamic> toJson() => {
        'id': PrimaryKey.thisToJson(id),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'migration': migration,
        'batch': batch,
      };
}
