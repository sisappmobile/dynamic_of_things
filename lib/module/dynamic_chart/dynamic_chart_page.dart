// ignore_for_file: deprecated_member_use

import "dart:convert";
import "dart:io";
import "dart:math" as math;
import "dart:typed_data";

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/chart_model.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart" show kIsWeb;
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

    if (!mounted) {
      return;
    }

    setState(() {
      prefsReady = true;
    });
  }

  bool get isGlass {
    if (!prefsReady) {
      return false;
    }

    final int t = Preferences.getInstance()
            .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
        1;
    return t == 2;
  }

  Widget glassBackground() {
    final String p = (Preferences.getInstance()
                .getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH) ??
            "")
        .trim();

    if (p.isEmpty) {
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }

    if (kIsWeb) {
      if (p == "wallpaper_default.jpg") {
        final String base64Data = Preferences.getInstance().getStringDynamicForm("WEB_WALLPAPER_BYTES") ?? "";
        if (base64Data.isNotEmpty) {
          try {
            final Uint8List bytes = base64Decode(base64Data);
            return Image.memory(bytes, fit: BoxFit.cover);
          } catch (_) {}
        }
      }
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }

    if (p.startsWith("assets/")) {
      return Image.asset(p, fit: BoxFit.cover);
    }

    final File f = File(p);
    if (f.existsSync()) {
      return Image.file(f, fit: BoxFit.cover);
    }

    return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
  }

  Jiffy begin() {
    if (customRange != null) {
      return Jiffy.parseFromDateTime(customRange!.start);
    }

    final Jiffy now = Jiffy.now();
    if (preset == RangePreset.today) {
      return now;
    }
    if (preset == RangePreset.last7) {
      return now.subtract(days: 6);
    }
    return now.subtract(days: 29);
  }

  Jiffy until() {
    if (customRange != null) {
      return Jiffy.parseFromDateTime(customRange!.end);
    }
    return Jiffy.now();
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

    refreshAllRange();
  }

  void refreshAllRange() {
    if (listResponse == null) {
      return;
    }

    final Jiffy b = begin();
    final Jiffy u = until();

    for (final Chart c in listResponse!.charts) {
      context.read<DynamicChartBloc>().add(
            DynamicChartData(
              id: c.id,
              begin: b,
              until: u,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartLoadLoading) {
          context.loaderOverlay.show();
          setState(() => listResponse = null);
        } else if (state is DynamicChartLoadSuccess) {
          setState(() => listResponse = state.listResponse);
          refreshAllRange();
        } else if (state is DynamicChartLoadFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = Dimensions.isMobile();

          return Scaffold(
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
                        AppBarDynamicChart(
                          isGlass: isGlass && isMobile,
                          title: "dynamic_chart".tr(),
                          rangeLabel: rangeLabel(),
                          onPickRange: pickRangeDate,
                          onBack: () {
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
                        Expanded(child: body(glass: isGlass)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget body({required bool glass}) {
    if (listResponse == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size30,
        ),
        children: [
          LoadingCard(isGlass: glass),
        ],
      );
    }

    final List<Chart> charts =
        listResponse!.charts.whereNot((e) => e is Summary).toList();

    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size30,
        ),
        itemCount: charts.length,
        itemBuilder: (context, index) {
          final Chart c = charts[index];

          return Padding(
            padding: EdgeInsets.only(bottom: Dimensions.size15),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ChartCard(
                  isGlass: glass,
                  chart: c,
                  begin: begin(),
                  until: until(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppBarDynamicChart extends StatelessWidget {
  final String title;
  final String rangeLabel;
  final VoidCallback onPickRange;
  final VoidCallback onBack;
  final bool isGlass;

  const AppBarDynamicChart({
    required this.title,
    required this.rangeLabel,
    required this.onPickRange,
    required this.onBack,
    required this.isGlass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return Container(
        height: Dimensions.size60,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
        child: Row(
          children: [
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
                    Icons.turn_left_rounded,
                    color: Colors.white.withOpacity(0.95),
                    size: Dimensions.size25,
                  ),
                ),
              ),
            ),
            SizedBox(width: Dimensions.size10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Dimensions.text14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.95),
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
          InkWell(
            borderRadius: BorderRadius.circular(Dimensions.size100),
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.all(Dimensions.size10),
              child: Icon(
                Icons.turn_left_rounded,
                size: Dimensions.size20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.90),
              ),
            ),
          ),
          SizedBox(width: Dimensions.size5),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.55),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.88),
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.88),
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
    Widget chip(String label, String value) {
      if (isGlass) {
        return GlassContainer(
          blur: Dimensions.size20,
          borderRadius: Dimensions.size15,
          opacity: 0.10,
          borderOpacity: 0.18,
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size10,
            vertical: Dimensions.size10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Dimensions.text12,
                  fontWeight: FontWeight.w700,
                  color: isGlass
                      ? Colors.white.withOpacity(0.82)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.78),
                ),
              ),
              SizedBox(width: Dimensions.size5),
              Text(
                value,
                style: TextStyle(
                  fontSize: Dimensions.text12,
                  fontWeight: FontWeight.w900,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size10,
          vertical: Dimensions.size10,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Dimensions.size10),
          border: Border.all(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : Theme.of(context).colorScheme.outlineVariant.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.35
                          : 0.55,
                    ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w700,
                color: isGlass
                    ? Colors.white.withOpacity(0.82)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.78),
              ),
            ),
            SizedBox(width: Dimensions.size5),
            Text(
              value,
              style: TextStyle(
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w900,
                color: isGlass
                    ? Colors.white.withOpacity(0.92)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      );
    }

    Widget rowItem(String name, num v) {
      return Padding(
        padding: EdgeInsets.only(bottom: Dimensions.size10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Dimensions.text12,
                      fontWeight: FontWeight.w700,
                      color: isGlass
                          ? Colors.white.withOpacity(0.82)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.78),
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Text(
                  "${v.toString()}  (${persentText(v)})",
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w900,
                    color: isGlass
                        ? Colors.white.withOpacity(0.92)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimensions.size5),
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.size100),
              child: LinearProgressIndicator(
                value: total <= 0 ? 0 : (v / total).toDouble().clamp(0, 1),
                minHeight: Dimensions.size5,
                backgroundColor: isGlass
                    ? Colors.white.withOpacity(0.12)
                    : Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.10
                              : 0.08,
                        ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFB9A7FF).withValues(alpha: 0.95),
                ),
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
            "summary".tr(),
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: Dimensions.size5),
          Text(
            "summary_description".tr(),
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: isGlass
                  ? Colors.white.withOpacity(0.78)
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: Dimensions.size10),
          Wrap(
            spacing: Dimensions.size10,
            runSpacing: Dimensions.size10,
            children: [
              chip("Periode", rangeLabel),
              chip("Total", total.toString()),
              chip("Data", rows.toString()),
            ],
          ),
          SizedBox(height: Dimensions.size15),
          Text(
            "type_composition".tr(),
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: Dimensions.size15),
          ...compositionByVariable.map((e) => rowItem(e.key, e.value)),
          SizedBox(height: Dimensions.size5),
          Text(
            "category_composition".tr(),
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: Dimensions.size10),
          ...compositionByCategory.map((e) => rowItem(e.key, e.value)),
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
    final num value = (e["value"] as num?) ?? 0;

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

extension ChartModelX on ChartModel {
  String label() {
    switch (this) {
      case ChartModel.stackedColumn:
        return "Stacked Column";
      case ChartModel.groupedColumn:
        return "Grouped Column";
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
        return Icons.bar_chart_rounded;
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

  const ChartCard({
    required this.chart,
    required this.begin,
    required this.until,
    required this.isGlass,
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

    fetch();
  }

  @override
  void didUpdateWidget(covariant ChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool changed = oldWidget.begin.dateTime != widget.begin.dateTime ||
        oldWidget.until.dateTime != widget.until.dateTime;

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
                          borderRadius:
                              BorderRadius.circular(Dimensions.size15),
                          border: Border.all(
                            color:
                                accent.withValues(alpha: active ? 0.35 : 0.22),
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
          raw = List<Map<String, dynamic>>.from(
            (state.data as List)
                .map((e) => Map<String, dynamic>.from(e as Map)),
          );
          setState(() {});
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
      final num val = (e["value"] as num?) ?? 0;
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
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.92),
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
            height: 320,
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
            child: innerChartCard,
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
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget anyChart(List<String> variables) {
    if (model == ChartModel.pie) {
      return pieChart();
    }
    return cartesianChart(variables);
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
      final num v = (e["value"] as num?) ?? 0;

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

    final List<PieSlice> slices =
        pieChartSlices(raw!, maxSlices: 7, minPct: 2.5);

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
        final num m =
            e.values.values.fold<num>(0, (pp, vv) => math.max(pp, vv));
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
          final CatPoint? p =
              points.firstWhereOrNull((e) => e.category == full);
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
                          borderRadius: BorderRadius.circular(Dimensions.size3),
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
                        "${e.value}",
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
      final num value = (e["value"] as num?) ?? 0;

      map.putIfAbsent(category, () => {});
      map[category]![variable] = (map[category]![variable] ?? 0) + value;
    }

    final List<CatPoint> points = map.entries.map((entry) {
      return CatPoint(
        category: entry.key,
        values: entry.value,
      );
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

class Agg {
  final List<CatPoint> points;
  Agg({required this.points});
}

class CatPoint {
  final String category;
  final Map<String, num> values;

  CatPoint({
    required this.category,
    required this.values,
  });

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
              padding:
                  EdgeInsets.only(right: i == variables.length - 1 ? 0 : 14),
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
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.55),
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.88),
            ),
            SizedBox(width: Dimensions.size5),
            Text(
              model.label(),
              style: TextStyle(
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w900,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.88),
              ),
            ),
            SizedBox(width: Dimensions.size5),
            Icon(
              Icons.expand_more_rounded,
              size: Dimensions.size20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.88),
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
                  : Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.55),
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
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.88),
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
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.06)),
      highlightColor: isGlass
          ? Colors.white.withOpacity(0.06)
          : (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.02)),
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
