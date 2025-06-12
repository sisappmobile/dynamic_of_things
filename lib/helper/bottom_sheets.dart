// ignore_for_file: always_specify_types, use_build_context_synchronously, cascade_invocations, always_put_required_named_parameters_first, constant_identifier_names, avoid_print

import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
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
                  context.pop();
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

  static Future<Map<String, dynamic>?> dynamicFormSpinner({
    required BuildContext context,
    required String title,
    required DynamicFormResourceResponse dynamicFormResourceResponse,
  }) async {
    TextEditingController textEditingController = TextEditingController();

    List<Map<String, dynamic>> filteredItems = [];

    filteredItems.addAll(dynamicFormResourceResponse.data);

    List<DynamicFormResourceFieldItem> dynamicFormResourceFieldItems = dynamicFormResourceResponse.fields.where((element) => !element.primaryKey).toList();

    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Text(
                  title,
                ),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.size20,
                      ),
                      child: SizedBox(
                        height: Dimensions.size60,
                        child: TextField(
                          controller: textEditingController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            filled: true,
                            prefixIcon: const Icon(
                              Icons.search,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Dimensions.size100,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            hintText: "search".tr(),
                          ),
                          onChanged: (String value) {
                            setState(() {
                              filteredItems.clear();

                              if (StringUtils.isNotNullOrEmpty(textEditingController.text)) {
                                for (Map<String, dynamic> item in dynamicFormResourceResponse.data) {
                                  String searchKey = "";

                                  for (DynamicFormResourceFieldItem dynamicFormResourceFieldItem in dynamicFormResourceResponse.fields) {
                                    searchKey += DynamicForms.spell(
                                      type: dynamicFormResourceFieldItem.type,
                                      value: item[dynamicFormResourceFieldItem.name],
                                    );
                                  }

                                  if (searchKey.toLowerCase().contains(textEditingController.text.toLowerCase())) {
                                    filteredItems.add(item);
                                  }
                                }
                              } else {
                                filteredItems.addAll(dynamicFormResourceResponse.data);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Dimensions.size20,
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                          color: AppColors.outline(),
                          height: 0,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        Map<String, dynamic> item = filteredItems[index];

                        List<Widget> widgets = [];

                        for (int i = 0; i < dynamicFormResourceFieldItems.length; i++) {
                          if (i % 2 == 0) {
                            List<Widget> children = [];

                            DynamicFormResourceFieldItem dfrfiLeft = dynamicFormResourceFieldItems[i];

                            children.add(
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dfrfiLeft.description,
                                      textAlign: TextAlign.start,
                                    ),
                                    Text(
                                      DynamicForms.spell(
                                        type: dfrfiLeft.type,
                                        value: item[dfrfiLeft.name],
                                      ),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: Dimensions.text16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (i + 1 < dynamicFormResourceFieldItems.length) {
                              DynamicFormResourceFieldItem dfrfiRight = dynamicFormResourceFieldItems[i + 1];

                              children.add(
                                SizedBox(
                                  width: Dimensions.size20,
                                ),
                              );

                              children.add(
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        dfrfiRight.description,
                                        textAlign: TextAlign.end,
                                      ),
                                      Text(
                                        DynamicForms.spell(
                                          type: dfrfiRight.type,
                                          value: item[dfrfiRight.name],
                                        ),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: Dimensions.text16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            widgets.add(
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children,
                              ),
                            );

                            if (i + 2 < dynamicFormResourceFieldItems.length) {
                              widgets.add(
                                SizedBox(
                                  height: Dimensions.size20,
                                ),
                              );
                            }
                          }
                        }

                        return InkWell(
                          onTap: () async {
                            context.pop(item);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(Dimensions.size20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widgets,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
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
