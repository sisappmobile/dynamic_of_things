import "package:dynamic_of_things/model/dynamic_form_schedule_response.dart";

abstract class DynamicFormScheduleState {}

class DynamicFormScheduleInitial extends DynamicFormScheduleState {}

class DynamicFormScheduleLoadLoading extends DynamicFormScheduleState {}

class DynamicFormScheduleLoadSuccess extends DynamicFormScheduleState {
  final ScheduleResponse scheduleResponse;

  DynamicFormScheduleLoadSuccess({
    required this.scheduleResponse,
  });
}

class DynamicFormScheduleLoadFinished extends DynamicFormScheduleState {}
