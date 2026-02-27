// ignore_for_file: deprecated_member_use

import "dart:io";

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class CustomDynamicFormSubDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final SubDetailForm subDetailForm;
  final Map<String, dynamic> data;

  const CustomDynamicFormSubDetailForm({
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.subDetailForm,
    required this.data,
    super.key,
  });

  @override
  State<CustomDynamicFormSubDetailForm> createState() =>
      CustomDynamicFormSubDetailFormState();
}

class CustomDynamicFormSubDetailFormState
    extends State<CustomDynamicFormSubDetailForm> with WidgetsBindingObserver {
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
    final String p = (Preferences.getInstance()
                .getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH) ??
            "")
        .trim();

    if (p.isEmpty) {
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }
    if (p.startsWith("assets/")) {
      return Image.asset(p, fit: BoxFit.cover);
    }

    final File f = File(p);
    if (f.existsSync()) {
      return Image.file(f, fit: BoxFit.cover);
    }

    return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;

    return Scaffold(
      backgroundColor: glass
          ? Colors.transparent
          : isGlass
              ? Colors.white.withOpacity(0.06)
              : AppColors.surfaceContainerLowest(),
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
                  Dimensions.size15,
                  Dimensions.size10,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                child: topBar(context),
              ),
              Expanded(child: body()),
              SizedBox(height: safe.bottom),
            ],
          ),
          Positioned(
            right: Dimensions.size15,
            bottom: safe.bottom + Dimensions.size10,
            child: floatingSaveFab(),
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

  Widget topBar(BuildContext context) {
    final bool glass = isGlass;

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
          child: Text(
            widget.subDetailForm.template.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : AppColors.onSurface(),
            ),
          ),
        ),
        if (widget.readOnly)
          glass
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
                        Icons.visibility_rounded,
                        size: Dimensions.size15,
                        color: isGlass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface().withValues(alpha: 0.75),
                      ),
                      SizedBox(width: Dimensions.size5),
                      Text(
                        "read_only".tr(),
                        style: TextStyle(
                          fontSize: Dimensions.text11,
                          fontWeight: FontWeight.w900,
                          color: isGlass
                              ? Colors.white.withOpacity(0.92)
                              : AppColors.onSurface().withValues(alpha: 0.80),
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
                    color: isGlass
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.surfaceContainerLowest(),
                    borderRadius: BorderRadius.circular(Dimensions.size100),
                    border: Border.all(
                      color: isGlass
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.outline().withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: Dimensions.size15,
                        color: isGlass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface().withValues(alpha: 0.75),
                      ),
                      SizedBox(width: Dimensions.size5),
                      Text(
                        "read_only".tr(),
                        style: TextStyle(
                          fontSize: Dimensions.text11,
                          fontWeight: FontWeight.w900,
                          color: isGlass
                              ? Colors.white.withOpacity(0.92)
                              : AppColors.onSurface().withValues(alpha: 0.75),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
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
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
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
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.35),
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
    final Color iconColor = glass
        ? Colors.white.withOpacity(0.92)
        : isGlass
            ? Colors.white.withOpacity(0.92)
            : AppColors.onSurface();

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
                  color: isGlass
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: isGlass
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.outline().withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                  size: Dimensions.size25,
                ),
              ),
      ),
    );
  }

  Widget floatingSaveFab() {
    if (widget.readOnly) {
      return const SizedBox.shrink();
    }

    final bool glass = isGlass;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (glass) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            save();
          },
          borderRadius: BorderRadius.circular(Dimensions.size30),
          child: GlassContainer(
            blur: Dimensions.size25,
            borderRadius: Dimensions.size30,
            opacity: 0.18,
            borderOpacity: 0.30,
            padding: EdgeInsets.zero,
            child: Container(
              height: Dimensions.size55,
              padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
              decoration: ShapeDecoration(
                color: primary.withOpacity(0.25),
                shadows: [
                  BoxShadow(
                    blurRadius: Dimensions.size25,
                    offset: Offset(0, Dimensions.size15),
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ],
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size30),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: primary.withOpacity(0.30),
                  ),
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
      );
    }

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
                blurRadius: Dimensions.size25,
                offset: Offset(0, Dimensions.size15),
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
                  color: onPrimary,
                  size: Dimensions.size20,
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

  Widget body() {
    final bool glass = isGlass;

    return Form(
      key: formState,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Builder(
          builder: (context) {
            final Widget formContent = Column(
              children: [
                CustomDynamicForm(
                  key:
                      ValueKey("SubDetail-${widget.subDetailForm.template.id}"),
                  readOnly: widget.readOnly,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                  template: widget.subDetailForm.template,
                  data: data,
                ),
              ],
            );

            if (glass) {
              return GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size20,
                opacity: 0.12,
                borderOpacity: 0.22,
                padding: EdgeInsets.all(Dimensions.size10),
                child: formContent,
              );
            }

            return Container(
              padding: EdgeInsets.all(Dimensions.size10),
              decoration: ShapeDecoration(
                color: isGlass
                    ? Colors.white.withOpacity(0.10)
                    : AppColors.surface(),
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
                    color: isGlass
                        ? Colors.white.withOpacity(0.18)
                        : AppColors.outline().withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: formContent,
            );
          },
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
