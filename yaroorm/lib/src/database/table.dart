abstract interface class TableBlueprint {
  void id();

  void string(String name);

  void integer(String name);

  void double(String name);

  void float(String name);

  void boolean(String name);

  void timestamp(String name);

  void datetime(String name);

  void blob(String name);

  void timestamps({String createdAt = 'created_at', String updatedAt = 'updated_at'});

  String createScript(String tableName);

  String dropScript(String tableName);
}
