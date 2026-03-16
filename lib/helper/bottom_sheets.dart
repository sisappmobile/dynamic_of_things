// ignore_for_file: always_specify_types, use_build_context_synchronously, cascade_invocations, always_put_required_named_parameters_first, constant_identifier_names, avoid_print, deprecated_member_use

import "dart:io";
import "dart:typed_data";
import "dart:ui"; // Ditambahkan untuk efek BackdropFilter (Glass)

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart"; // Akses constant
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:dynamic_of_things/helper/preferences.dart"; // Akses preference isGlass
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:photo_view/photo_view.dart";
import "package:smooth_corner/smooth_corner.dart";
import "package:video_player/video_player.dart";

class BottomSheets {
  // Helper internal untuk mengecek apakah menggunakan tema Glass
  static bool _isGlass() {
    try {
      return (Preferences.getInstance()
                  .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
              1) ==
          2;
    } catch (_) {
      return false;
    }
  }

  static Future<dynamic> popupMenu({
    required BuildContext context,
    required List<MenuItem> menuItems,
  }) async {
    final bool glass = _isGlass();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Transparan agar efek glass terlihat
      barrierColor:
          Colors.black.withOpacity(0.40), // Backdrop sedikit lebih pekat
      builder: (context) {
        final Widget sheetContent = SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Dimensions.size15,
              Dimensions.size10,
              Dimensions.size15,
              Dimensions.size20 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: Dimensions.size40,
                  height: Dimensions.size5,
                  margin: EdgeInsets.only(bottom: Dimensions.size15),
                  decoration: BoxDecoration(
                    color: glass
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.onSurface().withOpacity(0.18),
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                  ),
                ),
                // Menu Items
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: menuItems.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: Dimensions.size10),
                    itemBuilder: (context, index) {
                      MenuItem menuItem = menuItems[index];
                      final bool enabled = menuItem.onTap != null;
                      final Color fgColor = enabled
                          ? (glass
                              ? Colors.white.withOpacity(0.95)
                              : AppColors.onSurface())
                          : (glass
                              ? Colors.white.withOpacity(0.35)
                              : AppColors.onSurface().withOpacity(0.35));

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: enabled
                              ? () {
                                  // POP dialog ini sebelum mengeksekusi aksi
                                  if (BaseSettings.navigatorType ==
                                      BaseNavigatorType.legacy) {
                                    Navigators.pop();
                                  } else {
                                    context.pop();
                                  }
                                  menuItem.onTap!();
                                }
                              : null,
                          borderRadius:
                              BorderRadius.circular(Dimensions.size15),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.size15,
                              vertical: Dimensions.size15,
                            ),
                            decoration: ShapeDecoration(
                              color: glass
                                  ? Colors.white.withOpacity(0.08)
                                  : AppColors.surfaceContainerLowest(),
                              shape: SmoothRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Dimensions.size15),
                                smoothness: Dimensions.size1,
                                side: BorderSide(
                                  color: glass
                                      ? Colors.white.withOpacity(0.18)
                                      : AppColors.outline().withOpacity(0.18),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (menuItem.iconData != null) ...[
                                  Icon(
                                    menuItem.iconData,
                                    color: fgColor,
                                    size: Dimensions.size20,
                                  ),
                                  SizedBox(width: Dimensions.size15),
                                ],
                                Expanded(
                                  child: Text(
                                    menuItem.title,
                                    style: TextStyle(
                                      color: fgColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: Dimensions.text14,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                                if (enabled)
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: fgColor.withOpacity(0.4),
                                    size: Dimensions.size20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Cancel Button (Menggantikan IconButton X kuno)
                SizedBox(height: Dimensions.size15),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (BaseSettings.navigatorType ==
                          BaseNavigatorType.legacy) {
                        Navigators.pop();
                      } else {
                        context.pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    child: Ink(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: Dimensions.size15),
                      decoration: ShapeDecoration(
                        color: glass
                            ? Colors.white.withOpacity(0.12)
                            : AppColors.surface(),
                        shape: SmoothRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.size15),
                          smoothness: Dimensions.size1,
                          side: BorderSide(
                            color: glass
                                ? Colors.white.withOpacity(0.25)
                                : AppColors.outline().withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "cancel".tr(),
                          style: TextStyle(
                            color: glass
                                ? Colors.white.withOpacity(0.95)
                                : AppColors.onSurface(),
                            fontWeight: FontWeight.w900,
                            fontSize: Dimensions.text14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (glass) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.size30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: Dimensions.size20,
                sigmaY: Dimensions.size20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F1A).withOpacity(0.40),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                ),
                child: sheetContent,
              ),
            ),
          );
        }

        return Container(
          decoration: ShapeDecoration(
            color: AppColors.surface(),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Dimensions.size30),
              ),
              smoothness: Dimensions.size1,
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: Dimensions.size20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: sheetContent,
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
      backgroundColor: Colors.transparent, // Background tembus pandang
      builder: (context) {
        return Scaffold(
          backgroundColor:
              Colors.black, // Dark mode immersif untuk preview media
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.4), // Semi-transparan
            elevation: 0,
            centerTitle: true,
            title: Text(
              "common_view_image".tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: Dimensions.text16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                  Navigators.pop();
                } else {
                  context.pop();
                }
              },
            ),
          ),
          body: PhotoView(
            imageProvider: imageProvider,
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }

  static void videoPreview({
    required BuildContext context,
    required Uint8List bytes,
  }) async {
    File file = await CustomAttachments.temporarySave(
      fileName: "video-preview",
      bytes: bytes,
    );

    VideoPlayerController videoPlayerController =
        VideoPlayerController.file(file);

    await videoPlayerController.initialize();
    await videoPlayerController.setLooping(true);
    await videoPlayerController.play();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent, // Background tembus pandang
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.black, // Dark mode immersif
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.black.withOpacity(0.4),
                elevation: 0,
                centerTitle: true,
                title: Text(
                  "common_view_video".tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    if (BaseSettings.navigatorType ==
                        BaseNavigatorType.legacy) {
                      Navigators.pop();
                    } else {
                      context.pop();
                    }
                  },
                ),
              ),
              body: Center(
                child: AspectRatio(
                  aspectRatio: videoPlayerController.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(videoPlayerController),
                      VideoProgressIndicator(
                        videoPlayerController,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
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
