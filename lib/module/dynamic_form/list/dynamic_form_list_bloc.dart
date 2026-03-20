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
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicFormListBloc extends Bloc<DynamicFormListEvent, DynamicFormListState> {
  DynamicFormListBloc() : super(DynamicFormListInitial()) {
    on<DynamicFormListLoad>((event, emit) async {
      try {
        emit(DynamicFormListLoadLoading());

        ListResponse? listResponse;

        if (DynamicForms.offline) {
          listResponse = await Offlines.list(
            id: event.id,
            customerId: event.customerId,
          );
        } else {
          listResponse = await DotApis.getInstance().dynamicFormList(
            id: event.id,
            customerId: event.customerId,
          );
        }

        if (listResponse != null) {
          emit(DynamicFormListLoadSuccess(listResponse: listResponse));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormListLoadFinished());
      }
    });

    on<DynamicFormListCustomAction>((event, emit) async {
      try {
        emit(DynamicFormListCustomActionLoading());

        if (DynamicForms.offline) {
          HeaderForm? headerForm = await Offlines.dynamicFormCustomAction(
            actionId: event.actionId,
            formId: event.formId,
            dataId: event.dataId,
            customerId: event.customerId,
          );

          emit(DynamicFormListCustomActionSuccess(headerForm: headerForm));
        } else {
          Response response = await DotApis.getInstance().dynamicFormCustomAction(
            actionId: event.actionId,
            formId: event.formId,
            dataId: event.dataId,
            customerId: event.customerId,
          );

          if (response.statusCode == 204) {
            emit(DynamicFormListCustomActionSuccess(headerForm: null));
          } else if (response.statusCode == 200) {
            HeaderForm headerForm = HeaderForm.fromJson(response.data)..dataId = event.dataId;

            emit(DynamicFormListCustomActionSuccess(headerForm: headerForm));
          }
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormListCustomActionFinished());
      }
    });
  }
}
