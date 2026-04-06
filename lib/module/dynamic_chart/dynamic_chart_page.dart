// ignore_for_file: deprecated_member_use

import "dart:convert";
import "dart:math" as math;

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/chart_model.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/generals.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_desktop_window.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:jiffy/jiffy.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:shimmer/shimmer.dart";
import "package:syncfusion_flutter_charts/charts.dart";

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
  final ValueNotifier<int> _desktopDragNotifier = ValueNotifier<int>(0);

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
    _desktopDragNotifier.dispose();
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

  Future<void> initPrefs() async {
    try {
      await Preferences.getInstance().init();
    } catch (_) {
      return;
    }

    prefsReady = true;
    final _DynamicChartSavedLayoutPayload? savedPayload =
        _readCurrentDesktopLayoutPayload();

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

  String chartOrderPreferenceKey() {
    return "dynamic_chart_layout_order_v1";
  }

  String desktopWindowLayoutPreferenceKey() {
    return "dynamic_chart_desktop_window_layout_v1";
  }

  String floatingDesktopModePreferenceKey() {
    return "dynamic_chart_desktop_floating_mode_v1";
  }

  String hiddenDesktopPanelPreferenceKey() {
    return "dynamic_chart_hidden_panels_v1";
  }

  String _savedLayoutsListPreferenceKey() {
    return "dynamic_chart_saved_layouts_${_desktopPreferenceOwner()}";
  }

  String _desktopPreferenceOwner() {
    final String base = _currentLayoutUserId().trim();
    if (base.isEmpty) {
      return "default";
    }

    return base.replaceAll(RegExp(r"[^A-Za-z0-9_.-]"), "_");
  }

  String _currentLayoutUserId() {
    final String salesId =
        Preferences.getInstance().getStringDynamicForm("SALES_ID") ?? "";
    final String username =
        Preferences.getInstance().getStringDynamicForm("USER_NAME") ?? "";

    if (salesId.isNotEmpty) {
      return salesId;
    }

    if (username.isNotEmpty) {
      return username;
    }

    return "default";
  }

  String _currentLayoutUsername() {
    return Preferences.getInstance().getStringDynamicForm("USER_NAME") ?? "";
  }

  int _dashboardUiType() {
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

  Map<String, DynamicChartDesktopWindowLayout> readSavedDesktopWindowLayouts() {
    if (!prefsReady) {
      return <String, DynamicChartDesktopWindowLayout>{};
    }

    try {
      final String? raw = Preferences.getInstance().getStringDynamicForm(
        desktopWindowLayoutPreferenceKey(),
      );
      if (raw == null || raw.isEmpty) {
        return <String, DynamicChartDesktopWindowLayout>{};
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        final Map<String, DynamicChartDesktopWindowLayout> layouts =
            <String, DynamicChartDesktopWindowLayout>{};

        for (final dynamic item in decoded) {
          if (item is! Map) {
            continue;
          }

          final DynamicChartDesktopWindowLayout layout =
              DynamicChartDesktopWindowLayout.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (layout.id.isNotEmpty) {
            layouts[layout.id] = layout;
          }
        }

        return layouts;
      }

      if (decoded is! Map) {
        return <String, DynamicChartDesktopWindowLayout>{};
      }

      return _DynamicChartSavedLayoutPayload.fromJson(
        Map<String, dynamic>.from(decoded),
      ).layoutsMap;
    } catch (_) {
      return <String, DynamicChartDesktopWindowLayout>{};
    }
  }

  _DynamicChartSavedLayoutPayload? _readCurrentDesktopLayoutPayload() {
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
      return _decodeDesktopSavedLayoutPayload(raw);
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

  _DynamicChartSavedLayoutPayload _buildDesktopSavedLayoutPayload({
    required Map<String, DynamicChartDesktopWindowLayout> layouts,
    String? layoutName,
  }) {
    final List<DynamicChartDesktopWindowLayout> ordered =
        layouts.values.toList()..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return _DynamicChartSavedLayoutPayload(
      version: 3,
      name: layoutName?.trim() ?? "",
      userId: _currentLayoutUserId(),
      username: _currentLayoutUsername(),
      savedAt: DateTime.now().toIso8601String(),
      dashboardUiType: _dashboardUiType(),
      floatingMode: floatingDesktopMode,
      desktopNavigationVisible: true,
      widgetOrder: List<String>.from(chartOrder),
      hiddenWidgetIds: hiddenDesktopPanels.toList()..sort(),
      windows: ordered,
    );
  }

  _DynamicChartSavedLayoutPayload _decodeDesktopSavedLayoutPayload(
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
        "userId": _currentLayoutUserId(),
        "username": _currentLayoutUsername(),
        "savedAt": DateTime.now().toIso8601String(),
        "dashboardUiType": _dashboardUiType(),
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
        (map["userId"] ?? map["ownerId"] ?? _currentLayoutUserId()).toString();
    map["username"] =
        (map["username"] ?? map["ownerName"] ?? _currentLayoutUsername())
            .toString();
    map["savedAt"] =
        (map["savedAt"] ?? DateTime.now().toIso8601String()).toString();
    map["dashboardUiType"] = map["dashboardUiType"] ?? _dashboardUiType();
    map["floatingMode"] = map["floatingMode"] ?? floatingDesktopMode;
    map["desktopNavigationVisible"] = map["desktopNavigationVisible"] ?? true;
    map["widgetOrder"] =
        map["widgetOrder"] is List ? map["widgetOrder"] : const <dynamic>[];
    map["hiddenWidgetIds"] = map["hiddenWidgetIds"] is List
        ? map["hiddenWidgetIds"]
        : const <dynamic>[];
    map["windows"] =
        map["windows"] is List ? map["windows"] : const <dynamic>[];

    return _DynamicChartSavedLayoutPayload.fromJson(map);
  }

  Future<void> persistCurrentDesktopLayoutPayload({
    Map<String, DynamicChartDesktopWindowLayout>? layouts,
    String? layoutName,
  }) async {
    if (!prefsReady) {
      return;
    }

    final _DynamicChartSavedLayoutPayload payload =
        _buildDesktopSavedLayoutPayload(
      layouts: layouts ?? desktopWindowLayouts,
      layoutName: layoutName,
    );

    await Preferences.getInstance().setStringDynamicForm(
      desktopWindowLayoutPreferenceKey(),
      jsonEncode(payload.toJson()),
    );
  }

  List<_DynamicChartSavedLayoutPayload> _readSavedDesktopLayouts() {
    if (!prefsReady) {
      return <_DynamicChartSavedLayoutPayload>[];
    }

    final String? raw = Preferences.getInstance().getStringDynamicForm(
      _savedLayoutsListPreferenceKey(),
    );
    if (raw == null || raw.isEmpty) {
      return <_DynamicChartSavedLayoutPayload>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      final List<_DynamicChartSavedLayoutPayload> layouts =
          <_DynamicChartSavedLayoutPayload>[];

      if (decoded is List) {
        for (final dynamic item in decoded) {
          if (item is! Map) {
            continue;
          }
          layouts.add(_decodeDesktopSavedLayoutPayload(item));
        }
      } else if (decoded is Map && decoded["layouts"] is List) {
        for (final dynamic item in decoded["layouts"] as List<dynamic>) {
          if (item is! Map) {
            continue;
          }
          layouts.add(_decodeDesktopSavedLayoutPayload(item));
        }
      } else if (decoded is Map) {
        for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
          try {
            layouts.add(
              _decodeDesktopSavedLayoutPayload(
                entry.value,
                legacyName: entry.key.toString(),
              ),
            );
          } catch (_) {}
        }
      }

      layouts.sort((
        _DynamicChartSavedLayoutPayload a,
        _DynamicChartSavedLayoutPayload b,
      ) {
        final DateTime aTime =
            a.savedAtDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.savedAtDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return layouts;
    } catch (_) {
      return <_DynamicChartSavedLayoutPayload>[];
    }
  }

  Future<void> _writeSavedDesktopLayouts(
    List<_DynamicChartSavedLayoutPayload> layouts,
  ) async {
    await Preferences.getInstance().setStringDynamicForm(
      _savedLayoutsListPreferenceKey(),
      jsonEncode(<String, dynamic>{
        "version": 1,
        "layouts": layouts.map((_DynamicChartSavedLayoutPayload item) {
          return item.toJson();
        }).toList(),
      }),
    );
  }

  String _formatSavedLayoutDate(_DynamicChartSavedLayoutPayload payload) {
    final DateTime? savedAt = payload.savedAtDateTime;
    if (savedAt == null) {
      return "-";
    }

    return Jiffy.parseFromDateTime(savedAt).format(pattern: "d MMM yyyy HH:mm");
  }

  String _savedLayoutMetaLine(_DynamicChartSavedLayoutPayload payload) {
    final List<String> parts = <String>[
      payload.userId,
      payload.floatingMode ? "Floating" : "Fixed",
      payload.themeLabel,
    ].where((String item) => item.trim().isNotEmpty).toList();

    return parts.join(" • ");
  }

  Future<void> _deleteSavedDesktopLayout(String layoutName) async {
    final List<_DynamicChartSavedLayoutPayload> savedLayouts =
        _readSavedDesktopLayouts()
          ..removeWhere((_DynamicChartSavedLayoutPayload item) {
            return item.name.trim().toLowerCase() ==
                layoutName.trim().toLowerCase();
          });

    await _writeSavedDesktopLayouts(savedLayouts);
  }

  Future<void> _saveDesktopWindowLayouts(
    Map<String, DynamicChartDesktopWindowLayout> layouts, {
    String? layoutName,
  }) async {
    final _DynamicChartSavedLayoutPayload payload =
        _buildDesktopSavedLayoutPayload(
      layouts: layouts,
      layoutName: layoutName,
    );
    final String layoutJson = jsonEncode(payload.toJson());
    final Map<String, DynamicChartDesktopWindowLayout> orderedLayouts =
        payload.layoutsMap;

    if (layoutName != null && layoutName.trim().isNotEmpty) {
      final List<_DynamicChartSavedLayoutPayload> savedLayouts =
          _readSavedDesktopLayouts()
            ..removeWhere((_DynamicChartSavedLayoutPayload item) {
              return item.name.trim().toLowerCase() ==
                  layoutName.trim().toLowerCase();
            })
            ..insert(0, payload);
      await _writeSavedDesktopLayouts(savedLayouts);
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
      _desktopDragNotifier.value++;
    });

    await BaseOverlays.success(
      message: layoutName != null && layoutName.trim().isNotEmpty
          ? "Layout '$layoutName' berhasil disimpan."
          : "Layout desktop berhasil disimpan.",
    );
  }

  Future<void> _showSaveLayoutDialog(
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
      await _saveDesktopWindowLayouts(layouts, layoutName: result);
    }
  }

  Future<void> _applyDesktopLayoutJson(
    String layoutJson, {
    String? layoutName,
  }) async {
    final _DynamicChartSavedLayoutPayload payload =
        _decodeDesktopSavedLayoutPayload(layoutJson, legacyName: layoutName);
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
        _desktopDragNotifier.value++;
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

  Future<void> _showLoadLayoutDialog() async {
    final List<_DynamicChartSavedLayoutPayload> savedLayouts =
        _readSavedDesktopLayouts();
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
                          final _DynamicChartSavedLayoutPayload payload =
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
                                await _applyDesktopLayoutJson(
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
                                            _savedLayoutMetaLine(payload),
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
                                                  _formatSavedLayoutDate(
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
                                        await _deleteSavedDesktopLayout(
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

  Future<void> _showHiddenPanelsDialog({
    required List<_DynamicChartDesktopPanelDescriptor> hiddenPanels,
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
                              final _DynamicChartDesktopPanelDescriptor panel =
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

  List<_DynamicChartDesktopPanelDescriptor> _desktopPanelDescriptors(
    List<Chart> charts,
    bool glass,
  ) {
    return charts.map((chartItem) {
      final bool isSummary = chartItem is Summary;

      return _DynamicChartDesktopPanelDescriptor(
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

  int _desktopFloatingColumnCount(
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

  double _desktopFloatingPanelWidth({
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

  double _desktopFloatingPanelHeight(
    _DynamicChartDesktopPanelDescriptor panel,
    double panelWidth,
  ) {
    final double scaledHeight = panel.height * (panelWidth / panel.width);

    return math
        .min(panel.height, scaledHeight)
        .clamp(panel.minHeight, panel.height)
        .toDouble();
  }

  double _estimatedDesktopDefaultWorkspaceHeight({
    required List<_DynamicChartDesktopPanelDescriptor> panels,
    required double workspaceWidth,
    required double minHeight,
  }) {
    if (panels.isEmpty) {
      return minHeight;
    }

    final double gap = Dimensions.size20;
    final int columnCount = _desktopFloatingColumnCount(
      workspaceWidth,
      panelCount: panels.length,
    );
    final double panelWidth = _desktopFloatingPanelWidth(
      workspaceWidth: workspaceWidth,
      columnCount: columnCount,
      gap: gap,
    );

    double totalHeight = gap;

    for (int start = 0; start < panels.length; start += columnCount) {
      final List<_DynamicChartDesktopPanelDescriptor> rowPanels =
          panels.skip(start).take(columnCount).toList();

      double rowHeight = 0;
      for (final _DynamicChartDesktopPanelDescriptor panel in rowPanels) {
        rowHeight = math.max(
          rowHeight,
          _desktopFloatingPanelHeight(panel, panelWidth),
        );
      }

      totalHeight += rowHeight + gap;
    }

    return math.max(minHeight, totalHeight);
  }

  double _storedDesktopLayoutBottom({
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

  double _resolvedDesktopWorkspaceHeight({
    required List<_DynamicChartDesktopPanelDescriptor> panels,
    required double workspaceWidth,
    required double minHeight,
  }) {
    final Set<String> visibleIds = panels.map((panel) => panel.id).toSet();
    final double defaultHeight = _estimatedDesktopDefaultWorkspaceHeight(
      panels: panels,
      workspaceWidth: workspaceWidth,
      minHeight: minHeight,
    );
    final double storedBottom = _storedDesktopLayoutBottom(
      visibleIds: visibleIds,
      minHeight: minHeight,
    );

    return math.max(minHeight, math.max(defaultHeight, storedBottom));
  }

  Map<String, DynamicChartDesktopWindowLayout> _defaultDesktopWindowLayouts(
    List<_DynamicChartDesktopPanelDescriptor> panels,
    Size workspaceSize,
  ) {
    final Map<String, DynamicChartDesktopWindowLayout> defaults =
        <String, DynamicChartDesktopWindowLayout>{};

    if (panels.isEmpty) {
      return defaults;
    }

    final double gap = Dimensions.size20;
    final int columnCount = _desktopFloatingColumnCount(
      workspaceSize.width,
      panelCount: panels.length,
    );
    final double panelWidth = _desktopFloatingPanelWidth(
      workspaceWidth: workspaceSize.width,
      columnCount: columnCount,
      gap: gap,
    );
    double currentTop = gap;
    int nextZIndex = 10;

    for (int start = 0; start < panels.length; start += columnCount) {
      final List<_DynamicChartDesktopPanelDescriptor> rowPanels =
          panels.skip(start).take(columnCount).toList();

      double rowHeight = 0;
      for (final _DynamicChartDesktopPanelDescriptor panel in rowPanels) {
        rowHeight = math.max(
          rowHeight,
          _desktopFloatingPanelHeight(panel, panelWidth),
        );
      }

      for (int column = 0; column < rowPanels.length; column++) {
        final _DynamicChartDesktopPanelDescriptor panel = rowPanels[column];

        defaults[panel.id] = DynamicChartDesktopWindowLayout(
          id: panel.id,
          left: gap + ((panelWidth + gap) * column),
          top: currentTop,
          width: panelWidth,
          height: _desktopFloatingPanelHeight(panel, panelWidth),
          zIndex: nextZIndex++,
        );
      }

      currentTop += rowHeight + gap;
    }

    return defaults;
  }

  Map<String, DynamicChartDesktopWindowLayout> _mergedDesktopWindowLayouts(
    List<_DynamicChartDesktopPanelDescriptor> panels,
    Size workspaceSize,
  ) {
    final Map<String, DynamicChartDesktopWindowLayout> defaults =
        _defaultDesktopWindowLayouts(panels, workspaceSize);

    return <String, DynamicChartDesktopWindowLayout>{
      for (final _DynamicChartDesktopPanelDescriptor panel in panels)
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
      _desktopDragNotifier.value++;
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
      _desktopDragNotifier.value++;
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
      _desktopDragNotifier.value++;
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
      _desktopDragNotifier.value++;
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
    final bool hasSavedLayouts = _readSavedDesktopLayouts().isNotEmpty;

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
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              _showSaveLayoutDialog(desktopWindowLayouts);
                            },
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text("Save layout"),
                          ),
                          if (hasSavedLayouts)
                            OutlinedButton.icon(
                              onPressed: _showLoadLayoutDialog,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text("Load layout"),
                            ),
                          OutlinedButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Refresh"),
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
    final List<_DynamicChartDesktopPanelDescriptor> allPanels =
        _desktopPanelDescriptors(charts, glass);
    final List<_DynamicChartDesktopPanelDescriptor> hiddenPanels = allPanels
        .where((panel) => hiddenDesktopPanels.contains(panel.id))
        .toList();
    final List<_DynamicChartDesktopPanelDescriptor> visiblePanels = allPanels
        .where((panel) => !hiddenDesktopPanels.contains(panel.id))
        .toList();
    final bool hasSavedLayouts = _readSavedDesktopLayouts().isNotEmpty;

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
                  final double workspaceHeight =
                      _resolvedDesktopWorkspaceHeight(
                    panels: visiblePanels,
                    workspaceWidth: workspaceWidth,
                    minHeight: minWorkspaceHeight,
                  );
                  final Size workspaceSize = Size(
                    workspaceWidth,
                    workspaceHeight,
                  );
                  final Map<String, DynamicChartDesktopWindowLayout>
                      effectiveLayouts = _mergedDesktopWindowLayouts(
                    visiblePanels,
                    workspaceSize,
                  );
                  final List<_DynamicChartDesktopPanelDescriptor>
                      orderedPanels = visiblePanels.toList()
                        ..sort(
                          (
                            _DynamicChartDesktopPanelDescriptor a,
                            _DynamicChartDesktopPanelDescriptor b,
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
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              _showSaveLayoutDialog(effectiveLayouts);
                            },
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text("Save layout"),
                          ),
                          if (hasSavedLayouts)
                            OutlinedButton.icon(
                              onPressed: _showLoadLayoutDialog,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text("Load layout"),
                            ),
                          OutlinedButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Refresh"),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              resetDesktopWorkspace();
                            },
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text("Reset layout"),
                          ),
                          if (hiddenPanels.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {
                                _showHiddenPanelsDialog(
                                  hiddenPanels: hiddenPanels,
                                  glass: glass,
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text("Tambah widget"),
                            ),
                        ],
                      ),
                      SizedBox(height: Dimensions.size15),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(Dimensions.size20),
                          color: glass
                              ? Colors.white.withOpacity(0.03)
                              : Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: glass
                                ? Colors.white.withOpacity(0.08)
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.45),
                            width: 0.7,
                          ),
                        ),
                        child: SizedBox(
                          width: workspaceWidth,
                          height: workspaceHeight,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _desktopDragNotifier,
                            builder: (context, _, __) {
                              return Stack(
                                children: [
                                  for (final _DynamicChartDesktopPanelDescriptor panel
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
                                          maxDesktopZIndex(effectiveLayouts),
                                      minimized:
                                          effectiveLayouts[panel.id]!.minimized,
                                      maximized:
                                          effectiveLayouts[panel.id]!.maximized,
                                      floatingEnabled: true,
                                      title: panel.title,
                                      icon: panel.icon,
                                      onFocus: () => bringDesktopWindowToFront(
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
                                          _desktopDragNotifier.value++;
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
                                          _desktopDragNotifier.value++;
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
                                        physics: const BouncingScrollPhysics(),
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
}

class _DynamicChartDesktopPanelDescriptor {
  final String id;
  final String title;
  final IconData icon;
  final double width;
  final double height;
  final double minWidth;
  final double minHeight;
  final Widget child;

  const _DynamicChartDesktopPanelDescriptor({
    required this.id,
    required this.title,
    required this.icon,
    required this.width,
    required this.height,
    required this.minWidth,
    required this.minHeight,
    required this.child,
  });
}

class _DynamicChartSavedLayoutPayload {
  final int version;
  final String name;
  final String userId;
  final String username;
  final String savedAt;
  final int dashboardUiType;
  final bool floatingMode;
  final bool desktopNavigationVisible;
  final List<String> widgetOrder;
  final List<String> hiddenWidgetIds;
  final List<DynamicChartDesktopWindowLayout> windows;

  const _DynamicChartSavedLayoutPayload({
    required this.version,
    required this.name,
    required this.userId,
    required this.username,
    required this.savedAt,
    required this.dashboardUiType,
    required this.floatingMode,
    required this.desktopNavigationVisible,
    required this.widgetOrder,
    required this.hiddenWidgetIds,
    required this.windows,
  });

  factory _DynamicChartSavedLayoutPayload.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawWindows = json["windows"] is List
        ? json["windows"] as List<dynamic>
        : const <dynamic>[];
    final List<DynamicChartDesktopWindowLayout> parsedWindows =
        <DynamicChartDesktopWindowLayout>[];

    for (final dynamic item in rawWindows) {
      if (item is! Map) {
        continue;
      }

      final DynamicChartDesktopWindowLayout layout =
          DynamicChartDesktopWindowLayout.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (layout.id.isEmpty) {
        continue;
      }

      parsedWindows.add(layout);
    }

    return _DynamicChartSavedLayoutPayload(
      version: _readInt(json["version"], fallback: 3),
      name: (json["name"] ?? json["layoutName"] ?? "").toString(),
      userId: (json["userId"] ?? json["ownerId"] ?? "").toString(),
      username: (json["username"] ?? json["ownerName"] ?? "").toString(),
      savedAt: (json["savedAt"] ?? "").toString(),
      dashboardUiType: _readInt(json["dashboardUiType"], fallback: 1),
      floatingMode: _readBool(json["floatingMode"], fallback: true),
      desktopNavigationVisible:
          _readBool(json["desktopNavigationVisible"], fallback: true),
      widgetOrder: _readStringList(json["widgetOrder"]),
      hiddenWidgetIds: _readStringList(json["hiddenWidgetIds"]),
      windows: parsedWindows,
    );
  }

  DateTime? get savedAtDateTime {
    if (savedAt.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(savedAt);
  }

  String get themeLabel => dashboardUiType == 2 ? "Glass" : "Solid";

  Map<String, DynamicChartDesktopWindowLayout> get layoutsMap {
    return <String, DynamicChartDesktopWindowLayout>{
      for (final DynamicChartDesktopWindowLayout layout in windows)
        layout.id: layout,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "version": version,
      "name": name,
      "userId": userId,
      "username": username,
      "savedAt": savedAt,
      "dashboardUiType": dashboardUiType,
      "floatingMode": floatingMode,
      "desktopNavigationVisible": desktopNavigationVisible,
      "widgetOrder": widgetOrder,
      "hiddenWidgetIds": hiddenWidgetIds,
      "windows": windows.map((DynamicChartDesktopWindowLayout item) {
        return item.toJson();
      }).toList(),
    };
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value.map((dynamic item) => item.toString()).toList();
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == "true" || normalized == "1") {
        return true;
      }
      if (normalized == "false" || normalized == "0") {
        return false;
      }
    }

    return fallback;
  }
}

class AppBarDynamicChart extends StatelessWidget {
  final String title;
  final String rangeLabel;
  final VoidCallback onPickRange;
  final VoidCallback onBack;
  final bool isGlass;
  final bool showBackButton;
  final bool isMobile;

  const AppBarDynamicChart({
    required this.title,
    required this.rangeLabel,
    required this.onPickRange,
    required this.onBack,
    required this.isGlass,
    required this.showBackButton,
    required this.isMobile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return Container(
        height: Dimensions.size50,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
        child: Row(
          children: [
            if (showBackButton) ...[
              GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size20,
                opacity: 0.12,
                borderOpacity: 0.22,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size45,
                  height: Dimensions.size45,
                  child: IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isMobile
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.arrow_back_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: Dimensions.size20,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Dimensions.size10),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Dimensions.text14,
                  fontWeight: FontWeight.w900,
                  color: isGlass
                      ? Colors.white.withOpacity(0.95)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: Dimensions.size10),
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              onTap: onPickRange,
              child: GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size15,
                opacity: 0.12,
                borderOpacity: 0.22,
                padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
                child: SizedBox(
                  height: Dimensions.size40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: Dimensions.size20,
                        color: Colors.white.withOpacity(0.92),
                      ),
                      SizedBox(width: Dimensions.size10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          rangeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Dimensions.text12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.size5),
                      Icon(
                        Icons.expand_more_rounded,
                        size: Dimensions.size20,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: Dimensions.size55,
      padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
      child: Row(
        children: [
          if (showBackButton) ...[
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.size100),
              onTap: onBack,
              child: Padding(
                padding: EdgeInsets.all(Dimensions.size10),
                child: Icon(
                  isMobile
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_back_rounded,
                  size: Dimensions.size20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.90),
                ),
              ),
            ),
            SizedBox(width: Dimensions.size5),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w900,
                color: isGlass
                    ? Colors.white.withOpacity(0.95)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: Dimensions.size10),
          InkWell(
            borderRadius: BorderRadius.circular(Dimensions.size10),
            onTap: onPickRange,
            child: Container(
              height: Dimensions.size35,
              padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(Dimensions.size10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.35
                            : 0.55,
                      ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: Dimensions.size15,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.88),
                  ),
                  SizedBox(width: Dimensions.size5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Insight extends StatelessWidget {
  final num total;
  final int rows;
  final String rangeLabel;

  final List<MapEntry<String, num>> compositionByVariable;
  final List<MapEntry<String, num>> compositionByCategory;

  final bool isGlass;

  const Insight({
    required this.total,
    required this.rows,
    required this.rangeLabel,
    required this.compositionByVariable,
    required this.compositionByCategory,
    required this.isGlass,
    super.key,
  });

  String persentText(num v) {
    if (total <= 0) {
      return "0%";
    }
    final double p = (v / total) * 100.0;
    final String s = p >= 10 ? p.toStringAsFixed(0) : p.toStringAsFixed(1);
    return "$s% dari total";
  }

  @override
  Widget build(BuildContext context) {
    final MapEntry<String, num>? topVariable =
        compositionByVariable.firstOrNull;
    final MapEntry<String, num>? topCategory =
        compositionByCategory.firstOrNull;
    final Color primaryText = isGlass
        ? Colors.white.withOpacity(0.92)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.90);
    final Color secondaryText = isGlass
        ? Colors.white.withOpacity(0.74)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.86);
    final Color tileFill = isGlass
        ? Colors.white.withOpacity(0.08)
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.55,
            );
    final Color tileBorder = isGlass
        ? Colors.white.withOpacity(0.14)
        : Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.55,
            );

    Widget metricTile(String label, String value, String helper) {
      return Container(
        constraints: const BoxConstraints(minWidth: 150),
        padding: EdgeInsets.all(Dimensions.size10),
        decoration: BoxDecoration(
          color: tileFill,
          borderRadius: BorderRadius.circular(Dimensions.size15),
          border: Border.all(color: tileBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Dimensions.text11,
                fontWeight: FontWeight.w800,
                color: secondaryText,
              ),
            ),
            SizedBox(height: Dimensions.size4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Dimensions.text16,
                fontWeight: FontWeight.w900,
                color: primaryText,
              ),
            ),
            SizedBox(height: Dimensions.size2),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Dimensions.text10,
                fontWeight: FontWeight.w700,
                color: secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    Widget highlightRow(String label, MapEntry<String, num>? item) {
      final String name = item?.key.isNotEmpty == true ? item!.key : "-";
      final String helper = item == null ? "-" : persentText(item.value);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size10,
          vertical: Dimensions.size10,
        ),
        decoration: BoxDecoration(
          color: tileFill,
          borderRadius: BorderRadius.circular(Dimensions.size15),
          border: Border.all(color: tileBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: Dimensions.text11,
                      fontWeight: FontWeight.w800,
                      color: secondaryText,
                    ),
                  ),
                  SizedBox(height: Dimensions.size2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Dimensions.text13,
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Dimensions.size10),
            Text(
              helper,
              style: TextStyle(
                fontSize: Dimensions.text11,
                fontWeight: FontWeight.w800,
                color: secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    final Widget inner = Padding(
      padding: EdgeInsets.fromLTRB(
        Dimensions.size20,
        Dimensions.size15,
        Dimensions.size20,
        Dimensions.size15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ringkasan cepat",
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              color: primaryText,
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            rangeLabel,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
          SizedBox(height: Dimensions.size10),
          Wrap(
            spacing: Dimensions.size10,
            runSpacing: Dimensions.size10,
            children: [
              metricTile("Total", formatChartNumber(total), "Akumulasi nilai"),
              metricTile("Data", rows.toString(), "Baris tercatat"),
              metricTile(
                "Tipe dominan",
                topVariable?.key ?? "-",
                topVariable == null ? "-" : persentText(topVariable.value),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          highlightRow("Kategori teratas", topCategory),
          SizedBox(height: Dimensions.size10),
          highlightRow("Variabel teratas", topVariable),
        ],
      ),
    );

    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.10,
        borderOpacity: 0.18,
        padding: EdgeInsets.zero,
        child: inner,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        border: Border.all(
          color: isGlass
              ? Colors.white.withOpacity(0.18)
              : Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.35
                        : 0.55,
                  ),
        ),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.dark)
            BoxShadow(
              blurRadius: Dimensions.size25,
              offset: Offset(0, Dimensions.size10),
              color: Colors.black.withValues(alpha: 0.06),
            ),
        ],
      ),
      child: inner,
    );
  }
}

class InsightWidget {
  final num total;
  final int rows;
  final List<MapEntry<String, num>> compositionByVariable;
  final List<MapEntry<String, num>> compositionByCategory;

  const InsightWidget({
    required this.total,
    required this.rows,
    required this.compositionByVariable,
    required this.compositionByCategory,
  });
}

List<MapEntry<String, num>> topWithOther(
  Map<String, num> map, {
  int take = 5,
  String othersLabel = "Lainnya",
}) {
  final List<MapEntry<String, num>> sorted = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.length <= take) {
    return sorted;
  }

  final List<MapEntry<String, num>> head = sorted.take(take).toList();
  final num tailSum = sorted.skip(take).fold<num>(0, (p, e) => p + e.value);

  return <MapEntry<String, num>>[
    ...head,
    MapEntry<String, num>(othersLabel, tailSum),
  ];
}

InsightWidget buildInsight(List<Map<String, dynamic>> src) {
  final Map<String, num> byCategory = {};
  final Map<String, num> byVariable = {};

  num total = 0;
  int rows = 0;

  for (final Map<String, dynamic> e in src) {
    rows += 1;

    final String category = (e["category"] ?? "").toString().trim();
    final String variable = (e["variable"] ?? "").toString().trim();
    final num value = parseChartNumber(e["value"]);

    total += value;

    final String safeCategory = category.isEmpty ? "-" : category;
    final String safeVariable = variable.isEmpty ? "-" : variable;

    byCategory[safeCategory] = (byCategory[safeCategory] ?? 0) + value;
    byVariable[safeVariable] = (byVariable[safeVariable] ?? 0) + value;
  }

  return InsightWidget(
    total: total,
    rows: rows,
    compositionByVariable: topWithOther(
      byVariable,
      take: 5,
      othersLabel: "other".tr(),
    ),
    compositionByCategory: topWithOther(
      byCategory,
      take: 5,
      othersLabel: "other".tr(),
    ),
  );
}

num parseChartNumber(dynamic value) {
  if (value is num) {
    return value;
  }

  final String raw = (value ?? "").toString().trim();
  if (raw.isEmpty) {
    return 0;
  }

  String normalized = raw.replaceAll(RegExp(r"[^0-9,.\-]"), "");
  if (normalized.isEmpty ||
      normalized == "-" ||
      normalized == "." ||
      normalized == ",") {
    return 0;
  }

  if (normalized.contains(",") && normalized.contains(".")) {
    if (normalized.lastIndexOf(",") > normalized.lastIndexOf(".")) {
      normalized = normalized.replaceAll(".", "").replaceAll(",", ".");
    } else {
      normalized = normalized.replaceAll(",", "");
    }
  } else if (normalized.contains(",")) {
    if (RegExp(r",\d{1,2}$").hasMatch(normalized)) {
      normalized = normalized.replaceAll(".", "").replaceAll(",", ".");
    } else {
      normalized = normalized.replaceAll(",", "");
    }
  } else if (normalized.contains(".") &&
      !RegExp(r"\.\d{1,2}$").hasMatch(normalized)) {
    normalized = normalized.replaceAll(".", "");
  }

  return num.tryParse(normalized) ?? 0;
}

String formatChartNumber(num value) {
  final bool wholeNumber = value == value.roundToDouble();
  final NumberFormat formatter = wholeNumber
      ? NumberFormat.decimalPattern("id")
      : NumberFormat("#,##0.##", "id");
  return formatter.format(value);
}

String formatChartValue(dynamic value) {
  if (value == null) {
    return "";
  }

  if (value is num) {
    return formatChartNumber(value);
  }

  final String raw = value.toString().trim();
  if (raw.isEmpty) {
    return "";
  }

  final RegExpMatch? match = RegExp(r"-?[\d.,]+").firstMatch(raw);
  if (match == null) {
    return raw;
  }

  final String token = match.group(0) ?? "";
  if (token.isEmpty) {
    return raw;
  }

  final String formatted = formatChartNumber(parseChartNumber(token));
  return raw.replaceRange(match.start, match.end, formatted);
}

List<Map<String, dynamic>> normalizeChartRows(dynamic data) {
  if (data is! List) {
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      final bool looksLikePoint = map.containsKey("value") &&
          (map.containsKey("category") || map.containsKey("variable"));
      if (looksLikePoint) {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            "variable": (map["variable"] ?? "").toString().trim(),
            "category": (map["category"] ?? "").toString().trim(),
            "value": parseChartNumber(map["value"]),
          },
        ];
      }
    }
    return <Map<String, dynamic>>[];
  }

  return data.whereType<Map>().map((dynamic item) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
    return <String, dynamic>{
      "variable": (map["variable"] ?? "").toString().trim(),
      "category": (map["category"] ?? "").toString().trim(),
      "value": parseChartNumber(map["value"]),
    };
  }).toList();
}

class DynamicSummarySnapshot {
  final String label;
  final String value;
  final num? numericValue;

  const DynamicSummarySnapshot({
    required this.label,
    required this.value,
    required this.numericValue,
  });
}

DynamicSummarySnapshot? parseSummarySnapshot(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final String label = (map["label"] ?? "").toString().trim();
    final dynamic rawValue = map["value"];
    final String value = formatChartValue(rawValue);
    final bool hasUsableValue = value.trim().isNotEmpty;

    if (!hasUsableValue) {
      return null;
    }

    return DynamicSummarySnapshot(
      label: label,
      value: hasUsableValue ? value : "-",
      numericValue: rawValue == null ? null : parseChartNumber(rawValue),
    );
  }

  final List<Map<String, dynamic>> rows = normalizeChartRows(data);
  if (rows.isEmpty) {
    return null;
  }

  final InsightWidget insight = buildInsight(rows);
  return DynamicSummarySnapshot(
    label: "Total data",
    value: formatChartNumber(insight.total),
    numericValue: insight.total,
  );
}

Color summaryAccentColor(String? raw) {
  final String value = (raw ?? "").trim().toLowerCase();
  if (value.isEmpty) {
    return const Color(0xFF4C6FFF);
  }
  if (value.contains("red")) {
    return const Color(0xFFE03131);
  }
  if (value.contains("green")) {
    return const Color(0xFF2F9E44);
  }
  if (value.contains("orange")) {
    return const Color(0xFFF08C00);
  }
  if (value.contains("purple")) {
    return const Color(0xFF7B61FF);
  }
  if (value.contains("blue")) {
    return const Color(0xFF1971C2);
  }

  final String hex = value.replaceAll("#", "");
  if (hex.length == 6 || hex.length == 8) {
    final String normalized = hex.length == 6 ? "FF$hex" : hex;
    final int? parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }

  return const Color(0xFF4C6FFF);
}

IconData summaryIcon(String? raw) {
  final String value = (raw ?? "").trim().toLowerCase();

  if (value.contains("money") || value.contains("cash")) {
    return Icons.payments_rounded;
  }
  if (value.contains("person") || value.contains("user")) {
    return Icons.person_rounded;
  }
  if (value.contains("cart") || value.contains("bag")) {
    return Icons.shopping_bag_rounded;
  }
  if (value.contains("box") || value.contains("inventory")) {
    return Icons.inventory_2_rounded;
  }
  if (value.contains("trend") || value.contains("chart")) {
    return Icons.trending_up_rounded;
  }

  return Icons.auto_graph_rounded;
}

class DynamicSummaryCard extends StatefulWidget {
  final Summary summary;
  final Jiffy begin;
  final Jiffy until;
  final bool isGlass;
  final dynamic initialData;

  const DynamicSummaryCard({
    required this.summary,
    required this.begin,
    required this.until,
    required this.isGlass,
    this.initialData,
    super.key,
  });

  @override
  State<DynamicSummaryCard> createState() => _DynamicSummaryCardState();
}

class _DynamicSummaryCardState extends State<DynamicSummaryCard> {
  bool loading = true;
  DynamicSummarySnapshot? snapshot;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    snapshot = parseSummarySnapshot(widget.initialData);
    loading = widget.initialData == null;
    if (widget.initialData == null) {
      fetch();
    }
  }

  @override
  void didUpdateWidget(covariant DynamicSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialData != widget.initialData &&
        widget.initialData != null) {
      snapshot = parseSummarySnapshot(widget.initialData);
      loading = false;
    }

    final bool changed =
        !_sameDay(oldWidget.begin.dateTime, widget.begin.dateTime) ||
            !_sameDay(oldWidget.until.dateTime, widget.until.dateTime);

    if (changed) {
      fetch();
    }
  }

  void fetch() {
    context.read<DynamicChartBloc>().add(
          DynamicChartData(
            id: widget.summary.id,
            begin: widget.begin,
            until: widget.until,
          ),
        );
  }

  String rangeLabel() {
    final String a = widget.begin.format(pattern: "d MMM yyyy");
    final String z = widget.until.format(pattern: "d MMM yyyy");
    return "$a - $z";
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartDataLoading && state.id == widget.summary.id) {
          setState(() {
            loading = true;
          });
        } else if (state is DynamicChartDataSuccess &&
            state.id == widget.summary.id) {
          setState(() {
            snapshot = parseSummarySnapshot(state.data);
          });
        } else if (state is DynamicChartDataFinished &&
            state.id == widget.summary.id) {
          setState(() => loading = false);
        }
      },
      child: loading ? LoadingCard(isGlass: widget.isGlass) : content(),
    );
  }

  Widget content() {
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final Color accent = summaryAccentColor(widget.summary.color);
    final IconData icon = summaryIcon(widget.summary.icon);
    final Color primaryText = widget.isGlass
        ? Colors.white.withOpacity(0.94)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92);
    final Color secondaryText = widget.isGlass
        ? Colors.white.withOpacity(0.74)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.86);

    final Widget inner = Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isGlass
              ? <Color>[
                  accent.withValues(alpha: 0.18),
                  Colors.white.withOpacity(0.03),
                ]
              : <Color>[
                  accent.withValues(alpha: 0.12),
                  Theme.of(context).colorScheme.surface,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: Dimensions.size20),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.text13,
                        fontWeight: FontWeight.w900,
                        color: primaryText,
                      ),
                    ),
                    SizedBox(height: Dimensions.size2),
                    Text(
                      rangeLabel(),
                      style: TextStyle(
                        fontSize: Dimensions.text10,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size15),
          Text(
            snapshot!.value,
            style: TextStyle(
              fontSize: Dimensions.text24,
              fontWeight: FontWeight.w900,
              color: primaryText,
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            snapshot!.label.isEmpty
                ? "Ringkasan cepat siap dipakai untuk sales."
                : snapshot!.label,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );

    if (widget.isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.10,
        borderOpacity: 0.18,
        padding: EdgeInsets.zero,
        child: inner,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.55,
              ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.size15),
        child: inner,
      ),
    );
  }
}

extension ChartModelX on ChartModel {
  String label() {
    switch (this) {
      case ChartModel.stackedColumn:
        return "Stacked Column";
      case ChartModel.groupedColumn:
        return "Diverging Bar Chart";
      case ChartModel.line:
        return "Line";
      case ChartModel.stackedArea:
        return "Stacked Area";
      case ChartModel.stackedBar:
        return "Stacked Bar";
      case ChartModel.pie:
        return "Pie";
    }
  }

  IconData icon() {
    switch (this) {
      case ChartModel.stackedColumn:
        return Icons.stacked_bar_chart_rounded;
      case ChartModel.groupedColumn:
        return Icons.compare_arrows_rounded;
      case ChartModel.line:
        return Icons.show_chart_rounded;
      case ChartModel.stackedArea:
        return Icons.area_chart_rounded;
      case ChartModel.stackedBar:
        return Icons.view_week_rounded;
      case ChartModel.pie:
        return Icons.pie_chart_rounded;
    }
  }

  bool isStacked() {
    switch (this) {
      case ChartModel.stackedColumn:
      case ChartModel.stackedArea:
      case ChartModel.stackedBar:
        return true;
      case ChartModel.groupedColumn:
      case ChartModel.line:
      case ChartModel.pie:
        return false;
    }
  }

  bool isCircular() => this == ChartModel.pie;
}

class ChartCard extends StatefulWidget {
  final Chart chart;
  final Jiffy begin;
  final Jiffy until;
  final bool isGlass;
  final bool compact;
  final dynamic initialData;

  const ChartCard({
    required this.chart,
    required this.begin,
    required this.until,
    required this.isGlass,
    this.compact = false,
    this.initialData,
    super.key,
  });

  @override
  State<ChartCard> createState() => ChartCardState();
}

class ChartCardState extends State<ChartCard> {
  bool loading = true;
  List<Map<String, dynamic>>? raw;

  late ZoomPanBehavior zoom;

  ChartModel model = ChartModel.stackedColumn;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static const List<Color> basePalette = [
    Color(0xFFB9A7FF),
    Color(0xFFFFC08A),
    Color(0xFF9BE7FF),
    Color(0xFFA8F0D5),
    Color(0xFFFFA7C2),
    Color(0xFFB8C7FF),
    Color(0xFFFFE3B6),
    Color(0xFFE7B6FF),
  ];

  @override
  void initState() {
    super.initState();

    zoom = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      zoomMode: ZoomMode.x,
    );

    raw = normalizeChartRows(widget.initialData);
    loading = widget.initialData == null;
    if (widget.initialData == null) {
      fetch();
    }
  }

  @override
  void didUpdateWidget(covariant ChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialData != widget.initialData &&
        widget.initialData != null) {
      setState(() {
        raw = normalizeChartRows(widget.initialData);
        loading = false;
      });
    }

    final bool changed =
        !_sameDay(oldWidget.begin.dateTime, widget.begin.dateTime) ||
            !_sameDay(oldWidget.until.dateTime, widget.until.dateTime);

    if (changed) {
      fetch();
    }
  }

  void fetch() {
    context.read<DynamicChartBloc>().add(
          DynamicChartData(
            id: widget.chart.id,
            begin: widget.begin,
            until: widget.until,
          ),
        );
  }

  Future<void> selectModel() async {
    final ChartModel? selected = await showModalBottomSheet<ChartModel>(
      context: context,
      useSafeArea: false,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.size20),
        ),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.55,
              ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        final ColorScheme cs = Theme.of(context).colorScheme;

        final List<ChartModel> models = <ChartModel>[
          ChartModel.stackedColumn,
          ChartModel.groupedColumn,
          ChartModel.line,
          ChartModel.stackedArea,
          ChartModel.stackedBar,
          ChartModel.pie,
        ];

        final double bottomInset = MediaQuery.of(context).padding.bottom;
        final double screenH = MediaQuery.of(context).size.height;
        final double maxH = screenH * 0.30;

        const int crossAxisCount = 3;
        final double gap = Dimensions.size10;
        final double cardPadding = Dimensions.size10;
        final double headerH = Dimensions.size20;

        final double tileH = math.max(92.0, Dimensions.size100.toDouble());

        final int rows = (models.length / crossAxisCount).ceil();
        final double gridH = (rows * tileH) + ((rows - 1) * gap);

        final double estimatedH = headerH +
            Dimensions.size10 +
            gridH +
            (cardPadding * 2) +
            bottomInset +
            Dimensions.size10;

        final bool needsScroll = estimatedH > maxH;

        Color modelColor(ChartModel m) {
          switch (m) {
            case ChartModel.stackedColumn:
              return const Color.fromARGB(255, 157, 162, 0);
            case ChartModel.groupedColumn:
              return const Color.fromARGB(255, 19, 96, 0);
            case ChartModel.line:
              return const Color.fromARGB(255, 255, 152, 63);
            case ChartModel.stackedArea:
              return const Color.fromARGB(255, 0, 0, 0);
            case ChartModel.stackedBar:
              return const Color.fromARGB(255, 0, 27, 125);
            case ChartModel.pie:
              return const Color.fromARGB(255, 255, 0, 0);
          }
        }

        Widget gridItem(ChartModel m) {
          final bool active = m == model;

          final Color accent = modelColor(m);

          return InkWell(
            borderRadius: BorderRadius.circular(Dimensions.size15),
            onTap: () => Navigator.of(context).pop(m),
            child: Container(
              height: tileH,
              padding: EdgeInsets.all(Dimensions.size10),
              decoration: BoxDecoration(
                color: active
                    ? Color.alphaBlend(
                        accent.withValues(alpha: 0.10),
                        cs.surface,
                      )
                    : cs.surface,
                borderRadius: BorderRadius.circular(Dimensions.size15),
                border: Border.all(
                  color: active
                      ? Color.alphaBlend(
                          accent.withValues(alpha: 0.35),
                          cs.outlineVariant.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.35
                                    : 0.55,
                          ),
                        )
                      : cs.outlineVariant.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.55,
                        ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final bool compact = c.maxHeight < 84;

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(height: compact ? 2 : 4),
                      Container(
                        width: Dimensions.size35,
                        height: Dimensions.size35,
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            accent.withValues(alpha: active ? 0.18 : 0.12),
                            cs.surface,
                          ),
                          borderRadius: BorderRadius.circular(
                            Dimensions.size15,
                          ),
                          border: Border.all(
                            color: accent.withValues(
                              alpha: active ? 0.35 : 0.22,
                            ),
                          ),
                        ),
                        child: Icon(
                          m.icon(),
                          size: Dimensions.size20,
                          color: active
                              ? accent.withValues(alpha: 1.0)
                              : accent.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      Expanded(
                        child: Center(
                          child: Text(
                            m.label(),
                            textAlign: TextAlign.center,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact
                                  ? Dimensions.text11
                                  : Dimensions.text12,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface.withValues(alpha: 0.92),
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      if (!compact) ...[
                        SizedBox(height: Dimensions.size2),
                        Text(
                          m.isCircular()
                              ? "Circular"
                              : (m.isStacked() ? "Stacked" : "Non-stacked"),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:
                                compact ? Dimensions.text9 : Dimensions.text10,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                            height: 1.05,
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 4 : 8),
                      Container(
                        width: Dimensions.size20,
                        height: Dimensions.size20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? accent : Colors.transparent,
                          border: Border.all(
                            color: active
                                ? accent
                                : cs.onSurfaceVariant
                                    .withValues(alpha: 0.85)
                                    .withValues(alpha: 0.65),
                            width: 1.6,
                          ),
                        ),
                        child: active
                            ? Icon(
                                Icons.check,
                                size: Dimensions.size10,
                                color: cs.surface,
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        final Widget inner = SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              cardPadding,
              Dimensions.size10,
              cardPadding,
              bottomInset + Dimensions.size10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerH,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "select_chartmodel".tr(),
                      style: TextStyle(
                        fontSize: Dimensions.text16,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.size15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: models.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    mainAxisExtent: tileH,
                  ),
                  itemBuilder: (_, i) => gridItem(models[i]),
                ),
              ],
            ),
          ),
        );

        final Widget body = needsScroll
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: inner,
                ),
              )
            : inner;

        return body;
      },
    );

    if (selected == null) {
      return;
    }
    setState(() => model = selected);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartDataLoading && state.id == widget.chart.id) {
          setState(() {
            loading = true;
            raw = null;
          });
        } else if (state is DynamicChartDataSuccess &&
            state.id == widget.chart.id) {
          setState(() {
            raw = normalizeChartRows(state.data);
          });
        } else if (state is DynamicChartDataFinished &&
            state.id == widget.chart.id) {
          setState(() => loading = false);
        }
      },
      child: loading ? LoadingCard(isGlass: widget.isGlass) : content(),
    );
  }

  List<String> allVariableSorted(List<Map<String, dynamic>> src) {
    final Map<String, num> totals = {};
    for (final e in src) {
      final String v = e["variable"].toString();
      final num val = parseChartNumber(e["value"]);
      totals[v] = (totals[v] ?? 0) + val;
    }

    final List<MapEntry<String, num>> sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).toList();
  }

  Color colorIndex(int i) {
    if (i < basePalette.length) {
      return basePalette[i];
    }

    final double h = (i * 0.61803398875) % 1.0;
    final HSVColor hsv = HSVColor.fromAHSV(1, 360 * h, 0.38, 0.95);
    return hsv.toColor();
  }

  String rangeLabel() {
    final String a = widget.begin.format(pattern: "d MMM yyyy");
    final String z = widget.until.format(pattern: "d MMM yyyy");
    return "$a - $z";
  }

  Widget content() {
    final bool hasData = raw != null && raw!.isNotEmpty;

    final List<String> variables =
        hasData ? allVariableSorted(raw!) : <String>[];

    final List<PieSlice> pieSlices = hasData
        ? pieChartSlices(raw!, maxSlices: 7, minPct: 2.5)
        : <PieSlice>[];

    final List<String> pieCats = pieSlices.map((e) => e.label).toList();
    final bool showDivergingLegend = model == ChartModel.groupedColumn;
    final List<String> divergingLegend = const <String>[
      "Above average",
      "Below average",
    ];

    final Widget innerChartCard = Padding(
      padding: EdgeInsets.fromLTRB(
        Dimensions.size20,
        Dimensions.size15,
        Dimensions.size20,
        Dimensions.size15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.chart.title,
                  style: TextStyle(
                    fontSize: Dimensions.text13,
                    fontWeight: FontWeight.w800,
                    color: widget.isGlass
                        ? Colors.white.withOpacity(0.95)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.92),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: Dimensions.size10),
              ChartModelPill(
                isGlass: widget.isGlass,
                model: model,
                onTap: selectModel,
              ),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          if (model == ChartModel.pie && pieCats.isNotEmpty)
            ScroolLegend(
              isGlass: widget.isGlass,
              variables: pieCats,
              colorForIndex: colorIndex,
            )
          else if (showDivergingLegend)
            ScroolLegend(
              isGlass: widget.isGlass,
              variables: divergingLegend,
              colorForIndex: (int index) {
                return index == 0
                    ? const Color(0xFF2F9E44)
                    : const Color(0xFFE03131);
              },
            )
          else if (model != ChartModel.pie && variables.isNotEmpty)
            ScroolLegend(
              isGlass: widget.isGlass,
              variables: variables,
              colorForIndex: colorIndex,
            ),
          if ((model == ChartModel.pie && pieCats.isNotEmpty) ||
              (model != ChartModel.pie && variables.isNotEmpty))
            SizedBox(height: Dimensions.size10),
          SizedBox(
            height: widget.compact ? 300 : 320,
            child: hasData ? anyChart(variables) : empthy(),
          ),
        ],
      ),
    );

    final Widget chartCard = widget.isGlass
        ? GlassContainer(
            blur: Dimensions.size20,
            borderRadius: Dimensions.size20,
            opacity: 0.10,
            borderOpacity: 0.18,
            padding: EdgeInsets.zero,
            child: innerChartCard,
          )
        : Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(Dimensions.size15),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.35
                          : 0.55,
                    ),
              ),
              boxShadow: [
                if (Theme.of(context).brightness == Brightness.dark)
                  BoxShadow(
                    blurRadius: Dimensions.size25,
                    offset: Offset(0, Dimensions.size15),
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              child: innerChartCard,
            ),
          );

    final Widget insightCard = hasData
        ? Builder(
            builder: (_) {
              final InsightWidget ins = buildInsight(raw!);
              return Insight(
                isGlass: widget.isGlass,
                total: ins.total,
                rows: ins.rows,
                rangeLabel: rangeLabel(),
                compositionByVariable: ins.compositionByVariable,
                compositionByCategory: ins.compositionByCategory,
              );
            },
          )
        : const SizedBox.shrink();

    return Column(
      children: [
        chartCard,
        if (hasData) SizedBox(height: Dimensions.size15),
        if (hasData) insightCard,
      ],
    );
  }

  Widget empthy() {
    return Center(
      child: Text(
        raw == null ? "failed_to_load_data".tr() : "no_data".tr(),
        style: TextStyle(
          fontSize: Dimensions.text13,
          fontWeight: FontWeight.w800,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.80)
              : Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget anyChart(List<String> variables) {
    if (model == ChartModel.pie) {
      return KeyedSubtree(
        key: ValueKey<String>("${widget.chart.id}_${model.name}"),
        child: pieChart(),
      );
    }
    return KeyedSubtree(
      key: ValueKey<String>("${widget.chart.id}_${model.name}"),
      child: cartesianChart(variables),
    );
  }

  List<PieSlice> pieChartSlices(
    List<Map<String, dynamic>> src, {
    int maxSlices = 8,
    double minPct = 2.5,
  }) {
    final Map<String, num> sums = {};
    num grand = 0;

    for (final e in src) {
      final String cat = (e["category"] ?? "").toString().trim();
      final num v = parseChartNumber(e["value"]);

      if (v <= 0) {
        continue;
      }
      final String safe = cat.isEmpty ? "-" : cat;

      sums[safe] = (sums[safe] ?? 0) + v;
      grand += v;
    }

    final List<MapEntry<String, num>> sorted = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty || grand <= 0) {
      return <PieSlice>[];
    }

    final List<PieSlice> out = [];
    num other = 0;

    for (final e in sorted) {
      final double pct = (e.value / grand) * 100.0;

      if (out.length >= maxSlices || pct < minPct) {
        other += e.value;
      } else {
        out.add(PieSlice(label: e.key, value: e.value));
      }
    }

    if (other > 0) {
      out.add(PieSlice(label: "other".tr(), value: other));
    }

    return out;
  }

  Widget pieChart() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<PieSlice> slices = pieChartSlices(
      raw!,
      maxSlices: 7,
      minPct: 2.5,
    );

    if (slices.isEmpty) {
      return empthy();
    }

    final num total = slices.fold<num>(0, (p, e) => p + e.value);

    double pctVal(num v) => total <= 0 ? 0 : (v / total) * 100.0;
    String pctText(num v) {
      final double p = pctVal(v);
      return p >= 10 ? "${p.toStringAsFixed(0)}%" : "${p.toStringAsFixed(1)}%";
    }

    return SfCircularChart(
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero,
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: "",
        color: cs.surfaceContainerHighest,
        textStyle: TextStyle(color: cs.onSurface),
      ),
      series: <CircularSeries<PieSlice, String>>[
        DoughnutSeries<PieSlice, String>(
          dataSource: slices,
          xValueMapper: (PieSlice s, _) => s.label,
          yValueMapper: (PieSlice s, _) => s.value.toDouble(),
          pointColorMapper: (PieSlice s, int i) => colorIndex(i),
          cornerStyle: CornerStyle.endCurve,
          innerRadius: "66%",
          radius: "92%",
          strokeColor: cs.surface,
          strokeWidth: 2,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(
              color: widget.isGlass
                  ? Colors.white.withOpacity(0.18)
                  : cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55),
              length: "10%",
              width: 1,
            ),
            builder:
                (dynamic data, dynamic point, dynamic series, int i, int s) {
              final PieSlice sl = slices[i];
              final double p = pctVal(sl.value);
              if (p < 5) {
                return const SizedBox.shrink();
              }
              return Text(
                pctText(sl.value),
                style: TextStyle(
                  fontSize: Dimensions.text11,
                  fontWeight: FontWeight.w800,
                  color: widget.isGlass
                      ? Colors.white.withOpacity(0.88)
                      : cs.onSurface.withValues(alpha: 0.88),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget cartesianChart(List<String> variables) {
    if (model == ChartModel.groupedColumn) {
      return divergingBarChart();
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final Agg agg = aggregate(raw!);
    final List<CatPoint> points = agg.points;

    num maxYForStacked() {
      return points.fold<num>(0, (p, e) {
        final num sum = e.values.values.fold<num>(0, (pp, vv) => pp + vv);
        return math.max(p, sum);
      });
    }

    num maxYForNonStacked() {
      return points.fold<num>(0, (p, e) {
        final num m = e.values.values.fold<num>(
          0,
          (pp, vv) => math.max(pp, vv),
        );
        return math.max(p, m);
      });
    }

    final num maxY = model.isStacked() ? maxYForStacked() : maxYForNonStacked();

    final double maxAxis = maxY <= 0 ? 0 : (maxY * 1.10).ceilToDouble();

    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      plotAreaBackgroundColor: Colors.transparent,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelIntersectAction: AxisLabelIntersectAction.hide,
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.85)
              : cs.onSurfaceVariant.withValues(alpha: 0.90),
        ),
        autoScrollingDelta: 7,
        autoScrollingMode: AutoScrollingMode.start,
        axisLabelFormatter: (AxisLabelRenderDetails d) {
          final String full = d.text;
          final CatPoint? p = points.firstWhereOrNull(
            (e) => e.category == full,
          );
          return ChartAxisLabel(p?.shortLabel ?? full, d.textStyle);
        },
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: maxAxis == 0 ? null : maxAxis,
        interval: maxAxis == 0
            ? null
            : maxAxis <= 0
                ? 1
                : (maxAxis / 4).ceilToDouble(),
        rangePadding: ChartRangePadding.none,
        majorGridLines: MajorGridLines(
          width: 1,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.10)
              : cs.onSurface.withValues(alpha: dark ? 0.10 : 0.08),
        ),
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.80)
              : cs.onSurfaceVariant.withValues(alpha: 0.80),
        ),
      ),
      legend: const Legend(isVisible: false),
      tooltipBehavior: toolTip(points),
      zoomPanBehavior: zoom,
      series: series(points, variables),
    );
  }

  List<DivergingPoint> divergingPoints() {
    final Agg agg = aggregate(raw!);
    if (agg.points.isEmpty) {
      return <DivergingPoint>[];
    }

    final List<MapEntry<String, double>> totals =
        agg.points.map((CatPoint point) {
      final double total = point.values.values.fold<double>(
        0,
        (double previous, num value) => previous + value.toDouble(),
      );
      return MapEntry<String, double>(point.category, total);
    }).toList();

    final double baseline = totals.fold<double>(
          0,
          (double previous, item) => previous + item.value,
        ) /
        totals.length;

    return totals.map((MapEntry<String, double> item) {
      return DivergingPoint(
        category: item.key,
        total: item.value,
        delta: item.value - baseline,
        baseline: baseline,
      );
    }).toList()
      ..sort(
        (
          DivergingPoint a,
          DivergingPoint b,
        ) =>
            b.delta.compareTo(a.delta),
      );
  }

  Widget divergingBarChart() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<DivergingPoint> points = divergingPoints();

    if (points.isEmpty) {
      return empthy();
    }

    final double maxAbs = points
        .map((DivergingPoint point) => point.delta.abs())
        .fold<double>(0, math.max);
    final double axisExtent = maxAbs <= 0 ? 1 : (maxAbs * 1.20);

    return SfCartesianChart(
      isTransposed: true,
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      plotAreaBackgroundColor: Colors.transparent,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelIntersectAction: AxisLabelIntersectAction.wrap,
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.85)
              : cs.onSurfaceVariant.withValues(alpha: 0.90),
        ),
      ),
      primaryYAxis: NumericAxis(
        minimum: -axisExtent,
        maximum: axisExtent,
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(
          width: 1,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.10)
              : cs.onSurface.withValues(alpha: dark ? 0.10 : 0.08),
        ),
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.80)
              : cs.onSurfaceVariant.withValues(alpha: 0.80),
        ),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: "",
        color: cs.surfaceContainerHighest,
        textStyle: TextStyle(color: cs.onSurface),
        builder: (
          dynamic value,
          dynamic point,
          dynamic series,
          int pointIndex,
          int seriesIndex,
        ) {
          if (pointIndex < 0 || pointIndex >= points.length) {
            return const SizedBox.shrink();
          }

          final DivergingPoint item = points[pointIndex];
          final String direction =
              item.delta >= 0 ? "Above average" : "Below average";

          return Container(
            padding: EdgeInsets.all(Dimensions.size10),
            constraints: const BoxConstraints(minWidth: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: Dimensions.size10),
                Text("Total: ${formatChartNumber(item.total)}"),
                Text(
                  "$direction ${formatChartNumber(item.delta.abs())} dari rata-rata ${formatChartNumber(item.baseline)}",
                ),
              ],
            ),
          );
        },
      ),
      series: <CartesianSeries<DivergingPoint, String>>[
        ColumnSeries<DivergingPoint, String>(
          dataSource: points,
          xValueMapper: (DivergingPoint point, _) => point.category,
          yValueMapper: (DivergingPoint point, _) => point.delta,
          pointColorMapper: (DivergingPoint point, _) {
            return point.delta >= 0
                ? const Color(0xFF2F9E44)
                : const Color(0xFFE03131);
          },
          width: 0.62,
          borderRadius: BorderRadius.circular(Dimensions.size10),
        ),
      ],
    );
  }

  List<CartesianSeries<CatPoint, String>> series(
    List<CatPoint> points,
    List<String> variables,
  ) {
    switch (model) {
      case ChartModel.stackedColumn:
        return variables.mapIndexed((index, variable) {
          final Color c = colorIndex(index);
          return StackedColumnSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint p, _) => p.category,
            yValueMapper: (CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case ChartModel.groupedColumn:
        return variables.mapIndexed((index, variable) {
          final Color c = colorIndex(index);
          return ColumnSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint p, _) => p.category,
            yValueMapper: (CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case ChartModel.line:
        return variables.mapIndexed((index, variable) {
          final Color c = colorIndex(index);
          return LineSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint p, _) => p.category,
            yValueMapper: (CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 2,
            markerSettings: const MarkerSettings(isVisible: false),
          );
        }).toList();

      case ChartModel.stackedArea:
        return variables.mapIndexed((index, variable) {
          final Color c = colorIndex(index);
          return StackedAreaSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint p, _) => p.category,
            yValueMapper: (CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c.withValues(alpha: 0.80),
            borderColor: c.withValues(alpha: 0.95),
            borderWidth: 1.2,
          );
        }).toList();

      case ChartModel.stackedBar:
        return variables.mapIndexed((index, variable) {
          final Color c = colorIndex(index);
          return StackedBarSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint p, _) => p.category,
            yValueMapper: (CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case ChartModel.pie:
        return <CartesianSeries<CatPoint, String>>[];
    }
  }

  TooltipBehavior toolTip(List<CatPoint> points) {
    return TooltipBehavior(
      enable: true,
      header: "",
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      builder: (
        dynamic value,
        dynamic point,
        dynamic series,
        int pointIndex,
        int seriesIndex,
      ) {
        if (pointIndex < 0 || pointIndex >= points.length) {
          return const SizedBox.shrink();
        }

        final CatPoint p = points[pointIndex];
        final String cat = p.category;

        final List<MapEntry<String, num>> entries = p.values.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          padding: EdgeInsets.all(Dimensions.size10),
          constraints: const BoxConstraints(minWidth: 190),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: Dimensions.size10),
              ...entries.take(10).mapIndexed((i, e) {
                final Color c = colorIndex(i);
                return Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.size5),
                  child: Row(
                    children: [
                      Container(
                        width: Dimensions.size10,
                        height: Dimensions.size10,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(
                            Dimensions.size3,
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.size10),
                      Expanded(
                        child: Text(
                          e.key,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.size10),
                      Text(
                        formatChartNumber(e.value),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Agg aggregate(List<Map<String, dynamic>> src) {
    final Map<String, Map<String, num>> map = {};

    for (final Map<String, dynamic> e in src) {
      final String variable = e["variable"].toString();
      final String category = e["category"].toString();
      final num value = parseChartNumber(e["value"]);

      map.putIfAbsent(category, () => {});
      map[category]![variable] = (map[category]![variable] ?? 0) + value;
    }

    final List<CatPoint> points = map.entries.map((entry) {
      return CatPoint(category: entry.key, values: entry.value);
    }).toList()
      ..sort((a, b) {
        final num ta = a.values.values.fold<num>(0, (p, v) => p + v);
        final num tb = b.values.values.fold<num>(0, (p, v) => p + v);
        return tb.compareTo(ta);
      });

    return Agg(points: points);
  }
}

class PieSlice {
  final String label;
  final num value;
  const PieSlice({required this.label, required this.value});
}

class DivergingPoint {
  final String category;
  final double total;
  final double delta;
  final double baseline;

  const DivergingPoint({
    required this.category,
    required this.total,
    required this.delta,
    required this.baseline,
  });
}

class Agg {
  final List<CatPoint> points;
  Agg({required this.points});
}

class CatPoint {
  final String category;
  final Map<String, num> values;

  CatPoint({required this.category, required this.values});

  String get shortLabel {
    if (category.trim().isEmpty) {
      return "-";
    }
    if (category.length <= 3) {
      return category.toUpperCase();
    }

    final List<String> parts = category.trim().split(RegExp(r"\s+"));
    if (parts.length >= 2) {
      final String a = parts.first;
      final String b = parts.last;
      final String aa = a.characters.take(1).toString().toUpperCase();
      final String bb = b.characters.take(1).toString().toUpperCase();
      return "$aa$bb";
    }
    return category.characters.take(2).toString().toUpperCase();
  }
}

class ScroolLegend extends StatelessWidget {
  final List<String> variables;
  final Color Function(int index) colorForIndex;
  final bool isGlass;

  const ScroolLegend({
    required this.variables,
    required this.colorForIndex,
    required this.isGlass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Dimensions.size25,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: variables.mapIndexed((i, v) {
            return Padding(
              padding: EdgeInsets.only(
                right: i == variables.length - 1 ? 0 : 14,
              ),
              child: DotLegend(
                isGlass: isGlass,
                label: v,
                color: colorForIndex(i),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ChartModelPill extends StatelessWidget {
  final ChartModel model;
  final VoidCallback onTap;
  final bool isGlass;

  const ChartModelPill({
    required this.model,
    required this.onTap,
    required this.isGlass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return InkWell(
        borderRadius: BorderRadius.circular(Dimensions.size15),
        onTap: onTap,
        child: GlassContainer(
          blur: Dimensions.size20,
          borderRadius: Dimensions.size15,
          opacity: 0.10,
          borderOpacity: 0.18,
          padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
          child: SizedBox(
            height: Dimensions.size30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  model.icon(),
                  size: Dimensions.size15,
                  color: Colors.white.withOpacity(0.92),
                ),
                SizedBox(width: Dimensions.size5),
                Text(
                  model.label(),
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
                SizedBox(width: Dimensions.size5),
                Icon(
                  Icons.expand_more_rounded,
                  size: Dimensions.size20,
                  color: Colors.white.withOpacity(0.90),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.size10),
      onTap: onTap,
      child: Container(
        height: Dimensions.size30,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Dimensions.size10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.35
                      : 0.55,
                ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              model.icon(),
              size: Dimensions.size15,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.88),
            ),
            SizedBox(width: Dimensions.size5),
            Text(
              model.label(),
              style: TextStyle(
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w900,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
            SizedBox(width: Dimensions.size5),
            Icon(
              Icons.expand_more_rounded,
              size: Dimensions.size20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.88),
            ),
          ],
        ),
      ),
    );
  }
}

class DotLegend extends StatelessWidget {
  final String label;
  final Color color;
  final bool isGlass;

  const DotLegend({
    required this.label,
    required this.color,
    required this.isGlass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Dimensions.size10,
          height: Dimensions.size10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(Dimensions.size3),
            border: Border.all(
              color: isGlass
                  ? Colors.white.withOpacity(0.25)
                  : Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        SizedBox(width: Dimensions.size10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: isGlass
                  ? Colors.white.withOpacity(0.88)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

class LoadingCard extends StatelessWidget {
  final bool isGlass;

  const LoadingCard({required this.isGlass, super.key});

  @override
  Widget build(BuildContext context) {
    final Widget inner = Shimmer.fromColors(
      baseColor: isGlass
          ? Colors.white.withOpacity(0.10)
          : (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.10)
              : Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06)),
      highlightColor: isGlass
          ? Colors.white.withOpacity(0.06)
          : (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06)
              : Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.02)),
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isGlass ? 0.06 : 1),
          borderRadius: BorderRadius.circular(Dimensions.size15),
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: isGlass
            ? GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size20,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: inner,
              )
            : inner,
      ),
    );
  }
}
