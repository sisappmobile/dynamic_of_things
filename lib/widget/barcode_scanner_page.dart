// ignore_for_file: deprecated_member_use, constant_identifier_names

import "package:base/base.dart";
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

class BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: popHandle,
          icon: const Icon(
            Icons.turn_left_rounded,
            color: Colors.white,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              "Barcode Scanner".tr(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: Dimensions.text16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Dimensions.size5),
            StatusPill(
              icon: Icons.text_fields_rounded,
              label: scannerWordCase.spell(),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC0B0F1A),
                Color(0x000B0F1A),
              ],
            ),
          ),
        ),
      ),
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
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
              child: AspectRatio(
                aspectRatio: 1,
                child: ScanFrame(isActive: isScanning),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: (media.padding.bottom) + 110,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
              child: Column(
                children: [
                  Text(
                    "point_the_camera_at_a_barcode".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: Dimensions.text14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: Dimensions.size5),
                  Text(
                    "use_the_buttons_below_for_case_flash_and_camera".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: Dimensions.text12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: Dimensions.size15,
            right: Dimensions.size15,
            bottom: (media.padding.bottom) + Dimensions.size15,
            child: SolidBar(
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
                  SizedBox(width: Dimensions.size10),
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
                  SizedBox(width: Dimensions.size10),
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
        ],
      ),
    );
  }
}

class SolidBar extends StatelessWidget {
  final Widget child;
  const SolidBar({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.size10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.size20),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: Dimensions.size1,
        ),
      ),
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
        borderRadius: BorderRadius.circular(Dimensions.size15),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size10,
            vertical: Dimensions.size10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(Dimensions.size15),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: Dimensions.size1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                ),
                child: Icon(icon, color: Colors.white, size: Dimensions.size20),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: Dimensions.size2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  const StatusPill({
    required this.icon,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F1A).withOpacity(0.55),
        borderRadius: BorderRadius.circular(Dimensions.size100),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
          width: Dimensions.size1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: Dimensions.size15,
            color: Colors.white.withOpacity(0.92),
          ),
          SizedBox(width: Dimensions.size5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanFrame extends StatelessWidget {
  final bool isActive;

  const ScanFrame({required this.isActive, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F1A).withOpacity(0.18),
              borderRadius: BorderRadius.circular(Dimensions.size25),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: Dimensions.size1,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.size15),
            child: CustomPaint(
              painter: CornerPainter(
                color: Colors.white.withOpacity(0.95),
                strokeWidth: Dimensions.size4,
                radius: Dimensions.size20,
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
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double len = 36;

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
