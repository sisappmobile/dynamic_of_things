import "dart:io";

import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

const String offlineMapBaseFolder = "offline_maps";

bool get supportsOfflineMapStorage => true;

Future<String?> getOfflineMapStoragePath() async {
  final Directory baseDirectory = await getApplicationDocumentsDirectory();

  return baseDirectory.path;
}

Future<double?> getOfflineMapMinZoom({
  required String baseMap,
}) async {
  final String? storagePath = await getOfflineMapStoragePath();

  if (storagePath == null) {
    return null;
  }

  try {
    final List<double> zoomVarieties = Directory(
      "$storagePath/$offlineMapBaseFolder/$baseMap",
    )
        .listSync()
        .whereType<Directory>()
        .map((directory) => double.tryParse(p.basename(directory.path)))
        .whereType<double>()
        .toList()
      ..sort();

    if (zoomVarieties.isEmpty) {
      return null;
    }

    return zoomVarieties.first;
  } catch (_) {
    return null;
  }
}
