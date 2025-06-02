// ignore_for_file: always_specify_types, use_build_context_synchronously, empty_catches, cascade_invocations, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";

class CustomDynamicFormDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final Template template;
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic> data) onSaved;

  const CustomDynamicFormDetailForm({
    super.key,
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.template,
    required this.data,
    required this.onSaved,
  });

  @override
  State<CustomDynamicFormDetailForm> createState() => CustomDynamicFormDetailFormState();
}

class CustomDynamicFormDetailFormState extends State<CustomDynamicFormDetailForm> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.template.title,
        ),
      ),
      body: Form(
        key: formState,
        child: CustomDynamicForm(
          readOnly: widget.readOnly,
          customerId: widget.customerId,
          headerForm: widget.headerForm,
          template: widget.template,
          data: widget.data,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: floatingActionButton(),
    );
  }

  Widget floatingActionButton() {
    if (!widget.readOnly) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.tertiaryContainer(),
        foregroundColor: AppColors.onTertiaryContainer(),
        onPressed: () async {
          save();
        },
        icon: const Icon(
          Icons.save,
        ),
        label: Text(
          "save".tr().toUpperCase(),
        ),
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
            widget.onSaved(widget.data);

            Navigators.pop();
          },
        );
      }
    }
  }
}
