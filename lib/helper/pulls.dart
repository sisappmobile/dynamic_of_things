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

  bool onProgress = false;
  bool shouldShowProgress = false;
  OverlayEntry? overlayEntry;
  ValueNotifier<int?>? statusNotifier;
  VoidCallback? hideAnimation;

  Future<void> execute() async {
    if (!onProgress) {
      try {
        if (!Sqlites.supported) {
          if (kDebugMode) {
            print("Pulls skipped: SQLite offline storage is not available on web.");
          }

          return;
        }

        onProgress = true;
        shouldShowProgress = true;

        Future.delayed(Duration(seconds: 1), () {
          if (shouldShowProgress) {
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
          updateStatus(
            result ? 101 : -1,
            autoCloseAfter:
            result ? Duration.zero : const Duration(milliseconds: 1200),
          );
        }
      } finally {
        onProgress = false;
      }
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
    if (overlayEntry != null) {
      return;
    }

    final overlay = g.Get.key.currentState?.overlay;

    if (overlay == null) {
      return;
    }

    statusNotifier = ValueNotifier(null);

    overlayEntry = OverlayEntry(
      builder: (context) {
        return OverlayContent(
          statusNotifier: statusNotifier!,
          onHideReady: (hideFn) {
            hideAnimation = hideFn;
          },
        );
      },
    );

    overlay.insert(overlayEntry!);
  }

  void hide() {
    if (overlayEntry == null) {
      return;
    }

    hideAnimation?.call();
  }

  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
    statusNotifier = null;
    hideAnimation = null;
  }

  void updateStatus(int? status, {Duration? autoCloseAfter}) {
    shouldShowProgress = false;

    if (statusNotifier == null) {
      return;
    }

    statusNotifier!.value = status;

    if (autoCloseAfter != null) {
      Future.delayed(autoCloseAfter, () => hide());
    }
  }
}

class OverlayContent extends StatefulWidget {
  final ValueNotifier<int?> statusNotifier;
  final Function(VoidCallback hideFn) onHideReady;

  const OverlayContent({
    required this.statusNotifier,
    required this.onHideReady,
    super.key,
  });

  @override
  State<OverlayContent> createState() => OverlayContentState();
}

class OverlayContentState extends State<OverlayContent>
    with TickerProviderStateMixin {
  late AnimationController visibilityController;
  late AnimationController pulseController;
  late Animation<double> fade;
  late Animation<double> scale;
  late Animation<double> pulseFade;
  late Animation<double> pulseScale;

  @override
  void initState() {
    super.initState();

    visibilityController = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    pulseController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    )..repeat(reverse: true);

    fade = CurvedAnimation(
      parent: visibilityController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: visibilityController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    pulseFade = Tween(begin: 0.28, end: 1.0).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    pulseScale = Tween(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    widget.onHideReady(hideWithAnimation);

    visibilityController.forward();
  }

  void hideWithAnimation() async {
    await visibilityController.reverse();

    Pulls.instance.removeOverlay();
  }

  @override
  void dispose() {
    pulseController.dispose();
    visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Positioned(
          left: Dimensions.size15,
          bottom: Dimensions.size15,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: ValueListenableBuilder<int?>(
                  valueListenable: widget.statusNotifier,
                  builder: (context, value, child) {
                    return AnimatedStatusDot(
                      status: value,
                      pulseFade: pulseFade,
                      pulseScale: pulseScale,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedStatusDot extends StatelessWidget {
  final int? status;
  final Animation<double> pulseFade;
  final Animation<double> pulseScale;

  const AnimatedStatusDot({
    required this.status,
    required this.pulseFade,
    required this.pulseScale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
      },
      child: buildChild(status),
    );
  }

  Widget buildChild(int? status) {
    if (status == 101) {
      return const SizedBox.shrink(key: ValueKey("completed"));
    }

    final bool isError = status == -1;
    final Color dotColor =
        isError ? const Color(0xFFD64545) : const Color(0xFF14B8A6);

    return FadeTransition(
      key: ValueKey(isError ? "error-dot" : "loading-dot"),
      opacity: isError ? const AlwaysStoppedAnimation(1) : pulseFade,
      child: ScaleTransition(
        scale: isError ? const AlwaysStoppedAnimation(1) : pulseScale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.35),
                blurRadius: Dimensions.size10,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: SizedBox(width: Dimensions.size10, height: Dimensions.size10),
        ),
      ),
    );
  }
}
