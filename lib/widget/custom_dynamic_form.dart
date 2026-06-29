// ignore_for_file: deprecated_member_use


import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_detail_list.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_field.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_location_field.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

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
  // PERBAIKAN: Jarak diperkecil agar tidak terlalu renggang namun tetap modern
  static const double gapSection = 16;
  static const double gapFields = 12;

  bool get isGlass {
    try {
      return (Preferences.getInstance()
                  .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
              1) ==
          2;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: components.length,
      separatorBuilder: (context, index) => const SizedBox(height: gapSection),
      itemBuilder: (BuildContext context, int sectionIndex) {
        dynamic component = components.elementAt(sectionIndex);

        if (component is DetailForm) {
          DetailForm detailForm = component;

          if (detailForm.single) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.size15,
                    Dimensions.size10,
                    Dimensions.size15,
                    Dimensions.size10, // PERBAIKAN: Mengurangi jarak antara header dan card di bawahnya
                  ),
                  child: header(title: detailForm.template.title),
                ),
                CustomDynamicForm(
                  key: ValueKey("DetailForm-${widget.headerForm.template.id}"),
                  readOnly: widget.readOnly,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                  template: detailForm.template,
                  data: detailForm.getData(widget.headerForm),
                ),
              ],
            );
          } else {
            return CustomDynamicFormDetailList(
              key: ValueKey("DetailList-${detailForm.template.id}"),
              readOnly: widget.readOnly,
              customerId: widget.customerId,
              headerForm: widget.headerForm,
              detailForm: detailForm,
              onRefresh: () {
                if (mounted) {
                  context.read<DynamicFormBloc>().add(
                    DynamicFormRefresh(
                      formId: widget.headerForm.template.id,
                      customerId: widget.customerId,
                      headerForm: widget.headerForm,
                    ),
                  );
                }
              },
            );
          }
        } else {
          Section section = component as Section;

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

          return sectionCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget(section.title),
                if (loc is! SizedBox) ...[
                  loc,
                  const SizedBox(height: gapFields),
                ],
                ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: gapFields),
                  itemBuilder: (context, index) {
                    Field field = fields[index];

                    return fieldTile(
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
        }
      },
    );
  }

  Widget header({required String title}) {
    final bool glass = isGlass;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: Dimensions.size30,
          height: Dimensions.size30,
          decoration: BoxDecoration(
            color: primary.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.10,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: primary.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.28
                    : 0.18,
              ),
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
            title.toUpperCase(),
            style: TextStyle(
              color: glass
                  ? Colors.white.withOpacity(0.92)
                  : AppColors.onSurface(),
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  List<dynamic> get components {
    List<dynamic> result = List<dynamic>.from(widget.template.sections);

    if (widget.template == widget.headerForm.template) {
      for (DetailForm detailForm in widget.headerForm.detailForms) {
        if (detailForm.sectionIndex != null) {
          result.insert(detailForm.sectionIndex!, detailForm);
        } else {
          result.add(detailForm);
        }
      }
    }

    return result;
  }

  Color soft(BuildContext context) {
    if (isGlass) {
      return Colors.white.withOpacity(0.10);
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceContainerLow()
        : AppColors.surfaceContainerLowest();
  }

  Widget sectionCard({
    required BuildContext context,
    required Widget child,
  }) {
    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.all(Dimensions.size15), // PERBAIKAN: Padding dikembalikan ke proporsi yg pas
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.size15), // PERBAIKAN: Padding dikembalikan ke proporsi yg pas
      decoration: BoxDecoration(
        color: soft(context),
        borderRadius: BorderRadius.circular(Dimensions.size20),
        border: Border.all(
          color: isGlass
              ? Colors.white.withOpacity(0.18)
              : AppColors.outline().withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.30
                      : 0.14,
                ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.06,
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget fieldTile({
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
        padding: EdgeInsets.only(bottom: Dimensions.size10), // PERBAIKAN: Jarak ke konten diturunkan agar lebih padat
        child: Row(
          children: [
            Container(
              width: Dimensions.size30,
              height: Dimensions.size30,
              decoration: BoxDecoration(
                color: primary.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.14
                      : 0.10,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.28
                        : 0.18,
                  ),
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
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
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
      return CustomDynamicFormLocationField(
        readOnly: widget.readOnly,
        customerId: widget.customerId,
        headerForm: widget.headerForm,
        template: widget.template,
        data: widget.data,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  bool get wantKeepAlive => true;
}