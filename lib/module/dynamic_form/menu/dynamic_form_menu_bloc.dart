// ignore_for_file: always_specify_types, require_trailing_commas, avoid_print

import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_event.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_state.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicFormMenuBloc extends Bloc<DynamicFormMenuEvent, DynamicFormMenuState> {
  DynamicFormMenuBloc() : super(DynamicFormMenuInitial()) {
    on<DynamicFormMenuLoad>((event, emit) async {
      try {
        emit(DynamicFormMenuLoadLoading());

        DynamicFormMenuResponse? dynamicFormMenuResponse;

        if (DynamicForms.offline) {
          dynamicFormMenuResponse = await Offlines.menus(StringUtils.isNotNullOrEmpty(event.customerId));
        } else {
          dynamicFormMenuResponse = await DotApis.getInstance().dynamicFormMenu(customerId: event.customerId);
        }

        if (dynamicFormMenuResponse != null) {
          emit(DynamicFormMenuLoadSuccess(dynamicFormMenuResponse: dynamicFormMenuResponse));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }
      } finally {
        emit(DynamicFormMenuLoadFinished());
      }
    });
  }
}
