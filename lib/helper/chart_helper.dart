import "dart:convert";

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/enumeration/chart_model.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_chart_data_helper.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/window_model.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_desktop_window.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:flutter/material.dart";

bool prefsReady = false;

const String _widgetLayoutGetUrl =
    "https://posdemo.sisapp.com:8443/salesforce/api/v2/widget/get";
const String _widgetLayoutStoreUrl =
    "https://posdemo.sisapp.com:8443/salesforce/api/v2/widget/store";

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

String savedLayoutsListPreferenceKey() {
  return "dynamic_chart_saved_layouts_${desktopPreferenceOwner()}";
}

String desktopPreferenceOwner() {
  final String base = currentLayoutUserId().trim();
  if (base.isEmpty) {
    return "default";
  }

  return base.replaceAll(RegExp(r"[^A-Za-z0-9_.-]"), "_");
}

String currentLayoutUserId() {
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

String currentLayoutUsername() {
  return Preferences.getInstance().getStringDynamicForm("USER_NAME") ?? "";
}

Future<Map<String, dynamic>?> fetchWidgetLayoutServerPayload() async {
  try {
    final Response<dynamic> response = await DotApis.getInstance().dio.get(
          _widgetLayoutGetUrl,
          options:
              Options(headers: <String, dynamic>{"sfa-background": "true"}),
        );

    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300 ||
        response.data is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(response.data as Map);
  } catch (_) {
    return null;
  }
}

Future<DynamicChartSavedLayoutPayload?>
    loadDynamicChartLayoutFromServer() async {
  final Map<String, dynamic>? payload = await fetchWidgetLayoutServerPayload();
  if (payload == null) {
    return null;
  }

  final Map<String, dynamic>? layout = _readLayoutObject(
    payload["dynamicChartLayout"],
  );
  if (layout == null) {
    return null;
  }

  final int dashboardUiType = _readDashboardUiType(
    payload["themeStyle"] ??
        payload["themeStyleId"] ??
        payload["dashboardUiType"],
    fallback: Preferences.getInstance().getInt(
          SharedPreferenceKey.DASHBOARD_UI_TYPE,
        ) ??
        1,
  );
  final int themeMode = _readThemeMode(
    payload["themeMode"],
    fallback: Preferences.getInstance().getInt(
          SharedPreferenceKey.THEME_MODE,
        ) ??
        0,
  );

  layout["dashboardUiType"] = layout["dashboardUiType"] ?? dashboardUiType;
  layout["themeStyle"] =
      layout["themeStyle"] ?? (dashboardUiType == 2 ? "glass" : "solid");
  layout["themeMode"] = layout["themeMode"] ?? themeMode;

  final DynamicChartSavedLayoutPayload parsed =
      DynamicChartSavedLayoutPayload.fromJson(layout);

  await Preferences.getInstance().setInt(
    SharedPreferenceKey.DASHBOARD_UI_TYPE,
    dashboardUiType,
  );
  await Preferences.getInstance().setInt(
    SharedPreferenceKey.THEME_MODE,
    themeMode,
  );
  await Preferences.getInstance().setStringDynamicForm(
    desktopWindowLayoutPreferenceKey(),
    jsonEncode(parsed.toJson()),
  );
  await Preferences.getInstance().setStringDynamicForm(
    chartOrderPreferenceKey(),
    jsonEncode(parsed.widgetOrder),
  );
  await Preferences.getInstance().setStringDynamicForm(
    floatingDesktopModePreferenceKey(),
    jsonEncode(parsed.floatingMode),
  );
  await Preferences.getInstance().setStringDynamicForm(
    hiddenDesktopPanelPreferenceKey(),
    jsonEncode(parsed.hiddenWidgetIds),
  );

  return parsed;
}

Future<void> syncDynamicChartLayoutToServer(
  DynamicChartSavedLayoutPayload payload,
) async {
  try {
    final Map<String, dynamic>? serverPayload =
        await fetchWidgetLayoutServerPayload();
    if (serverPayload == null) {
      return;
    }

    final Map<String, dynamic> requestPayload =
        Map<String, dynamic>.from(serverPayload);

    requestPayload["version"] = serverPayload["version"] ?? 1;
    requestPayload["generatedAt"] = DateTime.now().toUtc().toIso8601String();
    requestPayload["userId"] = payload.userId;
    requestPayload["username"] = payload.username;
    requestPayload["dynamicChartLayout"] = payload.toJson();
    requestPayload["themeStyle"] ??=
        payload.dashboardUiType == 2 ? "glass" : "solid";
    requestPayload["themeStyleId"] ??= payload.dashboardUiType;
    requestPayload["themeMode"] ??=
        Preferences.getInstance().getInt(SharedPreferenceKey.THEME_MODE) ?? 0;
    requestPayload["themeModeLabel"] ??= _themeModeLabelForMode(
      Preferences.getInstance().getInt(SharedPreferenceKey.THEME_MODE) ?? 0,
    );

    await DotApis.getInstance().dio.post(
          _widgetLayoutStoreUrl,
          data: requestPayload,
          options:
              Options(headers: <String, dynamic>{"sfa-background": "true"}),
        );
  } catch (_) {}
}

int _readDashboardUiType(
  dynamic value, {
  required int fallback,
}) {
  if (value is bool) {
    return value ? 2 : 1;
  }

  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    if (normalized == "glass" || normalized == "2") {
      return 2;
    }
    if (normalized == "solid" || normalized == "1") {
      return 1;
    }
  }

  final int parsed = _readInt(value, fallback: fallback);
  return parsed <= 1 ? 1 : 2;
}

int _readThemeMode(
  dynamic value, {
  required int fallback,
}) {
  final int parsed = _readInt(value, fallback: fallback);
  return parsed < 0 ? fallback : parsed;
}

String _themeModeLabelForMode(int mode) {
  switch (mode) {
    case 1:
      return "Light";
    case 2:
      return "Dark";
    default:
      return "System";
  }
}

Map<String, dynamic>? _readLayoutObject(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(value);
}

int _readInt(dynamic value, {required int fallback}) {
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

    return DynamicChartSavedLayoutPayload.fromJson(
      Map<String, dynamic>.from(decoded),
    ).layoutsMap;
  } catch (_) {
    return <String, DynamicChartDesktopWindowLayout>{};
  }
}
