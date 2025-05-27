// ignore_for_file: always_specify_types, use_build_context_synchronously, always_put_required_named_parameters_first, cascade_invocations

import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:camera/camera.dart";
import "package:dynamic_of_things/helper/images.dart";
import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

class Dialogs {
  static Future<void> image({
    required BuildContext context,
    required String title,
    required bool multiple,
    required bool allowGallery,
    required void Function(List<Uint8List> files) callback,
  }) async {
    if (allowGallery) {
      List<Widget> actions = [
        TextButton(
          child: Text("common_close".tr()),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

      BoxDecoration boxDecoration = BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      );

      await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return AlertDialog(
            title: Text("common_choose_photo_source".tr()),
            content: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: boxDecoration,
                    child: InkWell(
                      onTap: () async {
                        if (multiple) {
                          List<Uint8List> files = [];

                          List<XFile> xFiles = await ImagePicker().pickMultiImage(
                            imageQuality: 20,
                          );

                          for (XFile xFile in xFiles) {
                            Uint8List bytesFile = Uint8List.fromList(await xFile.readAsBytes());

                            files.add(
                              bytesFile,
                            );
                          }

                          Navigators.pop();

                          callback.call(files);
                        } else {
                          XFile? xFile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 20,
                          );

                          if (xFile != null) {
                            Uint8List bytesFile = Uint8List.fromList(await xFile.readAsBytes());

                            Navigators.pop();

                            callback.call([bytesFile]);
                          }
                        }
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [const Icon(Icons.photo), Text("common_gallery".tr())],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: Dimensions.size10,
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: boxDecoration,
                    child: InkWell(
                      onTap: () async {
                        Images.camera(
                            context: context,
                            callback: (bytes) {
                              Navigators.pop();

                              callback.call([bytes]);
                            },
                        );
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [const Icon(Icons.camera_alt), Text("common_camera".tr())],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: actions,
          );
        },
      );
    } else {
      Images.camera(
        context: context,
        callback: (bytes) {
          Navigators.pop();

          callback.call([bytes]);
        },
      );
    }
  }

  static Future<void> video({
    required BuildContext context,
    required String title,
    required bool allowGallery,
    required void Function(List<File> files) callback,
  }) async {
    if (allowGallery) {
      List<Widget> actions = [
        TextButton(
          child: Text("common_close".tr()),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

      BoxDecoration boxDecoration = BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      );

      await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return AlertDialog(
            title: Text("common_choose_video_source".tr()),
            content: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: boxDecoration,
                    child: InkWell(
                      onTap: () async {
                        FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
                          withData: true,
                          type: FileType.video,
                        );

                        if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
                          List<File> files = [];

                          for (PlatformFile platformFile in filePickerResult.files) {
                            files.add(
                              File(platformFile.path!),
                            );
                          }

                          Navigators.pop();

                          callback.call(files);
                        }
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [const Icon(Icons.photo), Text("common_gallery".tr())],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: Dimensions.size10,
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: boxDecoration,
                    child: InkWell(
                      onTap: () async {
                        await availableCameras().then((value) {
                          Navigators.push(
                            RecordPage(
                              cameraDescriptions: value,
                              callback: (xFile) async {
                                Navigators.pop();

                                callback.call([File(xFile.path)]);
                              },
                            ),
                          );
                        });
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [const Icon(Icons.camera_alt), Text("common_camera".tr())],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: actions,
          );
        },
      );
    } else {
      await availableCameras().then((value) {
        Navigators.push(
          RecordPage(
            cameraDescriptions: value,
            callback: (xFile) async {
              Navigators.pop();

              callback.call([File(xFile.path)]);
            },
          ),
        );
      });
    }
  }
}
