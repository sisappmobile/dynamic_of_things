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
import "package:uuid/uuid.dart";

// Snapshot of where execute() currently is, shown by the corner overlay and
// its tap-to-expand detail sheet. `status` keeps the dot's original
// encoding (null/0-100 = in progress, 101 = success, -1 = error) so
// updateStatus()'s existing call sites didn't need to change. `batch` is
// 0 during the one-shot initial snapshot download and 1+ once execute()
// is chaining incremental pull-v2 batches (a large first-time pull can
// take many - up to _maxCatchUpBatches - since the API doesn't expose a
// total row count up front, `status`'s 0-100 necessarily resets each
// batch rather than reflecting whole-operation completion).
// `entityCounts` accumulates across the whole execute() cycle (not reset
// per batch) so the detail sheet can show what's actually been applied
// so far.
class PullProgressSnapshot {
  final int? status;
  final int batch;
  final Map<String, int> entityCounts;

  const PullProgressSnapshot({
    this.status,
    this.batch = 0,
    this.entityCounts = const {},
  });
}

class Pulls {
  // ✅ singleton instance
  static final Pulls _instance = Pulls._internal();

  static Pulls get instance => _instance;

  Pulls._internal();

  bool onProgress = false;
  bool shouldShowProgress = false;
  OverlayEntry? overlayEntry;
  ValueNotifier<PullProgressSnapshot>? statusNotifier;
  VoidCallback? hideAnimation;
  int _currentBatch = 0;
  Map<String, int> _entityCounts = {};

  // Safety bound on how many immediate hasMore round-trips execute() will
  // chain in a single call, so a client that's extremely far behind can't
  // make this loop forever - it'll just pick up where it left off (versions
  // are persisted per batch) the next time execute() is called.
  static const int _maxCatchUpBatches = 50;

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
        _currentBatch = 0;
        _entityCounts = {};

        Future.delayed(Duration(seconds: 1), () {
          if (shouldShowProgress) {
            show();
          }
        });

        Database database = await Sqlites.get();

        Map<String, int> versions = await loadSyncVersions(database);

        if (versions.isEmpty) {
          try {
            Response response =
            await DotApis.getInstance().synchronizationSnapshot();

            await consume(response, true);

            versions = await loadSyncVersions(database);
          } catch (e, s) {
            if (kDebugMode) {
              print("Caught Exception: $e");
              print("Stack Trace:\n$s");
            }
          }
        }

        bool result = false;

        try {
          bool hasMore = true;
          int batches = 0;

          while (hasMore && batches < _maxCatchUpBatches) {
            batches++;
            _currentBatch = batches;

            Response response =
            await DotApis.getInstance().synchronizationPullV2(versions);

            final (bool success, bool more) = await consumeV2(response);

            result = success;
            hasMore = success && more;

            if (!success) {
              break;
            }

            versions = await loadSyncVersions(database);
          }
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

        // Reconciled every cycle, not just when saveSyncVersions() runs -
        // see _syncGlobalVersionPref()'s own comment for why that alone
        // isn't enough for an already-caught-up device.
        await _syncGlobalVersionPref(versions);
      } finally {
        onProgress = false;
      }
    }
  }

  // Per-entity high-water marks, kept in SQLite (not BasePreferences, which
  // only ever held a single global int) so each entity can be checkpointed
  // independently - lazily created rather than added to Sqlites.onCreate,
  // matching the same pattern _segment_report_errors already uses here,
  // since the DB schema is pinned at version 1 with no onUpgrade path for
  // already-installed users.
  Future<Map<String, int>> loadSyncVersions(Database database) async {
    await database.execute(
      "CREATE TABLE IF NOT EXISTS _sync_versions ( entity TEXT PRIMARY KEY, version INTEGER )",
    );

    List<Map<String, dynamic>> rows = await database.query("_sync_versions");

    return {
      for (Map<String, dynamic> row in rows)
        row["entity"] as String: (row["version"] as num).toInt(),
    };
  }

  Future<void> saveSyncVersions(
    DatabaseExecutor executor,
    Map<String, int> versions,
  ) async {
    await executor.execute(
      "CREATE TABLE IF NOT EXISTS _sync_versions ( entity TEXT PRIMARY KEY, version INTEGER )",
    );

    for (MapEntry<String, int> entry in versions.entries) {
      await executor.insert(
        "_sync_versions",
        {"entity": entry.key, "version": entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await _syncGlobalVersionPref(versions);
  }

  // "dot-sync-current-version" used to be the one global watermark (host
  // apps like visitqu's account_page.dart still read it directly, e.g. for
  // a "Sync Version" display) - per-entity versioning replaced it as the
  // actual sync mechanism, and nothing else repopulates this pref anymore.
  // Kept meaningful as "the highest version we've seen anything for yet",
  // the closest analog to what the single global counter used to
  // represent. Only called from saveSyncVersions() (i.e. only when a pull
  // actually brings back new data) wasn't enough: a device that's already
  // fully caught up gets 204 "up to date" responses indefinitely, so a
  // device whose _sync_versions table was already populated before this
  // reconciliation existed - or before the device's last new row ever
  // arrived - would show "N/A" forever despite syncing successfully every
  // cycle. execute() also calls this directly, every cycle, regardless of
  // whether that cycle had anything new to apply.
  Future<void> _syncGlobalVersionPref(Map<String, int> versions) async {
    if (versions.isEmpty) {
      return;
    }

    final int maxVersion = versions.values.reduce((a, b) => a > b ? a : b);
    final int currentPrefValue =
        BasePreferences.getInstance().getInt("dot-sync-current-version") ?? 0;

    if (maxVersion > currentPrefValue) {
      await BasePreferences.getInstance()
          .setInt("dot-sync-current-version", maxVersion);
    }
  }

  Future<bool> consume(Response response, [bool snapshot = false]) async {
    if (response.statusCode == 200) {
      Map<String, dynamic> json = Map<String, dynamic>.from(response.data);

      int currentVersion = json["currentVersion"];
      List<Map<String, dynamic>> changes = _prioritizeDynamicTableMetadata(
        List<Map<String, dynamic>>.from(json["changes"]),
      );

      Database database = await Sqlites.get();

      Set<String> entitiesSeen = {};

      return await database.transaction((txn) async {
        for (int i = 0; i < changes.length; i++) {
          Map<String, dynamic> change = changes[i];

          String entity = change["entity"];

          entitiesSeen.add(entity);

          Map<String, dynamic> payload =
              Map<String, dynamic>.from(change["payload"]);

          List<Map<String, dynamic>> tableInfos =
              await getTableInfos(txn, entity);

          await process(txn, entity, payload, tableInfos);

          _entityCounts[entity] = (_entityCounts[entity] ?? 0) + 1;
          updateStatus(((i + 1) / changes.length * 100).toInt());
        }

        await BasePreferences.getInstance().setInt("dot-sync-current-version", currentVersion);

        if (snapshot) {
          // Every entity a snapshot handed us data for is, by definition,
          // fully current as of currentVersion (the same monotonic
          // sequence master_versions/pull-v2 use) - seeding each one's
          // per-entity high-water mark here is what lets the very next
          // pull-v2 call ask "what's new since currentVersion" per entity
          // instead of re-requesting everything the snapshot just gave us.
          await saveSyncVersions(
            txn,
            {for (String entity in entitiesSeen) entity: currentVersion},
          );
        }

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

  // pull-v2's response shape differs from consume()'s (per-entity `versions`
  // instead of one global `currentVersion`, plus `hasMore`) so it gets its
  // own parser rather than overloading consume() - the actual row-applying
  // logic (process()/getTableInfos()) is unchanged and fully reused.
  Future<(bool success, bool hasMore)> consumeV2(Response response) async {
    if (response.statusCode == 200) {
      Map<String, dynamic> json = Map<String, dynamic>.from(response.data);

      Map<String, int> versions = Map<String, dynamic>.from(json["versions"] ?? {})
          .map((key, value) => MapEntry(key, (value as num).toInt()));
      List<Map<String, dynamic>> changes = _prioritizeDynamicTableMetadata(
        List<Map<String, dynamic>>.from(json["changes"] ?? []),
      );
      bool hasMore = json["hasMore"] == true;

      if (versions.isEmpty && changes.isEmpty) {
        return (true, false);
      }

      Database database = await Sqlites.get();

      bool success = await database.transaction((txn) async {
        for (int i = 0; i < changes.length; i++) {
          Map<String, dynamic> change = changes[i];

          String entity = change["entity"];

          Map<String, dynamic> payload =
              Map<String, dynamic>.from(change["payload"]);

          List<Map<String, dynamic>> tableInfos =
              await getTableInfos(txn, entity);

          await process(txn, entity, payload, tableInfos);

          _entityCounts[entity] = (_entityCounts[entity] ?? 0) + 1;
          updateStatus(((i + 1) / changes.length * 100).toInt());
        }

        await saveSyncVersions(txn, versions);

        return true;
      }).onError((error, stackTrace) async {
        print("e: $error | s: $stackTrace");

        return false;
      });

      return (success, hasMore);
    } else if (response.statusCode == 204) {
      print("Sync version is up to date");

      return (true, false);
    } else {
      return (false, false);
    }
  }

  // Neither master_versions (pull-v2's source) nor the pre-baked offline
  // snapshot guarantee that f_dynamic_table/f_dynamic_table_detail (a
  // dynamic form's table definition) appears before a row of actual DATA
  // for that same table within one batch - their query/generation order
  // isn't tied to entity dependency. process() can only recognize a
  // dynamic table once its own metadata has been inserted locally; if a
  // data row is processed first, tableInfos comes back empty, the row is
  // silently skipped, and the per-entity version watermark still advances
  // past it - the server then never resends it. Moving metadata entities
  // to the front of the batch (stable otherwise) removes that race.
  List<Map<String, dynamic>> _prioritizeDynamicTableMetadata(
    List<Map<String, dynamic>> changes,
  ) {
    const List<String> metadataEntities = [
      "f_dynamic_table",
      "f_dynamic_table_detail",
    ];

    List<Map<String, dynamic>> metadata = [];
    List<Map<String, dynamic>> rest = [];

    for (Map<String, dynamic> change in changes) {
      if (metadataEntities.contains(change["entity"])) {
        metadata.add(change);
      } else {
        rest.add(change);
      }
    }

    return [...metadata, ...rest];
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
            await process(transaction, entry.key, detailPayload, detailTableInfos);
          }
        }
      }

      if (tableName == "c_segment_report") {
        await handleSegmentReport(transaction, payload);
      }

      if (tableName == "f_dynamic_table") {
        // getTableInfos() otherwise only ever creates a dynamic-form's
        // local data table lazily, the first time a row of actual DATA
        // for it shows up in a pull (process() calling getTableInfos() for
        // the entry key of a nested List payload). A table whose metadata
        // (this row + its just-processed f_dynamic_table_detail children,
        // above) has synced but which happens to have zero rows so far -
        // entirely possible, e.g. a brand new form, or one scoped down to
        // nothing by pull-v2's row-level access filtering - would then
        // never get its local table created at all, and any later query
        // against it (e.g. opening the form's list page) fails with
        // "no such table". Table metadata alone is enough to create an
        // empty table, so do it as soon as the metadata itself is known,
        // not gated on data existing.
        String? dataTableName = payload["table_name"] as String?;

        if (dataTableName != null && dataTableName.isNotEmpty) {
          await getTableInfos(transaction, dataTableName);
        }
      }
    }
  }

  // For use OUTSIDE the pull/sync flow (no active transaction) - e.g. right
  // before Offlines queries a dynamic form's table directly. A table can
  // legitimately have synced f_dynamic_table metadata but zero rows (a
  // brand new form, or one whose rows are all filtered out of this
  // device's pull-v2 scope) - getTableInfos() during a pull only ever
  // creates the table reactively when an actual data row shows up (see the
  // f_dynamic_table hook in process() above), so without this, querying an
  // as-yet-dataless form's list page throws "no such table". Safe/cheap to
  // call on every query - PRAGMA table_info is a no-op lookup when the
  // table already exists.
  Future<void> ensureTableExists(String tableName) async {
    Database database = await Sqlites.get();

    await database.transaction((txn) async {
      await getTableInfos(txn, tableName);
    });
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
          "CREATE TABLE $tableName ( ${columns.toSet().map((column) => '"$column" TEXT ${column == pkColumn ? "PRIMARY KEY" : ""}').join(", ")} )",
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
    String convertedQuery = "";

    try {
      final converter = PgToSqliteConverter();

      convertedQuery = converter.convert(payload["segment_report_query"]);

      await transaction.execute(
        "CREATE VIEW IF NOT EXISTS ${payload["view_name"]} AS $convertedQuery",
      );
    } catch (e, s) {
      if (kDebugMode) {
        print("Caught Exception: $e");
        print("Stack Trace:\n$s");
      }

      await logSegmentReportError(
        transaction: transaction,
        payload: payload,
        convertedQuery: convertedQuery,
        error: e,
        stackTrace: s,
      );
    }
  }

  // Segment report views come from a per-company/admin-authored Postgres
  // query converted to SQLite at pull time (PgToSqliteConverter), so failures
  // here are query-compatibility issues an admin needs to fix, not something
  // a user can act on - only debug-printing them left no way to identify
  // which segment report broke or why after the fact. Persisted into its own
  // table (lazily created here, same as getTableInfos does for dynamic-form
  // tables, since the DB schema is pinned at version 1 with no onUpgrade -
  // sqlites.dart's onCreate list never runs again for already-installed
  // users). Failure to log is swallowed so a broken log write can never take
  // down the sync transaction it's trying to diagnose.
  Future<void> logSegmentReportError({
    required Transaction transaction,
    required Map<String, dynamic> payload,
    required String convertedQuery,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    try {
      await transaction.execute(
        "CREATE TABLE IF NOT EXISTS _segment_report_errors ( id TEXT PRIMARY KEY, segment_report_id TEXT, segment_report_name TEXT, view_name TEXT, segment_report_query TEXT, converted_query TEXT, error_message TEXT, stack_trace TEXT, create_date TEXT )",
      );

      await transaction.insert("_segment_report_errors", {
        "id": Uuid().v4(),
        "segment_report_id": payload["id"]?.toString(),
        "segment_report_name": payload["segment_report_name"],
        "view_name": payload["view_name"],
        "segment_report_query": payload["segment_report_query"],
        "converted_query": convertedQuery,
        "error_message": error.toString(),
        "stack_trace": stackTrace.toString(),
        "create_date": DateTime.now().toIso8601String(),
      });
    } catch (e, s) {
      if (kDebugMode) {
        print("Caught Exception while logging segment report error: $e");
        print("Stack Trace:\n$s");
      }
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

    statusNotifier = ValueNotifier(const PullProgressSnapshot());

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

    statusNotifier!.value = PullProgressSnapshot(
      status: status,
      batch: _currentBatch,
      entityCounts: Map<String, int>.unmodifiable(_entityCounts),
    );

    if (autoCloseAfter != null) {
      Future.delayed(autoCloseAfter, () => hide());
    }
  }
}

class OverlayContent extends StatefulWidget {
  final ValueNotifier<PullProgressSnapshot> statusNotifier;
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

  void showDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.size20),
        ),
      ),
      builder: (context) =>
          PullProgressDetailSheet(statusNotifier: widget.statusNotifier),
    );
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
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: ValueListenableBuilder<PullProgressSnapshot>(
                valueListenable: widget.statusNotifier,
                builder: (context, snapshot, child) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: snapshot.status == 101 ? null : showDetail,
                    child: AnimatedProgressDot(
                      snapshot: snapshot,
                      pulseFade: pulseFade,
                      pulseScale: pulseScale,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedProgressDot extends StatelessWidget {
  final PullProgressSnapshot snapshot;
  final Animation<double> pulseFade;
  final Animation<double> pulseScale;

  const AnimatedProgressDot({
    required this.snapshot,
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
      child: buildChild(),
    );
  }

  Widget buildChild() {
    if (snapshot.status == 101) {
      return const SizedBox.shrink(key: ValueKey("completed"));
    }

    final bool isError = snapshot.status == -1;
    final Color accentColor =
        isError ? const Color(0xFFD64545) : const Color(0xFF14B8A6);
    // A batch's own 0-100 progress - real/determinate within that batch,
    // but it resets each time execute() starts a new pull-v2 batch (see
    // PullProgressSnapshot's comment), so null (no row applied yet this
    // batch) falls back to an indeterminate spin rather than a fake 0%.
    final double? progressValue =
        (!isError && snapshot.status != null) ? snapshot.status! / 100 : null;

    return FadeTransition(
      key: ValueKey(isError ? "error-ring" : "progress-ring"),
      opacity: isError ? const AlwaysStoppedAnimation(1) : pulseFade,
      child: ScaleTransition(
        scale: isError ? const AlwaysStoppedAnimation(1) : pulseScale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: Dimensions.size10,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(Dimensions.size5),
            child: SizedBox(
              width: Dimensions.size20,
              height: Dimensions.size20,
              child: isError
                  ? Icon(
                      Icons.priority_high_rounded,
                      size: Dimensions.text14,
                      color: accentColor,
                    )
                  : CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 2.5,
                      color: accentColor,
                      backgroundColor: accentColor.withValues(alpha: 0.15),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tap target for AnimatedProgressDot - a plain Material bottom sheet (no
// visitqu/glass-specific styling, since this package is host-app-agnostic)
// showing the current batch's progress plus a running tally of what's been
// applied so far this execute() cycle, grouped by entity.
class PullProgressDetailSheet extends StatelessWidget {
  final ValueNotifier<PullProgressSnapshot> statusNotifier;

  const PullProgressDetailSheet({
    required this.statusNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(Dimensions.size20),
        child: ValueListenableBuilder<PullProgressSnapshot>(
          valueListenable: statusNotifier,
          builder: (context, snapshot, child) {
            final bool isError = snapshot.status == -1;
            final bool isDone = snapshot.status == 101;

            final List<MapEntry<String, int>> entries =
                snapshot.entityCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

            final int totalRows =
                snapshot.entityCounts.values.fold(0, (a, b) => a + b);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status Sinkronisasi",
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: Dimensions.size15),
                if (isError)
                  Text(
                    "Sinkronisasi gagal, akan dicoba lagi.",
                    style: TextStyle(color: const Color(0xFFD64545)),
                  )
                else if (isDone)
                  const Text("Sinkronisasi selesai.")
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.size5),
                    child: LinearProgressIndicator(
                      value:
                          snapshot.status != null ? snapshot.status! / 100 : null,
                      minHeight: Dimensions.size5,
                      color: const Color(0xFF14B8A6),
                      backgroundColor:
                          const Color(0xFF14B8A6).withValues(alpha: 0.15),
                    ),
                  ),
                  SizedBox(height: Dimensions.size10),
                  Text(
                    snapshot.batch > 0
                        ? "Batch ${snapshot.batch} • ${snapshot.status ?? 0}%"
                        : "Mengunduh data awal...",
                    style: TextStyle(fontSize: Dimensions.text12),
                  ),
                ],
                SizedBox(height: Dimensions.size20),
                Text(
                  totalRows > 0
                      ? "Data terunduh ($totalRows baris)"
                      : "Data terunduh",
                  style: TextStyle(
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Dimensions.size10),
                if (entries.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.size10),
                    child: const Text("Belum ada data yang diproses."),
                  )
                else
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: Dimensions.size10),
                        itemBuilder: (context, index) {
                          final MapEntry<String, int> entry = entries[index];

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                entry.value.toString(),
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
