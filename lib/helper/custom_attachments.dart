import "dart:io";

import "package:path_provider/path_provider.dart";

class CustomAttachments {
  static Future<String> path({
    required String fileId,
  }) async {
    Directory baseDirectory = await getApplicationDocumentsDirectory();

    return "${baseDirectory.path}/offline_files/$fileId";
  }

  static Future<String> temporaryPath({
    required String fileName,
  }) async {
    Directory baseDirectory = await getTemporaryDirectory();

    return "${baseDirectory.path}/$fileName";
  }

  static Future<File> save({
    required String id,
    required List<int> bytes,
  }) async {
    Directory baseDirectory = await getApplicationDocumentsDirectory();
    Directory offlineFileDirectory = Directory("${baseDirectory.path}/offline_files");

    if (!await offlineFileDirectory.exists()) {
      await offlineFileDirectory.create();
    }

    File file = File("${offlineFileDirectory.path}/$id");

    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<File> temporarySave({
    required String fileName,
    required List<int> bytes,
  }) async {
    Directory baseDirectory = await getTemporaryDirectory();

    File file = File("${baseDirectory.path}/$fileName");

    await file.writeAsBytes(bytes);

    return file;
  }
}
