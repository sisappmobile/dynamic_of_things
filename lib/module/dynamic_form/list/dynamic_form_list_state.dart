import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/header_form.dart";

abstract class DynamicFormListState {}

class DynamicFormListInitial extends DynamicFormListState {}

class DynamicFormListLoadLoading extends DynamicFormListState {}

class DynamicFormListLoadSuccess extends DynamicFormListState {
  final ListResponse listResponse;

  DynamicFormListLoadSuccess({
    required this.listResponse,
  });
}

class DynamicFormListLoadFinished extends DynamicFormListState {}

class DynamicFormListCustomActionLoading extends DynamicFormListState {}

class DynamicFormListCustomActionSuccess extends DynamicFormListState {
  final HeaderForm? headerForm;

  DynamicFormListCustomActionSuccess({
    required this.headerForm,
  });
}

class DynamicFormListCustomActionFinished extends DynamicFormListState {}
