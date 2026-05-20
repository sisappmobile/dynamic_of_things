import "dart:math" as math;

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/chart_model.dart";
import "package:dynamic_of_things/helper/chart_helper.dart";
import "package:dynamic_of_things/helper/dynamic_chart_data_helper.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:dynamic_of_things/widget/insight.dart";
import "package:dynamic_of_things/widget/loading_card.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:jiffy/jiffy.dart";
import "package:syncfusion_flutter_charts/charts.dart";

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

  static const List<Color> basePalette = <Color>[
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
        !sameCalendarDay(oldWidget.begin.dateTime, widget.begin.dateTime) ||
            !sameCalendarDay(oldWidget.until.dateTime, widget.until.dateTime);

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
      isScrollControlled: true,
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
        final ColorScheme colorScheme = Theme.of(context).colorScheme;

        final List<ChartModel> models = <ChartModel>[
          ChartModel.stackedColumn,
          ChartModel.groupedColumn,
          ChartModel.line,
          ChartModel.stackedArea,
          ChartModel.stackedBar,
          ChartModel.pie,
          ChartModel.table,
        ];

        final double bottomInset = MediaQuery.of(context).padding.bottom;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double maxHeight = screenHeight * 0.78;

        const int crossAxisCount = 3;
        final double gap = Dimensions.size10;
        final double cardPadding = Dimensions.size10;
        final double headerHeight = Dimensions.size20;

        final double tileHeight = math.max(
          92.0,
          Dimensions.size100.toDouble(),
        );

        final int rows = (models.length / crossAxisCount).ceil();
        final double gridHeight = (rows * tileHeight) + ((rows - 1) * gap);

        final double estimatedHeight = headerHeight +
            Dimensions.size10 +
            gridHeight +
            (cardPadding * 2) +
            bottomInset +
            Dimensions.size10;

        final bool needsScroll = estimatedHeight > maxHeight;

        Color modelColor(ChartModel chartModel) {
          switch (chartModel) {
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
            case ChartModel.table:
              return const Color.fromARGB(255, 55, 116, 255);
          }
        }

        Widget gridItem(ChartModel chartModel) {
          final bool active = chartModel == model;
          final Color accent = modelColor(chartModel);

          return InkWell(
            borderRadius: BorderRadius.circular(Dimensions.size15),
            onTap: () => Navigator.of(context).pop(chartModel),
            child: Container(
              height: tileHeight,
              padding: EdgeInsets.all(Dimensions.size10),
              decoration: BoxDecoration(
                color: active
                    ? Color.alphaBlend(
                        accent.withValues(alpha: 0.10),
                        colorScheme.surface,
                      )
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(Dimensions.size15),
                border: Border.all(
                  color: active
                      ? Color.alphaBlend(
                          accent.withValues(alpha: 0.35),
                          colorScheme.outlineVariant.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.35
                                    : 0.55,
                          ),
                        )
                      : colorScheme.outlineVariant.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.55,
                        ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool compact = constraints.maxHeight < 84;

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
                            colorScheme.surface,
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
                          chartModel.icon(),
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
                            chartModel.label(),
                            textAlign: TextAlign.center,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact
                                  ? Dimensions.text11
                                  : Dimensions.text12,
                              fontWeight: FontWeight.w900,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.92),
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      if (!compact) ...[
                        SizedBox(height: Dimensions.size2),
                        Text(
                          chartModel == ChartModel.table
                              ? "Rows"
                              : (chartModel.isCircular()
                                  ? "Circular"
                                  : (chartModel.isStacked()
                                      ? "Stacked"
                                      : "Non-stacked")),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:
                                compact ? Dimensions.text9 : Dimensions.text10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.85,
                            ),
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
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.85)
                                    .withValues(alpha: 0.65),
                            width: 1.6,
                          ),
                        ),
                        child: active
                            ? Icon(
                                Icons.check,
                                size: Dimensions.size10,
                                color: colorScheme.surface,
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
                  height: headerHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "select_chartmodel".tr(),
                      style: TextStyle(
                        fontSize: Dimensions.text16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
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
                    mainAxisExtent: tileHeight,
                  ),
                  itemBuilder: (_, index) => gridItem(models[index]),
                ),
              ],
            ),
          ),
        );

        return needsScroll
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: inner,
                ),
              )
            : inner;
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
    final Map<String, num> totals = <String, num>{};
    for (final Map<String, dynamic> entry in src) {
      final String variable = entry["variable"].toString();
      final num value = parseChartNumber(entry["value"]);
      totals[variable] = (totals[variable] ?? 0) + value;
    }

    final List<MapEntry<String, num>> sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) => entry.key).toList();
  }

  Color colorIndex(int index) {
    if (index < basePalette.length) {
      return basePalette[index];
    }

    final double hue = (index * 0.61803398875) % 1.0;
    final HSVColor hsv = HSVColor.fromAHSV(1, 360 * hue, 0.38, 0.95);
    return hsv.toColor();
  }

  Widget content() {
    final bool hasData = raw != null && raw!.isNotEmpty;

    final List<String> variables =
        hasData ? allVariableSorted(raw!) : <String>[];

    final List<PieSlice> pieSlices = hasData
        ? pieChartSlices(raw!, maxSlices: 7, minPct: 2.5)
        : <PieSlice>[];

    final List<String> pieCategories =
        pieSlices.map((slice) => slice.label).toList();
    final bool showDivergingLegend = model == ChartModel.groupedColumn;
    final bool showTable = model == ChartModel.table;
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
          if (model == ChartModel.pie && pieCategories.isNotEmpty)
            ScroolLegend(
              isGlass: widget.isGlass,
              variables: pieCategories,
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
          else if (!showTable &&
              model != ChartModel.pie &&
              variables.isNotEmpty)
            ScroolLegend(
              isGlass: widget.isGlass,
              variables: variables,
              colorForIndex: colorIndex,
            ),
          if ((model == ChartModel.pie && pieCategories.isNotEmpty) ||
              (!showTable && model != ChartModel.pie && variables.isNotEmpty))
            SizedBox(height: Dimensions.size10),
          SizedBox(
            height: widget.compact ? 300 : 320,
            child: hasData ? anyChart(variables) : BaseWidgets.noData(),
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
              final insight = buildInsight(raw!);
              return Insight(
                isGlass: widget.isGlass,
                total: insight.total,
                rows: insight.rows,
                rangeLabel: buildChartDateRangeLabel(
                  widget.begin,
                  widget.until,
                ),
                compositionByVariable: insight.compositionByVariable,
                compositionByCategory: insight.compositionByCategory,
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

  Widget anyChart(List<String> variables) {
    if (model == ChartModel.pie) {
      return KeyedSubtree(
        key: ValueKey<String>("${widget.chart.id}_${model.name}"),
        child: pieChart(),
      );
    }

    if (model == ChartModel.table) {
      return KeyedSubtree(
        key: ValueKey<String>("${widget.chart.id}_${model.name}"),
        child: chartDataTable(),
      );
    }

    return KeyedSubtree(
      key: ValueKey<String>("${widget.chart.id}_${model.name}"),
      child: cartesianChart(variables),
    );
  }

  Widget chartDataTable() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = widget.isGlass
        ? Colors.white.withOpacity(0.14)
        : colorScheme.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);
    final Color headerBg = widget.isGlass
        ? Colors.white.withOpacity(0.08)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final Color oddRowBg = widget.isGlass
        ? Colors.white.withOpacity(0.04)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.24);
    final Color primaryText = widget.isGlass
        ? Colors.white.withOpacity(0.92)
        : colorScheme.onSurface.withValues(alpha: 0.88);
    final Color secondaryText = widget.isGlass
        ? Colors.white.withOpacity(0.68)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.84);
    final List<Map<String, dynamic>> rows = raw!.toList()
      ..sort((a, b) {
        final int valueCompare = parseChartNumber(
          b["value"],
        ).compareTo(parseChartNumber(a["value"]));
        if (valueCompare != 0) {
          return valueCompare;
        }

        final String categoryA = (a["category"] ?? "").toString();
        final String categoryB = (b["category"] ?? "").toString();
        return categoryA.toLowerCase().compareTo(categoryB.toLowerCase());
      });

    Widget cell(
      String text, {
      required int flex,
      bool header = false,
      TextAlign align = TextAlign.start,
      Color? color,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: header ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            fontSize: header ? Dimensions.text11 : Dimensions.text12,
            fontWeight: header ? FontWeight.w900 : FontWeight.w700,
            color: color ?? (header ? secondaryText : primaryText),
            height: 1.15,
          ),
        ),
      );
    }

    Widget tableRow({
      required List<Widget> children,
      required Color background,
      BorderRadius? radius,
      Border? border,
    }) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size10,
          vertical: Dimensions.size10,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: border,
        ),
        child: Row(children: children),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.size15),
      child: Column(
        children: [
          tableRow(
            background: headerBg,
            radius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.size15),
            ),
            border: Border.all(color: borderColor, width: 0.7),
            children: [
              cell("Variable", flex: 4, header: true),
              cell("Category", flex: 4, header: true),
              cell(
                "Total",
                flex: 3,
                header: true,
                align: TextAlign.end,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> row = rows[index];
                final String variable =
                    (row["variable"] ?? "").toString().trim();
                final String category =
                    (row["category"] ?? "").toString().trim();
                final num value = parseChartNumber(row["value"]);

                return tableRow(
                  background: index.isEven ? Colors.transparent : oddRowBg,
                  border: Border(
                    left: BorderSide(color: borderColor, width: 0.7),
                    right: BorderSide(color: borderColor, width: 0.7),
                    bottom: BorderSide(color: borderColor, width: 0.7),
                  ),
                  children: [
                    cell(variable.isEmpty ? "-" : variable, flex: 4),
                    cell(category.isEmpty ? "-" : category, flex: 4),
                    cell(
                      formatChartNumber(value),
                      flex: 3,
                      align: TextAlign.end,
                      color: primaryText,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PieSlice> pieChartSlices(
    List<Map<String, dynamic>> src, {
    int maxSlices = 8,
    double minPct = 2.5,
  }) {
    final Map<String, num> sums = <String, num>{};
    num grand = 0;

    for (final Map<String, dynamic> entry in src) {
      final String category = (entry["category"] ?? "").toString().trim();
      final num value = parseChartNumber(entry["value"]);

      if (value <= 0) {
        continue;
      }

      final String safeCategory = category.isEmpty ? "-" : category;
      sums[safeCategory] = (sums[safeCategory] ?? 0) + value;
      grand += value;
    }

    final List<MapEntry<String, num>> sorted = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty || grand <= 0) {
      return <PieSlice>[];
    }

    final List<PieSlice> output = <PieSlice>[];
    num other = 0;

    for (final MapEntry<String, num> entry in sorted) {
      final double percentage = (entry.value / grand) * 100.0;

      if (output.length >= maxSlices || percentage < minPct) {
        other += entry.value;
      } else {
        output.add(PieSlice(label: entry.key, value: entry.value));
      }
    }

    if (other > 0) {
      output.add(PieSlice(label: "other".tr(), value: other));
    }

    return output;
  }

  Widget pieChart() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<PieSlice> slices = pieChartSlices(
      raw!,
      maxSlices: 7,
      minPct: 2.5,
    );

    if (slices.isEmpty) {
      return BaseWidgets.noData();
    }

    final num total = slices.fold<num>(0, (previous, entry) {
      return previous + entry.value;
    });

    double percentageValue(num value) => total <= 0 ? 0 : (value / total) * 100;

    String percentageText(num value) {
      final double percentage = percentageValue(value);
      return percentage >= 10
          ? "${percentage.toStringAsFixed(0)}%"
          : "${percentage.toStringAsFixed(1)}%";
    }

    return SfCircularChart(
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero,
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: "",
        color: colorScheme.surfaceContainerHighest,
        textStyle: TextStyle(color: colorScheme.onSurface),
        builder: (
          dynamic value,
          dynamic point,
          dynamic series,
          int pointIndex,
          int seriesIndex,
        ) {
          if (pointIndex < 0 || pointIndex >= slices.length) {
            return const SizedBox.shrink();
          }

          final PieSlice item = slices[pointIndex];
          return Container(
            padding: EdgeInsets.all(Dimensions.size10),
            constraints: const BoxConstraints(minWidth: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: Dimensions.size5),
                Text(
                  formatChartNumber(item.value),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      series: <CircularSeries<PieSlice, String>>[
        DoughnutSeries<PieSlice, String>(
          dataSource: slices,
          xValueMapper: (PieSlice slice, _) => slice.label,
          yValueMapper: (PieSlice slice, _) => slice.value.toDouble(),
          pointColorMapper: (PieSlice slice, int index) => colorIndex(index),
          cornerStyle: CornerStyle.endCurve,
          innerRadius: "66%",
          radius: "92%",
          strokeColor: colorScheme.surface,
          strokeWidth: 2,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(
              color: widget.isGlass
                  ? Colors.white.withOpacity(0.18)
                  : colorScheme.outlineVariant.withValues(
                      alpha: dark ? 0.35 : 0.55,
                    ),
              length: "10%",
              width: 1,
            ),
            builder: (
              dynamic data,
              dynamic point,
              dynamic series,
              int index,
              int s,
            ) {
              final PieSlice slice = slices[index];
              final double percentage = percentageValue(slice.value);
              if (percentage < 5) {
                return const SizedBox.shrink();
              }

              return Text(
                percentageText(slice.value),
                style: TextStyle(
                  fontSize: Dimensions.text11,
                  fontWeight: FontWeight.w800,
                  color: widget.isGlass
                      ? Colors.white.withOpacity(0.88)
                      : colorScheme.onSurface.withValues(alpha: 0.88),
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

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final Agg aggregated = aggregate(raw!);
    final List<CatPoint> points = aggregated.points;

    num maxYForStacked() {
      return points.fold<num>(0, (previous, point) {
        final num sum = point.values.values.fold<num>(0, (inner, value) {
          return inner + value;
        });
        return math.max(previous, sum);
      });
    }

    num maxYForNonStacked() {
      return points.fold<num>(0, (previous, point) {
        final num maxValue = point.values.values.fold<num>(0, (inner, value) {
          return math.max(inner, value);
        });
        return math.max(previous, maxValue);
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
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.90),
        ),
        autoScrollingDelta: 7,
        autoScrollingMode: AutoScrollingMode.start,
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          final String full = details.text;
          final CatPoint? point = points.firstWhereOrNull(
            (item) => item.category == full,
          );
          return ChartAxisLabel(point?.shortLabel ?? full, details.textStyle);
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
              : colorScheme.onSurface.withValues(alpha: dark ? 0.10 : 0.08),
        ),
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        numberFormat: chartAxisNumberFormat(),
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.80)
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.80),
        ),
      ),
      legend: const Legend(isVisible: false),
      tooltipBehavior: toolTip(points),
      zoomPanBehavior: zoom,
      series: series(points, variables),
    );
  }

  List<DivergingPoint> divergingPoints() {
    final Agg aggregated = aggregate(raw!);
    if (aggregated.points.isEmpty) {
      return <DivergingPoint>[];
    }

    final List<MapEntry<String, double>> totals = aggregated.points.map((
      CatPoint point,
    ) {
      final double total = point.values.values.fold<double>(
        0,
        (double previous, num value) => previous + value.toDouble(),
      );
      return MapEntry<String, double>(point.category, total);
    }).toList();

    final double baseline = totals.fold<double>(
          0,
          (double previous, MapEntry<String, double> item) {
            return previous + item.value;
          },
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
      ..sort((a, b) => b.delta.compareTo(a.delta));
  }

  Widget divergingBarChart() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<DivergingPoint> points = divergingPoints();

    if (points.isEmpty) {
      return BaseWidgets.noData();
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
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.90),
        ),
      ),
      primaryYAxis: NumericAxis(
        minimum: -axisExtent,
        maximum: axisExtent,
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        numberFormat: chartAxisNumberFormat(),
        majorGridLines: MajorGridLines(
          width: 1,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.10)
              : colorScheme.onSurface.withValues(alpha: dark ? 0.10 : 0.08),
        ),
        labelStyle: TextStyle(
          fontSize: Dimensions.text11,
          fontWeight: FontWeight.w700,
          color: widget.isGlass
              ? Colors.white.withOpacity(0.80)
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.80),
        ),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: "",
        color: colorScheme.surfaceContainerHighest,
        textStyle: TextStyle(color: colorScheme.onSurface),
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
                    color: colorScheme.onSurface,
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
          final Color color = colorIndex(index);
          return StackedColumnSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint point, _) => point.category,
            yValueMapper: (CatPoint point, _) =>
                (point.values[variable] ?? 0).toDouble(),
            name: variable,
            color: color,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case ChartModel.groupedColumn:
        return variables.mapIndexed((index, variable) {
          final Color color = colorIndex(index);
          return ColumnSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint point, _) => point.category,
            yValueMapper: (CatPoint point, _) =>
                (point.values[variable] ?? 0).toDouble(),
            name: variable,
            color: color,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case ChartModel.line:
        return variables.mapIndexed((index, variable) {
          final Color color = colorIndex(index);
          return LineSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint point, _) => point.category,
            yValueMapper: (CatPoint point, _) =>
                (point.values[variable] ?? 0).toDouble(),
            name: variable,
            color: color,
            width: 2,
            markerSettings: const MarkerSettings(isVisible: false),
          );
        }).toList();

      case ChartModel.stackedArea:
        return variables.mapIndexed((index, variable) {
          final Color color = colorIndex(index);
          return StackedAreaSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint point, _) => point.category,
            yValueMapper: (CatPoint point, _) =>
                (point.values[variable] ?? 0).toDouble(),
            name: variable,
            color: color.withValues(alpha: 0.80),
            borderColor: color.withValues(alpha: 0.95),
            borderWidth: 1.2,
          );
        }).toList();

      case ChartModel.stackedBar:
        return variables.mapIndexed((index, variable) {
          final Color color = colorIndex(index);
          return StackedBarSeries<CatPoint, String>(
            dataSource: points,
            xValueMapper: (CatPoint point, _) => point.category,
            yValueMapper: (CatPoint point, _) =>
                (point.values[variable] ?? 0).toDouble(),
            name: variable,
            color: color,
            width: 0.60,
            spacing: 0.16,
            borderRadius: BorderRadius.circular(Dimensions.size5),
          );
        }).toList();

      case ChartModel.pie:
      case ChartModel.table:
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

        final CatPoint selectedPoint = points[pointIndex];
        final List<MapEntry<String, num>> entries = selectedPoint.values.entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          padding: EdgeInsets.all(Dimensions.size10),
          constraints: const BoxConstraints(minWidth: 190),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedPoint.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: Dimensions.size10),
              ...entries.take(10).mapIndexed((index, entry) {
                final Color color = colorIndex(index);
                return Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.size5),
                  child: Row(
                    children: [
                      Container(
                        width: Dimensions.size10,
                        height: Dimensions.size10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            Dimensions.size3,
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.size10),
                      Expanded(
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.size10),
                      Text(
                        formatChartNumber(entry.value),
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
}
