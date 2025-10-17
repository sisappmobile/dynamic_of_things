// ignore_for_file: always_specify_types, use_build_context_synchronously, cascade_invocations, always_put_required_named_parameters_first, constant_identifier_names, avoid_print

import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:photo_view/photo_view.dart";
import "package:video_player/video_player.dart";

class BottomSheets {
  static Future<dynamic> popupMenu({
    required BuildContext context,
    required List<MenuItem> menuItems,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: Dimensions.size10,
              ),
              IconButton(
                onPressed: () async {
                  if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                    Navigators.pop();
                  } else {
                    context.pop();
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer(),
                ),
                color: AppColors.primary(),
                icon: const Icon(
                  Icons.close,
                ),
              ),
              SizedBox(
                height: Dimensions.size10,
              ),
              ListView.separated(
                shrinkWrap: true,
                itemCount: menuItems.length,
                separatorBuilder: (context, index) {
                  return Divider(
                    color: AppColors.outline(),
                    thickness: 0.5,
                    height: 0,
                    indent: Dimensions.size20,
                  );
                },
                itemBuilder: (context, index) {
                  MenuItem menuItem = menuItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Dimensions.size20,
                      vertical: Dimensions.size5,
                    ),
                    onTap: menuItem.onTap,
                    leading: menuItem.iconData != null ? Icon(
                      menuItem.iconData,
                      color: menuItem.onTap != null ? AppColors.onSurface() : AppColors.onSurface().withOpacity(0.3),
                    ) : null,
                    title: Text(
                      menuItem.title,
                      style: TextStyle(
                        color: menuItem.onTap != null ? AppColors.onSurface() : AppColors.onSurface().withOpacity(0.3),
                        fontWeight: FontWeight.bold,
                        fontSize: Dimensions.text16,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void imagePreview({
    required BuildContext context,
    required ImageProvider imageProvider,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Material(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.04,
                ),
                child: Scaffold(
                  appBar: AppBar(
                    centerTitle: true,
                    title: Text("common_view_image".tr()),
                  ),
                  body: PhotoView(
                    imageProvider: imageProvider,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void videoPreview({
    required BuildContext context,
    required Uint8List bytes,
  }) async {
    File file = await CustomAttachments.temporarySave(fileName: "video-preview", bytes: bytes);

    VideoPlayerController videoPlayerController = VideoPlayerController.file(file);

    await videoPlayerController.initialize();
    await videoPlayerController.setLooping(true);
    await videoPlayerController.play();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Material(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.04,
                ),
                child: Scaffold(
                  appBar: AppBar(
                    centerTitle: true,
                    title: Text("common_view_video".tr()),
                  ),
                  body: Center(
                    child: AspectRatio(
                      aspectRatio: videoPlayerController.value.aspectRatio,
                      child: VideoPlayer(videoPlayerController),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await videoPlayerController.dispose();
  }
}
