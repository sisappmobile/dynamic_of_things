import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_desktop_window.dart";
import "package:flutter/material.dart";

class DynamicChartDesktopPanelDescriptor {
  final String id;
  final String title;
  final IconData icon;
  final double width;
  final double height;
  final double minWidth;
  final double minHeight;
  final Widget child;

  const DynamicChartDesktopPanelDescriptor({
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

class DynamicChartSavedLayoutPayload {
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

  const DynamicChartSavedLayoutPayload({
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

  factory DynamicChartSavedLayoutPayload.fromJson(Map<String, dynamic> json) {
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

    return DynamicChartSavedLayoutPayload(
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

