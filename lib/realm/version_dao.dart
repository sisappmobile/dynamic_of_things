import "package:dynamic_of_things/helper/realms.dart";
import "package:dynamic_of_things/realm/schemas.dart";
import "package:realm/realm.dart";

class VersionDao {
  static final String form = "FORM";

  static Map<String, int> check() {
    Realm realm = Realms.get();

    realm.write(() {
      if (!(realm.dynamic.find(Version.schema.name, form)?.isValid ?? false)) {
        realm.add(
          Version(
            form,
            0,
          ),
          update: true,
        );
      }
    });

    RealmResults<Version> versions = realm.all<Version>();

    Map<String, int> results = {};

    for (var version in versions) {
      results[version.key] = version.value;
    }

    return results;
  }

  static int last(String key) {
    Realm realm = Realms.get();

    Version? version = realm.find<Version>(key);

    if (version != null) {
      return version.value;
    } else {
      return 0;
    }
  }

  static void updateVersion({
    required Realm realm,
    required String key,
    required int lastVersion,
  }) {
    if (realm.isInTransaction) {
      Version? version = realm.find<Version>(key);

      if (version == null) {
        realm.add(
          Version(
            key,
            0,
          ),
          update: true,
        );
      }

      version = realm.find<Version>(key);

      if (version != null) {
        if (lastVersion > version.value) {
          version.value = lastVersion;
        }
      }
    }
  }
}
