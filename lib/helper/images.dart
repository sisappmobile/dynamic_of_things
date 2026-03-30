import "dart:typed_data";

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
    Uint8List watermarkedBytes = source;

    const List<Offset> outlineOffsets = <Offset>[
      Offset(0, 0),
      Offset(1, 0),
      Offset(2, 0),
      Offset(0, 1),
      Offset(2, 1),
      Offset(0, 2),
      Offset(1, 2),
      Offset(2, 2),
    ];

    for (final Offset offset in outlineOffsets) {
      watermarkedBytes = await ImageWatermark.addTextWatermark(
        imgBytes: watermarkedBytes,
        watermarkText: text,
        dstX: offset.dx.toInt(),
        dstY: offset.dy.toInt(),
        color: Colors.black,
      );
    }

    return ImageWatermark.addTextWatermark(
      imgBytes: watermarkedBytes,
      watermarkText: text,
      dstX: 1,
      dstY: 1,
      color: Colors.white,
    );
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

        Uint8List? watermarkedBytes = await Images.textWatermark(
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
