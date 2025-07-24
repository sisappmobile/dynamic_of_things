// ignore_for_file: always_specify_types, use_build_context_synchronously, always_put_required_named_parameters_first, cascade_invocations

import "dart:io";

import "package:base/base.dart";
import "package:camera/camera.dart";
import "package:dynamic_of_things/helper/images.dart";
import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";

class Dialogs {
  static Future<void> image({
    required BuildContext context,
    required String title,
    required bool multiple,
    required bool allowGallery,
    required void Function(List<XFile> files) callback,
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
                          List<XFile> xFiles = await ImagePicker().pickMultiImage(
                            imageQuality: 20,
                          );

                          if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                            Navigators.pop();
                          } else {
                            context.pop();
                          }

                          callback.call(xFiles);
                        } else {
                          XFile? xFile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 20,
                          );

                          if (xFile != null) {
                            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                              Navigators.pop();
                            } else {
                              context.pop();
                            }

                            callback.call([xFile]);
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
                            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                              Navigators.pop();
                            } else {
                              context.pop();
                            }

                            callback.call([
                              XFile.fromData(
                                bytes,
                                name: "${DateTime.now().millisecondsSinceEpoch.toString()}.png",
                                mimeType: "png",
                              ),
                            ]);
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
          if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
            Navigators.pop();
          } else {
            context.pop();
          }

          callback.call([
            XFile.fromData(
              bytes,
              name: "${DateTime.now().millisecondsSinceEpoch.toString()}.png",
              mimeType: "png",
            ),
          ]);
        },
      );
    }
  }

  static Future<void> video({
    required BuildContext context,
    required String title,
    required bool allowGallery,
    required void Function(List<PlatformFile> files) callback,
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
                          if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                            Navigators.pop();
                          } else {
                            context.pop();
                          }

                          callback.call(filePickerResult.files);
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
                                if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                                  Navigators.pop();
                                } else {
                                  context.pop();
                                }

                                callback.call([
                                  PlatformFile(
                                    path: xFile.path,
                                    name: xFile.name,
                                    size: await xFile.length(),
                                  ),
                                ]);
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
              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                Navigators.pop();
              } else {
                context.pop();
              }

              callback.call([
                PlatformFile(
                  path: xFile.path,
                  name: xFile.name,
                  size: await xFile.length(),
                ),
              ]);
            },
          ),
        );
      });
    }
  }
}
