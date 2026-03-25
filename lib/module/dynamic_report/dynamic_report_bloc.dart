// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offline_reports.dart";
import "package:dynamic_of_things/model/dynamic_report_data.dart";
import "package:dynamic_of_things/model/dynamic_report_template.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_event.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicReportBloc extends Bloc<DynamicReportEvent, DynamicReportState> {
  DynamicReportBloc() : super(DynamicReportInitial()) {
    on<DynamicReportTemplate>((event, emit) async {
      try {
        emit(DynamicReportTemplateLoading());

        Template? template;

        if (DynamicForms.offline) {
          template = await OfflineReports.template(event.id);
        } else {
          Response response = await DotApis.getInstance().dynamicReportTemplate(event.id);

          if (response.statusCode == 200) {
            template = Template.fromJson(response.data);
          }
        }

        if (template != null) {
          emit(DynamicReportTemplateSuccess(template: template));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicReportTemplateFinished());
      }
    });

    on<DynamicReportData>((event, emit) async {
      try {
        emit(DynamicReportDataLoading());

        DataResponse? dataResponse;

        if (DynamicForms.offline) {
          dataResponse = await OfflineReports.data(
            id: event.id,
            dataRequest: event.dataRequest,
          );
        } else {
          Response response = await DotApis.getInstance().dynamicReportData(
            id: event.id,
            dataRequest: event.dataRequest,
          );

          if (response.statusCode == 200) {
            dataResponse = DataResponse.fromJson(response.data);
          }
        }

        if (dataResponse != null) {
          emit(DynamicReportDataSuccess(dataResponse: dataResponse));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicReportDataFinished());
      }
    });

    on<DynamicReportExport>((event, emit) async {
      try {
        emit(DynamicReportExportLoading());

        if (DynamicForms.offline) {
          Map<String, dynamic>? result = await OfflineReports.export(
            id: event.id,
            dataRequest: event.dataRequest,
          );

          if (result != null) {
            emit(
              DynamicReportExportSuccess(
                fileName: result["fileName"],
                bytes: result["bytes"],
              ),
            );
          }
        } else {
          Response response = await DotApis.getInstance().dynamicReportExport(
            id: event.id,
            dataRequest: event.dataRequest,
          );

          if (response.statusCode == 200) {
            String fileName = response.headers["Content-Disposition"]![0].toString();

            fileName = fileName.substring(fileName.lastIndexOf(";") + 1);
            fileName = fileName.trim();
            fileName = fileName.replaceAll(" ", "_");
            fileName = fileName.toLowerCase();

            emit(
              DynamicReportExportSuccess(
                fileName: fileName,
                bytes: response.data,
              ),
            );
          }
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicReportExportFinished());
      }
    });
  }
}
