abstract class DynamicFormMenuEvent {}

class DynamicFormMenuLoad extends DynamicFormMenuEvent {
  final String? customerId;

  DynamicFormMenuLoad({
    required this.customerId,
  });
}
