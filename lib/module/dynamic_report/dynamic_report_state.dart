import "dart:typed_data";

import "package:dynamic_of_things/model/dynamic_report_data.dart";
import "package:dynamic_of_things/model/dynamic_report_template.dart";

abstract class DynamicReportState {}

class DynamicReportInitial extends DynamicReportState {}

class DynamicReportTemplateLoading extends DynamicReportState {}

class DynamicReportTemplateSuccess extends DynamicReportState {
  final Template template;

  DynamicReportTemplateSuccess({
    required this.template,
  });
}

class DynamicReportTemplateFinished extends DynamicReportState {}

class DynamicReportDataLoading extends DynamicReportState {}

class DynamicReportDataSuccess extends DynamicReportState {
  final DataResponse dataResponse;

  DynamicReportDataSuccess({
    required this.dataResponse,
  });
}

class DynamicReportDataFinished extends DynamicReportState {}

class DynamicReportExportLoading extends DynamicReportState {}

class DynamicReportExportSuccess extends DynamicReportState {
  final String fileName;
  final Uint8List bytes;

  DynamicReportExportSuccess({
    required this.fileName,
    required this.bytes,
  });
}

class DynamicReportExportFinished extends DynamicReportState {}
