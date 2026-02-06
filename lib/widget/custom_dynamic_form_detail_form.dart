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
import "package:smooth_corner/smooth_corner.dart";

class CustomDynamicFormDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final Map<String, dynamic> data;

  const CustomDynamicFormDetailForm({
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.data,
    super.key,
  });

  @override
  State<CustomDynamicFormDetailForm> createState() =>
      CustomDynamicFormDetailFormState();
}

class CustomDynamicFormDetailFormState
    extends State<CustomDynamicFormDetailForm> with WidgetsBindingObserver {
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
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: safe.top),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  Dimensions.size10,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                child: _topBar(),
              ),
              Expanded(child: body()),
              SizedBox(height: safe.bottom),
            ],
          ),
          Positioned(
            right: Dimensions.size15,
            bottom: safe.bottom + Dimensions.size5,
            child: bottomBar(),
          ),
        ],
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

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();
  Color _primary(BuildContext context) => Theme.of(context).colorScheme.primary;

  Widget _topBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _card(context),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          _iconPill(
            icon: Icons.turn_left_rounded,
            onTap: () {
              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                Navigators.pop();
              } else {
                context.pop();
              }
            },
          ),
          SizedBox(width: Dimensions.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detail",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w800,
                    color: _fg(context).withValues(alpha: 0.60),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: Dimensions.size2),
                Text(
                  widget.detailForm.template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: _fg(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.size10,
              vertical: Dimensions.size5,
            ),
            decoration: BoxDecoration(
              color: _soft(context),
              borderRadius: BorderRadius.circular(Dimensions.size100),
              border: Border.all(
                color: _outline(context).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.readOnly
                      ? Icons.visibility_rounded
                      : Icons.edit_rounded,
                  size: Dimensions.size15,
                  color: _primary(context),
                ),
                SizedBox(width: Dimensions.size5),
                Text(
                  widget.readOnly ? "View" : "Edit",
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w900,
                    color: _fg(context),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: _soft(context),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: _outline(context).withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Icon(
            icon,
            color: _fg(context),
            size: Dimensions.size25,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(Dimensions.size15),
      decoration: ShapeDecoration(
        color: _card(context),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.18),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget body() {
    return Container(
      color: _bg(context),
      child: Form(
        key: formState,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            0,
            Dimensions.size15,
            Dimensions.size15 + (widget.readOnly ? 0 : Dimensions.size75),
          ),
          child: Column(
            children: [
              _sectionCard(
                context: context,
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size10,
                  Dimensions.size10,
                  Dimensions.size10,
                  Dimensions.size10,
                ),
                child: CustomDynamicForm(
                  key: ValueKey("Detail-${widget.detailForm.template.id}"),
                  readOnly: widget.readOnly,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                  template: widget.detailForm.template,
                  data: data,
                ),
              ),
              ...widget.detailForm.subDetailForms.asMap().entries.map((entry) {
                final int i = entry.key;
                final subDetailForm = entry.value;

                return Padding(
                  padding: EdgeInsets.only(top: Dimensions.size10),
                  child: _sectionCard(
                    context: context,
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.size10,
                      Dimensions.size10,
                      Dimensions.size10,
                      Dimensions.size10,
                    ),
                    child: CustomDynamicFormSubDetailList(
                      key: ValueKey(
                        "SubDetailList-${subDetailForm.template.id}-$i",
                      ),
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
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomBar() {
    if (!widget.readOnly) {
      return _primarySaveButton();
    }
    return const SizedBox.shrink();
  }

  Widget _primarySaveButton() {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          save();
        },
        borderRadius: BorderRadius.circular(Dimensions.size30),
        child: Ink(
          height: Dimensions.size55,
          padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
          decoration: ShapeDecoration(
            color: primary,
            shadows: [
              BoxShadow(
                blurRadius: Dimensions.size20,
                offset: Offset(0, Dimensions.size10),
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ],
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size30),
              smoothness: Dimensions.size1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Dimensions.size35,
                height: Dimensions.size35,
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.save_rounded,
                  size: Dimensions.size20,
                  color: onPrimary,
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Text(
                "save".tr(),
                style: TextStyle(
                  color: onPrimary,
                  fontSize: Dimensions.text14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: Dimensions.size2),
            ],
          ),
        ),
      ),
    );
  }

  void save() async {
    if (formState.currentState != null) {
      if (formState.currentState!.validate()) {
        formState.currentState!.save();

        BaseDialogs.confirmation(
          title: "are_you_sure_want_to_proceed".tr(),
          positiveCallback: () {
            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              Navigators.pop(result: data);
            } else {
              context.pop(data);
            }
          },
        );
      }
    }
  }
}
