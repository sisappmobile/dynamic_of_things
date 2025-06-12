
// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, empty_catches, use_build_context_synchronously

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_state.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_detail_list.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:loader_overlay/loader_overlay.dart";

class DynamicFormPage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final bool readOnly;
  final String? dataId;
  final String? customerId;
  final HeaderForm? headerForm;

  const DynamicFormPage({
    required this.dynamicFormMenuItem,
    this.readOnly = false,
    this.dataId,
    required this.customerId,
    this.headerForm,
    super.key,
  });

  @override
  DynamicFormPageState createState() => DynamicFormPageState();
}

class DynamicFormPageState extends State<DynamicFormPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  HeaderForm? headerForm;

  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (widget.headerForm != null) {
      headerForm = widget.headerForm;

      WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
        await DynamicForms.decode(headerForm: headerForm!);

        loading = false;

        setState(() {});
      });
    } else {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicFormBloc, DynamicFormState>(
      listener: (context, state) async {
        if (state is DynamicFormCreateLoading) {
          loading = true;
          headerForm = null;

          setState(() {});
        } else if (state is DynamicFormCreateSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormCreateFinished) {

        } else if (state is DynamicFormViewLoading) {
          loading = true;
          headerForm = null;

          setState(() {});
        } else if (state is DynamicFormViewSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormViewFinished) {

        } else if (state is DynamicFormEditLoading) {
          setState(() {
            loading = true;
            headerForm = null;
          });
        } else if (state is DynamicFormEditSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormEditFinished) {

        } else if (state is DynamicFormSaveLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicFormSaveSuccess) {
          await BaseOverlays.success(message: "data_has_been_successfully_saved".tr());

          context.pop();
        } else if (state is DynamicFormSaveFinished) {
          context.loaderOverlay.hide();
        } else if (state is DynamicFormRefreshLoading) {
          loading = true;
          headerForm = null;

          setState(() {});
        } else if (state is DynamicFormRefreshSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormRefreshFinished) {

        }
      },
      child: BaseScaffold(
        statusBuilder: () {
          if (loading) {
            return BaseBodyStatus.loading;
          } else {
            if (headerForm != null) {
              return BaseBodyStatus.loaded;
            } else {
              return BaseBodyStatus.fail;
            }
          }
        },
        appBar: BaseAppBar(
          context: context,
          name: headerForm?.template.title ?? "",
          description: label(),
        ),
        contentBuilder: body,
        bottomNavigationBar: bottomBar(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  void refresh() {
    if (widget.headerForm == null) {
      if (widget.dataId != null) {
        if (widget.readOnly) {
          context.read<DynamicFormBloc>().add(
            DynamicFormView(
              formId: widget.dynamicFormMenuItem.id,
              dataId: widget.dataId!,
              customerId: widget.customerId,
            ),
          );
        } else {
          context.read<DynamicFormBloc>().add(
            DynamicFormEdit(
              formId: widget.dynamicFormMenuItem.id,
              dataId: widget.dataId!,
              customerId: widget.customerId,
            ),
          );
        }
      } else {
        context.read<DynamicFormBloc>().add(
          DynamicFormCreate(
            formId: widget.dynamicFormMenuItem.id,
            customerId: widget.customerId,
          ),
        );
      }
    }
  }

  String label() {
    if (StringUtils.isNotNullOrEmpty(widget.dataId) || widget.headerForm != null) {
      if (widget.readOnly) {
        return "view".tr();
      } else {
        return "edit".tr();
      }
    } else {
      return "add".tr();
    }
  }

  Widget body() {
    return Form(
      key: globalKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            CustomDynamicForm(
              readOnly: widget.readOnly,
              customerId: widget.customerId,
              headerForm: headerForm!,
              template: headerForm!.template,
              data: headerForm!.data,
            ),
            ...headerForm!.detailForms.map((detailForm) {
              return CustomDynamicFormDetailList(
                readOnly: widget.readOnly,
                customerId: widget.customerId,
                headerForm: headerForm!,
                detailForm: detailForm,
                onRefresh: () {
                  context.read<DynamicFormBloc>().add(
                    DynamicFormRefresh(
                      formId: headerForm!.template.id,
                      customerId: widget.customerId,
                      headerForm: headerForm!,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget bottomBar() {
    if (headerForm != null && !widget.readOnly) {
      return BaseBottomBar(
        children: [
          FilledButton.icon(
            onPressed: () async {
              if (globalKey.currentState != null) {
                if (globalKey.currentState!.validate()) {
                  BaseDialogs.confirmation(
                    title: "are_you_sure_want_to_proceed".tr(),
                    positiveCallback: () {
                      globalKey.currentState!.save();

                      context.read<DynamicFormBloc>().add(
                        DynamicFormSave(
                          formId: widget.dynamicFormMenuItem.id,
                          customerId: widget.customerId,
                          headerForm: headerForm!,
                        ),
                      );
                    },
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: Text("save".tr()),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
