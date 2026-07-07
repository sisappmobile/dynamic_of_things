import "dart:io";

import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:path/path.dart" as path;

class FileDownloads {
  static Future<String?> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.any,
      );

      return fileName;
    }

    if (Platform.isIOS) {
      return FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.any,
      );
    }

    final String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath == null) {
      return null;
    }

    final String filePath = await _availableFilePath(
      directoryPath: directoryPath,
      fileName: fileName,
    );

    await File(filePath).writeAsBytes(bytes);

    return filePath;
  }

  static Future<String> _availableFilePath({
    required String directoryPath,
    required String fileName,
  }) async {
    String currentFileName = fileName;
    String filePath = path.join(directoryPath, currentFileName);
    int count = 1;

    while (await File(filePath).exists()) {
      currentFileName = "$count-$fileName";
      filePath = path.join(directoryPath, currentFileName);
      count++;
    }

    return filePath;
  }

  static void showSuccessSnackBar(
    BuildContext context, {
    required String location,
  }) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("file_has_been_successfully_downloaded".tr()),
              Text(location),
            ],
          ),
          duration: const Duration(milliseconds: 2000),
        ),
      );
    });
  }
}
