// ignore_for_file: avoid_print

import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:sqflite/sqflite.dart";

class Pushes {
  static final Pushes _instance = Pushes._internal();

  static Pushes get instance => _instance;

  Pushes._internal();

  Future<void> execute() async {
    List<Map<String, dynamic>> syncQueues = await DMLAssemblers
        .create()
        .select("*")
        .from("_sync_queues")
        .desc("created_at")
        .all();

    if (syncQueues.isNotEmpty) {
      Response response = await DotApis.getInstance().synchronizationPush(syncQueues);

      if (response.statusCode == 204) {
        Database database = await Sqlites.get();

        await database.transaction((txn) async {
          for (Map<String, dynamic> syncQueue in syncQueues) {
            await txn.execute("DELETE FROM _sync_queues WHERE id = ?", [syncQueue["id"]]);
          }
        });
      }
    } else {
      print("No data to push");
    }
  }
}