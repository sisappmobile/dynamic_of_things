// ignore_for_file: deprecated_member_use, constant_identifier_names

import "dart:ui";

import "package:base/base.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:mobile_scanner/mobile_scanner.dart";

enum ScannerWordCase {
  UPPER_CASE,
  LOWER_CASE,
  NORMAL_CASE;

  String spell() {
    if (this == ScannerWordCase.NORMAL_CASE) {
      return "Normal Case";
    } else if (this == ScannerWordCase.UPPER_CASE) {
      return "UPPER CASE";
    } else {
      return "lower case";
    }
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final bool silent;
  final void Function(String data) onSuccess;
  final List<BarcodeFormat>? formats;

  const BarcodeScannerPage({
    required this.silent,
    required this.onSuccess,
    this.formats,
    super.key,
  });

  @override
  BarcodeScannerPageState createState() => BarcodeScannerPageState();
}

class BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController cameraController;

  ScannerWordCase scannerWordCase = ScannerWordCase.NORMAL_CASE;

  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(formats: widget.formats ?? []);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> torchToggle() async {
    await cameraController.toggleTorch();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> cameraSwitch() async {
    await cameraController.switchCamera();
    if (mounted) {
      setState(() {});
    }
  }

  void cycleWordCase() {
    if (scannerWordCase == ScannerWordCase.NORMAL_CASE) {
      scannerWordCase = ScannerWordCase.UPPER_CASE;
    } else if (scannerWordCase == ScannerWordCase.UPPER_CASE) {
      scannerWordCase = ScannerWordCase.LOWER_CASE;
    } else {
      scannerWordCase = ScannerWordCase.NORMAL_CASE;
    }
    setState(() {});
  }

  void popHandle() {
    if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
      Navigators.pop();
    } else {
      context.pop();
    }
  }

  Future<void> resumeScanning() async {
    try {
      await cameraController.start();
    } catch (_) {}
    if (mounted) {
      setState(() => isScanning = true);
    }
  }

  double scannerMaxWidth(DotScreenType screenType) {
    switch (screenType) {
      case DotScreenType.mobile:
        return 320;
      case DotScreenType.tablet:
        return 460;
      case DotScreenType.desktop:
        return 540;
    }
  }

  double scannerAspectRatio(DotScreenType screenType) {
    switch (screenType) {
      case DotScreenType.mobile:
        return 1.0;
      case DotScreenType.tablet:
        return 1.28;
      case DotScreenType.desktop:
        return 1.42;
    }
  }

  double dockMaxWidth(DotScreenType screenType) {
    switch (screenType) {
      case DotScreenType.mobile:
        return 520;
      case DotScreenType.tablet:
        return 640;
      case DotScreenType.desktop:
        return 720;
    }
  }

  Widget chromeButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FrostPanel(
      radius: 18,
      padding: EdgeInsets.zero,
      opacity: 0.16,
      borderOpacity: 0.16,
      blur: 18,
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: Icon(
            icon,
            color: Colors.white.withOpacity(0.95),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget topChrome(DotScreenType screenType) {
    final bool isMobile = screenType == DotScreenType.mobile;

    if (isMobile) {
      return FrostPanel(
        radius: Dimensions.size25,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size10,
          vertical: 8,
        ),
        opacity: 0.14,
        borderOpacity: 0.14,
        blur: 22,
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              chromeButton(
                icon: Icons.turn_left_rounded,
                onTap: popHandle,
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Text(
                  "Barcode Scanner".tr(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.97),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(width: 42),
            ],
          ),
        ),
      );
    }

    return FrostPanel(
      radius: Dimensions.size30,
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size10,
      ),
      opacity: 0.14,
      borderOpacity: 0.14,
      blur: 22,
      child: SizedBox(
        height: Dimensions.size45,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: chromeButton(
                icon: Icons.turn_left_rounded,
                onTap: popHandle,
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 78 : 108,
                ),
                child: Text(
                  "Barcode Scanner".tr(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: Dimensions.text18,
                    color: Colors.white.withOpacity(0.97),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: StatusPill(
                icon: Icons.text_fields_rounded,
                label: scannerWordCase.spell(),
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget scannerStage(
    DotScreenType screenType, {
    bool compactHeight = false,
  }) {
    final bool isMobile = screenType == DotScreenType.mobile;
    final double maxWidth = compactHeight && !isMobile
        ? scannerMaxWidth(screenType) - 40
        : scannerMaxWidth(screenType);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      child: FrostPanel(
        radius: isMobile ? Dimensions.size30 : Dimensions.size35,
        padding:
            EdgeInsets.all(isMobile ? Dimensions.size10 : Dimensions.size15),
        opacity: 0.08,
        borderOpacity: 0.14,
        blur: Dimensions.size25,
        child: AspectRatio(
          aspectRatio: scannerAspectRatio(screenType),
          child: ScanFrame(
            isActive: isScanning,
            wide: screenType != DotScreenType.mobile,
          ),
        ),
      ),
    );
  }

  Widget instructionCard(
    DotScreenType screenType, {
    bool compactHeight = false,
  }) {
    final bool isMobile = screenType == DotScreenType.mobile;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? 320 : 380,
      ),
      child: FrostPanel(
        radius: isMobile ? Dimensions.size20 : 24,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? Dimensions.size15 : Dimensions.size20,
          vertical: compactHeight ? Dimensions.size10 : 12,
        ),
        opacity: 0.16,
        borderOpacity: 0.12,
        blur: Dimensions.size20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "point_the_camera_at_a_barcode".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.94),
                fontSize: isMobile ? Dimensions.text13 : Dimensions.text13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "use_the_buttons_below_for_case_flash_and_camera".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: isMobile ? Dimensions.text11 : Dimensions.text12,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget controlDivider() {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(vertical: Dimensions.size10),
      color: Colors.white.withOpacity(0.10),
    );
  }

  Widget controlDock(DotScreenType screenType) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: dockMaxWidth(screenType),
      ),
      child: SolidBar(
        radius: screenType == DotScreenType.mobile ? 28 : 32,
        padding: EdgeInsets.symmetric(
          horizontal: screenType == DotScreenType.mobile ? 8 : 12,
          vertical: screenType == DotScreenType.mobile ? Dimensions.size10 : 12,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: ActionTile(
                  icon: Symbols.match_case,
                  title: "Case",
                  subtitle: scannerWordCase.spell(),
                  onTap: cycleWordCase,
                ),
              ),
              controlDivider(),
              Expanded(
                child: ActionTile(
                  icon: cameraController.torchEnabled
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  title: "Flash".tr(),
                  subtitle: cameraController.torchEnabled ? "On" : "Off",
                  onTap: torchToggle,
                ),
              ),
              controlDivider(),
              Expanded(
                child: ActionTile(
                  icon: cameraController.facing == CameraFacing.front
                      ? Icons.camera_front_rounded
                      : Icons.camera_rear_rounded,
                  title: "Camera".tr(),
                  subtitle: cameraController.facing == CameraFacing.front
                      ? "Front".tr()
                      : "Rear".tr(),
                  onTap: cameraSwitch,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final DotScreenType screenType = DotResponsive.sizeOf(context);
    final double horizontalPadding = DotResponsive.horizontalPadding(
      context,
      mobile: 15,
      tablet: 24,
      desktop: 32,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                cameraController.stop();
                isScanning = false;

                final List<Barcode> barcodes = capture.barcodes;

                if (barcodes.isNotEmpty) {
                  String data = barcodes[0].rawValue ?? "";

                  if (scannerWordCase == ScannerWordCase.UPPER_CASE) {
                    data = data.toUpperCase();
                  } else if (scannerWordCase == ScannerWordCase.LOWER_CASE) {
                    data = data.toLowerCase();
                  }

                  popHandle();

                  if (!widget.silent) {
                    BaseOverlays.success(
                      message: "barcode_scanner_success_dialog".tr(),
                    );
                  }

                  widget.onSuccess(data);
                } else {
                  resumeScanning();
                }
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.72),
                    ],
                    stops: const [0, 0.35, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: screenType == DotScreenType.desktop ? 0.9 : 1.08,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Dimensions.size10,
                horizontalPadding,
                Dimensions.size10,
              ),
              child: DotResponsive.centered(
                context: context,
                tablet: 860,
                desktop: 1120,
                child: Column(
                  children: [
                    topChrome(screenType),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool compactHeight =
                              constraints.maxHeight < 560;
                          final double spacing = compactHeight
                              ? Dimensions.size10
                              : Dimensions.size20;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  scannerStage(
                                    screenType,
                                    compactHeight: compactHeight,
                                  ),
                                  SizedBox(height: spacing),
                                  instructionCard(
                                    screenType,
                                    compactHeight: compactHeight,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: Dimensions.size15),
                    controlDock(screenType),
                    SizedBox(height: media.padding.bottom > 0 ? 0 : 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FrostPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double opacity;
  final double borderOpacity;
  final double blur;

  const FrostPanel({
    required this.child,
    required this.radius,
    required this.padding,
    required this.opacity,
    required this.borderOpacity,
    required this.blur,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F1A).withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: Dimensions.size1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SolidBar extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const SolidBar({
    required this.child,
    required this.radius,
    required this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FrostPanel(
      radius: radius,
      padding: padding,
      opacity: 0.18,
      borderOpacity: 0.14,
      blur: 26,
      child: child,
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.size20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: Dimensions.size5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.95),
                  size: Dimensions.size20,
                ),
              ),
              SizedBox(height: Dimensions.size10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: Dimensions.text11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: Dimensions.size2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: Dimensions.text11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const StatusPill({
    required this.icon,
    required this.label,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FrostPanel(
      radius: Dimensions.size100,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Dimensions.size10 : 12,
        vertical: compact ? 8 : 6,
      ),
      opacity: 0.16,
      borderOpacity: 0.14,
      blur: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 13 : Dimensions.size15,
            color: Colors.white.withOpacity(0.92),
          ),
          SizedBox(width: Dimensions.size5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: compact ? Dimensions.text11 : Dimensions.text12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanFrame extends StatelessWidget {
  final bool isActive;
  final bool wide;

  const ScanFrame({
    required this.isActive,
    required this.wide,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.size30),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.09),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(Dimensions.size30),
                border: Border.all(
                  color: Colors.white.withOpacity(isActive ? 0.16 : 0.10),
                  width: Dimensions.size1,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: Dimensions.size30,
                    color: Colors.black.withOpacity(0.18),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding:
                EdgeInsets.all(wide ? Dimensions.size20 : Dimensions.size15),
            child: CustomPaint(
              painter: CornerPainter(
                color: Colors.white.withOpacity(0.92),
                strokeWidth: 2.4,
                radius: 18,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: wide ? 0.72 : 0.82,
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isActive ? 0.24 : 0.12),
                borderRadius: BorderRadius.circular(Dimensions.size100),
                boxShadow: [
                  BoxShadow(
                    blurRadius: Dimensions.size15,
                    color: Colors.white.withOpacity(isActive ? 0.14 : 0.08),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double len = 28;

    canvas
      ..drawPath(
        Path()
          ..moveTo(radius, 0)
          ..lineTo(len, 0)
          ..moveTo(0, radius)
          ..lineTo(0, len),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(size.width - radius, 0)
          ..lineTo(size.width - len, 0)
          ..moveTo(size.width, radius)
          ..lineTo(size.width, len),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(radius, size.height)
          ..lineTo(len, size.height)
          ..moveTo(0, size.height - radius)
          ..lineTo(0, size.height - len),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(size.width - radius, size.height)
          ..lineTo(size.width - len, size.height)
          ..moveTo(size.width, size.height - radius)
          ..lineTo(size.width, size.height - len),
        p,
      );
  }

  @override
  bool shouldRepaint(covariant CornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
