// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_error_messages.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offline_charts.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicChartBloc extends Bloc<DynamicChartEvent, DynamicChartState> {
  DynamicChartBloc() : super(DynamicChartInitial()) {
    on<DynamicChartLoad>((event, emit) async {
      try {
        emit(DynamicChartLoadLoading());

        ListResponse? listResponse;

        if (DynamicForms.offline) {
          listResponse = await OfflineCharts.list();
        } else {
          Response response = await DotApis.getInstance().dynamicChartList();

          if (response.statusCode == 200) {
            listResponse = ListResponse.fromJson(response.data);
          }
        }

        if (listResponse != null) {
          emit(DynamicChartLoadSuccess(listResponse: listResponse));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(
          message: await DynamicErrorMessages.fromException(
            e,
            stackTrace: s,
          ),
        );
      } finally {
        emit(DynamicChartLoadFinished());
      }
    });

    on<DynamicChartData>((event, emit) async {
      try {
        emit(DynamicChartDataLoading(id: event.id));

        if (DynamicForms.offline) {
          emit(
            DynamicChartDataSuccess(
              id: event.id,
              data: await OfflineCharts.data(
                id: event.id,
                begin: event.begin,
                until: event.until,
              ),
            ),
          );
        } else {
          Response response = await DotApis.getInstance().dynamicChartDetail(
            id: event.id,
            begin: event.begin,
            until: event.until,
          );

          if (response.statusCode == 200) {
            emit(
              DynamicChartDataSuccess(
                id: event.id,
                data: response.data,
              ),
            );
          }
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(
          message: await DynamicErrorMessages.fromException(
            e,
            stackTrace: s,
          ),
        );
      } finally {
        emit(DynamicChartDataFinished(id: event.id));
      }
    });
  }
}
