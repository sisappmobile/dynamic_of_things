import "package:base/base.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:flutter/material.dart";
import "package:smooth_corner/smooth_corner.dart";

class DynamicChartDesktopWindowLayout {
  final String id;
  final double left;
  final double top;
  final double width;
  final double height;
  final int zIndex;
  final bool minimized;
  final bool maximized;
  final double? restoreLeft;
  final double? restoreTop;
  final double? restoreWidth;
  final double? restoreHeight;

  const DynamicChartDesktopWindowLayout({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.zIndex,
    this.minimized = false,
    this.maximized = false,
    this.restoreLeft,
    this.restoreTop,
    this.restoreWidth,
    this.restoreHeight,
  });

  factory DynamicChartDesktopWindowLayout.fromJson(Map<String, dynamic> json) {
    return DynamicChartDesktopWindowLayout(
      id: (json["id"] ?? "").toString(),
      left: _readDouble(json["left"], fallback: 24),
      top: _readDouble(json["top"], fallback: 24),
      width: _readDouble(json["width"], fallback: 360),
      height: _readDouble(json["height"], fallback: 420),
      zIndex: _readInt(json["zIndex"], fallback: 0),
      minimized: false,
      maximized: _readBool(json["maximized"], fallback: false),
      restoreLeft: _readOptionalDouble(json["restoreLeft"]),
      restoreTop: _readOptionalDouble(json["restoreTop"]),
      restoreWidth: _readOptionalDouble(json["restoreWidth"]),
      restoreHeight: _readOptionalDouble(json["restoreHeight"]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "id": id,
      "left": left,
      "top": top,
      "width": width,
      "height": height,
      "zIndex": zIndex,
      "minimized": minimized,
      "maximized": maximized,
      "restoreLeft": restoreLeft,
      "restoreTop": restoreTop,
      "restoreWidth": restoreWidth,
      "restoreHeight": restoreHeight,
    };
  }

  DynamicChartDesktopWindowLayout copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    int? zIndex,
    bool? minimized,
    bool? maximized,
    double? restoreLeft,
    bool clearRestoreLeft = false,
    double? restoreTop,
    bool clearRestoreTop = false,
    double? restoreWidth,
    bool clearRestoreWidth = false,
    double? restoreHeight,
    bool clearRestoreHeight = false,
  }) {
    return DynamicChartDesktopWindowLayout(
      id: id,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      minimized: minimized ?? this.minimized,
      maximized: maximized ?? this.maximized,
      restoreLeft: clearRestoreLeft ? null : (restoreLeft ?? this.restoreLeft),
      restoreTop: clearRestoreTop ? null : (restoreTop ?? this.restoreTop),
      restoreWidth:
          clearRestoreWidth ? null : (restoreWidth ?? this.restoreWidth),
      restoreHeight:
          clearRestoreHeight ? null : (restoreHeight ?? this.restoreHeight),
    );
  }

  static double _readDouble(dynamic value, {required double fallback}) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static double? _readOptionalDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == "true" || normalized == "1") {
        return true;
      }
      if (normalized == "false" || normalized == "0") {
        return false;
      }
    }
    return fallback;
  }
}

enum _ResizeEdge {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class DynamicChartDesktopWindowFrame extends StatelessWidget {
  final Rect rect;
  final bool glass;
  final bool active;
  final bool minimized;
  final bool maximized;
  final bool floatingEnabled;
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onFocus;
  final VoidCallback onToggleMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback? onClose;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback? onDragEnd;
  final ValueChanged<Offset> onResizeDelta;
  final VoidCallback? onResizeEnd;
  final void Function(double dLeft, double dTop, double dWidth, double dHeight)?
      onEdgeResizeDelta;

  const DynamicChartDesktopWindowFrame({
    required this.rect,
    required this.glass,
    required this.active,
    required this.minimized,
    required this.maximized,
    required this.floatingEnabled,
    required this.title,
    required this.icon,
    required this.child,
    required this.onFocus,
    required this.onToggleMinimize,
    required this.onToggleMaximize,
    required this.onDragDelta,
    required this.onResizeDelta,
    this.onClose,
    this.onDragEnd,
    this.onResizeEnd,
    this.onEdgeResizeDelta,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = glass
        ? Colors.white.withOpacity(active ? 0.24 : 0.14)
        : active
            ? AppColors.primary().withOpacity(0.18)
            : AppColors.surfaceContainerHighest();
    final Color titleColor =
        glass ? Colors.white.withOpacity(0.95) : AppColors.onSurface();
    final Color subtitleColor =
        glass ? Colors.white.withOpacity(0.70) : AppColors.onSurfaceVariant();
    final Color titleBarColor = glass
        ? Colors.white.withOpacity(active ? 0.08 : 0.05)
        : active
            ? AppColors.primary().withOpacity(0.05)
            : AppColors.surfaceContainerLow();
    final BorderRadius borderRadius = BorderRadius.circular(Dimensions.size20);

    Widget toolbarButton({
      required IconData iconData,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onFocus();
              onPressed();
            },
            borderRadius: BorderRadius.circular(Dimensions.size10),
            child: Padding(
              padding: EdgeInsets.all(Dimensions.size5),
              child: Icon(
                iconData,
                size: Dimensions.size20,
                color: titleColor,
              ),
            ),
          ),
        ),
      );
    }

    Widget titleBar() {
      return MouseRegion(
        cursor: floatingEnabled && !maximized && !minimized
            ? SystemMouseCursors.move
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: floatingEnabled && !maximized && !minimized
              ? (_) => onFocus()
              : null,
          onPanUpdate: floatingEnabled && !maximized && !minimized
              ? (DragUpdateDetails details) => onDragDelta(details.delta)
              : null,
          onPanEnd: floatingEnabled && !maximized && !minimized
              ? (_) => onDragEnd?.call()
              : null,
          onTap: onFocus,
          onDoubleTap: floatingEnabled ? onToggleMaximize : null,
          child: Container(
            height: Dimensions.size50,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
            decoration: BoxDecoration(
              color: titleBarColor,
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: minimized ? 0 : 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: Dimensions.size30,
                  height: Dimensions.size30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    color: glass
                        ? Colors.white.withOpacity(0.12)
                        : AppColors.surfaceContainerHighest(),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: Dimensions.size20,
                    color: titleColor,
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Dimensions.text13,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        floatingEnabled ? "Floating window" : "Fixed widget",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Dimensions.text10,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                toolbarButton(
                  iconData: maximized
                      ? Icons.filter_none_rounded
                      : Icons.crop_square_rounded,
                  tooltip: maximized ? "Restore size" : "Maximize widget",
                  onPressed: onToggleMaximize,
                ),
                if (onClose != null) ...[
                  SizedBox(width: Dimensions.size4),
                  Tooltip(
                    message: "Close widget",
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onFocus();
                          onClose!();
                        },
                        borderRadius: BorderRadius.circular(Dimensions.size10),
                        hoverColor: Colors.red.withOpacity(0.12),
                        child: Padding(
                          padding: EdgeInsets.all(Dimensions.size5),
                          child: Icon(
                            Icons.close_rounded,
                            size: Dimensions.size20,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget edgeHandle(_ResizeEdge edge) {
      final bool canResize = floatingEnabled && !maximized && !minimized;
      const double edgeThickness = 6.0;
      const double cornerSize = 14.0;

      MouseCursor cursor;
      double? handleLeft;
      double? handleRight;
      double? handleTop;
      double? handleBottom;
      double? handleWidth;
      double? handleHeight;

      switch (edge) {
        case _ResizeEdge.top:
          cursor = SystemMouseCursors.resizeRow;
          handleLeft = cornerSize;
          handleRight = cornerSize;
          handleTop = 0;
          handleHeight = edgeThickness;
          break;
        case _ResizeEdge.bottom:
          cursor = SystemMouseCursors.resizeRow;
          handleLeft = cornerSize;
          handleRight = cornerSize;
          handleBottom = 0;
          handleHeight = edgeThickness;
          break;
        case _ResizeEdge.left:
          cursor = SystemMouseCursors.resizeColumn;
          handleTop = cornerSize;
          handleBottom = cornerSize;
          handleLeft = 0;
          handleWidth = edgeThickness;
          break;
        case _ResizeEdge.right:
          cursor = SystemMouseCursors.resizeColumn;
          handleTop = cornerSize;
          handleBottom = cornerSize;
          handleRight = 0;
          handleWidth = edgeThickness;
          break;
        case _ResizeEdge.topLeft:
          cursor = SystemMouseCursors.resizeUpLeft;
          handleLeft = 0;
          handleTop = 0;
          handleWidth = cornerSize;
          handleHeight = cornerSize;
          break;
        case _ResizeEdge.topRight:
          cursor = SystemMouseCursors.resizeUpRight;
          handleRight = 0;
          handleTop = 0;
          handleWidth = cornerSize;
          handleHeight = cornerSize;
          break;
        case _ResizeEdge.bottomLeft:
          cursor = SystemMouseCursors.resizeDownLeft;
          handleLeft = 0;
          handleBottom = 0;
          handleWidth = cornerSize;
          handleHeight = cornerSize;
          break;
        case _ResizeEdge.bottomRight:
          cursor = SystemMouseCursors.resizeDownRight;
          handleRight = 0;
          handleBottom = 0;
          handleWidth = cornerSize;
          handleHeight = cornerSize;
          break;
      }

      void onPanUpdateEdge(DragUpdateDetails details) {
        if (!canResize) {
          return;
        }

        final double dx = details.delta.dx;
        final double dy = details.delta.dy;

        double dLeft = 0;
        double dTop = 0;
        double dWidth = 0;
        double dHeight = 0;

        switch (edge) {
          case _ResizeEdge.top:
            dTop = dy;
            dHeight = -dy;
            break;
          case _ResizeEdge.bottom:
            dHeight = dy;
            break;
          case _ResizeEdge.left:
            dLeft = dx;
            dWidth = -dx;
            break;
          case _ResizeEdge.right:
            dWidth = dx;
            break;
          case _ResizeEdge.topLeft:
            dLeft = dx;
            dWidth = -dx;
            dTop = dy;
            dHeight = -dy;
            break;
          case _ResizeEdge.topRight:
            dWidth = dx;
            dTop = dy;
            dHeight = -dy;
            break;
          case _ResizeEdge.bottomLeft:
            dLeft = dx;
            dWidth = -dx;
            dHeight = dy;
            break;
          case _ResizeEdge.bottomRight:
            dWidth = dx;
            dHeight = dy;
            break;
        }

        if (onEdgeResizeDelta != null) {
          onEdgeResizeDelta!(dLeft, dTop, dWidth, dHeight);
          return;
        }

        if (edge == _ResizeEdge.bottomRight) {
          onResizeDelta(Offset(dWidth, dHeight));
        }
      }

      return Positioned(
        left: handleLeft,
        right: handleRight,
        top: handleTop,
        bottom: handleBottom,
        width: handleWidth,
        height: handleHeight,
        child: MouseRegion(
          cursor: canResize ? cursor : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: canResize ? (_) => onFocus() : null,
            onPanUpdate: canResize ? onPanUpdateEdge : null,
            onPanEnd: canResize ? (_) => onResizeEnd?.call() : null,
            child: const SizedBox.expand(),
          ),
        ),
      );
    }

    Widget resizeGripIcon() {
      return Positioned(
        right: 0,
        bottom: 0,
        child: IgnorePointer(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.size10),
            child: CustomPaint(
              size: Size(Dimensions.size10, Dimensions.size10),
              painter: _ResizeGripPainter(
                color: subtitleColor.withOpacity(
                  floatingEnabled ? 0.9 : 0.35,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget frameChild() {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => onFocus(),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Column(
                children: [
                  titleBar(),
                  if (!minimized)
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: child,
                      ),
                    ),
                ],
              ),
              if (!minimized) resizeGripIcon(),
              if (!minimized) ...[
                edgeHandle(_ResizeEdge.top),
                edgeHandle(_ResizeEdge.bottom),
                edgeHandle(_ResizeEdge.left),
                edgeHandle(_ResizeEdge.right),
                edgeHandle(_ResizeEdge.topLeft),
                edgeHandle(_ResizeEdge.topRight),
                edgeHandle(_ResizeEdge.bottomLeft),
                edgeHandle(_ResizeEdge.bottomRight),
              ],
            ],
          ),
        ),
      );
    }

    Widget decoratedChild() {
      if (!glass) {
        return Material(
          color: AppColors.surfaceContainerLowest(),
          shape: SmoothRectangleBorder(
            smoothness: Dimensions.size1,
            borderRadius: borderRadius,
            side: BorderSide(
              color: borderColor,
              width: active ? 1.0 : 0.6,
            ),
          ),
          elevation: active ? 10 : 4,
          shadowColor: Colors.black.withOpacity(active ? 0.18 : 0.08),
          child: frameChild(),
        );
      }

      return GlassContainer(
        blur: Dimensions.size25,
        borderRadius: Dimensions.size20,
        opacity: active ? 0.12 : 0.08,
        borderOpacity: active ? 0.24 : 0.14,
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(active ? 0.08 : 0.04),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor,
              width: active ? 0.9 : 0.6,
            ),
          ),
          child: frameChild(),
        ),
      );
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: decoratedChild(),
    );
  }
}

class _ResizeGripPainter extends CustomPainter {
  final Color color;

  const _ResizeGripPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawLine(
        Offset(size.width * 0.55, size.height),
        Offset(size.width, size.height * 0.55),
        paint,
      )
      ..drawLine(
        Offset(size.width * 0.2, size.height),
        Offset(size.width, size.height * 0.2),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _ResizeGripPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
