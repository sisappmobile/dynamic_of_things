const String offlineMapBaseFolder = "offline_maps";

bool get supportsOfflineMapStorage => false;

Future<String?> getOfflineMapStoragePath() async {
  return null;
}

Future<double?> getOfflineMapMinZoom({
  required String baseMap,
}) async {
  return null;
}
