library;

import 'src/database/entity/entity.dart';

export 'src/query/query.dart';
export 'src/database/driver/driver.dart';
export 'src/database/entity/entity.dart' hide entityMapToDbData, entityToDbData, dbDataToEntity, combineConverters;
export 'src/database/database.dart';
export 'src/config.dart';
export 'src/reflection.dart'
    hide getEntityTableName, getEntityPrimaryKey, EntityInstanceReflector, EntityInstanceBuilder;
export 'src/migration.dart';

const primaryKey = PrimaryKey(autoIncrement: true);
const table = Table();
const createdAtCol = CreatedAtColumn();
const updatedAtCol = UpdatedAtColumn();
