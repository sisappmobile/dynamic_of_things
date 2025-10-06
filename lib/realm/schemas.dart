import "package:realm/realm.dart";

part "schemas.realm.dart";

@RealmModel()
class _Version {
  @PrimaryKey()
  late String key;
  late int value;
}

@RealmModel()
class _DynamicForm {
  @PrimaryKey()
  late String id;
  late String json;
}

@RealmModel()
class _Schema {
  @PrimaryKey()
  late String name;
  late String json;
}