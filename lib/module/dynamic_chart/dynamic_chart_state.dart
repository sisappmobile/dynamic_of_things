import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";

abstract class DynamicChartState {}

class DynamicChartInitial extends DynamicChartState {}

class DynamicChartLoadLoading extends DynamicChartState {}

class DynamicChartLoadSuccess extends DynamicChartState {
  final ListResponse listResponse;

  DynamicChartLoadSuccess({
    required this.listResponse,
  });
}

class DynamicChartLoadFinished extends DynamicChartState {}

class DynamicChartDataLoading extends DynamicChartState {
  final String id;

  DynamicChartDataLoading({
    required this.id,
  });
}

class DynamicChartDataSuccess extends DynamicChartState {
  final String id;
  final dynamic data;

  DynamicChartDataSuccess({
    required this.id,
    required this.data,
  });
}

class DynamicChartDataFinished extends DynamicChartState {
  final String id;

  DynamicChartDataFinished({
    required this.id,
  });
}
