import "dart:typed_data";
import "dart:ui" as ui;

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:camera/camera.dart";
import "package:dynamic_of_things/helper/generals.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:image_watermark/image_watermark.dart";

class Images {
  static Future<Uint8List?> textWatermark({
    required Uint8List source,
    required String text,
    required double fontSize,
    required double width,
    required double height,
  }) async {
    final recorder = ui.PictureRecorder();

    var canvas = Canvas(recorder);

    TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            backgroundColor: Colors.black,
            fontSize: Dimensions.text20,
          ),
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    )
      ..layout(maxWidth: width)
      ..paint(canvas, const Offset(0, 0));

    final picture = recorder.endRecording();

    var res = await picture.toImage(width.round(), textPainter.height.round());

    ByteData? data = await res.toByteData(format: ui.ImageByteFormat.png);

    if (data != null) {
      Uint8List watermarkedBytes = await ImageWatermark.addImageWatermark(
        originalImageBytes: source,
        waterkmarkImageBytes: Uint8List.view(data.buffer),
        imgWidth: width.round(),
        imgHeight: textPainter.height.round(),
        dstX: 0,
        dstY: 0,
      );

      return watermarkedBytes;
    } else {
      return null;
    }
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
        Uint8List bytesFile = Uint8List.fromList(
          await xFile.readAsBytes(),
        );

        var decodedImage = await decodeImageFromList(bytesFile);

        String watermark = DateTime.now().toString();

        String? placemark = await Generals.lastPlacemarkPosition();

        if (StringUtils.isNotNullOrEmpty(placemark)) {
          watermark += " • $placemark";
        }

        Uint8List? watermarkedBytes =  await Images.textWatermark(
          source: bytesFile,
          text: watermark,
          fontSize: decodedImage.width * 0.03,
          width: decodedImage.width.toDouble(),
          height: decodedImage.height.toDouble(),
        );

        if (watermarkedBytes != null) {
          callback.call(watermarkedBytes);
        }
      }
    } else {
      await availableCameras().then((value) {
        Navigators.push(
          CameraPage(
            cameraDescriptions: value,
            callback: callback,
          ),
        );
      });
    }
  }
}
