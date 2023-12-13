abstract class TableColumn {}

abstract class TableBlueprint {
  final String name;

  TableBlueprint(this.name);

  TableColumn id();

  TableColumn string(String name);

  TableColumn timestamp(String name);

  TableColumn password(String name);

  TableColumn rememberToken();

  TableColumn timestamps();
}

abstract class Migration {
  void up(TableBlueprint $table);

  void down(TableBlueprint $table);
}
