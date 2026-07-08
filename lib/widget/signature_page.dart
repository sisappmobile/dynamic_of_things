// ignore_for_file: use_build_context_synchronously

import "dart:math" as math;
import "dart:typed_data";
import "dart:ui" as ui;
import "dart:ui";

import "package:base/base.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:dynamic_of_things/helper/signature_png_export_native.dart"
    if (dart.library.html) "package:dynamic_of_things/helper/signature_png_export_web.dart"
    as signature_png_export;
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class SignaturePage extends StatefulWidget {
  const SignaturePage({
    super.key,
  });

  @override
  SignaturePageState createState() => SignaturePageState();
}

class SignaturePageState extends State<SignaturePage> {
  final List<Offset?> _points = <Offset?>[];
  Size _signatureSize = Size.zero;

  bool get hasSignature {
    return _points.any((Offset? point) => point != null);
  }

  void clearSignature() {
    if (_points.isEmpty) {
      return;
    }

    setState(() {
      _points.clear();
    });
  }

  void addPoint(Offset point) {
    final Size size = _signatureSize;
    final Offset normalized = Offset(
      point.dx.clamp(0.0, size.width),
      point.dy.clamp(0.0, size.height),
    );

    setState(() {
      _points.add(normalized);
    });
  }

  void endStroke() {
    if (_points.isEmpty || _points.last == null) {
      return;
    }

    setState(() {
      _points.add(null);
    });
  }

  Future<Uint8List?> exportSignature() async {
    return signature_png_export.exportSignaturePng(
      points: _points,
      size: _signatureSize,
      backgroundColor: AppColors.surfaceContainerLowest(),
      strokeColor: AppColors.onSurface(),
    );
  }

  Widget sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(Dimensions.size15),
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
            color: AppColors.outline().withValues(alpha: 0.20),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget iconPill({
    required BuildContext context,
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
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: AppColors.surfaceContainerLowest(),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: AppColors.outline().withValues(alpha: 0.22),
              ),
            ),
          ),
          child: Icon(
            icon,
            size: Dimensions.size25,
            color: AppColors.onSurface(),
          ),
        ),
      ),
    );
  }

  Widget glassTopbar(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          safe.top > 0 ? Dimensions.size10 : Dimensions.size15,
          horizontalPadding,
          Dimensions.size10,
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
                  color: AppColors.surface().withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(Dimensions.size25),
                  border: Border.all(
                    color: AppColors.outline().withValues(alpha: 0.18),
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
                    iconPill(
                      context: context,
                      icon: Icons.turn_left_rounded,
                      onTap: () {
                        if (BaseSettings.navigatorType ==
                            BaseNavigatorType.legacy) {
                          Navigators.pop();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    SizedBox(width: Dimensions.size10),
                    Expanded(
                      child: Text(
                        "signature".tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Dimensions.text16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          color: AppColors.onSurface(),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.size15,
                        vertical: Dimensions.size10,
                      ),
                      decoration: ShapeDecoration(
                        color: AppColors.surfaceContainerLowest(),
                        shape: SmoothRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.size15,
                          ),
                          smoothness: Dimensions.size1,
                          side: BorderSide(
                            color: AppColors.outline().withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: Dimensions.size15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: Dimensions.size10),
                          Text(
                            "Tanda Tangan",
                            style: TextStyle(
                              fontSize: Dimensions.text12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              color: AppColors.onSurface(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomGlassSaveBar(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          Dimensions.size10,
          horizontalPadding,
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
                padding: EdgeInsets.all(Dimensions.size10),
                decoration: BoxDecoration(
                  color: AppColors.surface().withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(Dimensions.size25),
                  border: Border.all(
                    color: AppColors.outline().withValues(alpha: 0.18),
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          clearSignature();
                        },
                        icon: const Icon(Icons.backspace_outlined),
                        label: Text("clear".tr().toUpperCase()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, Dimensions.size50),
                          shape: SmoothRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.size20),
                            smoothness: Dimensions.size1,
                          ),
                          side: BorderSide(
                            color: AppColors.outline().withValues(alpha: 0.30),
                          ),
                          foregroundColor: AppColors.onSurface(),
                          backgroundColor: AppColors.surfaceContainerLowest(),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final Uint8List? bytes = await exportSignature();

                            if (BaseSettings.navigatorType ==
                                BaseNavigatorType.legacy) {
                              Navigators.pop(result: bytes);
                            } else {
                              context.pop(bytes);
                            }
                          },
                          borderRadius:
                              BorderRadius.circular(Dimensions.size20),
                          child: Ink(
                            height: Dimensions.size50,
                            decoration: ShapeDecoration(
                              color: primary,
                              shadows: [
                                BoxShadow(
                                  blurRadius: Dimensions.size20,
                                  offset: Offset(0, Dimensions.size10),
                                  color: Colors.black.withValues(alpha: 0.16),
                                ),
                              ],
                              shape: SmoothRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Dimensions.size20),
                                smoothness: Dimensions.size1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: Dimensions.size30,
                                  height: Dimensions.size30,
                                  decoration: BoxDecoration(
                                    color: onPrimary.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.save_rounded,
                                    size: Dimensions.size15,
                                    color: onPrimary,
                                  ),
                                ),
                                SizedBox(width: Dimensions.size10),
                                Text(
                                  "save".tr().toUpperCase(),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget signatureCanvas(BuildContext context) {
    return sectionCard(
      context: context,
      padding: EdgeInsets.all(Dimensions.size10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double canvasHeight = math.min(
            math.max(constraints.maxWidth * 0.7, 260),
            520,
          );
          _signatureSize = Size(constraints.maxWidth, canvasHeight);

          return Container(
            width: double.infinity,
            height: canvasHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest(),
              border: Border.all(
                color: AppColors.outline().withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(Dimensions.size15),
            ),
            clipBehavior: Clip.antiAlias,
            child: MouseRegion(
              cursor: SystemMouseCursors.precise,
              child: GestureDetector(
                onPanStart: (details) {
                  addPoint(details.localPosition);
                },
                onPanUpdate: (details) {
                  addPoint(details.localPosition);
                },
                onPanEnd: (_) {
                  endStroke();
                },
                onPanCancel: endStroke,
                child: CustomPaint(
                  painter: _SignatureGuidePainter(
                    lineColor: AppColors.outline().withValues(alpha: 0.18),
                  ),
                  foregroundPainter: _SignatureCanvasPainter(
                    points: List<Offset?>.of(_points),
                    strokeColor: AppColors.onSurface(),
                  ),
                  child: Stack(
                    children: [
                      if (!hasSignature)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(Dimensions.size20),
                            child: Text(
                              "Tanda tangani di area ini",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.onSurface()
                                    .withValues(alpha: 0.42),
                                fontWeight: FontWeight.w800,
                                fontSize: Dimensions.text13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget hint(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.size10),
      child: sectionCard(
        context: context,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size15,
          vertical: Dimensions.size15,
        ),
        child: Row(
          children: [
            Container(
              width: Dimensions.size30,
              height: Dimensions.size30,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.gesture_rounded,
                size: Dimensions.size20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: Dimensions.size10),
            Expanded(
              child: Text(
                "Silakan tanda tangan pada area di bawah, lalu tekan SIMPAN.",
                style: TextStyle(
                  color: AppColors.onSurface().withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontSize: Dimensions.text12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest(),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                safe.top + (Dimensions.size10 + Dimensions.size70),
                horizontalPadding,
                safe.bottom + (Dimensions.size10 + Dimensions.size90),
              ),
              child: DotResponsive.centered(
                context: context,
                tablet: 900,
                desktop: 980,
                child: Column(
                  children: [
                    hint(context),
                    signatureCanvas(context),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: glassTopbar(context),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bottomGlassSaveBar(context),
          ),
        ],
      ),
    );
  }
}

class _SignatureCanvasPainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;

  const _SignatureCanvasPainter({
    required this.points,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (int i = 0; i < points.length; i++) {
      final Offset? current = points[i];

      if (current == null) {
        continue;
      }

      final Offset? next = i + 1 < points.length ? points[i + 1] : null;

      if (next != null) {
        canvas.drawLine(current, next, paint);
      } else {
        canvas.drawPoints(
          ui.PointMode.points,
          <Offset>[current],
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureCanvasPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.points.length != points.length ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class _SignatureGuidePainter extends CustomPainter {
  final Color lineColor;

  const _SignatureGuidePainter({
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double gap = math.max(size.height / 3, 70);

    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(
        Offset(Dimensions.size15, y),
        Offset(size.width - Dimensions.size15, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureGuidePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
