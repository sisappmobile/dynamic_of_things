// ignore_for_file: always_specify_types, require_trailing_commas, cascade_invocations, avoid_print

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  DynamicFormBloc() : super(DynamicFormInitial()) {
    on<DynamicFormCreate>((event, emit) async {
      try {
        emit(DynamicFormCreateLoading());

        HeaderForm? headerForm;

        if (DynamicForms.offline) {
          headerForm = await Offlines.create(
            formId: event.formId,
            customerId: event.customerId,
            extra: event.extra,
            referenceId: event.referenceId,
          );
        } else {
          headerForm = await DotApis.getInstance().dynamicFormCreate(
            formId: event.formId,
            customerId: event.customerId,
            extra: event.extra,
            referenceId: event.referenceId,
          );
        }

        if (headerForm != null) {
          emit(DynamicFormCreateSuccess(headerForm: headerForm));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormCreateFinished());
      }
    });

    on<DynamicFormView>((event, emit) async {
      try {
        emit(DynamicFormViewLoading());

        HeaderForm? headerForm;

        if (DynamicForms.offline) {
          headerForm = await Offlines.view(
            formId: event.formId,
            dataId: event.dataId,
          );
        } else {
          headerForm = await DotApis.getInstance().dynamicFormView(
            formId: event.formId,
            dataId: event.dataId,
            customerId: event.customerId,
          );
        }

        if (headerForm != null) {
          headerForm.dataId = event.dataId;

          emit(DynamicFormViewSuccess(headerForm: headerForm));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormViewFinished());
      }
    });

    on<DynamicFormEdit>((event, emit) async {
      try {
        emit(DynamicFormEditLoading());

        HeaderForm? headerForm;

        if (DynamicForms.offline) {
          headerForm = await Offlines.edit(
            formId: event.formId,
            dataId: event.dataId,
          );
        } else {
          headerForm = await DotApis.getInstance().dynamicFormEdit(
            formId: event.formId,
            dataId: event.dataId,
            customerId: event.customerId,
          );
        }

        if (headerForm != null) {
          headerForm.dataId = event.dataId;

          emit(DynamicFormEditSuccess(headerForm: headerForm));
        }
      } catch (e) {
        print(e);

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormEditFinished());
      }
    });

    on<DynamicFormSave>((event, emit) async {
      try {
        emit(DynamicFormSaveLoading());

        Map<String, dynamic> output = await DynamicForms.encode(event.headerForm);

        if (DynamicForms.offline) {
          await Offlines.dynamicFormSave(
            formId: event.formId,
            data: output,
            customerId: event.customerId,
          );
        } else {
          if (StringUtils.isNotNullOrEmpty(event.headerForm.dataId)) {
            await DotApis.getInstance().dynamicFormUpdate(
              dataId: event.headerForm.dataId!,
              formId: event.formId,
              data: output,
              customerId: event.customerId,
            );
          } else {
            await DotApis.getInstance().dynamicFormInsert(
              formId: event.formId,
              data: output,
              customerId: event.customerId,
            );
          }
        }

        emit(DynamicFormSaveSuccess());
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormSaveFinished());
      }
    });

    on<DynamicFormRefresh>((event, emit) async {
      try {
        emit(DynamicFormRefreshLoading());

        Map<String, dynamic> output = await DynamicForms.encode(event.headerForm);

        HeaderForm? headerForm;

        if (DynamicForms.offline) {
          headerForm = await Offlines.dynamicFormRefresh(
            formId: event.formId,
            data: output,
            customerId: event.customerId,
          );
        } else {
          headerForm = await DotApis.getInstance().dynamicFormRefresh(
            formId: event.formId,
            data: output,
            customerId: event.customerId,
          );
        }

        if (headerForm != null) {
          headerForm.dataId = event.headerForm.dataId;

          emit(DynamicFormRefreshSuccess(headerForm: headerForm));
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("Caught Exception: $e");
          print("Stack Trace:\n$s");
        }

        BaseOverlays.error(message: "common_something_wrong".tr());
      } finally {
        emit(DynamicFormRefreshFinished());
      }
    });
  }
}
