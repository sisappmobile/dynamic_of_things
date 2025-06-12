// ignore_for_file: always_specify_types, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_field.dart";
import "package:flutter/material.dart";

class CustomDynamicForm extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final Template template;
  final Map<String, dynamic> data;

  const CustomDynamicForm({
    super.key,
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.template,
    required this.data,
  });

  @override
  State<CustomDynamicForm> createState() => CustomDynamicFormState();
}

class CustomDynamicFormState extends State<CustomDynamicForm> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(Dimensions.size15),
      itemCount: widget.template.sections.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: Dimensions.size30);
      },
      itemBuilder: (BuildContext context, int sectionIndex) {
        Section section = widget.template.sections[sectionIndex];

        List<Field> fields = section.fields.where((element) => !element.hidden).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget(section.title),
            ListView.separated(
              separatorBuilder: (context, index) => SizedBox(height: Dimensions.size15),
              itemBuilder: (context, index) {
                Field field = fields[index];

                return CustomDynamicFormField(
                  readOnly: widget.readOnly,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                  template: widget.template,
                  field: field,
                  data: widget.data,
                );
              },
              itemCount: fields.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
            ),
          ],
        );
      },
    );
  }

  Widget titleWidget(String? title) {
    if (StringUtils.isNotNullOrEmpty(title)) {
      return Container(
        margin: EdgeInsets.only(bottom: Dimensions.size15),
        child: Text(
          title!.toUpperCase(),
          style: TextStyle(
            color: AppColors.primary(),
            fontSize: Dimensions.text18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  bool get wantKeepAlive => true;
}