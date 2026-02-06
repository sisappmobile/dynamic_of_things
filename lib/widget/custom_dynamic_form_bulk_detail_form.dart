import "dart:ui";

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
  State<CustomDynamicFormBulkDetailForm> createState() =>
      CustomDynamicFormBulkDetailFormState();
}

class CustomDynamicFormBulkDetailFormState
    extends State<CustomDynamicFormBulkDetailForm> with WidgetsBindingObserver {
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

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();
  Color _primary(BuildContext context) => Theme.of(context).colorScheme.primary;

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
            blurRadius: Dimensions.size25,
            offset: Offset(0, Dimensions.size15),
            color: Colors.black.withValues(alpha: 0.10),
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

  Widget _progressHeader(BuildContext context) {
    final Color fg = _fg(context);
    final Color outline = _outline(context);
    final Color primary = _primary(context);

    final int current = index + 1;
    final int total = rows.length;
    final double progress = total <= 0 ? 0 : (current / total).clamp(0.0, 1.0);

    return _sectionCard(
      context: context,
      padding: EdgeInsets.fromLTRB(
        Dimensions.size15,
        Dimensions.size15,
        Dimensions.size15,
        Dimensions.size15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size5,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(Dimensions.size100),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.layers_rounded,
                      size: Dimensions.size15,
                      color: primary,
                    ),
                    SizedBox(width: Dimensions.size5),
                    Text(
                      "$current ${"of".tr().toLowerCase()} $total",
                      style: TextStyle(
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Text(
                  widget.detailForm.template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.size100),
            child: LinearProgressIndicator(
              minHeight: Dimensions.size5,
              value: progress,
              backgroundColor: outline.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                primary.withValues(alpha: 0.90),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget body() {
    final Color bg = _bg(context);

    return Container(
      color: bg,
      child: Form(
        key: formState,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size10,
            Dimensions.size15,
            Dimensions.size15,
          ),
          child: Column(
            children: [
              _progressHeader(context),
              SizedBox(height: Dimensions.size15),
              _sectionCard(
                context: context,
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  Dimensions.size15,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                child: CustomDynamicForm(
                  key: ValueKey("Detail-${widget.detailForm.template.id}"),
                  readOnly: widget.readOnly,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                  template: widget.detailForm.template,
                  data: rows[index],
                ),
              ),
              ...widget.detailForm.subDetailForms.map((subDetailForm) {
                return Padding(
                  padding: EdgeInsets.only(top: Dimensions.size15),
                  child: _sectionCard(
                    context: context,
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.size15,
                      Dimensions.size15,
                      Dimensions.size15,
                      Dimensions.size15,
                    ),
                    child: CustomDynamicFormSubDetailList(
                      key: ValueKey(
                          "SubDetailList-${subDetailForm.template.id}"),
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
    Widget previousButton() {
      if (index > 0) {
        return _pillIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (valid()) {
              setState(() {
                index--;
              });
            }
          },
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
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: " ${"of".tr().toLowerCase()} ${rows.length}",
              style: TextStyle(
                color: AppColors.secondary(),
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    Widget nextButton() {
      if (index < rows.length - 1) {
        return _pillIconButton(
          icon: Icons.arrow_forward_rounded,
          onTap: () {
            if (valid()) {
              setState(() {
                index++;
              });
            }
          },
        );
      } else {
        return _pillPrimaryButton(
          icon: Icons.save_rounded,
          label: "save".tr(),
          onTap: () async {
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
        );
      }
    }

    if (!widget.readOnly) {
      final EdgeInsets safe = MediaQuery.of(context).padding;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size10,
            Dimensions.size15,
            Dimensions.size10 + safe.bottom,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.size25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size10,
                ),
                decoration: BoxDecoration(
                  color: _card(context).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(Dimensions.size25),
                  border: Border.all(
                    color: _outline(context).withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: Dimensions.size25,
                      offset: Offset(0, Dimensions.size15),
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    previousButton(),
                    SizedBox(width: Dimensions.size10),
                    Expanded(child: labelWidget()),
                    SizedBox(width: Dimensions.size10),
                    nextButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _pillIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: Dimensions.size45,
          height: Dimensions.size45,
          decoration: BoxDecoration(
            color: _soft(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: _outline(context).withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            color: _fg(context),
            size: Dimensions.size20,
          ),
        ),
      ),
    );
  }

  Widget _pillPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.size30),
        child: Ink(
          height: Dimensions.size45,
          padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
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
                width: Dimensions.size30,
                height: Dimensions.size30,
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: Dimensions.size15,
                  color: onPrimary,
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Text(
                label,
                style: TextStyle(
                  color: onPrimary,
                  fontSize: Dimensions.text13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool valid() {
    return formState.currentState != null && formState.currentState!.validate();
  }
}
