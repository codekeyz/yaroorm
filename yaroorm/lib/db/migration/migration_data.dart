import 'package:yaroorm/src/database/entity.dart';

class Migration extends Entity<int> {
  final String migration;
  final int batch;

  Migration(this.migration, this.batch);

  static Migration fromJson(Map<String, dynamic> json) =>
      Migration(json['migration'] as String, json['batch'] as int)..id = PrimaryKey.thisFromJson(json['id']);

  @override
  Map<String, dynamic> toJson() => {
        'id': PrimaryKey.thisToJson(id),
        'migration': migration,
        'batch': batch,
      };

  @override
  bool get enableTimestamps => false;
}
