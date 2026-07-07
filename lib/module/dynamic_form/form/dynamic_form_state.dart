import "package:dynamic_of_things/model/header_form.dart";

abstract class DynamicFormState {}

class DynamicFormInitial extends DynamicFormState {}

class DynamicFormCreateLoading extends DynamicFormState {}

class DynamicFormCreateSuccess extends DynamicFormState {
  final HeaderForm headerForm;

  DynamicFormCreateSuccess({
    required this.headerForm,
  });
}

class DynamicFormCreateFinished extends DynamicFormState {}

class DynamicFormViewLoading extends DynamicFormState {}

class DynamicFormViewSuccess extends DynamicFormState {
  final HeaderForm headerForm;

  DynamicFormViewSuccess({
    required this.headerForm,
  });
}

class DynamicFormViewFinished extends DynamicFormState {}

class DynamicFormEditLoading extends DynamicFormState {}

class DynamicFormEditSuccess extends DynamicFormState {
  final HeaderForm headerForm;

  DynamicFormEditSuccess({
    required this.headerForm,
  });
}

class DynamicFormEditFinished extends DynamicFormState {}

class DynamicFormSaveLoading extends DynamicFormState {}

class DynamicFormSaveSuccess extends DynamicFormState {}

class DynamicFormSaveFinished extends DynamicFormState {}

class DynamicFormRefreshLoading extends DynamicFormState {}

class DynamicFormRefreshSuccess extends DynamicFormState {
  final HeaderForm headerForm;

  DynamicFormRefreshSuccess({
    required this.headerForm,
  });
}

class DynamicFormRefreshFinished extends DynamicFormState {}
