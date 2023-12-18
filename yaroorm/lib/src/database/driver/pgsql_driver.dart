import 'package:yaroorm/src/access/access.dart';

import 'package:yaroorm/src/access/primitives/serializer.dart';

import '../../access/access.dart';
import '../../access/primitives/serializer.dart';
import '../migration.dart';
import 'driver.dart';

class PostgreSqlDriver implements DatabaseDriver {
  @override
  // TODO: implement blueprint
  TableBlueprint get blueprint => throw UnimplementedError();

  @override
  Future<DatabaseDriver> connect() {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future execute(String script) {
    // TODO: implement execute
    throw UnimplementedError();
  }

  @override
  Future insert(String tableName, Map<String, dynamic> data) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  // TODO: implement isOpen
  bool get isOpen => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> query(Query query) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  // TODO: implement serializer
  PrimitiveSerializer get serializer => throw UnimplementedError();

  @override
  // TODO: implement type
  DatabaseDriverType get type => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
