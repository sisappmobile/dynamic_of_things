// ignore_for_file: avoid_print

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/pg_to_sqlite_converter.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart" as g;
import "package:sqflite/sqflite.dart";

class Pulls {
  // ✅ singleton instance
  static final Pulls _instance = Pulls._internal();

  static Pulls get instance => _instance;

  Pulls._internal();

  bool _shouldShowProgress = false;
  OverlayEntry? _overlayEntry;
  ValueNotifier<int?>? _statusNotifier;
  VoidCallback? _hideAnimation;

  Future<void> execute() async {
    if (!Sqlites.supported) {
      if (kDebugMode) {
        print("Pulls skipped: SQLite offline storage is not available on web.");
      }

      return;
    }

    _shouldShowProgress = true;

    Future.delayed(Duration(seconds: 1), () {
      if (_shouldShowProgress) {
        show();
      }
    });

    int? currentVersion =
        BasePreferences.getInstance().getInt("dot-sync-current-version");

    if (currentVersion == null) {
      try {
        Response response =
            await DotApis.getInstance().synchronizationSnapshot();

        await consume(response, true);
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }
      }

      currentVersion =
          BasePreferences.getInstance().getInt("dot-sync-current-version") ?? 0;
    }

    bool result = false;

    try {
      Response response =
          await DotApis.getInstance().synchronizationPull(currentVersion);

      result = await consume(response);
    } catch (e, s) {
      if (kDebugMode) {
        print("Caught Exception: $e");
        print("Stack Trace:\n$s");
      }
    } finally {
      updateStatus(result ? 101 : -1, autoCloseAfter: Duration(seconds: 3));
    }
  }

  Future<bool> consume(Response response, [bool snapshot = false]) async {
    if (response.statusCode == 200) {
      Map<String, dynamic> json = Map<String, dynamic>.from(response.data);

      int currentVersion = json["currentVersion"];
      List<Map<String, dynamic>> changes =
          List<Map<String, dynamic>>.from(json["changes"]);

      Database database = await Sqlites.get();

      return await database.transaction((txn) async {
        for (int i = 0; i < changes.length; i++) {
          Map<String, dynamic> change = changes[i];

          String entity = change["entity"];

          Map<String, dynamic> payload =
              Map<String, dynamic>.from(change["payload"]);

          List<Map<String, dynamic>> tableInfos =
              await getTableInfos(txn, entity);

          await process(txn, entity, payload, tableInfos);

          updateStatus(((i + 1) / changes.length * 100).toInt());
        }
      }).then((value) async {
        await BasePreferences.getInstance()
            .setInt("dot-sync-current-version", currentVersion);

        return true;
      }).onError((error, stackTrace) async {
        print("e: $error | s: $stackTrace");

        return false;
      });
    } else if (response.statusCode == 204) {
      if (snapshot) {
        print("No snapshot data");
      } else {
        print("Sync version is up to date");
      }

      return true;
    } else {
      return false;
    }
  }

  Future<void> process(
    Transaction transaction,
    String tableName,
    Map<String, dynamic> payload,
    List<Map<String, dynamic>> tableInfos,
  ) async {
    if (tableInfos.isNotEmpty) {
      if (payload["idempotent_id"] != null) {
        int rowsAffected = await transaction.delete(
          tableName,
          where: "id = ?",
          whereArgs: [payload["idempotent_id"]],
        );

        if (rowsAffected > 0) {
          print(
            "$rowsAffected $tableName with idempotent id: ${payload["idempotent_id"]} has been deleted",
          );
        }
      }

      await transaction.insert(
        tableName,
        Map<String, dynamic>.fromEntries(
          payload.entries.where(
            (element) =>
                element.value is! List &&
                tableInfos.map((e) => e["name"]).contains(element.key),
          ),
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (MapEntry<String, dynamic> entry in payload.entries) {
        if (entry.value is List) {
          List<Map<String, dynamic>> detailTableInfos =
              await getTableInfos(transaction, entry.key);

          List<Map<String, dynamic>> detailPayloads =
              List<Map<String, dynamic>>.from(entry.value);

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

  Future<List<Map<String, dynamic>>> getTableInfos(
    Transaction transaction,
    String tableName,
  ) async {
    List<Map<String, dynamic>> tableInfos =
        await transaction.rawQuery("PRAGMA table_info($tableName)");

    if (tableInfos.isEmpty) {
      Map<String, dynamic>? table = await DMLAssemblers.create()
          .select("*")
          .from("f_dynamic_table")
          .equalTo("table_name", tableName)
          .first(transaction);

      if (table != null) {
        List<Map<String, dynamic>> dynamicTableDetailViews =
            await DMLAssemblers.create()
                .select("*")
                .from("f_dynamic_table_detail")
                .equalTo("table_id", table["id"])
                .all(transaction);

        String? pkColumn = dynamicTableDetailViews.firstWhereOrNull(
          (dynamicTableDetailViews) => dynamicTableDetailViews["f_pk"] == "Y",
        )?["column_name"];

        List<String> columns = dynamicTableDetailViews
            .map(
              (dynamicTableDetailViews) =>
                  dynamicTableDetailViews["column_name"] as String,
            )
            .toList();

        List<String> additionalColumns = [
          "create_who",
          "create_date",
          "change_who",
          "change_date",
          "table_id",
          "form_id",
          "f_delete",
          "version",
          "user_id",
          "header_id",
        ];

        for (String additionalColumn in additionalColumns) {
          if (!columns.contains(additionalColumn)) {
            columns.add(additionalColumn);
          }
        }

        await transaction.execute(
          "CREATE TABLE $tableName ( ${columns.toSet().map((column) => "$column TEXT ${column == pkColumn ? "PRIMARY KEY" : ""}").join(", ")} )",
        );

        tableInfos =
            await transaction.rawQuery("PRAGMA table_info($tableName)");
      }
    }

    return tableInfos;
  }

  Future<void> handleSegmentReport(
    Transaction transaction,
    Map<String, dynamic> payload,
  ) async {
    try {
      final converter = PgToSqliteConverter();

      final sqliteQuery = converter.convert(payload["segment_report_query"]);

      await transaction.execute(
        "CREATE VIEW IF NOT EXISTS ${payload["view_name"]} AS $sqliteQuery",
      );
    } catch (e, s) {
      if (kDebugMode) {
        print("Caught Exception: $e");
        print("Stack Trace:\n$s");
      }

      rethrow;
    }
  }

  void show() {
    if (_overlayEntry != null) {
      return;
    }

    final overlay = g.Get.key.currentState?.overlay;

    if (overlay == null) {
      return;
    }

    _statusNotifier = ValueNotifier(null);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _OverlayContent(
          statusNotifier: _statusNotifier!,
          onHideReady: (hideFn) {
            _hideAnimation = hideFn;
          },
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void hide() {
    if (_overlayEntry == null) {
      return;
    }

    _hideAnimation?.call();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _statusNotifier = null;
    _hideAnimation = null;
  }

  void updateStatus(int? status, {Duration? autoCloseAfter}) {
    _shouldShowProgress = false;

    if (_statusNotifier == null) {
      return;
    }

    _statusNotifier!.value = status;

    if (autoCloseAfter != null) {
      Future.delayed(autoCloseAfter, () => hide());
    }
  }
}

class _OverlayContent extends StatefulWidget {
  final ValueNotifier<int?> statusNotifier;
  final Function(VoidCallback hideFn) onHideReady;

  const _OverlayContent({
    required this.statusNotifier,
    required this.onHideReady,
  });

  @override
  State<_OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<_OverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    widget.onHideReady(_hideWithAnimation);

    _controller.forward();
  }

  void _hideWithAnimation() async {
    await _controller.reverse();

    Pulls.instance._removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Positioned(
          left: Dimensions.size15,
          bottom: Dimensions.size15,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Card(
                elevation: 6,
                shape: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ValueListenableBuilder<int?>(
                    valueListenable: widget.statusNotifier,
                    builder: (context, value, child) {
                      return _AnimatedStatusIcon(status: value);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedStatusIcon extends StatelessWidget {
  final int? status;

  const _AnimatedStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
      child: _buildChild(status),
    );
  }

  Widget _buildChild(int? status) {
    if (status == null) {
      return const SizedBox(
        key: ValueKey("loading"),
        width: 36,
        height: 36,
        child: CircularProgressIndicator(),
      );
    } else {
      if (status == -1) {
        return const Icon(
          Icons.cancel,
          key: ValueKey("error"),
          color: Colors.red,
          size: 36,
        );
      } else if (status == 101) {
        return const Icon(
          Icons.check_circle,
          key: ValueKey("success"),
          color: Colors.green,
          size: 36,
        );
      } else {
        return SizedBox(
          key: ValueKey("loading"),
          width: 36,
          height: 36,
          child: CircularProgressIndicator(value: status / 100),
        );
      }
    }
  }
}
