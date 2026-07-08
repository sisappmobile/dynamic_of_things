import "package:dynamic_of_things/model/dynamic_schedule_data.dart";
import "package:dynamic_of_things/model/dynamic_schedule_template.dart";

abstract class DynamicScheduleState {}

class DynamicScheduleInitial extends DynamicScheduleState {}

class DynamicScheduleTemplateLoading extends DynamicScheduleState {}

class DynamicScheduleTemplateSuccess extends DynamicScheduleState {
  final Template template;

  DynamicScheduleTemplateSuccess(this.template);
}

class DynamicScheduleTemplateFinished extends DynamicScheduleState {}

class DynamicScheduleDataLoading extends DynamicScheduleState {}

class DynamicScheduleDataSuccess extends DynamicScheduleState {
  final List<Item> items;

  DynamicScheduleDataSuccess(this.items);
}

class DynamicScheduleDataFinished extends DynamicScheduleState {}
