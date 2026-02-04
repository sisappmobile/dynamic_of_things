// ignore_for_file: always_specify_types, require_trailing_commas

import "package:base/base.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/header_form.dart" hide Action, Field;
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_event.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicFormListBloc extends Bloc<DynamicFormListEvent, DynamicFormListState> {
  DynamicFormListBloc() : super(DynamicFormListInitial()) {
    on<DynamicFormListLoad>((event, emit) async {
      try {
        emit(DynamicFormListLoadLoading());

        ListResponse? listResponse;

        if (DynamicForms.offline) {
          HeaderForm? headerForm = Offlines.headerForm(event.id);

          if (headerForm != null) {
            listResponse = ListResponse(
              createUsingScanQr: false,
              actions: headerForm.template.actions.map((element) {
                return Action(
                  id: element.id,
                  resourceId: element.resourceId,
                  name: element.name,
                );
              }).toList(),
              fields: headerForm.template.columns.map((element) {
                return Field(
                    name: element.name,
                    type: element.type,
                    description: element.description,
                    primaryKey: element.primaryKey
                );
              }).toList(),
              data: await Offlines.list(
                tableName: headerForm.template.tableName,
                customerId: event.customerId,
              ),
            );
          }
        } else {
          listResponse = await DotApis.getInstance().dynamicFormList(
            id: event.id,
            customerId: event.customerId,
          );
        }

        if (listResponse != null) {
          emit(DynamicFormListLoadSuccess(listResponse: listResponse));
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormListLoadFinished());
      }
    });

    on<DynamicFormListCustomAction>((event, emit) async {
      try {
        emit(DynamicFormListCustomActionLoading());

        Response response = await DotApis.getInstance().dynamicFormCustomAction(
          actionId: event.actionId,
          formId: event.formId,
          dataId: event.dataId,
          customerId: event.customerId,
        );

        if (response.statusCode == 204) {
          emit(DynamicFormListCustomActionSuccess(headerForm: null));
        } else if (response.statusCode == 200) {
          HeaderForm headerForm = HeaderForm.fromJson(response.data)
            ..dataId = event.dataId;

          emit(DynamicFormListCustomActionSuccess(headerForm: headerForm));
        }
      } catch (e) {
        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormListCustomActionFinished());
      }
    });
  }
}
