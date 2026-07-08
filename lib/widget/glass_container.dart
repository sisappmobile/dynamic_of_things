// ignore_for_file: deprecated_member_use

import "dart:math" as math;
import "dart:ui";

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

enum GlassEffectProfile {
  standard(0),
  lowBlur(1),
  transparent(2);

  const GlassEffectProfile(this.storageValue);

  final int storageValue;

  static GlassEffectProfile fromStorageValue(Object? value) {
    if (value is int) {
      for (final GlassEffectProfile profile in GlassEffectProfile.values) {
        if (profile.storageValue == value) {
          return profile;
        }
      }
    }

    if (value is String) {
      final String normalized = value.toLowerCase().trim();
      if (normalized == "1" ||
          normalized == "low" ||
          normalized == "low_blur") {
        return GlassEffectProfile.lowBlur;
      }
      if (normalized == "2" ||
          normalized == "transparent" ||
          normalized == "clear") {
        return GlassEffectProfile.transparent;
      }
    }

    return GlassEffectProfile.standard;
  }
}

class GlassPerformance {
  const GlassPerformance._();

  static const double minVisibleBlur = 0.6;

  static T resolve<T>({
    required T standard,
    T? lowBlur,
    T? transparent,
    GlassEffectProfile? profile,
  }) {
    switch (profile ?? effectProfile()) {
      case GlassEffectProfile.standard:
        return standard;
      case GlassEffectProfile.lowBlur:
        return lowBlur ?? standard;
      case GlassEffectProfile.transparent:
        return transparent ?? standard;
    }
  }

  static GlassEffectProfile effectProfile() {
    try {
      final Preferences prefs = Preferences.getInstance();

      final int? intValue =
          prefs.getInt(SharedPreferenceKey.GLASS_EFFECT_PROFILE);
      if (intValue != null) {
        return GlassEffectProfile.fromStorageValue(intValue);
      }

      final String? stringValue =
          prefs.getString(SharedPreferenceKey.GLASS_EFFECT_PROFILE);
      if (stringValue != null && stringValue.isNotEmpty) {
        return GlassEffectProfile.fromStorageValue(stringValue);
      }
    } catch (_) {}

    return GlassEffectProfile.standard;
  }

  static bool isLowBlurProfile({GlassEffectProfile? profile}) {
    return (profile ?? effectProfile()) == GlassEffectProfile.lowBlur;
  }

  static bool isTransparentProfile({GlassEffectProfile? profile}) {
    return (profile ?? effectProfile()) == GlassEffectProfile.transparent;
  }

  static bool reduceEffects(BuildContext context) {
    final MediaQueryData? mq = MediaQuery.maybeOf(context);

    return (mq?.disableAnimations ?? false) ||
        (mq?.accessibleNavigation ?? false) ||
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
  }

  static bool isMobileDevice(BuildContext context) {
    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    final double shortestSide = mq?.size.shortestSide ?? 0;
    final TargetPlatform platform = Theme.of(context).platform;

    return shortestSide > 0 &&
        shortestSide < 700 &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  }

  static bool isTouchTabletDevice(BuildContext context) {
    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    final double shortestSide = mq?.size.shortestSide ?? 0;
    final TargetPlatform platform = Theme.of(context).platform;

    return shortestSide >= 700 &&
        shortestSide <= 1100 &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  }

  static bool isAndroidTabletDevice(BuildContext context) {
    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    final double shortestSide = mq?.size.shortestSide ?? 0;

    return shortestSide >= 700 &&
        shortestSide <= 1100 &&
        Theme.of(context).platform == TargetPlatform.android;
  }

  static double effectiveBlur(
    BuildContext context,
    double blur, {
    bool isScrolling = false,
    GlassEffectProfile? profile,
  }) {
    if (blur <= 0) {
      return 0;
    }

    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    final bool reduce = reduceEffects(context);
    final bool mobile = isMobileDevice(context);
    final bool touchTablet = isTouchTabletDevice(context);
    final GlassEffectProfile resolvedProfile = profile ?? effectProfile();
    final bool deferDuringScroll = isScrolling ||
        (!reduce && Scrollable.recommendDeferredLoadingForContext(context));

    final double dpr = (mq?.devicePixelRatio ?? 2.0).clamp(1.0, 3.5);
    final double shortestSide = (mq?.size.shortestSide ?? 420).clamp(
      320.0,
      1600.0,
    );

    double adjusted = blur;

    if (mobile) {
      adjusted = math.min(adjusted, shortestSide < 390 ? 11.0 : 13.0);
    } else if (shortestSide < 900) {
      adjusted = math.min(adjusted, 18.0);
    }

    if (resolvedProfile == GlassEffectProfile.lowBlur) {
      adjusted = math.min(adjusted, mobile ? 3.2 : 4.6);
      adjusted *= mobile ? 0.50 : 0.58;
    } else if (resolvedProfile == GlassEffectProfile.transparent) {
      adjusted = math.min(adjusted * 1.18, mobile ? 18.0 : 22.0);
    }

    final double dprFactor = dpr >= 3.0 ? 1.45 : (dpr >= 2.5 ? 1.28 : 1.0);
    adjusted /= dprFactor;

    if (mobile) {
      adjusted *= shortestSide < 390 ? 0.88 : 0.94;
    }

    if (deferDuringScroll) {
      double scrollMultiplier = 0.10;

      if (mobile) {
        scrollMultiplier =
            resolvedProfile == GlassEffectProfile.lowBlur ? 0.42 : 0.26;
      } else if (touchTablet) {
        scrollMultiplier =
            resolvedProfile == GlassEffectProfile.lowBlur ? 0.28 : 0.16;
      }

      adjusted *= scrollMultiplier;
    }

    if (reduce) {
      adjusted *= 0.25;
    }

    return adjusted.clamp(0.0, blur);
  }

  static double surfaceOpacityMultiplier({GlassEffectProfile? profile}) {
    switch (profile ?? effectProfile()) {
      case GlassEffectProfile.standard:
        return 1;
      case GlassEffectProfile.lowBlur:
        return 1.36;
      case GlassEffectProfile.transparent:
        return 0.42;
    }
  }

  static double borderOpacityMultiplier({GlassEffectProfile? profile}) {
    switch (profile ?? effectProfile()) {
      case GlassEffectProfile.standard:
        return 1;
      case GlassEffectProfile.lowBlur:
        return 0.82;
      case GlassEffectProfile.transparent:
        return 1.18;
    }
  }
}

class GlassBackdropFilter extends StatefulWidget {
  const GlassBackdropFilter({
    required this.child,
    required this.blur,
    super.key,
    this.profileOverride,
    this.tileMode = TileMode.decal,
    this.useRepaintBoundary = true,
    this.useGroupedBackdrop = true,
  });

  final Widget child;
  final double blur;
  final GlassEffectProfile? profileOverride;
  final TileMode tileMode;
  final bool useRepaintBoundary;
  final bool useGroupedBackdrop;

  @override
  State<GlassBackdropFilter> createState() => GlassBackdropFilterState();
}

class GlassBackdropFilterState extends State<GlassBackdropFilter> {
  static const Duration _blurTransitionDuration = Duration(milliseconds: 170);

  ScrollPosition? scrollPosition;
  bool isScrolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindScrollPosition();
  }

  @override
  void dispose() {
    scrollPosition?.isScrollingNotifier.removeListener(_onScrollStateChanged);
    super.dispose();
  }

  void _bindScrollPosition() {
    final ScrollPosition? nextPosition = Scrollable.maybeOf(context)?.position;

    if (identical(scrollPosition, nextPosition)) {
      return;
    }

    scrollPosition?.isScrollingNotifier.removeListener(_onScrollStateChanged);
    scrollPosition = nextPosition;
    scrollPosition?.isScrollingNotifier.addListener(_onScrollStateChanged);
    isScrolling = scrollPosition?.isScrollingNotifier.value ?? false;
  }

  void _onScrollStateChanged() {
    final bool nextValue = scrollPosition?.isScrollingNotifier.value ?? false;

    if (!mounted || nextValue == isScrolling) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final bool currentValue =
            scrollPosition?.isScrollingNotifier.value ?? false;
        if (currentValue == isScrolling) {
          return;
        }

        setState(() {
          isScrolling = currentValue;
        });
      });
      return;
    }

    setState(() {
      isScrolling = nextValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double targetBlur = GlassPerformance.effectiveBlur(
      context,
      widget.blur,
      isScrolling: isScrolling,
      profile: widget.profileOverride,
    );
    final Widget animatedBlur = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: targetBlur),
      duration: _blurTransitionDuration,
      curve: Curves.easeOutCubic,
      child: widget.child,
      builder: (BuildContext context, double animatedBlur, Widget? child) {
        if (animatedBlur <= 0.05) {
          return child ?? const SizedBox.shrink();
        }

        final ImageFilter filter = ImageFilter.blur(
          sigmaX: animatedBlur,
          sigmaY: animatedBlur,
          tileMode: widget.tileMode,
        );

        return widget.useGroupedBackdrop && BackdropGroup.of(context) != null
            ? BackdropFilter.grouped(
                enabled: animatedBlur >= GlassPerformance.minVisibleBlur,
                filter: filter,
                child: child,
              )
            : BackdropFilter(
                enabled: animatedBlur >= GlassPerformance.minVisibleBlur,
                filter: filter,
                child: child,
              );
      },
    );

    if (!widget.useRepaintBoundary) {
      return animatedBlur;
    }

    return RepaintBoundary(child: animatedBlur);
  }
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.borderRadius = 15,
    this.blur = 15,
    this.opacity = 0.18,
    this.borderOpacity = 0.22,
    this.padding,
    this.profileOverride,
    this.useGroupedBackdrop = true,
    this.useRepaintBoundary = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;
  final GlassEffectProfile? profileOverride;
  final bool useGroupedBackdrop;
  final bool useRepaintBoundary;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final double surfaceOpacity =
        ((brightness == Brightness.dark ? opacity : opacity + 0.06) *
                GlassPerformance.surfaceOpacityMultiplier(
                  profile: profileOverride,
                ))
            .clamp(0.03, 1.0);
    final double outlineOpacity = ((brightness == Brightness.dark
                ? borderOpacity
                : borderOpacity + 0.08) *
            GlassPerformance.borderOpacityMultiplier(
              profile: profileOverride,
            ))
        .clamp(0.05, 1.0);
    final Widget glassBody = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(surfaceOpacity),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withOpacity(outlineOpacity),
            width: Dimensions.size1,
          ),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: GlassBackdropFilter(
        blur: blur,
        profileOverride: profileOverride,
        useGroupedBackdrop: useGroupedBackdrop,
        useRepaintBoundary: useRepaintBoundary,
        child: glassBody,
      ),
    );
  }
}
