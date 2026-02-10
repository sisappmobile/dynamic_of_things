// ignore_for_file: deprecated_member_use

import "dart:ui";

import "package:flutter/material.dart";

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.borderRadius = 15,
    this.blur = 15,
    this.opacity = 0.18,
    this.borderOpacity = 0.22,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fill = isDark
        ? Colors.white.withOpacity(opacity)
        : Colors.white.withOpacity(opacity + 0.06);

    final Color border = isDark
        ? Colors.white.withOpacity(borderOpacity)
        : Colors.white.withOpacity(borderOpacity + 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
