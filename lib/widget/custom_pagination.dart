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

  Widget _buildPageNumbers(int rangeStart, int rangeEnd) {
    return Flexible(
      fit: FlexFit.loose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          rangeEnd <= widget.pageTotal ? widget.threshold : widget.pageTotal % widget.threshold,
          (index) => Flexible(
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.buttonRadius),
                    side: BorderSide(color: AppColors.outline()),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  foregroundColor: (currentPage - 1) % widget.threshold == index ? widget.colorSub : widget.colorPrimary,
                  backgroundColor: (currentPage - 1) % widget.threshold == index ? widget.colorPrimary : widget.colorSub,
                ),
                onPressed: () => _changePage(index + 1 + rangeStart),
                child: Text(
                  "${index + 1 + rangeStart}",
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontFamily: widget.fontFamily,
                    color: (currentPage - 1) % widget.threshold == index ? widget.colorSub : widget.colorPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(Widget icon, bool enabled, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size10),
          smoothness: 1,
          side: BorderSide(
            color: AppColors.outline(),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        foregroundColor: enabled ? widget.colorPrimary : Colors.grey,
        backgroundColor: widget.colorSub,
        disabledForegroundColor: widget.colorPrimary,
        disabledBackgroundColor: widget.colorSub,
      ),
      onPressed: enabled ? onTap : null,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeStart = currentPage % widget.threshold == 0 ? currentPage - widget.threshold : (currentPage ~/ widget.threshold) * widget.threshold;

    final rangeEnd = rangeStart + widget.threshold;

    return Row(
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
      ],
    );
  }
}
