// ignore_for_file: always_specify_types, use_build_context_synchronously, empty_catches, cascade_invocations, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_sub_detail_list.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";

class CustomDynamicFormDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final Map<String, dynamic> data;

  const CustomDynamicFormDetailForm({
    super.key,
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.data,
  });

  @override
  State<CustomDynamicFormDetailForm> createState() => CustomDynamicFormDetailFormState();
}

class CustomDynamicFormDetailFormState extends State<CustomDynamicFormDetailForm> with WidgetsBindingObserver {
  GlobalKey<FormState> formState = GlobalKey<FormState>();

  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      context: context,
      appBar: BaseAppBar(
        context: context,
        name: widget.detailForm.template.title,
      ),
      contentBuilder: body,
      bottomNavigationBar: bottomBar(),
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

  Widget body() {
    return Form(
      key: formState,
      child: SingleChildScrollView(
        child: Column(
          children: [
            CustomDynamicForm(
              key: ValueKey("Detail-${widget.detailForm.template.id}"),
              readOnly: widget.readOnly,
              customerId: widget.customerId,
              headerForm: widget.headerForm,
              template: widget.detailForm.template,
              data: data,
            ),
            ...widget.detailForm.subDetailForms.map((subDetailForm) {
              return CustomDynamicFormSubDetailList(
                key: ValueKey("SubDetailList-${subDetailForm.template.id}"),
                readOnly: widget.readOnly,
                customerId: widget.customerId,
                headerForm: widget.headerForm,
                detailForm: widget.detailForm,
                subDetailForm: subDetailForm,
                detailData: data,
                onRefresh: () {
                  context.read<DynamicFormBloc>().add(
                    DynamicFormRefresh(
                      formId: widget.headerForm.template.id,
                      customerId: widget.customerId,
                      headerForm: widget.headerForm,
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
    if (!widget.readOnly) {
      return BaseBottomBar(
        children: [
          FilledButton.icon(
            onPressed: () async {
              save();
            },
            icon: const Icon(Icons.save),
            label: Text("save".tr()),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void save() async {
    if (formState.currentState != null) {
      if (formState.currentState!.validate()) {
        formState.currentState!.save();

        BaseDialogs.confirmation(
          title: "are_you_sure_want_to_proceed".tr(),
          positiveCallback: () {
            context.pop(data);
          },
        );
      }
    }
  }
}
