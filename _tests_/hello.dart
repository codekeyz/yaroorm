import 'package:yaroorm/yaroorm.dart';

@Table()
class Hello extends Entity<Hello> {}

void main() async {
  final query = Hello.query;
  final schema = Hello.schema;
}
