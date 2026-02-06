import "dart:ui";

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

  ///Trigger when page changed
  final Function(int) onPageChanged;

  ///End of numbers.
  final int pageTotal;

  ///Page number to be displayed first, default is 1.
  final int pageInit;

  ///Numbers to show at once. default is 10.
  final int threshold;

  ///Color of numbers. default is black.
  final Color colorPrimary;

  ///Color of background. default is white.
  final Color colorSub;

  ///to First, to Previous, to next, to Last Button UI.
  final Widget? controlButton;

  ///The icon of button to previous.
  final Widget iconPrevious;

  ///The icon of button to next.
  final Widget iconNext;

  ///The size of numbers. default is 15.
  final double fontSize;

  ///The fontFamily of numbers.
  final String? fontFamily;

  ///The elevation of the buttons.
  final double buttonElevation;

  ///The Radius of the buttons.
  final double buttonRadius;

  // Spacing between buttons, default is 4.0
  final double buttonSpacing;

  // Spacing between button groups, default is 10.0
  final double groupSpacing;

  @override
  _NumberPaginationState createState() => _NumberPaginationState();
}

class _NumberPaginationState extends State<CustomPagination> {
  late int currentPage;

  @override
  void initState() {
    currentPage = widget.pageInit;
    super.initState();
  }

  void _changePage(int targetPage) {
    int newPage = targetPage.clamp(1, widget.pageTotal);

    if (currentPage != newPage) {
      setState(() {
        currentPage = newPage;
        widget.onPageChanged(currentPage);
      });
    }
  }

  // =========================
  // Redesign helpers (UI only)
  // =========================

  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  bool _isActiveIndex(int index) {
    return (currentPage - 1) % widget.threshold == index;
  }

  Widget _pillShell({required Widget child}) {
    // Glass-ish container ala "Dynamic Report"
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.size25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size10,
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
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPageNumbers(int rangeStart, int rangeEnd) {
    final int count = rangeEnd <= widget.pageTotal
        ? widget.threshold
        : (widget.pageTotal % widget.threshold);

    return Flexible(
      fit: FlexFit.loose,
      child: Wrap(
        spacing: widget.buttonSpacing,
        runSpacing: widget.buttonSpacing,
        alignment: WrapAlignment.center,
        children: List.generate(
          count,
          (index) {
            final bool active = _isActiveIndex(index);
            final int pageNumber = index + 1 + rangeStart;

            final Color primary = Theme.of(context).colorScheme.primary;
            final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

            final Color bg = active ? primary : _soft(context);
            final Color border =
                active ? primary.withValues(alpha: 0.28) : _outline(context).withValues(alpha: 0.18);
            final Color textColor =
                active ? onPrimary : (widget.colorPrimary);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _changePage(pageNumber),
                borderRadius: BorderRadius.circular(widget.buttonRadius),
                child: Ink(
                  width: 46,
                  height: 46,
                  decoration: ShapeDecoration(
                    color: bg,
                    shadows: active
                        ? [
                            BoxShadow(
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                          ]
                        : const [],
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.buttonRadius),
                      smoothness: 1,
                      side: BorderSide(color: border),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "$pageNumber",
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontFamily: widget.fontFamily,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: textColor,
                      ),
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

  Widget _buildControlButton(Widget icon, bool enabled, VoidCallback onTap) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        child: Ink(
          width: 46,
          height: 46,
          decoration: ShapeDecoration(
            color: enabled ? _soft(context) : _soft(context).withValues(alpha: 0.55),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: 1,
              side: BorderSide(
                color: enabled
                    ? _outline(context).withValues(alpha: 0.22)
                    : _outline(context).withValues(alpha: 0.12),
              ),
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              size: 26,
              color: enabled ? primary : _fg(context).withValues(alpha: 0.30),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  Widget _pageInfoChip() {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color fg = _fg(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _soft(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: 1,
          side: BorderSide(color: _outline(context).withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Dimensions.size25,
            height: Dimensions.size25,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            child: Icon(
              Icons.layers_rounded,
              size: 16,
              color: primary,
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Text(
            "$currentPage",
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            " / ${widget.pageTotal}",
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: fg.withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeStart = currentPage % widget.threshold == 0
        ? currentPage - widget.threshold
        : (currentPage ~/ widget.threshold) * widget.threshold;

    final rangeEnd = rangeStart + widget.threshold;

    return _pillShell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            widget.iconPrevious,
            currentPage != 1,
            () => _changePage(currentPage - 1),
          ),
          SizedBox(width: widget.groupSpacing),
          _buildPageNumbers(rangeStart, rangeEnd),
          SizedBox(width: widget.groupSpacing),
          _buildControlButton(
            widget.iconNext,
            currentPage != widget.pageTotal,
            () => _changePage(currentPage + 1),
          ),
          SizedBox(width: widget.groupSpacing),
          _pageInfoChip(),
        ],
      ),
    );
  }
}
