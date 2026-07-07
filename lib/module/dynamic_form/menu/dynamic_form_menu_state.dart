import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";

abstract class DynamicFormMenuState {}

class DynamicFormMenuInitial extends DynamicFormMenuState {}

class DynamicFormMenuLoadLoading extends DynamicFormMenuState {}

class DynamicFormMenuLoadSuccess extends DynamicFormMenuState {
  final DynamicFormMenuResponse dynamicFormMenuResponse;

  DynamicFormMenuLoadSuccess({
    required this.dynamicFormMenuResponse,
  });
}

class DynamicFormMenuLoadFinished extends DynamicFormMenuState {}
