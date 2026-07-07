import "package:flutter/material.dart";

enum ChartModel {
  stackedColumn,
  groupedColumn,
  line,
  stackedArea,
  stackedBar,
  pie,
  table,
}

enum RangePreset { today, last7, last30 }

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
      case ChartModel.table:
        return "Table";
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
      case ChartModel.table:
        return Icons.table_chart_rounded;
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
      case ChartModel.table:
        return false;
    }
  }

  bool isCircular() => this == ChartModel.pie;
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
