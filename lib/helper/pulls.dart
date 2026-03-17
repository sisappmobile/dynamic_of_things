import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
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
          Map<String, dynamic> data = Map<String, dynamic>.from(change["data"]);

          List<Map<String, dynamic>> tableInfos = await txn.rawQuery("PRAGMA table_info($entity)");

          if (tableInfos.isEmpty) {
            Map<String, dynamic>? table = await DMLAssemblers
                .create()
                .select("*")
                .from("f_dynamic_table")
                .equalTo("table_name", entity)
                .firstWithTransaction(txn);

            if (table != null) {
              List<Map<String, dynamic>> columns = await DMLAssemblers
                  .create()
                  .select("*")
                  .from("f_dynamic_table_detail")
                  .equalTo("table_id", table["id"])
                  .allWithTransaction(txn);

              await txn.execute("CREATE TABLE $entity ( ${columns.map((column) => "${column["column_name"]} TEXT").join(", ")} )");

              tableInfos = await txn.rawQuery("PRAGMA table_info($entity)");
            }
          }

          if (tableInfos.isNotEmpty) {
            await txn.insert(entity, Map<String, dynamic>.fromEntries(data.entries.where((element) => element.value is! List && tableInfos.map((e) => e["name"]).contains(element.key))), conflictAlgorithm: ConflictAlgorithm.replace);
          }

          await checkList(txn, data);
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

  static Future<void> checkList(Transaction transaction, Map<String, dynamic> data) async {
    for (MapEntry<String, dynamic> element in data.entries) {
      if (element.value is List) {
        List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(element.value);

        List<Map<String, dynamic>> tableInfos = await transaction.rawQuery("PRAGMA table_info(${element.key})");

        if (tableInfos.isEmpty) {
          Map<String, dynamic>? table = await DMLAssemblers
              .create()
              .select("*")
              .from("f_dynamic_table")
              .equalTo("table_name", element.key)
              .firstWithTransaction(transaction);

          if (table != null) {
            List<Map<String, dynamic>> columns = await DMLAssemblers
                .create()
                .select("*")
                .from("f_dynamic_table_detail")
                .equalTo("table_id", table["id"])
                .allWithTransaction(transaction);

            await transaction.execute("CREATE TABLE ${element.key} ( ${columns.map((column) => "${column["column_name"]} TEXT").join(", ")} )");

            tableInfos = await transaction.rawQuery("PRAGMA table_info(${element.key})");
          }
        }

        for (Map<String, dynamic> row in rows) {
          await transaction.insert(element.key, Map<String, dynamic>.fromEntries(row.entries.where((element) => element.value is! List && tableInfos.map((e) => e["name"]).contains(element.key))), conflictAlgorithm: ConflictAlgorithm.replace);
          await checkList(transaction, row);
        }
      }
    }
  }
}