// ignore_for_file: deprecated_member_use

import "dart:math" as math;

import "package:base/base.dart";
import "package:flutter/material.dart";
import "package:smooth_corner/smooth_corner.dart";

class CustomPagination extends StatefulWidget {
  const CustomPagination({
    required this.onPageChanged,
    required this.pageTotal,
    super.key,
    this.threshold = 10,
    this.pageInit = 1,
    this.colorPrimary = Colors.black,
    this.colorSub = Colors.white,
    this.controlButton,
    this.iconPrevious = const Icon(Icons.keyboard_arrow_left),
    this.iconNext = const Icon(Icons.keyboard_arrow_right),
    this.fontSize = 15,
    this.fontFamily,
    this.buttonElevation = 5,
    this.buttonRadius = 10,
    this.buttonSpacing = 4.0,
    this.groupSpacing = 10.0,
  });

  final Function(int) onPageChanged;

  final int pageTotal;

  final int pageInit;

  final int threshold;

  final Color colorPrimary;

  final Color colorSub;

  final Widget? controlButton;

  final Widget iconPrevious;

  final Widget iconNext;

  final double fontSize;

  final String? fontFamily;

  final double buttonElevation;

  final double buttonRadius;

  final double buttonSpacing;

  final double groupSpacing;

  @override
  NumberPaginationState createState() => NumberPaginationState();
}

class NumberPaginationState extends State<CustomPagination> {
  late int currentPage;

  @override
  void initState() {
    currentPage = widget.pageInit;
    super.initState();
  }

  void changePage(int targetPage) {
    final int newPage = targetPage.clamp(1, widget.pageTotal);

    if (currentPage != newPage) {
      setState(() {
        currentPage = newPage;
        widget.onPageChanged(currentPage);
      });
    }
  }

  int channelToLinear(int c) {
    final double v = c / 255.0;
    if (v <= 0.03928) {
      return (v / 12.92 * 1000000).round();
    }
    return (math.pow((v + 0.055) / 1.055, 2.4) * 1000000).round();
  }

  double relativeLuminance(Color color) {
    final int r = channelToLinear(color.red);
    final int g = channelToLinear(color.green);
    final int b = channelToLinear(color.blue);

    final double rf = r / 1000000.0;
    final double gf = g / 1000000.0;
    final double bf = b / 1000000.0;
    return 0.2126 * rf + 0.7152 * gf + 0.0722 * bf;
  }

  double contrastRatio(Color a, Color b) {
    final double l1 = relativeLuminance(a);
    final double l2 = relativeLuminance(b);
    final double hi = math.max(l1, l2);
    final double lo = math.min(l1, l2);
    return (hi + 0.05) / (lo + 0.05);
  }

  bool isNearWhite(Color c) => relativeLuminance(c) > 0.92;

  bool isLowContrast(Color fg, Color bg) => contrastRatio(fg, bg) < 3.0;

  Color safeTextOn(Color desiredText, Color bg, {Color? fallback}) {
    if (!isLowContrast(desiredText, bg)) {
      return desiredText;
    }

    final Color fb = fallback ?? AppColors.onSurface();
    if (!isLowContrast(fb, bg)) {
      return fb;
    }

    final Color alt = relativeLuminance(bg) > 0.6 ? Colors.black : Colors.white;
    return alt;
  }

  Color safeFill(Color desiredBg, Color fgHint) {
    if (isNearWhite(desiredBg) && isNearWhite(fgHint)) {
      return desiredBg.withOpacity(0.20);
    }

    if (isLowContrast(fgHint, desiredBg)) {
      return desiredBg.withOpacity(0.35);
    }
    return desiredBg;
  }

  BorderSide safeBorder(Color bg) {
    final Color base = AppColors.outline();
    if (isNearWhite(bg)) {
      return BorderSide(color: base.withOpacity(0.85));
    }
    return BorderSide(color: base);
  }

  Widget pageNumbers(int rangeStart, int rangeEnd) {
    final int count = rangeEnd <= widget.pageTotal
        ? widget.threshold
        : widget.pageTotal % widget.threshold;

    return Flexible(
      fit: FlexFit.loose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) {
            final bool isSelected =
                (currentPage - 1) % widget.threshold == index;

            final Color desiredBg =
                isSelected ? widget.colorPrimary : widget.colorSub;
            final Color desiredFg =
                isSelected ? widget.colorSub : widget.colorPrimary;

            final Color safeBg = safeFill(desiredBg, desiredFg);

            final Color desiredText = isSelected ? Colors.black : desiredFg;
            final Color safeText = safeTextOn(
              desiredText,
              safeBg,
              fallback: isSelected ? widget.colorSub : AppColors.onSurface(),
            );

            final Color safeFgForButton =
                safeTextOn(desiredFg, safeBg, fallback: AppColors.onSurface());

            return Flexible(
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.buttonRadius),
                      side: safeBorder(safeBg),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: Size(Dimensions.size50, Dimensions.size50),
                    foregroundColor: safeFgForButton,
                    backgroundColor: safeBg,
                  ),
                  onPressed: () => changePage(index + 1 + rangeStart),
                  child: Text(
                    "${index + 1 + rangeStart}",
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontFamily: widget.fontFamily,
                      color: safeText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget controlButton(Widget icon, bool enabled, VoidCallback onTap) {
    final Color bg = safeFill(widget.colorSub, widget.colorPrimary);
    final Color fgEnabled =
        safeTextOn(widget.colorPrimary, bg, fallback: AppColors.onSurface());
    final Color fgDisabled = safeTextOn(Colors.grey, bg, fallback: Colors.grey);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size10),
          smoothness: Dimensions.size1,
          side: safeBorder(bg),
        ),
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: Size(Dimensions.size50, Dimensions.size50),
        foregroundColor: enabled ? fgEnabled : fgDisabled,
        backgroundColor: bg,
        disabledForegroundColor: fgDisabled,
        disabledBackgroundColor: bg,
      ),
      onPressed: enabled ? onTap : null,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int rangeStart = currentPage % widget.threshold == 0
        ? currentPage - widget.threshold
        : (currentPage ~/ widget.threshold) * widget.threshold;

    final int rangeEnd = rangeStart + widget.threshold;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        controlButton(
          widget.iconPrevious,
          currentPage != 1,
          () => changePage(currentPage - 1),
        ),
        SizedBox(width: widget.groupSpacing),
        pageNumbers(rangeStart, rangeEnd),
        SizedBox(width: widget.groupSpacing),
        controlButton(
          widget.iconNext,
          currentPage != widget.pageTotal,
          () => changePage(currentPage + 1),
        ),
      ],
    );
  }
}
