abstract class DynamicFormListEvent {}

class DynamicFormListLoad extends DynamicFormListEvent {
  final String id;
  final String? customerId;
  final String name;

  DynamicFormListLoad({
    required this.id,
    required this.customerId,
    required this.name,
  });
}

class DynamicFormListCustomAction extends DynamicFormListEvent {
  final String actionId;
  final String formId;
  final String dataId;
  final String? customerId;

  DynamicFormListCustomAction({
    required this.actionId,
    required this.formId,
    required this.dataId,
    required this.customerId,
  });
}
