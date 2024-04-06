// ignore_for_file: non_constant_identifier_names

import 'package:yaroorm/migration.dart';
import 'package:yaroorm/yaroorm.dart';

// ignore: implementation_imports
import 'package:yaroorm/src/reflection.dart';

class MigrationData extends Entity {
  @primaryKey
  final int id;

  final String migration;

  final int batch;

  MigrationData(this.id, this.migration, this.batch);
}

class _$MigrationDataEntityMirror extends EntityMirror<MigrationData> {
  const _$MigrationDataEntityMirror(super.instance);

  @override
  Object? get(Symbol field) => switch (field) {
        #id => instance.id,
        #migration => instance.migration,
        #batch => instance.batch,
        _ => throw Exception('Unknown property $field'),
      };
}

final _typeData = DBEntity<MigrationData>(
  "migrations",
  timestampsEnabled: false,
  columns: [
    PrimaryKeyField("id", int, #id),
    DBEntityField("migration", String, #migration),
    DBEntityField("batch", int, #batch)
  ],
  mirror: _$MigrationDataEntityMirror.new,
  build: (args) => MigrationData(
    args[#id],
    args[#migration],
    args[#batch],
  ),
);

extension MigrationDataQueryExtension on Query<MigrationData> {
  Future<MigrationData> create({
    required String migration,
    required int batch,
  }) {
    return insert({#migration: migration, #batch: batch});
  }

  Future<void> update({
    required WhereBuilder<MigrationData> where,
    required MigrationData value,
  }) async {
    final props = {
      for (final column in _typeData.columns)
        column.dartName: _typeData.mirror(value).get(column.dartName),
    };

    final update = UpdateQuery(
      entity.tableName,
      whereClause: where(this),
      data: conformToDbTypes(props, converters),
    );

    await accept<UpdateQuery>(update);
  }
}

Query<MigrationData> get MigrationQuery {
  Query.addTypeDef<MigrationData>(_typeData);
  return DB.query<MigrationData>();
}

CreateSchema get MigrationDataSchema {
  Query.addTypeDef<MigrationData>(_typeData);
  return Schema.fromEntity<MigrationData>();
}
