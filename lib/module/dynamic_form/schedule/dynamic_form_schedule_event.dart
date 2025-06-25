abstract class DynamicFormScheduleEvent {}

class DynamicFormScheduleLoad extends DynamicFormScheduleEvent {
  final String id;
  final String? customerId;
  final String name;

  DynamicFormScheduleLoad({
    required this.id,
    required this.customerId,
    required this.name,
  });
}
