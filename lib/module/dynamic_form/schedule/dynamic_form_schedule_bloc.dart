// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/model/dynamic_form_schedule_response.dart";
import "package:dynamic_of_things/module/dynamic_form/schedule/dynamic_form_schedule_event.dart";
import "package:dynamic_of_things/module/dynamic_form/schedule/dynamic_form_schedule_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicFormScheduleBloc extends Bloc<DynamicFormScheduleEvent, DynamicFormScheduleState> {
  DynamicFormScheduleBloc() : super(DynamicFormScheduleInitial()) {
    on<DynamicFormScheduleLoad>((event, emit) async {
      try {
        emit(DynamicFormScheduleLoadLoading());

        ScheduleResponse? scheduleResponse = await DotApis.getInstance().dynamicFormSchedule(
          id: event.id,
          customerId: event.customerId,
        );

        if (scheduleResponse != null) {
          emit(DynamicFormScheduleLoadSuccess(scheduleResponse: scheduleResponse));
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormScheduleLoadFinished());
      }
    });
  }
}
