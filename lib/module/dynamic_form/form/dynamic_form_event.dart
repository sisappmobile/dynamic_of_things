// ignore_for_file: always_put_required_named_parameters_first

import "package:dynamic_of_things/model/header_form.dart";

abstract class DynamicFormEvent {}

class DynamicFormCreate extends DynamicFormEvent {
  final String formId;
  final String? customerId;

  DynamicFormCreate({
    required this.formId,
    required this.customerId,
  });
}

class DynamicFormView extends DynamicFormEvent {
  final String formId;
  final String dataId;
  final String? customerId;

  DynamicFormView({
    required this.formId,
    required this.dataId,
    required this.customerId,
  });
}

class DynamicFormEdit extends DynamicFormEvent {
  final String formId;
  final String dataId;
  final String? customerId;

  DynamicFormEdit({
    required this.formId,
    required this.dataId,
    required this.customerId,
  });
}

class DynamicFormSave extends DynamicFormEvent {
  final String formId;
  final String? customerId;
  final HeaderForm headerForm;

  DynamicFormSave({
    required this.formId,
    required this.customerId,
    required this.headerForm,
  });
}

class DynamicFormRefresh extends DynamicFormEvent {
  final String formId;
  final String? customerId;
  final HeaderForm headerForm;

  DynamicFormRefresh({
    required this.formId,
    required this.customerId,
    required this.headerForm,
  });
}
