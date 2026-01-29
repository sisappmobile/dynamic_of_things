// ignore_for_file: avoid_single_cascade_in_expression_statements

import "package:dynamic_of_things/realm/schemas.dart";
import "package:path/path.dart" as path;
import "package:realm/realm.dart";

class Realms {
  static Realm? realm;

  static Realm get() {
    realm ??= Realm(
      Configuration.local([
        Version.schema,
        DynamicForm.schema,
        Schema.schema,
      ], path: path.join(Configuration.defaultStoragePath, "dynamic_of_things.realm")),
    );

    return realm!;
  }

  static void clear() {
    var realm = get();

    realm.write(() {
      realm
        ..deleteAll<Version>()
        ..deleteAll<DynamicForm>()
        ..deleteAll<Schema>();
    });
  }
}
