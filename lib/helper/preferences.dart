// ignore_for_file: always_declare_return_types, always_specify_types

import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:shared_preferences/shared_preferences.dart";

class Preferences {
  static Preferences? _instance;

  Preferences._internal();

  static Preferences getInstance() {
    _instance ??= Preferences._internal();

    return _instance!;
  }

  late SharedPreferences sharedPreferences;

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();

    await migrate();
  }

  bool? getBool(SharedPreferenceKey sharedPreferenceKey, [bool? defValue]) {
    return sharedPreferences.getBool(sharedPreferenceKey.name) ?? defValue;
  }

  int? getInt(SharedPreferenceKey sharedPreferenceKey, [int? defValue]) {
    return sharedPreferences.getInt(sharedPreferenceKey.name) ?? defValue;
  }

  double? getDouble(
    SharedPreferenceKey sharedPreferenceKey, [
    double? defValue,
  ]) {
    return sharedPreferences.getDouble(sharedPreferenceKey.name) ?? defValue;
  }

  String? getString(
    SharedPreferenceKey sharedPreferenceKey, [
    String? defValue,
  ]) {
    return sharedPreferences.getString(sharedPreferenceKey.name) ?? defValue;
  }

  String? getStringDynamicForm(
    String key, [
    String? defValue,
    ]) {
    return sharedPreferences.getString(key) ?? defValue;
  }

  List<String>? getStrings(
    SharedPreferenceKey sharedPreferenceKey, [
    List<String>? defValue,
  ]) {
    return sharedPreferences.getStringList(sharedPreferenceKey.name) ?? defValue;
  }

  Future<void> setBool(SharedPreferenceKey sharedPreferenceKey, bool? value) async {
    if (value != null) {
      await sharedPreferences.setBool(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setInt(SharedPreferenceKey sharedPreferenceKey, int? value) async {
    if (value != null) {
      await sharedPreferences.setInt(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setDouble(SharedPreferenceKey sharedPreferenceKey, double? value) async {
    if (value != null) {
      await sharedPreferences.setDouble(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setString(SharedPreferenceKey sharedPreferenceKey, String? value) async {
    if (value != null) {
      await sharedPreferences.setString(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setStringDynamicForm(String key, String? value) async {
    if (value != null) {
      await sharedPreferences.setString(key, value);
    }
  }

  Future<void> setStrings(
    SharedPreferenceKey sharedPreferenceKey,
    List<String>? value,
  ) async {
    if (value != null) {
      await sharedPreferences.setStringList(sharedPreferenceKey.name, value);
    }
  }

  Future<void> remove(SharedPreferenceKey sharedPreferenceKey) async {
    await sharedPreferences.remove(sharedPreferenceKey.name);
  }

  Future<void> removeDynamicForm(String key) async {
    await sharedPreferences.remove(key);
  }

  bool contain(SharedPreferenceKey sharedPreferenceKey) {
    return sharedPreferences.containsKey(sharedPreferenceKey.name);
  }

  Future<void> clear() async {
    await sharedPreferences.clear();
  }

  Future<void> reload() async {
    await sharedPreferences.reload();
  }

  Map<String, String> all() {
    final values = <String, String>{};

    for (String key in sharedPreferences.getKeys()) {
      Object? object = sharedPreferences.get(key);

      if (object != null) {
        values[key] = object.toString();
      }
    }

    return values;
  }

  Future<void> migrate() async {
    for (SharedPreferenceKey sharedPreferenceKey in SharedPreferenceKey.values) {
      final String? legacyKey = sharedPreferenceKey.legacyKey;
      if (StringUtils.isNullOrEmpty(legacyKey)) {
        continue;
      }
      if (legacyKey == sharedPreferenceKey.name) {
        continue;
      }

      if (StringUtils.isNotNullOrEmpty(legacyKey)) {
        Object? object = sharedPreferences.get(legacyKey!);

        if (object != null) {
          if (object is bool) {
            await sharedPreferences.setBool(sharedPreferenceKey.name, object);
          } else {
            await sharedPreferences.setString(sharedPreferenceKey.name, object.toString());
          }

          await sharedPreferences.remove(legacyKey);
        }
      }
    }
  }
}
