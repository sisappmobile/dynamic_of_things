// ignore_for_file: avoid_print

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/pg_to_sqlite_converter.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:flutter/foundation.dart";
import "package:sqflite/sqflite.dart";

class Pulls {
  static Future<void> execute() async {
    Response response = await DotApis.getInstance().synchronizationPull(BasePreferences.getInstance().getInt("sync_current_version", 0)!);

    if (response.statusCode == 200) {
      Map<String, dynamic> json = Map<String, dynamic>.from(response.data);

      int currentVersion = json["currentVersion"];
      List<Map<String, dynamic>> changes = List<Map<String, dynamic>>.from(json["changes"]);

      Database database = await Sqlites.get();

      await database.transaction((txn) async {
        for (Map<String, dynamic> change in changes) {
          String entity = change["entity"];

          Map<String, dynamic> payload = Map<String, dynamic>.from(change["payload"]);

          List<Map<String, dynamic>> tableInfos = await getTableInfos(txn, entity);

          await process(txn, entity, payload, tableInfos);
        }
      }).then((value) async {
        await BasePreferences.getInstance().setInt("sync_current_version", currentVersion);
      }).onError((error, stackTrace) async {
        print("e: $error | s: $stackTrace");
      });
    } else if (response.statusCode == 204) {
      print("Sync version is up to date");
    }
  }

  static Future<void> process(Transaction transaction, String tableName, Map<String, dynamic> payload, List<Map<String, dynamic>> tableInfos) async {
    if (tableInfos.isNotEmpty) {
      if (payload["idempotent_id"] != null) {
        int rowsAffected = await transaction.delete(tableName, where: "id = ?", whereArgs: [payload["idempotent_id"]]);

        if (rowsAffected > 0) {
          print("$rowsAffected $tableName with idempotent id: ${payload["idempotent_id"]} has been deleted");
        }
      }

      await transaction.insert(tableName, Map<String, dynamic>.fromEntries(payload.entries.where((element) => element.value is! List && tableInfos.map((e) => e["name"]).contains(element.key))), conflictAlgorithm: ConflictAlgorithm.replace);

      for (MapEntry<String, dynamic> entry in payload.entries) {
        if (entry.value is List) {
          List<Map<String, dynamic>> detailTableInfos = await getTableInfos(transaction, entry.key);

          List<Map<String, dynamic>> detailPayloads = List<Map<String, dynamic>>.from(entry.value);

          for (Map<String, dynamic> detailPayload in detailPayloads) {
            process(transaction, entry.key, detailPayload, detailTableInfos);
          }
        }
      }

      if (tableName == "c_segment_report") {
        handleSegmentReport(transaction, payload);
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getTableInfos(Transaction transaction, String tableName) async {
    List<Map<String, dynamic>> tableInfos = await transaction.rawQuery("PRAGMA table_info($tableName)");

    if (tableInfos.isEmpty) {
      Map<String, dynamic>? table = await DMLAssemblers
          .create()
          .select("*")
          .from("f_dynamic_table")
          .equalTo("table_name", tableName)
          .first(transaction);

      if (table != null) {
        List<Map<String, dynamic>> dynamicTableDetailViews = await DMLAssemblers
            .create()
            .select("*")
            .from("f_dynamic_table_detail")
            .equalTo("table_id", table["id"])
            .all(transaction);

        String? pkColumn = dynamicTableDetailViews.firstWhereOrNull((dynamicTableDetailViews) => dynamicTableDetailViews["f_pk"] == "Y")?["column_name"];

        List<String> columns = dynamicTableDetailViews.map((dynamicTableDetailViews) => dynamicTableDetailViews["column_name"] as String).toList();

        List<String> additionalColumns = [
          "table_id",
          "form_id",
          "f_delete",
          "version",
          "user_id",
        ];

        for (String additionalColumn in additionalColumns) {
          if (!columns.contains(additionalColumn)) {
            columns.add(additionalColumn);
          }
        }

        await transaction.execute("CREATE TABLE $tableName ( ${columns.map((column) => "$column TEXT ${column == pkColumn ? "PRIMARY KEY" : ""}").join(", ")} )");

        tableInfos = await transaction.rawQuery("PRAGMA table_info($tableName)");
      }
    }

    return tableInfos;
  }

  static Future<void> handleSegmentReport(Transaction transaction, Map<String, dynamic> payload) async {
    try {
      final converter = PgToSqliteConverter();

      final sqliteQuery = converter.convert(payload["segment_report_query"]);

      await transaction.execute("CREATE VIEW IF NOT EXISTS ${payload["view_name"]} AS $sqliteQuery");
    } catch (e, s) {
      if (kDebugMode) {
        print("Caught Exception: $e");
        print("Stack Trace:\n$s");
      }

      rethrow;
    }
  }
}