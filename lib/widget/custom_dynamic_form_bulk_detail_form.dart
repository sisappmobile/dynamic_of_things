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

class CustomDynamicFormBulkDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final List<Map<String, dynamic>> rows;

  const CustomDynamicFormBulkDetailForm({
    super.key,
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.rows,
  });

  @override
  State<CustomDynamicFormBulkDetailForm> createState() => CustomDynamicFormBulkDetailFormState();
}

class CustomDynamicFormBulkDetailFormState extends State<CustomDynamicFormBulkDetailForm> with WidgetsBindingObserver {
  GlobalKey<FormState> formState = GlobalKey<FormState>();

  late List<Map<String, dynamic>> rows;

  int index = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    rows = widget.rows;
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
              data: rows[index],
            ),
            ...widget.detailForm.subDetailForms.map((subDetailForm) {
              return CustomDynamicFormSubDetailList(
                key: ValueKey("SubDetailList-${subDetailForm.template.id}"),
                readOnly: widget.readOnly,
                customerId: widget.customerId,
                headerForm: widget.headerForm,
                detailForm: widget.detailForm,
                subDetailForm: subDetailForm,
                detailData: rows[index],
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
    Widget previousButton() {
      if (index > 0) {
        return IconButton.filledTonal(
          onPressed: () {
            if (valid()) {
              setState(() {
                index--;
              });
            }
          },
          icon: Icon(Icons.arrow_back),
        );
      }

      return const SizedBox.shrink();
    }

    Widget labelWidget() {
      return RichText(
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: (index + 1).toString(),
              style: TextStyle(
                color: AppColors.onSurface(),
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: " ${"of".tr().toLowerCase()} ${rows.length}",
              style: TextStyle(
                color: AppColors.secondary(),
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    Widget nextButton() {
      if (index < rows.length - 1) {
        return IconButton.filledTonal(
          onPressed: () {
            if (valid()) {
              setState(() {
                index++;
              });
            }
          },
          icon: Icon(Icons.arrow_forward),
        );
      } else {
        return FilledButton.icon(
          onPressed: () async {
            if (valid()) {
              BaseDialogs.confirmation(
                title: "are_you_sure_want_to_proceed".tr(),
                positiveCallback: () {
                  if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                    Navigators.pop(result: rows);
                  } else {
                    context.pop(rows);
                  }
                },
              );
            }
          },
          icon: const Icon(Icons.save),
          label: Text("save".tr()),
        );
      }
    }

    if (!widget.readOnly) {
      return BaseBottomBar(
        children: [
          previousButton(),
          Expanded(child: labelWidget()),
          nextButton(),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  bool valid() {
    return formState.currentState != null && formState.currentState!.validate();
  }
}
