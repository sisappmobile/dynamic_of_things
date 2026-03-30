// ignore_for_file: deprecated_member_use

import "dart:io";
import "dart:ui";

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
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

class CustomDynamicFormBulkDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final List<Map<String, dynamic>> rows;

  const CustomDynamicFormBulkDetailForm({
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.rows,
    super.key,
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
  bool prefsReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    initPrefs();

    rows = widget.rows;
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
    final bool glass = isGlass;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    if (glass) {
      final EdgeInsets safe = MediaQuery.of(context).padding;

      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
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
                    child: appBarGlass(context),
                  ),
                ),
                Expanded(child: body()),
                SizedBox(height: safe.bottom),
              ],
            ),
          ],
        ),
        bottomNavigationBar: bottomBar(),
      );
    }

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

  Widget iconPill({
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
        child: GlassContainer(
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
              color: Colors.white.withOpacity(0.92),
              size: Dimensions.size25,
            ),
          ),
        ),
      ),
    );
  }

  Widget appBarGlass(BuildContext context) {
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
            widget.detailForm.template.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ),
      ],
    );

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

  // Header Progress dipertahankan bentuk card-nya karena merupakan indikator
  Widget progressHeader(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    final int current = index + 1;
    final int total = rows.length;
    final double progress = total <= 0 ? 0 : (current / total).clamp(0.0, 1.0);

    final Widget content = Column(
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
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
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
            backgroundColor: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(
              primary.withValues(alpha: 0.90),
            ),
          ),
        ),
      ],
    );

    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.all(Dimensions.size15),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.all(Dimensions.size15),
      decoration: ShapeDecoration(
        color: AppColors.surface(),
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
            color: AppColors.outline().withValues(alpha: 0.18),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget body() {
    final bool glass = isGlass;

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
              Dimensions.size10,
              Dimensions.size15,
              Dimensions.size15 + Dimensions.size100, // Space aman untuk bottomBar
            ),
            child: DotResponsive.centered(
              context: context,
              tablet: 900,
              desktop: 980,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  progressHeader(context),
                  SizedBox(height: Dimensions.size20), // Spasi antar header progress dan form

                  // PERBAIKAN UTAMA: Wrapper `sectionCard` dibuang
                  CustomDynamicForm(
                    key: ValueKey("Detail-${widget.detailForm.template.id}-$index"),
                    readOnly: widget.readOnly,
                    customerId: widget.customerId,
                    headerForm: widget.headerForm,
                    template: widget.detailForm.template,
                    data: rows[index],
                  ),

                  ...widget.detailForm.subDetailForms.map((subDetailForm) {
                    return Padding(
                      // PERBAIKAN UTAMA: Wrapper `sectionCard` dibuang, gap diperlebar
                      padding: EdgeInsets.only(top: Dimensions.size25),
                      child: CustomDynamicFormSubDetailList(
                        key: ValueKey(
                          "SubDetailList-${subDetailForm.template.id}-$index",
                        ),
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
    final bool glass = isGlass;

    Widget previousButton() {
      if (index > 0) {
        return pillIconButton(
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
                color: isGlass
                    ? Colors.white.withOpacity(0.92)
                    : AppColors.onSurface(),
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: " ${"of".tr().toLowerCase()} ${rows.length}",
              style: TextStyle(
                color: glass
                    ? Colors.white.withOpacity(0.70)
                    : AppColors.secondary(),
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
        return pillIconButton(
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
        return pillButton(
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
          child: DotResponsive.centered(
            context: context,
            tablet: 900,
            desktop: 980,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.size25),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: Dimensions.size15,
                  sigmaY: Dimensions.size15,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.size15,
                    vertical: Dimensions.size10,
                  ),
                  decoration: BoxDecoration(
                    color: glass
                        ? Colors.white.withOpacity(0.12)
                        : AppColors.surface().withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(Dimensions.size25),
                    border: Border.all(
                      color: glass
                          ? Colors.white.withOpacity(0.22)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.18),
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
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget pillIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size50,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size45,
                  height: Dimensions.size45,
                  child: Icon(
                    icon,
                    color: Colors.white.withOpacity(0.92),
                    size: Dimensions.size20,
                  ),
                ),
              )
            : Ink(
                width: Dimensions.size45,
                height: Dimensions.size45,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: Dimensions.size20,
                ),
              ),
      ),
    );
  }

  Widget pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (glass) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.size30),
          child: GlassContainer(
            blur: Dimensions.size20,
            borderRadius: Dimensions.size30,
            opacity: 0.18,
            borderOpacity: 0.30,
            padding: EdgeInsets.zero,
            child: Container(
              height: Dimensions.size45,
              padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
              decoration: ShapeDecoration(
                color: primary.withOpacity(0.25),
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
                  side: BorderSide(
                    color: primary.withOpacity(0.30),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: Dimensions.size30,
                    height: Dimensions.size30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.28),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: Dimensions.size15,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  SizedBox(width: Dimensions.size10),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: Dimensions.text13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
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
