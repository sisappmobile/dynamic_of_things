import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_field.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_location_field.dart";
import "package:flutter/material.dart";

class CustomDynamicForm extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final Template template;
  final Map<String, dynamic> data;

  const CustomDynamicForm({
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.template,
    required this.data,
    super.key,
  });

  @override
  State<CustomDynamicForm> createState() => CustomDynamicFormState();
}

class CustomDynamicFormState extends State<CustomDynamicForm>
    with AutomaticKeepAliveClientMixin {
  static const double _gapSection = 14;
  static const double _gapFields = 12;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.template.sections.length,
      separatorBuilder: (context, index) => SizedBox(height: _gapSection),
      itemBuilder: (BuildContext context, int sectionIndex) {
        Section section = widget.template.sections[sectionIndex];

        List<Field> fields = section.fields
            .where(
              (element) =>
                  !element.hidden &&
                  !StringUtils.inList(
                    element.name,
                    ["latitude", "longitude", "longtitude"],
                  ),
            )
            .toList();

        final Widget loc = locationWidget();

        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget(section.title),
              if (loc is! SizedBox) ...[
                loc,
                SizedBox(height: _gapFields),
              ],
              ListView.separated(
                separatorBuilder: (context, index) =>
                    SizedBox(height: _gapFields),
                itemBuilder: (context, index) {
                  Field field = fields[index];

                  return _fieldTile(
                    context: context,
                    child: CustomDynamicFormField(
                      readOnly: widget.readOnly,
                      customerId: widget.customerId,
                      headerForm: widget.headerForm,
                      template: widget.template,
                      field: field,
                      data: widget.data,
                    ),
                  );
                },
                itemCount: fields.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Color _soft(BuildContext context) {
    return _isDark
        ? AppColors.surfaceContainerLow()
        : AppColors.surfaceContainerLowest();
  }

  Color _soft2(BuildContext context) {
    return _isDark
        ? AppColors.surfaceContainer()
        : AppColors.surfaceContainerLow();
  }

  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  Widget _sectionCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.size15),
      decoration: BoxDecoration(
        color: _soft(context),
        borderRadius: BorderRadius.circular(Dimensions.size20),
        border: Border.all(
          color: _outline(context).withValues(alpha: _isDark ? 0.30 : 0.14),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: _isDark ? 0.22 : 0.06),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fieldTile({
    required BuildContext context,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.zero,
      child: child,
    );
  }

  Widget titleWidget(String? title) {
    if (StringUtils.isNotNullOrEmpty(title)) {
      final Color primary = Theme.of(context).colorScheme.primary;

      return Padding(
        padding: EdgeInsets.only(bottom: Dimensions.size10),
        child: Row(
          children: [
            Container(
              width: Dimensions.size30,
              height: Dimensions.size30,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: _isDark ? 0.14 : 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha: _isDark ? 0.28 : 0.18),
                ),
              ),
              child: Icon(
                Icons.segment_rounded,
                color: primary,
                size: Dimensions.size20,
              ),
            ),
            SizedBox(width: Dimensions.size10),
            Expanded(
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  color: _fg(context),
                  fontSize: Dimensions.text14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget locationWidget() {
    bool hasLocationField = false;

    for (Section section in widget.template.sections) {
      bool hasLatitudeField = false;
      bool hasLongitudeField = false;

      for (Field field in section.fields) {
        if (field.name == "latitude") {
          hasLatitudeField = true;
        } else if (StringUtils.inList(
          field.name,
          ["longitude", "longtitude"],
        )) {
          hasLongitudeField = true;
        }
      }

      hasLocationField = hasLatitudeField && hasLongitudeField;

      if (hasLocationField) {
        break;
      }
    }

    if (hasLocationField) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(Dimensions.size10),
        decoration: BoxDecoration(
          color: _soft2(context),
          borderRadius: BorderRadius.circular(Dimensions.size15),
          border: Border.all(
            color: _outline(context).withValues(alpha: _isDark ? 0.28 : 0.14),
          ),
        ),
        child: CustomDynamicFormLocationField(
          readOnly: widget.readOnly,
          customerId: widget.customerId,
          headerForm: widget.headerForm,
          template: widget.template,
          data: widget.data,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  bool get wantKeepAlive => true;
}
