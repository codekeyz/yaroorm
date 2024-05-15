import 'package:yaroorm/yaroorm.dart';

@Table()
class User {
  final String name;
  final int age;

  User(this.name, this.age);
}

void main() {
  final hello = User('34343', 34);

  print(hello.toString());
}
