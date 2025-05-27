// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
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

        Response response = await DotApis.getInstance().dynamicReportTemplate(
          id: event.id,
        );

        if (response.statusCode == 200) {
          emit(
            DynamicReportTemplateSuccess(
              template: Template.fromJson(response.data),
            ),
          );
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicReportTemplateFinished());
      }
    });

    on<DynamicReportData>((event, emit) async {
      try {
        emit(DynamicReportDataLoading());

        Response response = await DotApis.getInstance().dynamicReportData(
          id: event.id,
          dataRequest: event.dataRequest,
        );

        if (response.statusCode == 200) {
          emit(
            DynamicReportDataSuccess(
              dataResponse: DataResponse.fromJson(response.data),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicReportDataFinished());
      }
    });

    on<DynamicReportExport>((event, emit) async {
      try {
        emit(DynamicReportExportLoading());

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
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicReportExportFinished());
      }
    });
  }
}
