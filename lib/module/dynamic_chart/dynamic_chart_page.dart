// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/helper/formats.dart";
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
import "package:smooth_corner/smooth_corner.dart";
import "package:syncfusion_flutter_charts/charts.dart";

class DynamicChartPage extends StatefulWidget {
  const DynamicChartPage({
    super.key,
  });

  @override
  DynamicChartPageState createState() => DynamicChartPageState();
}

class DynamicChartPageState extends State<DynamicChartPage> with WidgetsBindingObserver {
  ListResponse? listResponse;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartLoadLoading) {
          context.loaderOverlay.show();

          setState(() {
            listResponse = null;
          });
        } else if (state is DynamicChartLoadSuccess) {
          setState(() {
            listResponse = state.listResponse;
          });
        } else if (state is DynamicChartLoadFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "dynamic_chart".tr(),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: body(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  void refresh() {
    context.read<DynamicChartBloc>().add(DynamicChartLoad());
  }

  Widget body() {
    if (listResponse != null) {
      return Container(
        padding: EdgeInsets.all(Dimensions.size20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              direction: Axis.horizontal,
              spacing: Dimensions.size10,
              runSpacing: Dimensions.size10,
              children: listResponse!.charts.whereType<Summary>().map((e) {
                return SummaryWidget(summary: e);
              }).toList(),
            ),
            SizedBox(height: Dimensions.size10),
            Wrap(
              direction: Axis.vertical,
              spacing: Dimensions.size10,
              runSpacing: Dimensions.size10,
              children: listResponse!.charts.whereNot((element) => element is Summary).map((e) {
                return ChartWidget(chart: e);
              }).toList(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class SummaryWidget extends StatefulWidget {
  final Summary summary;

  const SummaryWidget({
    required this.summary,
    super.key,
  });

  @override
  SummaryWidgetState createState() => SummaryWidgetState();
}

class SummaryWidgetState extends State<SummaryWidget> {
  bool loading = false;

  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();

    context.read<DynamicChartBloc>().add(
      DynamicChartData(
        id: widget.summary.id,
        begin: Jiffy.now(),
        until: Jiffy.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartDataLoading) {
          if (state.id == widget.summary.id) {
            setState(() {
              loading = true;
              data = null;
            });
          }
        } else if (state is DynamicChartDataSuccess) {
          if (state.id == widget.summary.id) {
            data = state.data;

            setState(() {});
          }
        } else if (state is DynamicChartDataFinished) {
          if (state.id == widget.summary.id) {
            setState(() {
              loading = false;
            });
          }
        }
      },
      child: body(),
    );
  }

  Widget body() {
    double width = (Dimensions.screenWidth - 50) / 2;

    if (loading) {
      return Shimmer.fromColors(
        baseColor: AppColors.surfaceContainerLowest(),
        highlightColor: AppColors.surfaceContainerHighest(),
        child: Container(
          width: width,
          height: Dimensions.size100,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size10),
              smoothness: 1,
            ),
            color: AppColors.onSurface(),
          ),
        ),
      );
    } else {
      if (data != null) {
        return SizedBox(
          width: width,
          child: OutlinedButton.icon(
            onPressed: () {

            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.size10,
                vertical: Dimensions.size15,
              ),
              alignment: Alignment.centerLeft,
              backgroundColor: AppColors.materialContainer(color()),
              foregroundColor: AppColors.onMaterialContainer(color()),
              iconColor: AppColors.onMaterialContainer(color()),
              side: BorderSide(color: AppColors.onMaterialContainer(color())),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size10),
                smoothness: 1,
              ),
            ),
            icon: Icon(
              icon(),
              size: Dimensions.size35,
            ),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.summary.title,
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                  ),
                ),
                Text(
                  data!["value"],
                  style: TextStyle(
                    fontSize: Dimensions.text20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data!["label"],
                  style: TextStyle(
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          width: width,
          height: Dimensions.size100,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size10),
              smoothness: 1,
              side: BorderSide(
                color: AppColors.onErrorContainer(),
              ),
            ),
            color: AppColors.errorContainer(),
          ),
          alignment: Alignment.center,
          child: Text(
            "failed_to_load_data".tr(),
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.bold,
              color: AppColors.onErrorContainer(),
            ),
          ),
        );
      }
    }
  }

  MaterialColor color() {
    if (widget.summary.color == "Red") {
      return Colors.red;
    } else if (widget.summary.color == "Blue") {
      return Colors.blue;
    } else if (widget.summary.color == "Green") {
      return Colors.green;
    } else if (widget.summary.color == "Yellow") {
      return Colors.yellow;
    } else {
      return Colors.blueGrey;
    }
  }

  IconData icon() {
    if (widget.summary.icon == "House") {
      return Icons.house_outlined;
    } else if (widget.summary.icon == "Cart") {
      return Icons.shopping_cart_outlined;
    } else if (widget.summary.icon == "Person") {
      return Icons.person_outline;
    } else if (widget.summary.icon == "Book") {
      return Icons.menu_book_outlined;
    } else {
      return Icons.category_outlined;
    }
  }
}

class ChartWidget extends StatefulWidget {
  final Chart chart;

  const ChartWidget({
    required this.chart,
    super.key,
  });

  @override
  ChartWidgetState createState() => ChartWidgetState();
}

class ChartWidgetState extends State<ChartWidget> {
  List<Map<String, dynamic>>? data;

  bool loading = true;

  static const List<MaterialColor> materialColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.deepOrange,
    Colors.green,
    Colors.lightBlue,
    Colors.brown,
    Colors.orange,
    Colors.deepPurple,
    Colors.indigo,
    Colors.cyan,
    Colors.teal,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();

    context.read<DynamicChartBloc>().add(
      DynamicChartData(
        id: widget.chart.id,
        begin: Jiffy.now(),
        until: Jiffy.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartDataLoading) {
          if (state.id == widget.chart.id) {
            setState(() {
              loading = true;
              data = null;
            });
          }
        } else if (state is DynamicChartDataSuccess) {
          if (state.id == widget.chart.id) {
            data = List<Map<String, dynamic>>.from(
              state.data.map((e) {
                return e;
              }),
            );

            setState(() {});
          }
        } else if (state is DynamicChartDataFinished) {
          if (state.id == widget.chart.id) {
            setState(() {
              loading = false;
            });
          }
        }
      },
      child: body(),
    );
  }

  Widget body() {
    if (loading) {
      return Shimmer.fromColors(
        baseColor: AppColors.surfaceContainerLowest(),
        highlightColor: AppColors.surfaceContainerHighest(),
        child: Container(
          height: Dimensions.size100 * 3,
          margin: EdgeInsets.fromLTRB(
            Dimensions.size20,
            Dimensions.size20,
            Dimensions.size20,
            0,
          ),
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size10),
              smoothness: 1,
              side: BorderSide(color: AppColors.outline()),
            ),
            color: AppColors.onSurface(),
          ),
        ),
      );
    } else {
      if (data != null && data!.isNotEmpty) {
        return Container(
          width: Dimensions.screenWidth - Dimensions.size40,
          height: Dimensions.size100 * 5,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size10),
              smoothness: 1,
              side: BorderSide(color: AppColors.outline()),
            ),
            color: AppColors.surface(),
          ),
          padding: EdgeInsets.all(
            Dimensions.size15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chart.title,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimensions.size10),
              Expanded(
                child: chart(),
              ),
            ],
          ),
        );
      } else {
        return Container(
          height: Dimensions.size100 * 3,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size10),
              smoothness: 1,
              side: BorderSide(
                color: AppColors.onErrorContainer(),
              ),
            ),
            color: AppColors.errorContainer(),
          ),
          alignment: Alignment.center,
          child: Text(
            "failed_to_load_data".tr(),
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.bold,
              color: AppColors.onErrorContainer(),
            ),
          ),
        );
      }
    }
  }

  Widget chart() {
    if (data!.first.containsKey("variable")) {
      Set<String> variables = data!.map((e) => e["variable"].toString()).toSet();

      return SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          axisLine: const AxisLine(width: 0),
          borderWidth: 0,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface().withValues(alpha: 0.5),
          ),
          maximumLabels: 100,
          autoScrollingDelta: 10,
          autoScrollingMode: AutoScrollingMode.start,
          labelRotation: 90,
        ),
        primaryYAxis: NumericAxis(
          axisLabelFormatter: (AxisLabelRenderDetails args) {
            return ChartAxisLabel(
              Formats.tryParseNumber(args.text).shortHand(),
              args.textStyle,
            );
          },
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          axisLine: const AxisLine(width: 0),
          borderWidth: 0,
          edgeLabelPlacement: EdgeLabelPlacement.hide,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface().withValues(alpha: 0.5),
          ),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          legendItemBuilder: (legendText, series, point, seriesIndex) {
            if (series != null) {
              return Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: series.color,
                    size: Dimensions.size15,
                  ),
                  SizedBox(width: Dimensions.size5),
                  Text(series.name!),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: "",
          builder: (dynamic value, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
            String category = value["category"];

            List<Map<String, dynamic>> maps = data!.where((element) => element["category"] == category).toList();

            return IntrinsicHeight(
              child: Container(
                padding: EdgeInsets.all(Dimensions.size10),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: AppColors.surface(),
                        fontSize: Dimensions.text14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...maps.mapIndexed((index, element) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: materialColors[index],
                                size: Dimensions.size15,
                              ),
                              SizedBox(width: Dimensions.size5),
                              Text(
                                "${element["variable"]} : ",
                                style: TextStyle(
                                  color: AppColors.surface(),
                                ),
                              ),
                              Text(
                                (element["value"] as num).currency(),
                                style: TextStyle(
                                  color: AppColors.surface(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        series: variables.mapIndexed((index, variable) {
          List<Map<String, dynamic>> subData = data!.where((element) => element["variable"] == variable).toList();

          MaterialColor materialColor = materialColors[index];

          return series(subData, variable, materialColor, true);
        }).toList(),
      );
    } else {
      return SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          axisLine: const AxisLine(width: 0),
          borderWidth: 0,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface().withValues(alpha: 0.5),
          ),
          maximumLabels: 100,
          labelRotation: 90,
        ),
        primaryYAxis: NumericAxis(
          axisLabelFormatter: (AxisLabelRenderDetails args) {
            return ChartAxisLabel(
              Formats.tryParseNumber(args.text).shortHand(),
              args.textStyle,
            );
          },
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          axisLine: const AxisLine(width: 0),
          borderWidth: 0,
          edgeLabelPlacement: EdgeLabelPlacement.hide,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface().withValues(alpha: 0.5),
          ),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: "",
          builder: (dynamic value, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
            return IntrinsicHeight(
              child: Container(
                padding: EdgeInsets.all(Dimensions.size10),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value["category"],
                      style: TextStyle(
                        color: AppColors.surface(),
                        fontSize: Dimensions.text14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      (value["value"] as num).currency(),
                      style: TextStyle(
                        color: AppColors.surface(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        series: <CartesianSeries>[
          series(data!, "", Colors.purple, false),
        ],
      );
    }
  }

  CartesianSeries series(List<Map<String, dynamic>> source, String name, MaterialColor color, bool stacked) {
    if (stacked) {
      if (widget.chart.type == "Line Chart") {
        return StackedLineSeries<Map<String, dynamic>, String>(
          dataSource: source,
          xValueMapper: (Map<String, dynamic> data, _) => data["category"],
          yValueMapper: (Map<String, dynamic> data, _) => data["value"],
          name: name,
          color: AppColors.material(color),
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: AppColors.onMaterial(color),
            borderColor: AppColors.material(color),
          ),
        );
      } else {
        return StackedColumnSeries<Map<String, dynamic>, String>(
          dataSource: source,
          xValueMapper: (Map<String, dynamic> data, _) => data["category"],
          yValueMapper: (Map<String, dynamic> data, _) => data["value"],
          name: name,
          color: AppColors.material(color),
        );
      }
    } else {
      if (widget.chart.type == "Line Chart") {
        return LineSeries<Map<String, dynamic>, String>(
          dataSource: source,
          xValueMapper: (Map<String, dynamic> data, _) => data["category"],
          yValueMapper: (Map<String, dynamic> data, _) => data["value"],
          name: name,
          color: AppColors.material(color),
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: AppColors.onMaterial(color),
            borderColor: AppColors.material(color),
          ),
        );
      } else {
        return ColumnSeries<Map<String, dynamic>, String>(
          dataSource: source,
          xValueMapper: (Map<String, dynamic> data, _) => data["category"],
          yValueMapper: (Map<String, dynamic> data, _) => data["value"],
          name: name,
          borderColor: AppColors.material(color),
          borderRadius: BorderRadius.circular(Dimensions.size10),
          gradient: LinearGradient(
            colors: [
              AppColors.surface(),
              AppColors.materialContainer(color),
            ],
            stops: const [0.0, 1.2],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        );
      }
    }
  }
}
