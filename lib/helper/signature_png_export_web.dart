// ignore_for_file: avoid_web_libraries_in_flutter, cascade_invocations

import "dart:convert";
import "dart:html" as html;
import "dart:math" as math;
import "dart:typed_data";

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
  final html.CanvasElement canvas = html.CanvasElement(
    width: width,
    height: height,
  );
  final html.CanvasRenderingContext2D context = canvas.context2D;

  context.fillStyle = rgbaString(backgroundColor);
  context.fillRect(0, 0, width.toDouble(), height.toDouble());
  context.strokeStyle = rgbaString(strokeColor);
  context.fillStyle = rgbaString(strokeColor);
  context.lineCap = "round";
  context.lineJoin = "round";
  context.lineWidth = strokeWidth;
  context.imageSmoothingEnabled = true;

  for (int i = 0; i < points.length; i++) {
    final Offset? current = points[i];

    if (current == null) {
      continue;
    }

    final Offset? next = i + 1 < points.length ? points[i + 1] : null;

    if (next != null) {
      context
        ..beginPath()
        ..moveTo(current.dx, current.dy)
        ..lineTo(next.dx, next.dy)
        ..stroke();
    } else {
      context
        ..beginPath()
        ..arc(
          current.dx,
          current.dy,
          strokeWidth / 2,
          0,
          math.pi * 2,
        )
        ..fill();
    }
  }

  final String dataUrl = canvas.toDataUrl("image/png");
  final int commaIndex = dataUrl.indexOf(",");

  if (commaIndex < 0) {
    return null;
  }

  return base64Decode(dataUrl.substring(commaIndex + 1));
}

String rgbaString(Color color) {
  return "rgba(${color.red}, ${color.green}, ${color.blue}, "
      "${(color.alpha / 255).toStringAsFixed(3)})";
}
