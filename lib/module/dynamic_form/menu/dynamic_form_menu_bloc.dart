// ignore_for_file: always_specify_types, require_trailing_commas, avoid_print

import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_event.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_state.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicFormMenuBloc
    extends Bloc<DynamicFormMenuEvent, DynamicFormMenuState> {
  DynamicFormMenuBloc() : super(DynamicFormMenuInitial()) {
    on<DynamicFormMenuLoad>((event, emit) async {
      try {
        emit(DynamicFormMenuLoadLoading());

        DynamicFormMenuResponse? dynamicFormMenuResponse;

        if (DynamicForms.offline) {
          List<HeaderForm> headerForms = Offlines.headerForms(
              StringUtils.isNotNullOrEmpty(event.customerId));

          dynamicFormMenuResponse = DynamicFormMenuResponse(categories: []);

          for (HeaderForm headerForm in headerForms) {
            DynamicFormCategoryItem? dynamicFormCategoryItem =
                dynamicFormMenuResponse.categories.firstWhereOrNull((element) =>
                    StringUtils.equalsIgnoreCase(
                        element.id, headerForm.category.id));

            if (dynamicFormCategoryItem == null) {
              dynamicFormCategoryItem = DynamicFormCategoryItem(
                id: headerForm.category.id,
                name: headerForm.category.name,
                index: headerForm.category.index,
                menus: [],
              );

              dynamicFormMenuResponse.categories.add(dynamicFormCategoryItem);
            }

            dynamicFormCategoryItem.menus.add(
              DynamicFormMenuItem(
                id: headerForm.category.menu.id,
                name: headerForm.category.menu.name,
                index: headerForm.category.menu.index,
                type: headerForm.category.menu.type,
                icon: headerForm.category.menu.icon,
                referenceId: null,
                referenceName: null,
              ),
            );
          }
        } else {
          dynamicFormMenuResponse = await DotApis.getInstance()
              .dynamicFormMenu(customerId: event.customerId);
        }

        if (dynamicFormMenuResponse != null) {
          emit(DynamicFormMenuLoadSuccess(
              dynamicFormMenuResponse: dynamicFormMenuResponse));
        }
      } catch (e) {
        print(e);
      } finally {
        emit(DynamicFormMenuLoadFinished());
      }
    });
  }
}
