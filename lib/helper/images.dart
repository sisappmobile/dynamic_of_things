import "dart:math" as math;
import "dart:typed_data";

import "package:base/base.dart";
import "package:camera/camera.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:geocoding/geocoding.dart";
import "package:image/image.dart" as img;
import "package:image_picker/image_picker.dart";

class Images {
  static String _cameraWatermarkTimestamp(DateTime value) {
    return DateFormat("dd MMMM yyyy : HH:mm.ss", "id").format(value);
  }

  static String _cameraWatermarkCoordinate(double? value) {
    if (value == null) {
      return "-";
    }

    return value.toStringAsFixed(6);
  }

  static String? _normalizedValue(String? value) {
    final String trimmed = (value ?? "").trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String? _cameraWatermarkAddress(Placemark placemark) {
    final List<String?> sourceParts = <String?>[
      _normalizedValue(placemark.street) ??
          _normalizedValue(
            [
              placemark.thoroughfare,
              placemark.subThoroughfare,
            ].whereType<String>().where((String item) => item.trim().isNotEmpty).join(" "),
          ) ??
          _normalizedValue(placemark.name),
      _normalizedValue(placemark.subLocality),
      _normalizedValue(placemark.locality),
      _normalizedValue(placemark.subAdministrativeArea),
      _normalizedValue(placemark.administrativeArea),
      _normalizedValue(placemark.postalCode),
      _normalizedValue(placemark.country),
    ];

    final List<String> parts = <String>[];
    final Set<String> unique = <String>{};

    for (final String? sourcePart in sourceParts) {
      if (sourcePart == null) {
        continue;
      }

      final String normalizedKey = sourcePart.toLowerCase();

      if (unique.contains(normalizedKey)) {
        continue;
      }

      unique.add(normalizedKey);
      parts.add(sourcePart);
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(", ");
  }

  static Future<String> _cameraWatermarkText() async {
    String coordinateLine = "Lat -, Long -";
    String? addressLine;

    try {
      final LongLat? longLat = await Locations.lastPosition();

      coordinateLine =
          "Lat ${_cameraWatermarkCoordinate(longLat?.latitude)}, Long ${_cameraWatermarkCoordinate(longLat?.longitude)}";

      if (longLat != null) {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          longLat.latitude,
          longLat.longitude,
        );

        if (placemarks.isNotEmpty) {
          addressLine = _cameraWatermarkAddress(placemarks.first);
        }
      }
    } catch (_) {}

    final List<String> lines = <String>[
      _cameraWatermarkTimestamp(DateTime.now()),
      coordinateLine,
    ];

    if (_normalizedValue(addressLine) != null) {
      lines.add(addressLine!);
    }

    return lines.join("\n");
  }

  static img.BitmapFont _watermarkFont(img.Image image) {
    if (image.width >= 1400) {
      return img.arial48;
    }

    if (image.width >= 700) {
      return img.arial24;
    }

    return img.arial14;
  }

  static int _measureTextWidth({
    required String text,
    required img.BitmapFont font,
  }) {
    int width = 0;

    for (final int codeUnit in text.codeUnits) {
      width += font.characterXAdvance(String.fromCharCode(codeUnit));
    }

    return width;
  }

  static List<String> _wrapTextLine({
    required String text,
    required img.BitmapFont font,
    required int maxWidth,
  }) {
    final String trimmed = text.trim();

    if (trimmed.isEmpty) {
      return <String>[];
    }

    if (_measureTextWidth(text: trimmed, font: font) <= maxWidth) {
      return <String>[trimmed];
    }

    final List<String> words =
        trimmed.split(RegExp(r"\s+")).where((String item) => item.isNotEmpty).toList();

    if (words.isEmpty) {
      return <String>[trimmed];
    }

    final List<String> lines = <String>[];
    String currentLine = "";

    for (final String word in words) {
      final String candidate =
          currentLine.isEmpty ? word : "$currentLine $word";

      if (_measureTextWidth(text: candidate, font: font) <= maxWidth) {
        currentLine = candidate;
        continue;
      }

      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }

      currentLine = word;
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.isEmpty ? <String>[trimmed] : lines;
  }

  static Future<Uint8List?> textWatermark({
    required Uint8List source,
    required String text,
  }) async {
    final img.Image? image = img.decodeImage(source);

    if (image == null) {
      return null;
    }

    final img.BitmapFont font = _watermarkFont(image);
    final List<String> lines = text
        .split("\n")
        .where((String line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return source;
    }

    final int padding = math.max(12, (image.width * 0.02).round());
    final int lineSpacing = math.max(6, (font.lineHeight * 0.25).round());
    final int maxTextWidth = math.max(
      1,
      image.width - (padding * 4),
    );
    final List<String> wrappedLines = <String>[];

    for (final String line in lines) {
      wrappedLines.addAll(
        _wrapTextLine(
          text: line,
          font: font,
          maxWidth: maxTextWidth,
        ),
      );
    }

    if (wrappedLines.isEmpty) {
      return source;
    }

    int maxLineWidth = 0;

    for (final String line in wrappedLines) {
      maxLineWidth = math.max(
        maxLineWidth,
        _measureTextWidth(
          text: line,
          font: font,
        ),
      );
    }

    final int boxWidth = math.min(
      image.width - (padding * 2),
      maxLineWidth + (padding * 2),
    );
    final int boxHeight =
        (padding * 2) +
        (font.lineHeight * wrappedLines.length) +
        (lineSpacing * (wrappedLines.length - 1));
    final int boxLeft = padding;
    final int boxTop = math.max(0, image.height - boxHeight - padding);
    final int boxRight = math.min(image.width - 1, boxLeft + boxWidth);
    final int boxBottom = math.min(image.height - 1, boxTop + boxHeight);

    img.fillRect(
      image,
      x1: boxLeft,
      y1: boxTop,
      x2: boxRight,
      y2: boxBottom,
      color: img.ColorRgba8(0, 0, 0, 170),
      radius: math.max(8, (image.width * 0.012).round()),
    );

    int cursorY = boxTop + padding;

    for (final String line in wrappedLines) {
      img.drawString(
        image,
        line,
        font: font,
        x: boxLeft + padding,
        y: cursorY,
        color: img.ColorRgb8(255, 255, 255),
      );

      cursorY += font.lineHeight + lineSpacing;
    }

    return Uint8List.fromList(
      img.encodePng(image),
    );
  }

  static Future<Uint8List> processCameraCaptureBytes(Uint8List bytes) async {
    final String watermark = await _cameraWatermarkText();
    final Uint8List? watermarkedBytes = await Images.textWatermark(
      source: bytes,
      text: watermark,
    );

    return watermarkedBytes ?? bytes;
  }

  static void camera({
    required BuildContext context,
    required void Function(Uint8List bytes) callback,
    bool legacy = false,
  }) async {
    if (legacy) {
      final XFile? xFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 20,
      );

      if (xFile != null) {
        final Uint8List bytesFile = Uint8List.fromList(
          await xFile.readAsBytes(),
        );

        callback.call(
          await processCameraCaptureBytes(bytesFile),
        );
      }
    } else {
      await availableCameras().then((value) {
        Navigators.push(
          _WatermarkedCameraPage(
            cameraDescriptions: value,
            callback: callback,
          ),
        );
      });
    }
  }
}

class _WatermarkedCameraPage extends StatefulWidget {
  final List<CameraDescription>? cameraDescriptions;
  final void Function(Uint8List bytes) callback;

  const _WatermarkedCameraPage({
    required this.cameraDescriptions,
    required this.callback,
  });

  @override
  State<_WatermarkedCameraPage> createState() => _WatermarkedCameraPageState();
}

class _WatermarkedCameraPageState extends State<_WatermarkedCameraPage> {
  bool holdCamera = false;
  int cameraIndex = 0;
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();
    cameraIndex = _initialCameraIndex();

    if ((widget.cameraDescriptions ?? <CameraDescription>[]).isNotEmpty) {
      initCamera(widget.cameraDescriptions![cameraIndex]);
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  int _initialCameraIndex() {
    final List<CameraDescription> cameras =
        widget.cameraDescriptions ?? <CameraDescription>[];

    final int rearIndex = cameras.indexWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.back,
    );

    return rearIndex >= 0 ? rearIndex : 0;
  }

  Future<void> initCamera(CameraDescription cameraDescription) async {
    final CameraController? previousController = cameraController;
    final CameraController nextController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    cameraController = nextController;

    try {
      await previousController?.dispose();
      await nextController.initialize();

      if (!mounted || cameraController != nextController) {
        await nextController.dispose();
        return;
      }

      try {
        await nextController.setFocusMode(FocusMode.auto);
      } on CameraException catch (e) {
        debugPrint("camera focus mode error $e");
      }

      try {
        await nextController.setExposureMode(ExposureMode.auto);
      } on CameraException catch (e) {
        debugPrint("camera exposure mode error $e");
      }

      setState(() {});
    } on CameraException catch (e) {
      debugPrint("camera error $e");
    }
  }

  Future<void> switchCamera() async {
    final List<CameraDescription> cameras =
        widget.cameraDescriptions ?? <CameraDescription>[];

    if (cameras.length <= 1 || holdCamera) {
      return;
    }

    cameraIndex = (cameraIndex + 1) % cameras.length;
    setState(() {});
    await initCamera(cameras[cameraIndex]);
  }

  Future<void> takePicture() async {
    final CameraController? controller = cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isTakingPicture || holdCamera) {
      return;
    }

    try {
      setState(() {
        holdCamera = true;
      });

      await controller.setFlashMode(FlashMode.off);

      final XFile xFile = await controller.takePicture();
      final Uint8List bytesFile = Uint8List.fromList(
        await xFile.readAsBytes(),
      );
      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(bytesFile);
      final Uint8List watermarkedBytes =
          await Images.processCameraCaptureBytes(compressedBytes);

      if (!mounted) {
        return;
      }

      Navigators.pushReplacement(
        _WatermarkedCameraPreviewPage(
          bytes: watermarkedBytes,
          cameraDescriptions: widget.cameraDescriptions,
          callback: widget.callback,
        ),
      );
    } on CameraException catch (e) {
      debugPrint("Error occured while taking picture: $e");
    } finally {
      if (mounted) {
        setState(() {
          holdCamera = false;
        });
      }
    }
  }

  Widget body() {
    final CameraController? controller = cameraController;

    if (controller != null && controller.value.isInitialized) {
      return CameraPreview(controller);
    }

    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSwitchCamera =
        (widget.cameraDescriptions ?? <CameraDescription>[]).length > 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            body(),
            Visibility(
              visible: holdCamera,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Text(
                    "hold_camera_position".tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.20,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  color: Colors.black,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 30,
                        icon: Icon(
                          canSwitchCamera
                              ? Icons.switch_camera
                              : Icons.camera_alt_outlined,
                          color: canSwitchCamera
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                        ),
                        onPressed: canSwitchCamera ? switchCamera : null,
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        onPressed: takePicture,
                        iconSize: 50,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatermarkedCameraPreviewPage extends StatelessWidget {
  final Uint8List bytes;
  final List<CameraDescription>? cameraDescriptions;
  final void Function(Uint8List bytes) callback;

  const _WatermarkedCameraPreviewPage({
    required this.bytes,
    required this.cameraDescriptions,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.20,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                color: Colors.black,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 30,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigators.pushReplacement(
                            _WatermarkedCameraPage(
                              cameraDescriptions: cameraDescriptions,
                              callback: callback,
                            ),
                          );
                        },
                      ),
                      Text(
                        "retake_photo".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: Dimensions.size30,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 30,
                        icon: const Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigators.pop();
                          callback.call(bytes);
                        },
                      ),
                      Text(
                        "use_this_photo".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
