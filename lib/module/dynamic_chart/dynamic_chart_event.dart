import "package:jiffy/jiffy.dart";

abstract class DynamicChartEvent {}

class DynamicChartLoad extends DynamicChartEvent {}

class DynamicChartData extends DynamicChartEvent {
  final String id;
  final Jiffy begin;
  final Jiffy until;

  DynamicChartData({
    required this.id,
    required this.begin,
    required this.until,
  });
}
