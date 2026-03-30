import "dart:math" as math;
import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/material.dart";

Future<Uint8List?> exportSignaturePng({
  required List<Offset?> points,
  required Size size,
  required Color backgroundColor,
  required Color strokeColor,
  double strokeWidth = 2.8,
}) async {
  if (size.width <= 0 || size.height <= 0) {
    return null;
  }

  final int width = math.max(size.width.ceil(), 1);
  final int height = math.max(size.height.ceil(), 1);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Paint backgroundPaint = Paint()..color = backgroundColor;

  canvas.drawRect(
    Offset.zero & Size(width.toDouble(), height.toDouble()),
    backgroundPaint,
  );

  final Paint paint = Paint()
    ..color = strokeColor
    ..strokeWidth = strokeWidth
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

  final ui.Image image = await recorder.endRecording().toImage(
        width,
        height,
      );
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  image.dispose();

  if (byteData == null) {
    return null;
  }

  return byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
}
