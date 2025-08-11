import "package:jiffy/jiffy.dart";

abstract class DynamicScheduleEvent {}

class DynamicScheduleTemplate extends DynamicScheduleEvent {
  final String id;
  final String? customerId;

  DynamicScheduleTemplate({
    required this.id,
    required this.customerId,
  });
}

class DynamicScheduleData extends DynamicScheduleEvent {
  final String id;
  final String? customerId;
  final Jiffy begin;
  final Jiffy until;
  final String? formId;

  DynamicScheduleData({
    required this.id,
    required this.customerId,
    required this.begin,
    required this.until,
    required this.formId,
  });
}
