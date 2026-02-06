import "dart:math" as math;

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:jiffy/jiffy.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:shimmer/shimmer.dart";
import "package:syncfusion_flutter_charts/charts.dart";

class DynamicChartPage extends StatefulWidget {
  const DynamicChartPage({super.key});

  @override
  DynamicChartPageState createState() => DynamicChartPageState();
}

enum _RangePreset { today, last7, last30 }

class DynamicChartPageState extends State<DynamicChartPage>
    with WidgetsBindingObserver {
  ListResponse? listResponse;

  final _RangePreset _preset = _RangePreset.last7;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Jiffy _begin() {
    if (_customRange != null) {
      return Jiffy.parseFromDateTime(_customRange!.start);
    }

    final Jiffy now = Jiffy.now();
    if (_preset == _RangePreset.today) {
      return now;
    }
    if (_preset == _RangePreset.last7) {
      return now.subtract(days: 6);
    }
    return now.subtract(days: 29);
  }

  Jiffy _until() {
    if (_customRange != null) {
      return Jiffy.parseFromDateTime(_customRange!.end);
    }
    return Jiffy.now();
  }

  String _rangeLabel() {
    final Jiffy b = _begin();
    final Jiffy u = _until();

    final String a = b.format(pattern: "d MMM yyyy");
    final String z = u.format(pattern: "d MMM yyyy");
    return "$a - $z";
  }

  Future<void> _pickRange() async {
    final DateTime now = DateTime.now();

    final DateTime initialStart = _customRange?.start ?? _begin().dateTime;
    final DateTime initialEnd = _customRange?.end ?? _until().dateTime;

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
      _customRange = normalized;
    });

    _refetchAllForRange();
  }

  void _refetchAllForRange() {
    if (listResponse == null) {
      return;
    }

    final Jiffy b = _begin();
    final Jiffy u = _until();

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
          _refetchAllForRange();
        } else if (state is DynamicChartLoadFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CleanTopBar(
                title: "dynamic_chart".tr(),
                rangeLabel: _rangeLabel(),
                onPickRange: _pickRange,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (listResponse == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size30,
        ),
        children: const [
          _LoadingCardSkeleton(),
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
                child: _CleanChartCard(
                  chart: c,
                  begin: _begin(),
                  until: _until(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CleanTopBar extends StatelessWidget {
  final String title;
  final String rangeLabel;
  final VoidCallback onPickRange;
  final VoidCallback onBack;

  const _CleanTopBar({
    required this.title,
    required this.rangeLabel,
    required this.onPickRange,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final Color iconColor = cs.onSurface.withValues(alpha: 0.90);
    final Color pillBg = cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color pillBorder =
        cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);
    final Color pillText = cs.onSurface.withValues(alpha: 0.88);

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
                color: iconColor,
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
                color: cs.onSurface,
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
                color: pillBg,
                borderRadius: BorderRadius.circular(Dimensions.size10),
                border: Border.all(color: pillBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: Dimensions.size15,
                    color: pillText,
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
                        color: pillText,
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

class _InsightPanel extends StatelessWidget {
  final num total;
  final int rows;
  final String rangeLabel;

  final List<MapEntry<String, num>> compositionByVariable;
  final List<MapEntry<String, num>> compositionByCategory;

  const _InsightPanel({
    required this.total,
    required this.rows,
    required this.rangeLabel,
    required this.compositionByVariable,
    required this.compositionByCategory,
  });

  String _pctText(num v) {
    if (total <= 0) {
      return "0%";
    }
    final double p = (v / total) * 100.0;
    final String s = p >= 10 ? p.toStringAsFixed(0) : p.toStringAsFixed(1);
    return "$s% dari total";
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final TextStyle titleStyle = TextStyle(
      fontSize: Dimensions.text12,
      fontWeight: FontWeight.w900,
      color: cs.onSurface.withValues(alpha: 0.88),
    );

    final TextStyle subStyle = TextStyle(
      fontSize: Dimensions.text12,
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
    );

    final TextStyle labelStyle = TextStyle(
      fontSize: Dimensions.text12,
      fontWeight: FontWeight.w700,
      color: cs.onSurface.withValues(alpha: 0.78),
    );

    final TextStyle valueStyle = TextStyle(
      fontSize: Dimensions.text12,
      fontWeight: FontWeight.w900,
      color: cs.onSurface.withValues(alpha: 0.92),
    );

    final Color cardBg = cs.surface;
    final Color border =
        cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);

    Widget chip(String label, String value) {
      final Color chipBg = cs.surfaceContainerHighest.withValues(alpha: 0.55);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size10,
          vertical: Dimensions.size10,
        ),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(Dimensions.size10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            SizedBox(width: Dimensions.size5),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    Widget rowItem(String name, num v) {
      final double frac = total <= 0 ? 0 : (v / total).toDouble().clamp(0, 1);

      final Color track = cs.onSurface.withValues(alpha: dark ? 0.10 : 0.08);
      final Color fill = const Color(0xFFB9A7FF).withValues(alpha: 0.95);

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
                    style: labelStyle,
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Text("${v.toString()}  (${_pctText(v)})", style: valueStyle),
              ],
            ),
            SizedBox(height: Dimensions.size5),
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.size100),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: Dimensions.size5,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation<Color>(fill),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        border: Border.all(color: border),
        boxShadow: [
          if (!dark)
            BoxShadow(
              blurRadius: Dimensions.size25,
              offset: Offset(0, Dimensions.size10),
              color: Colors.black.withValues(alpha: 0.06),
            ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        Dimensions.size20,
        Dimensions.size15,
        Dimensions.size20,
        Dimensions.size15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("summary".tr(), style: titleStyle),
          SizedBox(height: Dimensions.size5),
          Text("summary_description".tr(), style: subStyle),
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
          Text("type_composition".tr(), style: titleStyle),
          SizedBox(height: Dimensions.size15),
          ...compositionByVariable.map((e) => rowItem(e.key, e.value)),
          SizedBox(height: Dimensions.size5),
          Text("category_composition".tr(), style: titleStyle),
          SizedBox(height: Dimensions.size10),
          ...compositionByCategory.map((e) => rowItem(e.key, e.value)),
        ],
      ),
    );
  }
}

class _Insight {
  final num total;
  final int rows;
  final List<MapEntry<String, num>> compositionByVariable;
  final List<MapEntry<String, num>> compositionByCategory;

  const _Insight({
    required this.total,
    required this.rows,
    required this.compositionByVariable,
    required this.compositionByCategory,
  });
}

List<MapEntry<String, num>> _topWithOthers(
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

_Insight _buildInsight(List<Map<String, dynamic>> src) {
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

  return _Insight(
    total: total,
    rows: rows,
    compositionByVariable: _topWithOthers(
      byVariable,
      take: 5,
      othersLabel: "other".tr(),
    ),
    compositionByCategory: _topWithOthers(
      byCategory,
      take: 5,
      othersLabel: "other".tr(),
    ),
  );
}

enum _ChartModel {
  stackedColumn,
  groupedColumn,
  line,
  stackedArea,
  stackedBar,
  pie,
}

extension _ChartModelX on _ChartModel {
  String label() {
    switch (this) {
      case _ChartModel.stackedColumn:
        return "Stacked Column";
      case _ChartModel.groupedColumn:
        return "Grouped Column";
      case _ChartModel.line:
        return "Line";
      case _ChartModel.stackedArea:
        return "Stacked Area";
      case _ChartModel.stackedBar:
        return "Stacked Bar";
      case _ChartModel.pie:
        return "Pie";
    }
  }

  IconData icon() {
    switch (this) {
      case _ChartModel.stackedColumn:
        return Icons.stacked_bar_chart_rounded;
      case _ChartModel.groupedColumn:
        return Icons.bar_chart_rounded;
      case _ChartModel.line:
        return Icons.show_chart_rounded;
      case _ChartModel.stackedArea:
        return Icons.area_chart_rounded;
      case _ChartModel.stackedBar:
        return Icons.view_week_rounded;
      case _ChartModel.pie:
        return Icons.pie_chart_rounded;
    }
  }

  bool isStacked() {
    switch (this) {
      case _ChartModel.stackedColumn:
      case _ChartModel.stackedArea:
      case _ChartModel.stackedBar:
        return true;
      case _ChartModel.groupedColumn:
      case _ChartModel.line:
      case _ChartModel.pie:
        return false;
    }
  }

  bool isCircular() => this == _ChartModel.pie;
}

class _CleanChartCard extends StatefulWidget {
  final Chart chart;
  final Jiffy begin;
  final Jiffy until;

  const _CleanChartCard({
    required this.chart,
    required this.begin,
    required this.until,
  });

  @override
  State<_CleanChartCard> createState() => _CleanChartCardState();
}

class _CleanChartCardState extends State<_CleanChartCard> {
  bool loading = true;
  List<Map<String, dynamic>>? raw;

  late ZoomPanBehavior _zoom;

  _ChartModel _model = _ChartModel.stackedColumn;

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

    _zoom = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      zoomMode: ZoomMode.x,
    );

    _fetch();
  }

  @override
  void didUpdateWidget(covariant _CleanChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool changed = oldWidget.begin.dateTime != widget.begin.dateTime ||
        oldWidget.until.dateTime != widget.until.dateTime;

    if (changed) {
      _fetch();
    }
  }

  void _fetch() {
    context.read<DynamicChartBloc>().add(
          DynamicChartData(
            id: widget.chart.id,
            begin: widget.begin,
            until: widget.until,
          ),
        );
  }

  Future<void> _pickModel() async {
    final ColorScheme csRoot = Theme.of(context).colorScheme;
    final bool darkRoot = Theme.of(context).brightness == Brightness.dark;

    final _ChartModel? selected = await showModalBottomSheet<_ChartModel>(
      context: context,
      useSafeArea: false,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: csRoot.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.size20),
        ),
        side: BorderSide(
          color:
              csRoot.outlineVariant.withValues(alpha: darkRoot ? 0.35 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        final ColorScheme cs = Theme.of(context).colorScheme;
        final bool dark = Theme.of(context).brightness == Brightness.dark;

        final List<_ChartModel> models = <_ChartModel>[
          _ChartModel.stackedColumn,
          _ChartModel.groupedColumn,
          _ChartModel.line,
          _ChartModel.stackedArea,
          _ChartModel.stackedBar,
          _ChartModel.pie,
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

        Color modelColor(_ChartModel m) {
          switch (m) {
            case _ChartModel.stackedColumn:
              return const Color.fromARGB(255, 157, 162, 0);
            case _ChartModel.groupedColumn:
              return const Color.fromARGB(255, 19, 96, 0);
            case _ChartModel.line:
              return const Color.fromARGB(255, 255, 152, 63);
            case _ChartModel.stackedArea:
              return const Color.fromARGB(255, 0, 0, 0);
            case _ChartModel.stackedBar:
              return const Color.fromARGB(255, 0, 27, 125);
            case _ChartModel.pie:
              return const Color.fromARGB(255, 255, 0, 0);
          }
        }

        Widget gridItem(_ChartModel m) {
          final bool active = m == _model;

          final Color border =
              cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);
          final Color text = cs.onSurface.withValues(alpha: 0.92);
          final Color sub = cs.onSurfaceVariant.withValues(alpha: 0.85);

          final Color accent = modelColor(m);
          final Color iconColor = active
              ? accent.withValues(alpha: 1.0)
              : accent.withValues(alpha: 0.85);

          final Color bg = active
              ? Color.alphaBlend(accent.withValues(alpha: 0.10), cs.surface)
              : cs.surface;

          return InkWell(
            borderRadius: BorderRadius.circular(Dimensions.size15),
            onTap: () => Navigator.of(context).pop(m),
            child: Container(
              height: tileH,
              padding: EdgeInsets.all(Dimensions.size10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Dimensions.size15),
                border: Border.all(
                  color: active
                      ? Color.alphaBlend(accent.withValues(alpha: 0.35), border)
                      : border,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final bool compact = c.maxHeight < 84;

                  final double iconSize = Dimensions.size20;
                  final double titleSize =
                      compact ? Dimensions.text11 : Dimensions.text12;
                  final double subSize =
                      compact ? Dimensions.text9 : Dimensions.text10;

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
                          size: iconSize,
                          color: iconColor,
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
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              color: text,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      if (!compact) ...[
                        SizedBox(height: 2),
                        Text(
                          m.isCircular()
                              ? "Circular"
                              : (m.isStacked() ? "Stacked" : "Non-stacked"),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            fontWeight: FontWeight.w700,
                            color: sub,
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
                            color:
                                active ? accent : sub.withValues(alpha: 0.65),
                            width: 1.6,
                          ),
                        ),
                        child: active
                            ? Icon(Icons.check, size: 12, color: cs.surface)
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
                      "select_chart_model".tr(),
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
    setState(() => _model = selected);
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
      child: loading ? const _LoadingCardSkeleton() : _content(),
    );
  }

  List<String> _allVariablesSorted(List<Map<String, dynamic>> src) {
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

  Color _colorForIndex(int i) {
    if (i < basePalette.length) {
      return basePalette[i];
    }

    final double h = (i * 0.61803398875) % 1.0;
    final HSVColor hsv = HSVColor.fromAHSV(1, 360 * h, 0.38, 0.95);
    return hsv.toColor();
  }

  String _rangeLabel() {
    final String a = widget.begin.format(pattern: "d MMM yyyy");
    final String z = widget.until.format(pattern: "d MMM yyyy");
    return "$a - $z";
  }

  Widget _content() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final bool hasData = raw != null && raw!.isNotEmpty;

    final List<String> variables =
        hasData ? _allVariablesSorted(raw!) : <String>[];

    final Color cardBg = cs.surface;
    final Color border =
        cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);

    final TextStyle titleStyle = TextStyle(
      fontSize: Dimensions.text13,
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withValues(alpha: 0.92),
    );

    final List<_PieSlice> pieSlices = hasData
        ? _buildPieSlices(raw!, maxSlices: 7, minPct: 2.5)
        : <_PieSlice>[];

    final List<String> pieCats = pieSlices.map((e) => e.label).toList();

    final Widget chartCard = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        border: Border.all(color: border),
        boxShadow: [
          if (!dark)
            BoxShadow(
              blurRadius: Dimensions.size25,
              offset: Offset(0, Dimensions.size15),
              color: Colors.black.withValues(alpha: 0.06),
            ),
        ],
      ),
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
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: Dimensions.size10),
              _ChartModelPill(
                model: _model,
                onTap: _pickModel,
              ),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          if (_model == _ChartModel.pie && pieCats.isNotEmpty)
            _ScrollableLegend(
              variables: pieCats,
              colorForIndex: _colorForIndex,
            )
          else if (_model != _ChartModel.pie && variables.isNotEmpty)
            _ScrollableLegend(
              variables: variables,
              colorForIndex: _colorForIndex,
            ),
          if ((_model == _ChartModel.pie && pieCats.isNotEmpty) ||
              (_model != _ChartModel.pie && variables.isNotEmpty))
            SizedBox(height: Dimensions.size10),
          SizedBox(
            height: 320,
            child: hasData ? _buildAnyChart(variables) : _emptyState(),
          ),
        ],
      ),
    );

    final Widget insightCard = hasData
        ? Builder(
            builder: (_) {
              final _Insight ins = _buildInsight(raw!);
              return _InsightPanel(
                total: ins.total,
                rows: ins.rows,
                rangeLabel: _rangeLabel(),
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

  Widget _emptyState() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        raw == null ? "failed_to_load_data".tr() : "no_data".tr(),
        style: TextStyle(
          fontSize: Dimensions.text13,
          fontWeight: FontWeight.w800,
          color: cs.onSurfaceVariant.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildAnyChart(List<String> variables) {
    if (_model == _ChartModel.pie) {
      return _buildPieChart();
    }
    return _buildCartesianChart(variables);
  }

  List<_PieSlice> _buildPieSlices(
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
      return <_PieSlice>[];
    }

    final List<_PieSlice> out = [];
    num other = 0;

    for (final e in sorted) {
      final double pct = (e.value / grand) * 100.0;

      if (out.length >= maxSlices || pct < minPct) {
        other += e.value;
      } else {
        out.add(_PieSlice(label: e.key, value: e.value));
      }
    }

    if (other > 0) {
      out.add(_PieSlice(label: "other".tr(), value: other));
    }

    return out;
  }

  Widget _buildPieChart() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<_PieSlice> slices =
        _buildPieSlices(raw!, maxSlices: 7, minPct: 2.5);

    if (slices.isEmpty) {
      return _emptyState();
    }

    final num total = slices.fold<num>(0, (p, e) => p + e.value);

    double pctVal(num v) => total <= 0 ? 0 : (v / total) * 100.0;
    String pctText(num v) {
      final double p = pctVal(v);
      return p >= 10 ? "${p.toStringAsFixed(0)}%" : "${p.toStringAsFixed(1)}%";
    }

    final Color border =
        cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);

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
      series: <CircularSeries<_PieSlice, String>>[
        DoughnutSeries<_PieSlice, String>(
          dataSource: slices,
          xValueMapper: (_PieSlice s, _) => s.label,
          yValueMapper: (_PieSlice s, _) => s.value.toDouble(),
          pointColorMapper: (_PieSlice s, int i) => _colorForIndex(i),
          cornerStyle: CornerStyle.endCurve,
          innerRadius: "66%",
          radius: "92%",
          strokeColor: cs.surface,
          strokeWidth: 2,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(
              color: border,
              length: "10%",
              width: 1,
            ),
            builder:
                (dynamic data, dynamic point, dynamic series, int i, int s) {
              final _PieSlice sl = slices[i];
              final double p = pctVal(sl.value);
              if (p < 5) {
                return const SizedBox.shrink();
              }
              return Text(
                pctText(sl.value),
                style: TextStyle(
                  fontSize: Dimensions.text11,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withValues(alpha: 0.88),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartesianChart(List<String> variables) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final _Agg agg = _aggregate(raw!);
    final List<_CatPoint> points = agg.points;

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

    final num maxY =
        _model.isStacked() ? maxYForStacked() : maxYForNonStacked();

    final double maxAxis = maxY <= 0 ? 0 : (maxY * 1.10).ceilToDouble();
    final double interval = maxAxis <= 0 ? 1 : (maxAxis / 4).ceilToDouble();

    final Color grid = cs.onSurface.withValues(alpha: dark ? 0.10 : 0.08);
    final Color axisTextX = cs.onSurfaceVariant.withValues(alpha: 0.90);
    final Color axisTextY = cs.onSurfaceVariant.withValues(alpha: 0.80);

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
          color: axisTextX,
        ),
        autoScrollingDelta: 7,
        autoScrollingMode: AutoScrollingMode.start,
        axisLabelFormatter: (AxisLabelRenderDetails d) {
          final String full = d.text;
          final _CatPoint? p =
              points.firstWhereOrNull((e) => e.category == full);
          return ChartAxisLabel(p?.shortLabel ?? full, d.textStyle);
        },
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: maxAxis == 0 ? null : maxAxis,
        interval: maxAxis == 0 ? null : interval,
        rangePadding: ChartRangePadding.none,
        majorGridLines: MajorGridLines(
          width: 1,
          color: grid,
        ),
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: axisTextY,
        ),
      ),
      legend: const Legend(isVisible: false),
      tooltipBehavior: _buildTooltip(points),
      zoomPanBehavior: _zoom,
      series: _buildSeries(points, variables),
    );
  }

  List<CartesianSeries<_CatPoint, String>> _buildSeries(
    List<_CatPoint> points,
    List<String> variables,
  ) {
    switch (_model) {
      case _ChartModel.stackedColumn:
        return variables.mapIndexed((index, variable) {
          final Color c = _colorForIndex(index);
          return StackedColumnSeries<_CatPoint, String>(
            dataSource: points,
            xValueMapper: (_CatPoint p, _) => p.category,
            yValueMapper: (_CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case _ChartModel.groupedColumn:
        return variables.mapIndexed((index, variable) {
          final Color c = _colorForIndex(index);
          return ColumnSeries<_CatPoint, String>(
            dataSource: points,
            xValueMapper: (_CatPoint p, _) => p.category,
            yValueMapper: (_CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case _ChartModel.line:
        return variables.mapIndexed((index, variable) {
          final Color c = _colorForIndex(index);
          return LineSeries<_CatPoint, String>(
            dataSource: points,
            xValueMapper: (_CatPoint p, _) => p.category,
            yValueMapper: (_CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 2,
            markerSettings: const MarkerSettings(isVisible: false),
          );
        }).toList();

      case _ChartModel.stackedArea:
        return variables.mapIndexed((index, variable) {
          final Color c = _colorForIndex(index);
          return StackedAreaSeries<_CatPoint, String>(
            dataSource: points,
            xValueMapper: (_CatPoint p, _) => p.category,
            yValueMapper: (_CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c.withValues(alpha: 0.80),
            borderColor: c.withValues(alpha: 0.95),
            borderWidth: 1.2,
          );
        }).toList();

      case _ChartModel.stackedBar:
        return variables.mapIndexed((index, variable) {
          final Color c = _colorForIndex(index);
          return StackedBarSeries<_CatPoint, String>(
            dataSource: points,
            xValueMapper: (_CatPoint p, _) => p.category,
            yValueMapper: (_CatPoint p, _) =>
                (p.values[variable] ?? 0).toDouble(),
            name: variable,
            color: c,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case _ChartModel.pie:
        return <CartesianSeries<_CatPoint, String>>[];
    }
  }

  TooltipBehavior _buildTooltip(List<_CatPoint> points) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final Color bg =
        dark ? cs.surfaceContainerHighest : cs.surfaceContainerHighest;
    final Color text = cs.onSurface;

    return TooltipBehavior(
      enable: true,
      header: "",
      color: bg,
      textStyle: TextStyle(color: text),
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

        final _CatPoint p = points[pointIndex];
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
                  color: text,
                ),
              ),
              SizedBox(height: Dimensions.size10),
              ...entries.take(10).mapIndexed((i, e) {
                final Color c = _colorForIndex(i);
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
                          style: TextStyle(color: text),
                        ),
                      ),
                      SizedBox(width: Dimensions.size10),
                      Text(
                        "${e.value}",
                        style: TextStyle(
                          color: text,
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

  _Agg _aggregate(List<Map<String, dynamic>> src) {
    final Map<String, Map<String, num>> map = {};

    for (final Map<String, dynamic> e in src) {
      final String variable = e["variable"].toString();
      final String category = e["category"].toString();
      final num value = (e["value"] as num?) ?? 0;

      map.putIfAbsent(category, () => {});
      map[category]![variable] = (map[category]![variable] ?? 0) + value;
    }

    final List<_CatPoint> points = map.entries.map((entry) {
      return _CatPoint(
        category: entry.key,
        values: entry.value,
      );
    }).toList()
      ..sort((a, b) {
        final num ta = a.values.values.fold<num>(0, (p, v) => p + v);
        final num tb = b.values.values.fold<num>(0, (p, v) => p + v);
        return tb.compareTo(ta);
      });

    return _Agg(points: points);
  }
}

class _PieSlice {
  final String label;
  final num value;
  const _PieSlice({required this.label, required this.value});
}

class _Agg {
  final List<_CatPoint> points;
  _Agg({required this.points});
}

class _CatPoint {
  final String category;
  final Map<String, num> values;

  _CatPoint({
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

class _ScrollableLegend extends StatelessWidget {
  final List<String> variables;
  final Color Function(int index) colorForIndex;

  const _ScrollableLegend({
    required this.variables,
    required this.colorForIndex,
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
              child: _LegendDot(
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

class _ChartModelPill extends StatelessWidget {
  final _ChartModel model;
  final VoidCallback onTap;

  const _ChartModelPill({
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color border =
        cs.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);
    final Color text = cs.onSurface.withValues(alpha: 0.88);

    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.size10),
      onTap: onTap,
      child: Container(
        height: Dimensions.size30,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Dimensions.size10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(model.icon(), size: Dimensions.size15, color: text),
            SizedBox(width: Dimensions.size5),
            Text(
              model.label(),
              style: TextStyle(
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w900,
                color: text,
              ),
            ),
            SizedBox(width: Dimensions.size5),
            Icon(
              Icons.expand_more_rounded,
              size: Dimensions.size20,
              color: text,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Dimensions.size10,
          height: Dimensions.size10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(Dimensions.size3),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
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
              color: cs.onSurface.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingCardSkeleton extends StatelessWidget {
  const _LoadingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme cs = Theme.of(context).colorScheme;

    final Color base = dark
        ? cs.onSurface.withValues(alpha: 0.10)
        : cs.onSurface.withValues(alpha: 0.06);

    final Color hi = dark
        ? cs.onSurface.withValues(alpha: 0.06)
        : cs.onSurface.withValues(alpha: 0.02);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: hi,
          child: Container(
            height: 380,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(Dimensions.size15),
            ),
          ),
        ),
      ),
    );
  }
}
