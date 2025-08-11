// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/model/dynamic_schedule_data.dart";
import "package:dynamic_of_things/model/dynamic_schedule_template.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_event.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicScheduleBloc extends Bloc<DynamicScheduleEvent, DynamicScheduleState> {
  DynamicScheduleBloc() : super(DynamicScheduleInitial()) {
    on<DynamicScheduleTemplate>((event, emit) async {
      try {
        emit(DynamicScheduleTemplateLoading());

        Response response = await DotApis.getInstance().dynamicScheduleTemplate(
          id: event.id,
          customerId: event.customerId,
        );

        if (response.statusCode == 200) {
          emit(DynamicScheduleTemplateSuccess(Template.fromJson(response.data)));
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicScheduleTemplateFinished());
      }
    });

    on<DynamicScheduleData>((event, emit) async {
      try {
        emit(DynamicScheduleDataLoading());

        Response response = await DotApis.getInstance().dynamicScheduleData(
          id: event.id,
          customerId: event.customerId,
          begin: event.begin,
          until: event.until,
          formId: event.formId,
        );

        if (response.statusCode == 200) {
          emit(DynamicScheduleDataSuccess(response.data != null ? List<Item>.from(response.data.map((e) => Item.fromJson(e))) : []));
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicScheduleDataFinished());
      }
    });
  }
}
