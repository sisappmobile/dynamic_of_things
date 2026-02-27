import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";

class LocalDiskTileProvider extends TileProvider {
  final String basePath;

  LocalDiskTileProvider({required this.basePath});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final path =
        "$basePath/${coordinates.z}/${coordinates.x}/${coordinates.y}.png";
    final file = File(path);

    if (file.existsSync()) {
      return FileImage(file);
    }

    return const NetworkImage("https://via.placeholder.com/256?text=Kosong");
  }
}
