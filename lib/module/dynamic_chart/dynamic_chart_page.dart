// ignore_for_file: deprecated_member_use

import "dart:convert";
import "dart:math" as math;

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/chart_model.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/chart_helper.dart";
import "package:dynamic_of_things/helper/dynamic_chart_data_helper.dart";
import "package:dynamic_of_things/helper/generals.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/model/window_model.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_desktop_window.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:dynamic_of_things/widget/chart_card.dart";
import "package:dynamic_of_things/widget/dynamic_chart_app_bar.dart";
import "package:dynamic_of_things/widget/dynamic_summary_card.dart";
import "package:dynamic_of_things/widget/loading_card.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:jiffy/jiffy.dart";
import "package:loader_overlay/loader_overlay.dart";

class DynamicChartPage extends StatefulWidget {
  const DynamicChartPage({super.key});

  @override
  DynamicChartPageState createState() => DynamicChartPageState();
}

class DynamicChartPageState extends State<DynamicChartPage>
    with WidgetsBindingObserver {
  ListResponse? listResponse;
  bool prefsReady = false;
  List<String> chartOrder = <String>[];
  String? draggingChartId;
  String? dragTargetChartId;
  bool floatingDesktopMode = false;
  Map<String, DynamicChartDesktopWindowLayout> desktopWindowLayouts =
      <String, DynamicChartDesktopWindowLayout>{};
  Set<String> hiddenDesktopPanels = <String>{};
  Map<String, dynamic> chartDataCache = <String, dynamic>{};
  final ValueNotifier<int> desktopDragNotifier = ValueNotifier<int>(0);

  final RangePreset preset = RangePreset.last7;
  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPrefs();
    refresh();
  }

  @override
  void dispose() {
    desktopDragNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    setState(() {});
  }

  void refresh() {
    context.read<DynamicChartBloc>().add(DynamicChartLoad());
  }

  ButtonStyle desktopToolbarButtonStyle(
    BuildContext context, {
    required bool glass,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton.styleFrom(
      foregroundColor:
          glass ? Colors.white.withOpacity(0.94) : colorScheme.onSurface,
      iconColor: glass ? Colors.white.withOpacity(0.94) : colorScheme.onSurface,
      backgroundColor:
          glass ? Colors.white.withOpacity(0.04) : colorScheme.surface,
      side: BorderSide(
        color: glass
            ? Colors.white.withOpacity(0.18)
            : colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size15,
      ),
      textStyle: TextStyle(
        fontSize: Dimensions.text12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Future<void> initPrefs() async {
    try {
      await Preferences.getInstance().init();
    } catch (_) {
      return;
    }

    prefsReady = true;
    final DynamicChartSavedLayoutPayload? savedPayload =
        readCurrentDesktopLayoutPayload();

    if (!mounted) {
      return;
    }

    setState(() {
      chartOrder = savedPayload?.widgetOrder ?? readSavedChartOrder();
      floatingDesktopMode =
          savedPayload?.floatingMode ?? readFloatingDesktopMode();
      desktopWindowLayouts =
          savedPayload?.layoutsMap ?? readSavedDesktopWindowLayouts();
      hiddenDesktopPanels = savedPayload != null
          ? savedPayload.hiddenWidgetIds.toSet()
          : readHiddenDesktopPanels();
    });
  }

  int dashboardUiType() {
    return isGlass ? 2 : 1;
  }

  List<String> readSavedChartOrder() {
    if (!prefsReady) {
      return <String>[];
    }

    try {
      final String? raw = Preferences.getInstance().getStringDynamicForm(
        chartOrderPreferenceKey(),
      );
      if (raw == null || raw.isEmpty) {
        return <String>[];
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((dynamic item) => item.toString()).toList();
      }
    } catch (_) {}

    return <String>[];
  }

  bool readFloatingDesktopMode() {
    if (!prefsReady) {
      return false;
    }

    try {
      final String? raw = Preferences.getInstance().getStringDynamicForm(
        floatingDesktopModePreferenceKey(),
      );
      if (raw == null || raw.isEmpty) {
        return false;
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is bool) {
        return decoded;
      }
      if (decoded is num) {
        return decoded != 0;
      }
      if (decoded is String) {
        final String normalized = decoded.trim().toLowerCase();
        return normalized == "true" || normalized == "1";
      }
    } catch (_) {}

    return false;
  }

  DynamicChartSavedLayoutPayload? readCurrentDesktopLayoutPayload() {
    if (!prefsReady) {
      return null;
    }

    final String? raw = Preferences.getInstance().getStringDynamicForm(
      desktopWindowLayoutPreferenceKey(),
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return decodeDesktopSavedLayoutPayload(raw);
    } catch (_) {
      return null;
    }
  }

  Set<String> readHiddenDesktopPanels() {
    if (!prefsReady) {
      return <String>{};
    }

    try {
      final String? raw = Preferences.getInstance().getStringDynamicForm(
        hiddenDesktopPanelPreferenceKey(),
      );
      if (raw == null || raw.isEmpty) {
        return <String>{};
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }

      return decoded.map((dynamic item) => item.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  List<String> resolvedChartOrderIds(List<Chart> charts) {
    final List<String> availableIds =
        charts.map((Chart chart) => chart.id).toList();
    final List<String> baseOrder =
        chartOrder.isNotEmpty ? chartOrder : readSavedChartOrder();
    final List<String> resolved = <String>[];

    for (final String id in baseOrder) {
      if (availableIds.contains(id) && !resolved.contains(id)) {
        resolved.add(id);
      }
    }

    for (final String id in availableIds) {
      if (!resolved.contains(id)) {
        resolved.add(id);
      }
    }

    return resolved;
  }

  void syncChartOrder(List<Chart> charts) {
    chartOrder = resolvedChartOrderIds(charts);
    persistChartOrder();
  }

  Future<void> persistChartOrder() async {
    if (!prefsReady) {
      return;
    }

    try {
      await Preferences.getInstance().setStringDynamicForm(
        chartOrderPreferenceKey(),
        jsonEncode(chartOrder),
      );
      await persistCurrentDesktopLayoutPayload();
    } catch (_) {}
  }

  Future<void> persistDesktopWindowLayouts() async {
    if (!prefsReady) {
      return;
    }

    try {
      await persistCurrentDesktopLayoutPayload();
    } catch (_) {}
  }

  Future<void> persistFloatingDesktopMode() async {
    if (!prefsReady) {
      return;
    }

    try {
      await Preferences.getInstance().setStringDynamicForm(
        floatingDesktopModePreferenceKey(),
        jsonEncode(floatingDesktopMode),
      );
      await persistCurrentDesktopLayoutPayload();
    } catch (_) {}
  }

  Future<void> persistHiddenDesktopPanels() async {
    if (!prefsReady) {
      return;
    }

    try {
      await Preferences.getInstance().setStringDynamicForm(
        hiddenDesktopPanelPreferenceKey(),
        jsonEncode(hiddenDesktopPanels.toList()..sort()),
      );
      await persistCurrentDesktopLayoutPayload();
    } catch (_) {}
  }

  DynamicChartSavedLayoutPayload buildDesktopSavedLayoutPayload({
    required Map<String, DynamicChartDesktopWindowLayout> layouts,
    String? layoutName,
  }) {
    final List<DynamicChartDesktopWindowLayout> ordered =
        layouts.values.toList()..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return DynamicChartSavedLayoutPayload(
      version: 3,
      name: layoutName?.trim() ?? "",
      userId: currentLayoutUserId(),
      username: currentLayoutUsername(),
      savedAt: DateTime.now().toIso8601String(),
      dashboardUiType: dashboardUiType(),
      floatingMode: floatingDesktopMode,
      desktopNavigationVisible: true,
      widgetOrder: List<String>.from(chartOrder),
      hiddenWidgetIds: hiddenDesktopPanels.toList()..sort(),
      windows: ordered,
    );
  }

  DynamicChartSavedLayoutPayload decodeDesktopSavedLayoutPayload(
    dynamic source, {
    String? legacyName,
  }) {
    dynamic decoded = source;

    if (decoded is String) {
      decoded = jsonDecode(decoded);
    }

    if (decoded is List) {
      decoded = <String, dynamic>{
        "version": 3,
        "name": legacyName ?? "",
        "userId": currentLayoutUserId(),
        "username": currentLayoutUsername(),
        "savedAt": DateTime.now().toIso8601String(),
        "dashboardUiType": dashboardUiType(),
        "floatingMode": floatingDesktopMode,
        "desktopNavigationVisible": true,
        "widgetOrder": chartOrder,
        "hiddenWidgetIds": hiddenDesktopPanels.toList(),
        "windows": decoded,
      };
    }

    if (decoded is! Map) {
      throw const FormatException("Invalid desktop layout payload");
    }

    final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
    map["version"] ??= 3;
    map["name"] = (map["name"] ?? legacyName ?? "").toString();
    map["userId"] =
        (map["userId"] ?? map["ownerId"] ?? currentLayoutUserId()).toString();
    map["username"] =
        (map["username"] ?? map["ownerName"] ?? currentLayoutUsername())
            .toString();
    map["savedAt"] =
        (map["savedAt"] ?? DateTime.now().toIso8601String()).toString();
    map["dashboardUiType"] = map["dashboardUiType"] ?? dashboardUiType();
    map["floatingMode"] = map["floatingMode"] ?? floatingDesktopMode;
    map["desktopNavigationVisible"] = map["desktopNavigationVisible"] ?? true;
    map["widgetOrder"] =
        map["widgetOrder"] is List ? map["widgetOrder"] : const <dynamic>[];
    map["hiddenWidgetIds"] = map["hiddenWidgetIds"] is List
        ? map["hiddenWidgetIds"]
        : const <dynamic>[];
    map["windows"] =
        map["windows"] is List ? map["windows"] : const <dynamic>[];

    return DynamicChartSavedLayoutPayload.fromJson(map);
  }

  Future<void> persistCurrentDesktopLayoutPayload({
    Map<String, DynamicChartDesktopWindowLayout>? layouts,
    String? layoutName,
  }) async {
    if (!prefsReady) {
      return;
    }

    final DynamicChartSavedLayoutPayload payload =
        buildDesktopSavedLayoutPayload(
      layouts: layouts ?? desktopWindowLayouts,
      layoutName: layoutName,
    );

    await Preferences.getInstance().setStringDynamicForm(
      desktopWindowLayoutPreferenceKey(),
      jsonEncode(payload.toJson()),
    );
  }

  List<DynamicChartSavedLayoutPayload> readSavedDesktopLayouts() {
    if (!prefsReady) {
      return <DynamicChartSavedLayoutPayload>[];
    }

    final String? raw = Preferences.getInstance().getStringDynamicForm(
      savedLayoutsListPreferenceKey(),
    );
    if (raw == null || raw.isEmpty) {
      return <DynamicChartSavedLayoutPayload>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      final List<DynamicChartSavedLayoutPayload> layouts =
          <DynamicChartSavedLayoutPayload>[];

      if (decoded is List) {
        for (final dynamic item in decoded) {
          if (item is! Map) {
            continue;
          }
          layouts.add(decodeDesktopSavedLayoutPayload(item));
        }
      } else if (decoded is Map && decoded["layouts"] is List) {
        for (final dynamic item in decoded["layouts"] as List<dynamic>) {
          if (item is! Map) {
            continue;
          }
          layouts.add(decodeDesktopSavedLayoutPayload(item));
        }
      } else if (decoded is Map) {
        for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
          try {
            layouts.add(
              decodeDesktopSavedLayoutPayload(
                entry.value,
                legacyName: entry.key.toString(),
              ),
            );
          } catch (_) {}
        }
      }

      layouts.sort((
        DynamicChartSavedLayoutPayload a,
        DynamicChartSavedLayoutPayload b,
      ) {
        final DateTime aTime =
            a.savedAtDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.savedAtDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return layouts;
    } catch (_) {
      return <DynamicChartSavedLayoutPayload>[];
    }
  }

  Future<void> writeSavedDesktopLayouts(
    List<DynamicChartSavedLayoutPayload> layouts,
  ) async {
    await Preferences.getInstance().setStringDynamicForm(
      savedLayoutsListPreferenceKey(),
      jsonEncode(<String, dynamic>{
        "version": 1,
        "layouts": layouts.map((DynamicChartSavedLayoutPayload item) {
          return item.toJson();
        }).toList(),
      }),
    );
  }

  String formatSavedLayoutDate(DynamicChartSavedLayoutPayload payload) {
    final DateTime? savedAt = payload.savedAtDateTime;
    if (savedAt == null) {
      return "-";
    }

    return Jiffy.parseFromDateTime(savedAt).format(pattern: "d MMM yyyy HH:mm");
  }

  String savedLayoutMetaLine(DynamicChartSavedLayoutPayload payload) {
    final List<String> parts = <String>[
      payload.userId,
      payload.floatingMode ? "Floating" : "Fixed",
      payload.themeLabel,
    ].where((String item) => item.trim().isNotEmpty).toList();

    return parts.join(" • ");
  }

  Future<void> deleteSavedDesktopLayout(String layoutName) async {
    final List<DynamicChartSavedLayoutPayload> savedLayouts =
        readSavedDesktopLayouts()
          ..removeWhere((DynamicChartSavedLayoutPayload item) {
            return item.name.trim().toLowerCase() ==
                layoutName.trim().toLowerCase();
          });

    await writeSavedDesktopLayouts(savedLayouts);
  }

  Future<void> saveDesktopWindowLayouts(
    Map<String, DynamicChartDesktopWindowLayout> layouts, {
    String? layoutName,
  }) async {
    final DynamicChartSavedLayoutPayload payload =
        buildDesktopSavedLayoutPayload(
      layouts: layouts,
      layoutName: layoutName,
    );
    final String layoutJson = jsonEncode(payload.toJson());
    final Map<String, DynamicChartDesktopWindowLayout> orderedLayouts =
        payload.layoutsMap;

    if (layoutName != null && layoutName.trim().isNotEmpty) {
      final List<DynamicChartSavedLayoutPayload> savedLayouts =
          readSavedDesktopLayouts()
            ..removeWhere((DynamicChartSavedLayoutPayload item) {
              return item.name.trim().toLowerCase() ==
                  layoutName.trim().toLowerCase();
            })
            ..insert(0, payload);
      await writeSavedDesktopLayouts(savedLayouts);
    }

    await Preferences.getInstance().setStringDynamicForm(
      desktopWindowLayoutPreferenceKey(),
      layoutJson,
    );
    await Preferences.getInstance().setStringDynamicForm(
      chartOrderPreferenceKey(),
      jsonEncode(chartOrder),
    );
    await Preferences.getInstance().setStringDynamicForm(
      floatingDesktopModePreferenceKey(),
      jsonEncode(floatingDesktopMode),
    );
    await Preferences.getInstance().setStringDynamicForm(
      hiddenDesktopPanelPreferenceKey(),
      jsonEncode(hiddenDesktopPanels.toList()..sort()),
    );

    if (!mounted) {
      desktopWindowLayouts = orderedLayouts;
      return;
    }

    setState(() {
      desktopWindowLayouts = orderedLayouts;
      desktopDragNotifier.value++;
    });

    await BaseOverlays.success(
      message: layoutName != null && layoutName.trim().isNotEmpty
          ? "Layout '$layoutName' berhasil disimpan."
          : "Layout desktop berhasil disimpan.",
    );
  }

  Future<void> showSaveLayoutDialog(
    Map<String, DynamicChartDesktopWindowLayout> layouts,
  ) async {
    final TextEditingController nameController = TextEditingController();
    final bool glass = isGlass;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: glass
              ? Colors.white.withOpacity(0.1)
              : (dark ? AppColors.surfaceContainerHigh() : Colors.white),
          elevation: glass ? 0 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.size20),
            side: glass
                ? BorderSide(color: Colors.white.withOpacity(0.2))
                : BorderSide.none,
          ),
          title: Text(
            "Simpan Layout",
            style: TextStyle(
              color:
                  glass ? Colors.white : (dark ? Colors.white : Colors.black),
            ),
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(
              color:
                  glass ? Colors.white : (dark ? Colors.white : Colors.black),
            ),
            decoration: InputDecoration(
              hintText: "Nama layout (contoh: Dynamic Sales)",
              hintStyle: TextStyle(
                color: glass
                    ? Colors.white54
                    : (dark ? Colors.white54 : Colors.black54),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(nameController.text),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      await saveDesktopWindowLayouts(layouts, layoutName: result);
    }
  }

  Future<void> applyDesktopLayoutJson(
    String layoutJson, {
    String? layoutName,
  }) async {
    final DynamicChartSavedLayoutPayload payload =
        decodeDesktopSavedLayoutPayload(layoutJson, legacyName: layoutName);
    final Map<String, DynamicChartDesktopWindowLayout> loadedLayouts =
        payload.layoutsMap;
    final Set<String> loadedHiddenPanels = payload.hiddenWidgetIds.toSet();
    final List<String> loadedChartOrder = payload.widgetOrder;

    await Preferences.getInstance().setStringDynamicForm(
      desktopWindowLayoutPreferenceKey(),
      jsonEncode(payload.toJson()),
    );
    await Preferences.getInstance().setStringDynamicForm(
      chartOrderPreferenceKey(),
      jsonEncode(loadedChartOrder),
    );
    await Preferences.getInstance().setStringDynamicForm(
      floatingDesktopModePreferenceKey(),
      jsonEncode(payload.floatingMode),
    );
    await Preferences.getInstance().setStringDynamicForm(
      hiddenDesktopPanelPreferenceKey(),
      jsonEncode(loadedHiddenPanels.toList()..sort()),
    );

    if (mounted) {
      setState(() {
        floatingDesktopMode = payload.floatingMode;
        chartOrder = loadedChartOrder;
        hiddenDesktopPanels = loadedHiddenPanels;
        desktopWindowLayouts = loadedLayouts;
        desktopDragNotifier.value++;
      });
    } else {
      floatingDesktopMode = payload.floatingMode;
      chartOrder = loadedChartOrder;
      hiddenDesktopPanels = loadedHiddenPanels;
      desktopWindowLayouts = loadedLayouts;
    }

    await BaseOverlays.success(
      message: layoutName != null && layoutName.isNotEmpty
          ? "Layout '$layoutName' dimuat."
          : "Layout desktop dimuat.",
    );
  }

  Future<void> showLoadLayoutDialog() async {
    final List<DynamicChartSavedLayoutPayload> savedLayouts =
        readSavedDesktopLayouts();
    final bool glass = isGlass;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    if (savedLayouts.isEmpty) {
      BaseOverlays.error(message: "Belum ada layout yang disimpan.");
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final Color foregroundColor =
            glass ? Colors.white : (dark ? Colors.white : Colors.black87);
        final Color secondaryColor =
            glass ? Colors.white70 : AppColors.onSurfaceVariant();
        final Color backgroundColor = glass
            ? Colors.white.withOpacity(0.08)
            : (dark ? AppColors.surfaceContainerHigh() : Colors.white);
        final Color cardColor = glass
            ? Colors.white.withOpacity(0.07)
            : (dark
                ? AppColors.surfaceContainer()
                : AppColors.surfaceContainerLowest());
        final Color borderColor = glass
            ? Colors.white.withOpacity(0.16)
            : AppColors.surfaceContainerHighest();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Dimensions.size20,
            vertical: Dimensions.size25,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(Dimensions.size25),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(glass ? 0.18 : 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: glass
                      ? <Color>[
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ]
                      : <Color>[
                          backgroundColor,
                          cardColor,
                        ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size20,
                  Dimensions.size20,
                  Dimensions.size20,
                  Dimensions.size15,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: Dimensions.size45,
                          height: Dimensions.size45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              Dimensions.size15,
                            ),
                            color: glass
                                ? Colors.white.withOpacity(0.12)
                                : AppColors.primary().withOpacity(0.10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.layers_rounded,
                            color: glass
                                ? Colors.white
                                : AppColors.primary().withOpacity(0.90),
                            size: Dimensions.size25,
                          ),
                        ),
                        SizedBox(width: Dimensions.size15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Load layout",
                                style: TextStyle(
                                  color: foregroundColor,
                                  fontSize: Dimensions.text18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: Dimensions.size5),
                              Text(
                                "Pilih susunan panel yang ingin dipakai lagi.",
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: Dimensions.text12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.size20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: savedLayouts.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: Dimensions.size10),
                        itemBuilder: (context, index) {
                          final DynamicChartSavedLayoutPayload payload =
                              savedLayouts[index];
                          final String title = payload.name.trim().isEmpty
                              ? "Layout tanpa nama"
                              : payload.name.trim();

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                Dimensions.size20,
                              ),
                              onTap: () async {
                                Navigator.of(context).pop();
                                await applyDesktopLayoutJson(
                                  jsonEncode(payload.toJson()),
                                  layoutName: payload.name,
                                );
                              },
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.size20,
                                  ),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 0.8,
                                  ),
                                ),
                                padding: EdgeInsets.all(Dimensions.size15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: foregroundColor,
                                              fontSize: Dimensions.text14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(
                                            height: Dimensions.size5,
                                          ),
                                          Text(
                                            savedLayoutMetaLine(payload),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: secondaryColor,
                                              fontSize: Dimensions.text11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(
                                            height: Dimensions.size4,
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: Dimensions.size15,
                                                color: secondaryColor,
                                              ),
                                              SizedBox(
                                                width: Dimensions.size5,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  formatSavedLayoutDate(
                                                    payload,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: secondaryColor,
                                                    fontSize: Dimensions.text11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: Dimensions.size10),
                                    IconButton(
                                      tooltip: "Hapus layout",
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await deleteSavedDesktopLayout(
                                          payload.name,
                                        );
                                        await BaseOverlays.success(
                                          message:
                                              "Layout '${payload.name}' dihapus.",
                                        );
                                      },
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: secondaryColor,
                                      ),
                                    ),
                                    Container(
                                      width: Dimensions.size35,
                                      height: Dimensions.size35,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.size15,
                                        ),
                                        color: glass
                                            ? Colors.white.withOpacity(0.12)
                                            : AppColors.primary().withOpacity(
                                                0.10,
                                              ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: Dimensions.size20,
                                        color: glass
                                            ? Colors.white
                                            : AppColors.primary(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: Dimensions.size15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Tutup"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> showHiddenPanelsDialog({
    required List<DynamicChartDesktopPanelDescriptor> hiddenPanels,
    required bool glass,
  }) async {
    if (hiddenPanels.isEmpty) {
      return;
    }

    final bool dark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final Color foregroundColor =
            glass ? Colors.white : (dark ? Colors.white : Colors.black87);
        final Color secondaryColor =
            glass ? Colors.white70 : AppColors.onSurfaceVariant();
        final Color backgroundColor = glass
            ? Colors.white.withOpacity(0.08)
            : (dark ? AppColors.surfaceContainerHigh() : Colors.white);
        final Color cardColor = glass
            ? Colors.white.withOpacity(0.07)
            : (dark
                ? AppColors.surfaceContainer()
                : AppColors.surfaceContainerLowest());
        final Color borderColor = glass
            ? Colors.white.withOpacity(0.16)
            : AppColors.surfaceContainerHighest();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Dimensions.size20,
            vertical: Dimensions.size25,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(Dimensions.size25),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(glass ? 0.18 : 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: glass
                      ? <Color>[
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ]
                      : <Color>[
                          backgroundColor,
                          cardColor,
                        ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size20,
                  Dimensions.size20,
                  Dimensions.size20,
                  Dimensions.size15,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: Dimensions.size45,
                          height: Dimensions.size45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              Dimensions.size15,
                            ),
                            color: glass
                                ? Colors.white.withOpacity(0.12)
                                : AppColors.primary().withOpacity(0.10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_chart_rounded,
                            color: glass
                                ? Colors.white
                                : AppColors.primary().withOpacity(0.90),
                            size: Dimensions.size25,
                          ),
                        ),
                        SizedBox(width: Dimensions.size15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tambah widget",
                                style: TextStyle(
                                  color: foregroundColor,
                                  fontSize: Dimensions.text18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: Dimensions.size5),
                              Text(
                                "Pilih panel yang ingin ditampilkan lagi.",
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: Dimensions.text12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.size20),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final int columns = constraints.maxWidth >= 500
                            ? 3
                            : constraints.maxWidth >= 320
                                ? 2
                                : 1;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 420),
                          child: GridView.builder(
                            shrinkWrap: true,
                            itemCount: hiddenPanels.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: Dimensions.size10,
                              mainAxisSpacing: Dimensions.size10,
                              childAspectRatio: 1.15,
                            ),
                            itemBuilder: (context, index) {
                              final DynamicChartDesktopPanelDescriptor panel =
                                  hiddenPanels[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.size20,
                                  ),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await showDesktopWindow(panel.id);
                                  },
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.size20,
                                      ),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 0.8,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(Dimensions.size15),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: Dimensions.size40,
                                          height: Dimensions.size40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.size10,
                                            ),
                                            color: glass
                                                ? Colors.white.withOpacity(0.12)
                                                : AppColors.primary()
                                                    .withOpacity(0.10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            panel.icon,
                                            color: glass
                                                ? Colors.white
                                                : AppColors.primary(),
                                            size: Dimensions.size20,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          panel.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: foregroundColor,
                                            fontSize: Dimensions.text13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: Dimensions.size5),
                                        Text(
                                          "Tampilkan kembali",
                                          style: TextStyle(
                                            color: secondaryColor,
                                            fontSize: Dimensions.text11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: Dimensions.size15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Tutup"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> setFloatingDesktopMode(bool value) async {
    if (floatingDesktopMode == value) {
      return;
    }

    setState(() {
      floatingDesktopMode = value;
    });
    await persistFloatingDesktopMode();
  }

  List<Chart> orderedCharts(List<Chart> charts) {
    final List<String> resolved = resolvedChartOrderIds(charts);
    final Map<String, Chart> chartMap = <String, Chart>{
      for (final Chart chart in charts) chart.id: chart,
    };

    return resolved
        .map((String id) => chartMap[id])
        .whereType<Chart>()
        .toList();
  }

  bool shouldRenderChart(Chart chart) {
    if (chart is! Summary) {
      return true;
    }

    if (!chartDataCache.containsKey(chart.id)) {
      return true;
    }

    return parseSummarySnapshot(chartDataCache[chart.id]) != null;
  }

  List<Chart> visibleCharts(List<Chart> charts) {
    return charts.where(shouldRenderChart).toList();
  }

  IconData panelIcon(Chart chart) {
    if (chart is Summary) {
      return Icons.summarize_rounded;
    }

    return Icons.insights_rounded;
  }

  Widget buildPanelContent(Chart chart, bool glass) {
    if (chart is Summary) {
      return DynamicSummaryCard(
        key: ValueKey<String>("summary_${chart.id}"),
        summary: chart,
        begin: begin(),
        until: until(),
        isGlass: glass,
        initialData: chartDataCache[chart.id],
      );
    }

    return ChartCard(
      key: ValueKey<String>("chart_${chart.id}"),
      isGlass: glass,
      chart: chart,
      begin: begin(),
      until: until(),
      compact: true,
      initialData: chartDataCache[chart.id],
    );
  }

  List<DynamicChartDesktopPanelDescriptor> _desktopPanelDescriptors(
    List<Chart> charts,
    bool glass,
  ) {
    return charts.map((chartItem) {
      final bool isSummary = chartItem is Summary;

      return DynamicChartDesktopPanelDescriptor(
        id: chartItem.id,
        title: chartItem.title,
        icon: panelIcon(chartItem),
        width: isSummary ? 240 : 320,
        height: isSummary ? 200 : 520,
        minWidth: isSummary ? 190 : 240,
        minHeight: isSummary ? 170 : 230,
        child: buildPanelContent(chartItem, glass),
      );
    }).toList();
  }

  int desktopFloatingColumnCount(
    double workspaceWidth, {
    int panelCount = 0,
  }) {
    if (panelCount >= 3 && workspaceWidth >= 940) {
      return 3;
    }
    if (panelCount >= 2 && workspaceWidth >= 680) {
      return 2;
    }
    return 1;
  }

  double desktopFloatingPanelWidth({
    required double workspaceWidth,
    required int columnCount,
    required double gap,
  }) {
    if (columnCount <= 1) {
      return (workspaceWidth - (gap * 2)).clamp(250.0, 420.0).toDouble();
    }

    return ((workspaceWidth - (gap * (columnCount + 1))) / columnCount)
        .clamp(220.0, 350.0)
        .toDouble();
  }

  double desktopFloatingPanelHeight(
    DynamicChartDesktopPanelDescriptor panel,
    double panelWidth,
  ) {
    final double scaledHeight = panel.height * (panelWidth / panel.width);

    return math
        .min(panel.height, scaledHeight)
        .clamp(panel.minHeight, panel.height)
        .toDouble();
  }

  double estimatedDesktopDefaultWorkspaceHeight({
    required List<DynamicChartDesktopPanelDescriptor> panels,
    required double workspaceWidth,
    required double minHeight,
  }) {
    if (panels.isEmpty) {
      return minHeight;
    }

    final double gap = Dimensions.size20;
    final int columnCount = desktopFloatingColumnCount(
      workspaceWidth,
      panelCount: panels.length,
    );
    final double panelWidth = desktopFloatingPanelWidth(
      workspaceWidth: workspaceWidth,
      columnCount: columnCount,
      gap: gap,
    );

    double totalHeight = gap;

    for (int start = 0; start < panels.length; start += columnCount) {
      final List<DynamicChartDesktopPanelDescriptor> rowPanels =
          panels.skip(start).take(columnCount).toList();

      double rowHeight = 0;
      for (final DynamicChartDesktopPanelDescriptor panel in rowPanels) {
        rowHeight = math.max(
          rowHeight,
          desktopFloatingPanelHeight(panel, panelWidth),
        );
      }

      totalHeight += rowHeight + gap;
    }

    return math.max(minHeight, totalHeight);
  }

  double storedDesktopLayoutBottom({
    required Set<String> visibleIds,
    required double minHeight,
  }) {
    if (visibleIds.isEmpty) {
      return 0;
    }

    final double gap = Dimensions.size20;
    double maxBottom = 0;

    for (final DynamicChartDesktopWindowLayout layout
        in desktopWindowLayouts.values) {
      if (!visibleIds.contains(layout.id)) {
        continue;
      }

      final double resolvedHeight = layout.maximized
          ? minHeight - (gap * 2)
          : (layout.minimized
              ? desktopMinimizedWindowHeight()
              : math.max(layout.height, 0));

      maxBottom = math.max(
        maxBottom,
        layout.top + resolvedHeight + gap,
      );
    }

    return maxBottom;
  }

  double resolvedDesktopWorkspaceHeight({
    required List<DynamicChartDesktopPanelDescriptor> panels,
    required double workspaceWidth,
    required double minHeight,
  }) {
    final Set<String> visibleIds = panels.map((panel) => panel.id).toSet();
    final double defaultHeight = estimatedDesktopDefaultWorkspaceHeight(
      panels: panels,
      workspaceWidth: workspaceWidth,
      minHeight: minHeight,
    );
    final double storedBottom = storedDesktopLayoutBottom(
      visibleIds: visibleIds,
      minHeight: minHeight,
    );

    return math.max(minHeight, math.max(defaultHeight, storedBottom));
  }

  Map<String, DynamicChartDesktopWindowLayout> defaultDesktopWindowLayouts(
    List<DynamicChartDesktopPanelDescriptor> panels,
    Size workspaceSize,
  ) {
    final Map<String, DynamicChartDesktopWindowLayout> defaults =
        <String, DynamicChartDesktopWindowLayout>{};

    if (panels.isEmpty) {
      return defaults;
    }

    final double gap = Dimensions.size20;
    final int columnCount = desktopFloatingColumnCount(
      workspaceSize.width,
      panelCount: panels.length,
    );
    final double panelWidth = desktopFloatingPanelWidth(
      workspaceWidth: workspaceSize.width,
      columnCount: columnCount,
      gap: gap,
    );
    double currentTop = gap;
    int nextZIndex = 10;

    for (int start = 0; start < panels.length; start += columnCount) {
      final List<DynamicChartDesktopPanelDescriptor> rowPanels =
          panels.skip(start).take(columnCount).toList();

      double rowHeight = 0;
      for (final DynamicChartDesktopPanelDescriptor panel in rowPanels) {
        rowHeight = math.max(
          rowHeight,
          desktopFloatingPanelHeight(panel, panelWidth),
        );
      }

      for (int column = 0; column < rowPanels.length; column++) {
        final DynamicChartDesktopPanelDescriptor panel = rowPanels[column];

        defaults[panel.id] = DynamicChartDesktopWindowLayout(
          id: panel.id,
          left: gap + ((panelWidth + gap) * column),
          top: currentTop,
          width: panelWidth,
          height: desktopFloatingPanelHeight(panel, panelWidth),
          zIndex: nextZIndex++,
        );
      }

      currentTop += rowHeight + gap;
    }

    return defaults;
  }

  Map<String, DynamicChartDesktopWindowLayout> mergedDesktopWindowLayouts(
    List<DynamicChartDesktopPanelDescriptor> panels,
    Size workspaceSize,
  ) {
    final Map<String, DynamicChartDesktopWindowLayout> defaults =
        defaultDesktopWindowLayouts(panels, workspaceSize);

    return <String, DynamicChartDesktopWindowLayout>{
      for (final DynamicChartDesktopPanelDescriptor panel in panels)
        panel.id: desktopWindowLayouts[panel.id] ??
            defaults[panel.id] ??
            DynamicChartDesktopWindowLayout(
              id: panel.id,
              left: Dimensions.size20,
              top: Dimensions.size20,
              width: panel.width,
              height: panel.height,
              zIndex: 10,
            ),
    };
  }

  int maxDesktopZIndex(
    Map<String, DynamicChartDesktopWindowLayout> layouts,
  ) {
    int maxValue = 0;

    for (final DynamicChartDesktopWindowLayout layout in layouts.values) {
      if (layout.zIndex > maxValue) {
        maxValue = layout.zIndex;
      }
    }

    return maxValue;
  }

  Rect resolveDesktopWindowRect({
    required DynamicChartDesktopWindowLayout layout,
    required Size workspaceSize,
    required double minWidth,
    required double minHeight,
  }) {
    final double boundaryPadding = Dimensions.size10;
    if (layout.maximized) {
      return Rect.fromLTWH(
        boundaryPadding,
        boundaryPadding,
        math.max(
          minWidth,
          workspaceSize.width - (boundaryPadding * 2),
        ),
        math.max(
          minHeight,
          workspaceSize.height - (boundaryPadding * 2),
        ),
      );
    }

    final double width = layout.width.clamp(
      minWidth,
      math.max(minWidth, workspaceSize.width - (boundaryPadding * 2)),
    );
    final double height = layout.minimized
        ? desktopMinimizedWindowHeight()
        : layout.height.clamp(
            minHeight,
            math.max(minHeight, workspaceSize.height - (boundaryPadding * 2)),
          );
    final double left = layout.left.clamp(
      boundaryPadding,
      math.max(
        boundaryPadding,
        workspaceSize.width - width - boundaryPadding,
      ),
    );
    final double top = layout.top.clamp(
      boundaryPadding,
      math.max(
        boundaryPadding,
        workspaceSize.height - height - boundaryPadding,
      ),
    );

    return Rect.fromLTWH(left, top, width, height);
  }

  void bringDesktopWindowToFront(
    String id,
    Map<String, DynamicChartDesktopWindowLayout> effectiveLayouts,
  ) {
    final DynamicChartDesktopWindowLayout? current = effectiveLayouts[id];
    if (current == null) {
      return;
    }

    final int highestZIndex = maxDesktopZIndex(effectiveLayouts);
    if (current.zIndex >= highestZIndex) {
      return;
    }

    setState(() {
      desktopWindowLayouts = <String, DynamicChartDesktopWindowLayout>{
        ...effectiveLayouts,
        id: current.copyWith(zIndex: highestZIndex + 1),
      };
      desktopDragNotifier.value++;
    });
  }

  double desktopMinimizedWindowHeight() {
    return Dimensions.size50 + (Dimensions.size5 * 2);
  }

  void updateDesktopWindowPosition({
    required String id,
    required Offset delta,
    required Map<String, DynamicChartDesktopWindowLayout> effectiveLayouts,
    required Size workspaceSize,
    required double minWidth,
    required double minHeight,
  }) {
    final DynamicChartDesktopWindowLayout? current = effectiveLayouts[id];
    if (current == null || current.maximized || current.minimized) {
      return;
    }

    final Rect rect = resolveDesktopWindowRect(
      layout: current,
      workspaceSize: workspaceSize,
      minWidth: minWidth,
      minHeight: minHeight,
    );
    final double boundaryPadding = Dimensions.size10;
    final double nextLeft = (rect.left + delta.dx).clamp(
      boundaryPadding,
      math.max(
        boundaryPadding,
        workspaceSize.width - rect.width - boundaryPadding,
      ),
    );
    final double nextTop = (rect.top + delta.dy).clamp(
      boundaryPadding,
      math.max(
        boundaryPadding,
        workspaceSize.height - rect.height - boundaryPadding,
      ),
    );

    setState(() {
      desktopWindowLayouts = <String, DynamicChartDesktopWindowLayout>{
        ...effectiveLayouts,
        id: current.copyWith(
          left: nextLeft.toDouble(),
          top: nextTop.toDouble(),
          zIndex: maxDesktopZIndex(effectiveLayouts) + 1,
        ),
      };
      desktopDragNotifier.value++;
    });
  }

  void updateDesktopWindowSize({
    required String id,
    required Offset delta,
    required Map<String, DynamicChartDesktopWindowLayout> effectiveLayouts,
    required Size workspaceSize,
    required double minWidth,
    required double minHeight,
  }) {
    final DynamicChartDesktopWindowLayout? current = effectiveLayouts[id];
    if (current == null || current.maximized || current.minimized) {
      return;
    }

    final Rect rect = resolveDesktopWindowRect(
      layout: current,
      workspaceSize: workspaceSize,
      minWidth: minWidth,
      minHeight: minHeight,
    );
    final double boundaryPadding = Dimensions.size10;

    final double maxWidth = workspaceSize.width - rect.left - boundaryPadding;
    final double maxHeight = workspaceSize.height - rect.top - boundaryPadding;
    final double safeMinWidth = minWidth > maxWidth ? maxWidth : minWidth;
    final double safeMinHeight = minHeight > maxHeight ? maxHeight : minHeight;

    final double nextWidth =
        (rect.width + delta.dx).clamp(safeMinWidth, maxWidth).toDouble();
    final double nextHeight =
        (rect.height + delta.dy).clamp(safeMinHeight, maxHeight).toDouble();

    setState(() {
      desktopWindowLayouts = <String, DynamicChartDesktopWindowLayout>{
        ...effectiveLayouts,
        id: current.copyWith(
          width: nextWidth,
          height: nextHeight,
          zIndex: maxDesktopZIndex(effectiveLayouts) + 1,
        ),
      };
      desktopDragNotifier.value++;
    });
  }

  void updateDesktopWindowEdgeResize({
    required String id,
    required double dLeft,
    required double dTop,
    required double dWidth,
    required double dHeight,
    required Map<String, DynamicChartDesktopWindowLayout> effectiveLayouts,
    required Size workspaceSize,
    required double minWidth,
    required double minHeight,
  }) {
    final DynamicChartDesktopWindowLayout? current = effectiveLayouts[id];
    if (current == null || current.maximized || current.minimized) {
      return;
    }

    final Rect rect = resolveDesktopWindowRect(
      layout: current,
      workspaceSize: workspaceSize,
      minWidth: minWidth,
      minHeight: minHeight,
    );
    final double boundaryPadding = Dimensions.size10;

    double newLeft = rect.left + dLeft;
    double newTop = rect.top + dTop;
    double newWidth = rect.width + dWidth;
    double newHeight = rect.height + dHeight;

    if (newWidth < minWidth) {
      final double diff = minWidth - newWidth;
      newWidth = minWidth;
      if (dLeft != 0) {
        newLeft -= diff;
      }
    }
    if (newHeight < minHeight) {
      final double diff = minHeight - newHeight;
      newHeight = minHeight;
      if (dTop != 0) {
        newTop -= diff;
      }
    }

    newLeft = newLeft
        .clamp(
          boundaryPadding,
          workspaceSize.width - newWidth - boundaryPadding,
        )
        .toDouble();
    newTop = newTop
        .clamp(
          boundaryPadding,
          workspaceSize.height - newHeight - boundaryPadding,
        )
        .toDouble();

    final double maxWidth = workspaceSize.width - newLeft - boundaryPadding;
    final double maxHeight = workspaceSize.height - newTop - boundaryPadding;
    newWidth = newWidth.clamp(minWidth, maxWidth).toDouble();
    newHeight = newHeight.clamp(minHeight, maxHeight).toDouble();

    setState(() {
      desktopWindowLayouts = <String, DynamicChartDesktopWindowLayout>{
        ...effectiveLayouts,
        id: current.copyWith(
          left: newLeft,
          top: newTop,
          width: newWidth,
          height: newHeight,
          zIndex: maxDesktopZIndex(effectiveLayouts) + 1,
        ),
      };
      desktopDragNotifier.value++;
    });
  }

  DynamicChartDesktopWindowLayout? toggleDesktopWindowMinimize({
    required String id,
    required Map<String, DynamicChartDesktopWindowLayout> effectiveLayouts,
  }) {
    final DynamicChartDesktopWindowLayout? current = effectiveLayouts[id];
    if (current == null) {
      return null;
    }

    final int nextZIndex = maxDesktopZIndex(effectiveLayouts) + 1;
    if (current.minimized) {
      return current.copyWith(
        minimized: false,
        zIndex: nextZIndex,
      );
    }

    return current.copyWith(
      minimized: true,
      maximized: false,
      zIndex: nextZIndex,
      clearRestoreLeft: false,
      clearRestoreTop: false,
      clearRestoreWidth: false,
      clearRestoreHeight: false,
    );
  }

  DynamicChartDesktopWindowLayout? toggleDesktopWindowMaximize({
    required String id,
    required Map<String, DynamicChartDesktopWindowLayout> effectiveLayouts,
    required Size workspaceSize,
    required double minWidth,
    required double minHeight,
  }) {
    final DynamicChartDesktopWindowLayout? current = effectiveLayouts[id];
    if (current == null) {
      return null;
    }

    final int nextZIndex = maxDesktopZIndex(effectiveLayouts) + 1;
    final Rect currentRect = resolveDesktopWindowRect(
      layout: current,
      workspaceSize: workspaceSize,
      minWidth: minWidth,
      minHeight: minHeight,
    );

    if (current.maximized) {
      return current.copyWith(
        left: current.restoreLeft ?? current.left,
        top: current.restoreTop ?? current.top,
        width: current.restoreWidth ?? current.width,
        height: current.restoreHeight ?? current.height,
        minimized: false,
        maximized: false,
        zIndex: nextZIndex,
        clearRestoreLeft: true,
        clearRestoreTop: true,
        clearRestoreWidth: true,
        clearRestoreHeight: true,
      );
    }

    return current.copyWith(
      minimized: false,
      maximized: true,
      left: currentRect.left,
      top: currentRect.top,
      width: currentRect.width,
      height: currentRect.height,
      zIndex: nextZIndex,
      restoreLeft: currentRect.left,
      restoreTop: currentRect.top,
      restoreWidth: currentRect.width,
      restoreHeight: currentRect.height,
    );
  }

  Future<void> closeDesktopWindow(String id) async {
    setState(() {
      hiddenDesktopPanels = <String>{...hiddenDesktopPanels, id};
    });
    await persistHiddenDesktopPanels();
  }

  Future<void> showDesktopWindow(String id) async {
    setState(() {
      hiddenDesktopPanels = <String>{...hiddenDesktopPanels}..remove(id);
    });
    await persistHiddenDesktopPanels();
  }

  Future<void> resetDesktopWorkspace() async {
    setState(() {
      desktopWindowLayouts = <String, DynamicChartDesktopWindowLayout>{};
      hiddenDesktopPanels = <String>{};
    });

    if (prefsReady) {
      await Preferences.getInstance().removeDynamicForm(
        desktopWindowLayoutPreferenceKey(),
      );
      await Preferences.getInstance().removeDynamicForm(
        hiddenDesktopPanelPreferenceKey(),
      );
    }
  }

  double desktopWorkspaceHeight(
    Map<String, DynamicChartDesktopWindowLayout> layouts,
    double viewportHeight,
  ) {
    return viewportHeight;
  }

  void swapChartOrder(String sourceId, String targetId) {
    final int sourceIndex = chartOrder.indexOf(sourceId);
    final int targetIndex = chartOrder.indexOf(targetId);

    if (sourceIndex < 0 || targetIndex < 0 || sourceIndex == targetIndex) {
      return;
    }

    final List<String> next = List<String>.from(chartOrder);
    final String moved = next.removeAt(sourceIndex);
    next.insert(targetIndex, moved);

    setState(() {
      chartOrder = next;
      draggingChartId = null;
      dragTargetChartId = null;
    });

    persistChartOrder();
  }

  bool get isGlass {
    if (!prefsReady) {
      return false;
    }

    final int t = Preferences.getInstance().getInt(
          SharedPreferenceKey.DASHBOARD_UI_TYPE,
        ) ??
        1;
    return t == 2;
  }

  Widget glassBackground() {
    return Generals.orientationAwareWallpaper(context);
  }

  Jiffy begin() {
    if (customRange != null) {
      return Jiffy.parseFromDateTime(
        DateTime(
          customRange!.start.year,
          customRange!.start.month,
          customRange!.start.day,
        ),
      );
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (preset == RangePreset.today) {
      return Jiffy.parseFromDateTime(today);
    }
    if (preset == RangePreset.last7) {
      return Jiffy.parseFromDateTime(today.subtract(const Duration(days: 6)));
    }
    return Jiffy.parseFromDateTime(today.subtract(const Duration(days: 29)));
  }

  Jiffy until() {
    if (customRange != null) {
      return Jiffy.parseFromDateTime(
        DateTime(
          customRange!.end.year,
          customRange!.end.month,
          customRange!.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    }
    final DateTime now = DateTime.now();
    return Jiffy.parseFromDateTime(
      DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  String rangeLabel() {
    final Jiffy b = begin();
    final Jiffy u = until();

    final String a = b.format(pattern: "d MMM yyyy");
    final String z = u.format(pattern: "d MMM yyyy");
    return "$a - $z";
  }

  Future<void> pickRangeDate() async {
    final DateTime now = DateTime.now();

    final DateTime initialStart = customRange?.start ?? begin().dateTime;
    final DateTime initialEnd = customRange?.end ?? until().dateTime;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: "select_period".tr(),
      cancelText: "cancel".tr(),
      confirmText: "use".tr(),
    );

    if (picked == null) {
      return;
    }

    final DateTimeRange normalized = DateTimeRange(
      start: DateTime(picked.start.year, picked.start.month, picked.start.day),
      end: DateTime(picked.end.year, picked.end.month, picked.end.day),
    );

    setState(() {
      customRange = normalized;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = DotResponsive.isMobileContext(context);
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartLoadLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicChartLoadSuccess) {
          final List<Chart> charts = state.listResponse.charts.toList();

          setState(() {
            listResponse = state.listResponse;
            syncChartOrder(charts);
          });
        } else if (state is DynamicChartDataSuccess) {
          setState(() {
            chartDataCache[state.id] = state.data;
          });
        } else if (state is DynamicChartLoadFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: Scaffold(
        backgroundColor: isGlass
            ? Colors.transparent
            : Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            if (isGlass && isMobile) ...[
              Positioned.fill(child: glassBackground()),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color.fromRGBO(0, 0, 0, 0.55),
                        Color.fromRGBO(0, 0, 0, 0.22),
                        Color.fromRGBO(0, 0, 0, 0.40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.only(top: Dimensions.size20),
              child: SafeArea(
                top: !isGlass && isMobile,
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: DotResponsive.centered(
                        context: context,
                        tablet: 920,
                        desktop: 1080,
                        child: AppBarDynamicChart(
                          isGlass: isGlass && isMobile,
                          useWhiteForeground: isGlass,
                          showBackButton: true,
                          isMobile: isMobile,
                          title: "dynamic_chart".tr(),
                          rangeLabel: rangeLabel(),
                          onPickRange: pickRangeDate,
                          onBack: () {
                            if (!isMobile) {
                              context.go("/");
                              return;
                            }

                            if (BaseSettings.navigatorType ==
                                BaseNavigatorType.legacy) {
                              Navigators.pop();
                              return;
                            }

                            final GoRouter r = GoRouter.of(context);
                            if (r.canPop()) {
                              r.pop();
                              return;
                            }

                            final NavigatorState nav = Navigator.of(context);
                            if (nav.canPop()) {
                              nav.pop();
                              return;
                            }
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: body(
                        glass: isGlass,
                        horizontalPadding: horizontalPadding,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget body({required bool glass, required double horizontalPadding}) {
    final bool isMobile = DotResponsive.isMobileContext(context);

    if (listResponse == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          Dimensions.size10,
          horizontalPadding,
          Dimensions.size30,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: LoadingCard(isGlass: glass),
            ),
          ),
        ],
      );
    }

    final List<Chart> charts =
        visibleCharts(orderedCharts(listResponse!.charts));

    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: isMobile
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Dimensions.size10,
                horizontalPadding,
                Dimensions.size30,
              ),
              itemCount: charts.length,
              itemBuilder: (context, index) {
                final Chart c = charts[index];
                final Widget card = c is Summary
                    ? DynamicSummaryCard(
                        key: ValueKey<String>("summary_${c.id}"),
                        summary: c,
                        begin: begin(),
                        until: until(),
                        isGlass: glass,
                        initialData: chartDataCache[c.id],
                      )
                    : ChartCard(
                        key: ValueKey<String>("chart_${c.id}"),
                        isGlass: glass,
                        chart: c,
                        begin: begin(),
                        until: until(),
                        initialData: chartDataCache[c.id],
                      );

                return Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.size15),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: card,
                    ),
                  ),
                );
              },
            )
          : (floatingDesktopMode
              ? desktopFloatingBody(
                  glass: glass,
                  horizontalPadding: horizontalPadding,
                  charts: charts,
                )
              : desktopFixedBody(
                  glass: glass,
                  horizontalPadding: horizontalPadding,
                  charts: charts,
                )),
    );
  }

  Widget desktopFixedBody({
    required bool glass,
    required double horizontalPadding,
    required List<Chart> charts,
  }) {
    final List<Summary> summaries = charts.whereType<Summary>().toList();
    final List<Chart> regularCharts =
        charts.where((Chart chart) => chart is! Summary).toList();
    final bool hasSavedLayouts = readSavedDesktopLayouts().isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            Dimensions.size10,
            horizontalPadding,
            Dimensions.size30,
          ),
          children: [
            DotResponsive.centered(
              context: context,
              tablet: 960,
              desktop: 1380,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double gap = Dimensions.size15;
                  final int summaryColumns = constraints.maxWidth >= 1160
                      ? 4
                      : constraints.maxWidth >= 860
                          ? 3
                          : constraints.maxWidth >= 560
                              ? 2
                              : 1;
                  final int chartColumns = constraints.maxWidth >= 1320
                      ? 4
                      : constraints.maxWidth >= 1024
                          ? 3
                          : constraints.maxWidth >= 720
                              ? 2
                              : 1;
                  final double summaryWidth = summaryColumns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - (gap * (summaryColumns - 1))) /
                          summaryColumns;
                  final double chartWidth = chartColumns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - (gap * (chartColumns - 1))) /
                          chartColumns;
                  final Color helperColor = glass
                      ? Colors.white.withOpacity(0.78)
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.88);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: Dimensions.size5,
                          bottom: Dimensions.size10,
                        ),
                        child: Text(
                          "Mode fixed aktif. Layout desktop tampil rapat dan rapi, lalu floating dipakai saat user ingin geser widget.",
                          style: TextStyle(
                            fontSize: Dimensions.text12,
                            fontWeight: FontWeight.w700,
                            color: helperColor,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: Dimensions.size10,
                        runSpacing: Dimensions.size10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setFloatingDesktopMode(true);
                            },
                            icon: const Icon(Icons.open_in_full_rounded),
                            label: const Text("Aktifkan Floating"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showSaveLayoutDialog(desktopWindowLayouts);
                            },
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text("Save layout"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                          if (hasSavedLayouts)
                            OutlinedButton.icon(
                              onPressed: showLoadLayoutDialog,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text("Load layout"),
                              style: desktopToolbarButtonStyle(
                                context,
                                glass: glass,
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Refresh"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                        ],
                      ),
                      if (summaries.isNotEmpty) ...[
                        SizedBox(height: gap),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: summaries.map((Summary summary) {
                            return SizedBox(
                              width: summaryWidth,
                              child: DynamicSummaryCard(
                                key: ValueKey<String>(
                                  "fixed_summary_${summary.id}",
                                ),
                                summary: summary,
                                begin: begin(),
                                until: until(),
                                isGlass: glass,
                                initialData: chartDataCache[summary.id],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (regularCharts.isNotEmpty) ...[
                        SizedBox(height: gap),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: regularCharts.map((Chart chart) {
                            return SizedBox(
                              width: chartWidth,
                              child: ChartCard(
                                key:
                                    ValueKey<String>("fixed_chart_${chart.id}"),
                                chart: chart,
                                begin: begin(),
                                until: until(),
                                isGlass: glass,
                                initialData: chartDataCache[chart.id],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(
                        height: math.max(
                          Dimensions.size20,
                          viewportConstraints.maxHeight * 0.02,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget desktopFloatingBody({
    required bool glass,
    required double horizontalPadding,
    required List<Chart> charts,
  }) {
    final List<DynamicChartDesktopPanelDescriptor> allPanels =
        _desktopPanelDescriptors(charts, glass);
    final List<DynamicChartDesktopPanelDescriptor> hiddenPanels = allPanels
        .where((panel) => hiddenDesktopPanels.contains(panel.id))
        .toList();
    final List<DynamicChartDesktopPanelDescriptor> visiblePanels = allPanels
        .where((panel) => !hiddenDesktopPanels.contains(panel.id))
        .toList();
    final bool hasSavedLayouts = readSavedDesktopLayouts().isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            Dimensions.size10,
            horizontalPadding,
            Dimensions.size30,
          ),
          children: [
            DotResponsive.centered(
              context: context,
              tablet: 960,
              desktop: 1380,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double workspaceWidth = constraints.maxWidth;
                  final double minWorkspaceHeight = math.max(
                    760,
                    viewportConstraints.maxHeight - 40,
                  );
                  final double workspaceHeight = resolvedDesktopWorkspaceHeight(
                    panels: visiblePanels,
                    workspaceWidth: workspaceWidth,
                    minHeight: minWorkspaceHeight,
                  );
                  final Size workspaceSize = Size(
                    workspaceWidth,
                    workspaceHeight,
                  );
                  final Map<String, DynamicChartDesktopWindowLayout>
                      effectiveLayouts = mergedDesktopWindowLayouts(
                    visiblePanels,
                    workspaceSize,
                  );
                  final List<DynamicChartDesktopPanelDescriptor> orderedPanels =
                      visiblePanels.toList()
                        ..sort(
                          (
                            DynamicChartDesktopPanelDescriptor a,
                            DynamicChartDesktopPanelDescriptor b,
                          ) {
                            return (effectiveLayouts[a.id]?.zIndex ?? 0)
                                .compareTo(
                              effectiveLayouts[b.id]?.zIndex ?? 0,
                            );
                          },
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: Dimensions.size5,
                          bottom: Dimensions.size10,
                        ),
                        child: Text(
                          "Mode floating aktif. Widget bisa di-drag, di-resize, di-maximize, lalu di-close dan dimunculkan lagi kapan saja.",
                          style: TextStyle(
                            fontSize: Dimensions.text12,
                            fontWeight: FontWeight.w700,
                            color: glass
                                ? Colors.white.withOpacity(0.80)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: Dimensions.size10,
                        runSpacing: Dimensions.size10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setFloatingDesktopMode(false);
                            },
                            icon: const Icon(Icons.dashboard_customize_rounded),
                            label: const Text("Mode Fixed"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showSaveLayoutDialog(effectiveLayouts);
                            },
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text("Save layout"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                          if (hasSavedLayouts)
                            OutlinedButton.icon(
                              onPressed: showLoadLayoutDialog,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text("Load layout"),
                              style: desktopToolbarButtonStyle(
                                context,
                                glass: glass,
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Refresh"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              resetDesktopWorkspace();
                            },
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text("Reset layout"),
                            style: desktopToolbarButtonStyle(
                              context,
                              glass: glass,
                            ),
                          ),
                          if (hiddenPanels.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {
                                showHiddenPanelsDialog(
                                  hiddenPanels: hiddenPanels,
                                  glass: glass,
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text("Tambah widget"),
                              style: desktopToolbarButtonStyle(
                                context,
                                glass: glass,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: Dimensions.size15),
                      Builder(
                        builder: (BuildContext context) {
                          final BorderRadius workspaceBorderRadius =
                              BorderRadius.circular(Dimensions.size20);
                          final Widget workspaceWindows = SizedBox(
                            width: workspaceWidth,
                            height: workspaceHeight,
                            child: ValueListenableBuilder<int>(
                              valueListenable: desktopDragNotifier,
                              builder: (context, _, __) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    for (final DynamicChartDesktopPanelDescriptor panel
                                        in orderedPanels)
                                      DynamicChartDesktopWindowFrame(
                                        key: ValueKey<String>(panel.id),
                                        rect: resolveDesktopWindowRect(
                                          layout: effectiveLayouts[panel.id]!,
                                          workspaceSize: workspaceSize,
                                          minWidth: panel.minWidth,
                                          minHeight: panel.minHeight,
                                        ),
                                        glass: glass,
                                        active: effectiveLayouts[panel.id]!
                                                .zIndex ==
                                            maxDesktopZIndex(
                                              effectiveLayouts,
                                            ),
                                        minimized: effectiveLayouts[panel.id]!
                                            .minimized,
                                        maximized: effectiveLayouts[panel.id]!
                                            .maximized,
                                        floatingEnabled: true,
                                        title: panel.title,
                                        icon: panel.icon,
                                        onFocus: () =>
                                            bringDesktopWindowToFront(
                                          panel.id,
                                          effectiveLayouts,
                                        ),
                                        onToggleMinimize: () {
                                          final DynamicChartDesktopWindowLayout?
                                              nextLayout =
                                              toggleDesktopWindowMinimize(
                                            id: panel.id,
                                            effectiveLayouts: effectiveLayouts,
                                          );
                                          if (nextLayout == null) {
                                            return;
                                          }

                                          setState(() {
                                            desktopWindowLayouts = <String,
                                                DynamicChartDesktopWindowLayout>{
                                              ...effectiveLayouts,
                                              panel.id: nextLayout,
                                            };
                                            desktopDragNotifier.value++;
                                          });
                                          persistDesktopWindowLayouts();
                                        },
                                        onToggleMaximize: () {
                                          final DynamicChartDesktopWindowLayout?
                                              nextLayout =
                                              toggleDesktopWindowMaximize(
                                            id: panel.id,
                                            effectiveLayouts: effectiveLayouts,
                                            workspaceSize: workspaceSize,
                                            minWidth: panel.minWidth,
                                            minHeight: panel.minHeight,
                                          );
                                          if (nextLayout == null) {
                                            return;
                                          }

                                          setState(() {
                                            desktopWindowLayouts = <String,
                                                DynamicChartDesktopWindowLayout>{
                                              ...effectiveLayouts,
                                              panel.id: nextLayout,
                                            };
                                            desktopDragNotifier.value++;
                                          });
                                          persistDesktopWindowLayouts();
                                        },
                                        onClose: () {
                                          closeDesktopWindow(panel.id);
                                        },
                                        onDragDelta: (Offset delta) {
                                          updateDesktopWindowPosition(
                                            id: panel.id,
                                            delta: delta,
                                            effectiveLayouts: effectiveLayouts,
                                            workspaceSize: workspaceSize,
                                            minWidth: panel.minWidth,
                                            minHeight: panel.minHeight,
                                          );
                                        },
                                        onResizeDelta: (Offset delta) {
                                          updateDesktopWindowSize(
                                            id: panel.id,
                                            delta: delta,
                                            effectiveLayouts: effectiveLayouts,
                                            workspaceSize: workspaceSize,
                                            minWidth: panel.minWidth,
                                            minHeight: panel.minHeight,
                                          );
                                        },
                                        onEdgeResizeDelta: (
                                          double dLeft,
                                          double dTop,
                                          double dWidth,
                                          double dHeight,
                                        ) {
                                          updateDesktopWindowEdgeResize(
                                            id: panel.id,
                                            dLeft: dLeft,
                                            dTop: dTop,
                                            dWidth: dWidth,
                                            dHeight: dHeight,
                                            effectiveLayouts: effectiveLayouts,
                                            workspaceSize: workspaceSize,
                                            minWidth: panel.minWidth,
                                            minHeight: panel.minHeight,
                                          );
                                        },
                                        onDragEnd: () {
                                          persistDesktopWindowLayouts();
                                        },
                                        onResizeEnd: () {
                                          persistDesktopWindowLayouts();
                                        },
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: EdgeInsets.all(
                                            Dimensions.size15,
                                          ),
                                          child: panel.child,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          );

                          if (glass) {
                            return workspaceWindows;
                          }

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: workspaceBorderRadius,
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.45),
                                width: 0.7,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: workspaceBorderRadius,
                              child: workspaceWindows,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
