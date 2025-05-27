import "package:dynamic_of_things/model/dynamic_report_data.dart";

abstract class DynamicReportEvent {}

class DynamicReportTemplate extends DynamicReportEvent {
  final String id;

  DynamicReportTemplate({
    required this.id,
  });
}

class DynamicReportData extends DynamicReportEvent {
  final String id;
  final DataRequest dataRequest;

  DynamicReportData({
    required this.id,
    required this.dataRequest,
  });
}

class DynamicReportExport extends DynamicReportEvent {
  final String id;
  final DataRequest dataRequest;

  DynamicReportExport({
    required this.id,
    required this.dataRequest,
  });
}
