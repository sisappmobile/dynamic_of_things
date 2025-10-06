// ignore_for_file: avoid_single_cascade_in_expression_statements

import "package:basic_utils/basic_utils.dart";
import "package:flutter/foundation.dart";
import "package:sqflite/sqflite.dart";

class Sqlites {
  static Database? database;

  static Future<Database> get() async {
    if (database == null) {
      database = await openDatabase(
        "${await getDatabasesPath()}/dynamic_of_things.db",
        version: 1,
        singleInstance: false,
      );

      if (kDebugMode) {
        print("Sqlites: successfully opened database");
      }
    }

    return database!;
  }

  static void delete() async {
    await deleteDatabase("${await getDatabasesPath()}/dynamic_of_things.db");

    if (database != null) {
      await database!.close();

      database = null;
    }
  }

  static String dataType(String value) {
    if (StringUtils.equalsIgnoreCase(value, "DATETIME")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "DATE")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "IMEI")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "DATA")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "FILE")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "CHECKBOX")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "COMBOBOX")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "MULTIDATA")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "STRING")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "NUMERIC")) {
      return "NUMERIC";
    } else if (StringUtils.equalsIgnoreCase(value, "EMAIL")) {
      return "TEXT";
    } else if (StringUtils.equalsIgnoreCase(value, "PASSWORD")) {
      return "TEXT";
    } else {
      return "TEXT";
    }
  }
}
