// ignore_for_file: always_specify_types, use_build_context_synchronously, empty_catches, cascade_invocations, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class CustomDynamicFormSubDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final SubDetailForm subDetailForm;
  final Map<String, dynamic> data;

  const CustomDynamicFormSubDetailForm({
    super.key,
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.subDetailForm,
    required this.data,
  });

  @override
  State<CustomDynamicFormSubDetailForm> createState() => CustomDynamicFormSubDetailFormState();
}

class CustomDynamicFormSubDetailFormState extends State<CustomDynamicFormSubDetailForm> with WidgetsBindingObserver {
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
        name: widget.subDetailForm.template.title,
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
              key: ValueKey("SubDetail-${widget.subDetailForm.template.id}"),
              readOnly: widget.readOnly,
              customerId: widget.customerId,
              headerForm: widget.headerForm,
              template: widget.subDetailForm.template,
              data: data,
            ),
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
