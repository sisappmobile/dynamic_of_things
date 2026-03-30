import "dart:math" as math;

import "package:flutter/material.dart";

enum DotScreenType {
  mobile,
  tablet,
  desktop,
}

class DotResponsive {
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1180;

  static double widthOf(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static DotScreenType sizeOf(BuildContext context) {
    return sizeOfWidth(widthOf(context));
  }

  static DotScreenType sizeOfWidth(double width) {
    if (width >= desktopBreakpoint) {
      return DotScreenType.desktop;
    }

    if (width >= tabletBreakpoint) {
      return DotScreenType.tablet;
    }

    return DotScreenType.mobile;
  }

  static bool isMobileContext(BuildContext context) {
    return sizeOf(context) == DotScreenType.mobile;
  }

  static double horizontalPadding(
    BuildContext context, {
    double mobile = 15,
    double tablet = 24,
    double desktop = 32,
  }) {
    switch (sizeOf(context)) {
      case DotScreenType.mobile:
        return mobile;
      case DotScreenType.tablet:
        return tablet;
      case DotScreenType.desktop:
        return desktop;
    }
  }

  static double maxContentWidth(
    BuildContext context, {
    double mobile = double.infinity,
    double tablet = 920,
    double desktop = 1120,
  }) {
    final double width = widthOf(context);
    final double target = switch (sizeOf(context)) {
      DotScreenType.mobile => mobile,
      DotScreenType.tablet => tablet,
      DotScreenType.desktop => desktop,
    };

    if (target.isInfinite) {
      return width;
    }

    return math.min(width, target);
  }

  static Widget centered({
    required BuildContext context,
    required Widget child,
    double mobile = double.infinity,
    double tablet = 920,
    double desktop = 1120,
    AlignmentGeometry alignment = Alignment.topCenter,
  }) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth(
            context,
            mobile: mobile,
            tablet: tablet,
            desktop: desktop,
          ),
        ),
        child: child,
      ),
    );
  }

  static int gridColumnCount({
    required double availableWidth,
    required double minItemWidth,
    int min = 1,
    int max = 6,
  }) {
    if (availableWidth <= 0 || minItemWidth <= 0) {
      return min;
    }

    final int count = (availableWidth / minItemWidth).floor();
    return count.clamp(min, max);
  }
}
