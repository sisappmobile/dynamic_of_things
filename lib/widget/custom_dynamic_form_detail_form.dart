// ignore_for_file: deprecated_member_use

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/generals.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_sub_detail_list.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
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
  bool prefsReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    initPrefs();

    data = widget.data;
  }

  Future<void> initPrefs() async {
    try {
      await Preferences.getInstance().init();
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      prefsReady = true;
    });
  }

  bool get isGlass {
    if (!prefsReady) {
      return false;
    }

    final int t = Preferences.getInstance()
            .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
        1;
    return t == 2;
  }

  Widget glassBackground() {
    return Generals.orientationAwareWallpaper(context);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor:
          glass ? Colors.transparent : AppColors.surfaceContainerLowest(),
      body: Stack(
        children: [
          if (glass) ...[
            Positioned.fill(child: glassBackground()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.fromRGBO(0, 0, 0, 0.55),
                      Color.fromRGBO(0, 0, 0, 0.22),
                      Color.fromRGBO(0, 0, 0, 0.40),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Column(
            children: [
              SizedBox(height: safe.top),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  Dimensions.size10,
                  horizontalPadding,
                  Dimensions.size10,
                ),
                child: DotResponsive.centered(
                  context: context,
                  tablet: 900,
                  desktop: 980,
                  child: appBar(),
                ),
              ),
              Expanded(child: body()),
              SizedBox(height: safe.bottom),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: safe.bottom + Dimensions.size5,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: DotResponsive.centered(
                context: context,
                tablet: 900,
                desktop: 980,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: bottomBar(),
                ),
              ),
            ),
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

  Widget appBar() {
    final bool glass = isGlass;
    final Color titleColor =
        glass ? Colors.white.withOpacity(0.95) : AppColors.onSurface();
    final Color subColor = glass
        ? Colors.white.withOpacity(0.70)
        : AppColors.onSurface().withValues(alpha: 0.60);

    final Widget modePill = glass
        ? GlassContainer(
            blur: Dimensions.size15,
            borderRadius: Dimensions.size100,
            opacity: 0.10,
            borderOpacity: 0.18,
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.size10,
              vertical: Dimensions.size5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.readOnly
                      ? Icons.visibility_rounded
                      : Icons.edit_rounded,
                  size: Dimensions.size15,
                  color: Colors.white.withOpacity(0.85),
                ),
                SizedBox(width: Dimensions.size5),
                Text(
                  widget.readOnly ? "View" : "Edit",
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.90),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          )
        : Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.size10,
              vertical: Dimensions.size5,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest(),
              borderRadius: BorderRadius.circular(Dimensions.size100),
              border: Border.all(
                color: AppColors.outline().withValues(alpha: 0.22),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: Dimensions.size5),
                Text(
                  widget.readOnly ? "View" : "Edit",
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface(),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          );

    final Widget content = Row(
      children: [
        iconPill(
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
                  color: subColor,
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
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: Dimensions.size10),
        modePill,
      ],
    );

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size15,
          vertical: Dimensions.size10,
        ),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surface(),
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
            color: AppColors.outline().withValues(alpha: 0.35),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color iconColor =
        glass ? Colors.white.withOpacity(0.92) : AppColors.onSurface();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size15,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: Dimensions.size25,
                  ),
                ),
              )
            : Ink(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: ShapeDecoration(
                  color: AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.outline().withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.onSurface(),
                  size: Dimensions.size25,
                ),
              ),
      ),
    );
  }

  Widget body() {
    final bool glass = isGlass;

    // PERBAIKAN UTAMA: Menggunakan MediaQuery.removePadding untuk mencegah ListView
    // di dalam CustomDynamicForm menyedot safe area (poni layar) yang menyebabkan gap raksasa.
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: Container(
        color: glass ? Colors.transparent : AppColors.surfaceContainerLowest(),
        child: Form(
          key: formState,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Dimensions.size15,
              Dimensions.size10, // Jarak telah disesuaikan agar rapi
              Dimensions.size15,
              Dimensions.size15 + (widget.readOnly ? 0 : Dimensions.size75),
            ),
            child: DotResponsive.centered(
              context: context,
              tablet: 900,
              desktop: 980,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDynamicForm(
                    key: ValueKey("Detail-${widget.detailForm.template.id}"),
                    readOnly: widget.readOnly,
                    customerId: widget.customerId,
                    headerForm: widget.headerForm,
                    template: widget.detailForm.template,
                    data: data,
                  ),
                  ...widget.detailForm.subDetailForms
                      .asMap()
                      .entries
                      .map((entry) {
                    final int i = entry.key;
                    final subDetailForm = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(
                        top: Dimensions.size20,
                      ), // Spasi antar section dibuat lega & proporsional
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
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomBar() {
    if (!widget.readOnly) {
      return buttonSave();
    }
    return const SizedBox.shrink();
  }

  Widget buttonSave() {
    final bool glass = isGlass;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (glass) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.size30),
          boxShadow: [
            BoxShadow(
              blurRadius: Dimensions.size20,
              offset: Offset(0, Dimensions.size10),
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ],
        ),
        child: GlassContainer(
          blur: Dimensions.size25,
          borderRadius: Dimensions.size30,
          opacity: 0.18,
          borderOpacity: 0.30,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: save,
              borderRadius: BorderRadius.circular(Dimensions.size30),
              child: Container(
                height: Dimensions.size55,
                padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(Dimensions.size30),
                  border: Border.all(
                    color: primary.withOpacity(0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: Dimensions.size35,
                      height: Dimensions.size35,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.save_rounded,
                        size: Dimensions.size20,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Text(
                      "save".tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
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
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.size30),
        boxShadow: [
          BoxShadow(
            blurRadius: Dimensions.size15,
            offset: Offset(0, Dimensions.size5),
            color: primary.withValues(alpha: 0.38),
          ),
        ],
      ),
      child: Material(
        color: primary,
        borderRadius: BorderRadius.circular(Dimensions.size30),
        child: InkWell(
          onTap: save,
          borderRadius: BorderRadius.circular(Dimensions.size30),
          child: Container(
            height: Dimensions.size55,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
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
