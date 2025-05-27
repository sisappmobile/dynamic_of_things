// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicChartBloc extends Bloc<DynamicChartEvent, DynamicChartState> {
  DynamicChartBloc() : super(DynamicChartInitial()) {
    on<DynamicChartLoad>((event, emit) async {
      try {
        emit(DynamicChartLoadLoading());

        Response response = await DotApis.getInstance().dynamicChartList();

        if (response.statusCode == 200) {
          emit(DynamicChartLoadSuccess(listResponse: ListResponse.fromJson(response.data)));
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicChartLoadFinished());
      }
    });

    on<DynamicChartData>((event, emit) async {
      try {
        emit(DynamicChartDataLoading(id: event.id));

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
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicChartDataFinished(id: event.id));
      }
    });
  }
}
