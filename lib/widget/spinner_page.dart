// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import "dart:io";
import "dart:ui";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:dynamic_of_things/widget/map_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:latlong2/latlong.dart";
import "package:smooth_corner/smooth_corner.dart";

class SpinnerPage extends StatefulWidget {
  final HeaderForm headerForm;
  final String title;
  final String name;
  final Map<String, dynamic> data;
  final DynamicFormResourceResponse dynamicFormResourceResponse;
  final String? customerId;

  const SpinnerPage({
    required this.headerForm,
    required this.title,
    required this.name,
    required this.data,
    required this.dynamicFormResourceResponse,
    required this.customerId,
    super.key,
  });

  @override
  SpinnerPageState createState() => SpinnerPageState();
}

class SpinnerPageState extends State<SpinnerPage> with WidgetsBindingObserver {
  int size = 0;
  int pageIndex = 1;
  int pageSize = 50;

  bool loading = false;
  bool prefsReady = false;

  List<Map<String, dynamic>>? items;

  TextEditingController tecSearch = TextEditingController();

  // PERBAIKAN: Jarak disesuaikan agar lebih bernafas dan modern
  static const double gapCard = 16;
  static const double gapInner = 16;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    initPrefs();

    refresh();
  }

  Future<void> initPrefs() async {
    try {
      await Preferences.getInstance().init();
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      prefsReady = true;
    });
  }

  bool get isGlass {
    if (!prefsReady) {
      return false;
    }

    final int t = Preferences.getInstance()
            .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
        1;
    return t == 2;
  }

  Widget glassBackground() {
    final String p = (Preferences.getInstance()
                .getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH) ??
            "")
        .trim();

    if (p.isEmpty) {
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }
    if (p.startsWith("assets/")) {
      return Image.asset(p, fit: BoxFit.cover);
    }

    final File f = File(p);
    if (f.existsSync()) {
      return Image.file(f, fit: BoxFit.cover);
    }

    return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;

    return Scaffold(
      backgroundColor: glass
          ? Colors.transparent
          : isGlass
              ? Colors.white.withOpacity(0.06)
              : AppColors.surfaceContainerLowest(),
      body: Stack(
        children: [
          if (glass) ...[
            Positioned.fill(child: glassBackground()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.fromRGBO(0, 0, 0, 0.55),
                      Color.fromRGBO(0, 0, 0, 0.22),
                      Color.fromRGBO(0, 0, 0, 0.40),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Column(
            children: [
              SizedBox(height: safe.top),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  Dimensions.size10,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                child: topBar(),
              ),
              Expanded(child: bodyHost()),
              SizedBox(height: safe.bottom),
            ],
          ),
          Positioned(
            left: Dimensions.size15,
            right: Dimensions.size15,
            bottom: safe.bottom + Dimensions.size10,
            child: floatingActionBar(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
    tecSearch.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  void refresh() async {
    try {
      setState(() {
        size = 0;
        loading = true;
        items = null;
      });

      if (DynamicForms.offline) {
        Data? data = await Offlines.resourceData(
          headerForm: widget.headerForm,
          name: widget.name,
          data: widget.data,
          pageIndex: pageIndex,
          pageSize: pageSize,
          query: tecSearch.text,
          customerId: widget.customerId,
        );

        if (data != null) {
          setState(() {
            items = data.items;
            size = data.size;
          });
        }
      } else {
        Response response = await DotApis.getInstance().dynamicFormResourceData(
          formId: widget.headerForm.template.id,
          name: widget.name,
          data: widget.data,
          customerId: widget.customerId,
          query: tecSearch.text,
          pageIndex: pageIndex,
          pageSize: pageSize,
        );

        if (response.statusCode == 200) {
          setState(() {
            items = List<Map<String, dynamic>>.from(response.data);
            size = Formats.tryParseNumber(response.headers.value("X-Data-Size"))
                .toInt();
          });
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("Caught Exception: $e");
        print("Stack Trace:\n$s");
      }

      BaseOverlays.error(message: "unknown_error_please_try_again".tr());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget topBar() {
    final bool glass = isGlass;

    final Widget content = Column(
      children: [
        Row(
          children: [
            iconPill(
              icon: Icons.turn_left_rounded,
              onTap: () {
                if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                  Navigators.pop();
                } else {
                  context.pop();
                }
              },
            ),
            SizedBox(width: Dimensions.size10),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                ),
              ),
            ),
            SizedBox(width: Dimensions.size10),
            mapModeButton(),
          ],
        ),
        SizedBox(height: Dimensions.size10),
        searchBox(),
      ],
    );

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size15,
          vertical: Dimensions.size10,
        ),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.35),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget searchBox() {
    return Container(
      height: Dimensions.size50,
      decoration: ShapeDecoration(
        color: isGlass
            ? Colors.white.withOpacity(0.08)
            : AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.22),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(alpha: 0.65),
          ),
          SizedBox(width: Dimensions.size10),
          Expanded(
            child: TextField(
              controller: tecSearch,
              onSubmitted: (value) {
                pageIndex = 1;
                refresh();
              },
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "search".tr(),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.80)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (StringUtils.isNotNullOrEmpty(tecSearch.text))
            iconTiny(
              icon: Icons.close,
              onTap: () {
                tecSearch.clear();
                pageIndex = 1;
                setState(() {});
                refresh();
              },
            ),
        ],
      ),
    );
  }

  Widget iconTiny({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.size5),
          child: Icon(
            icon,
            size: Dimensions.size20,
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color iconColor = glass
        ? Colors.white.withOpacity(0.92)
        : isGlass
            ? Colors.white.withOpacity(0.92)
            : AppColors.onSurface();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size15,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: Dimensions.size25,
                  ),
                ),
              )
            : Ink(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: ShapeDecoration(
                  color: isGlass
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: 1,
                    side: BorderSide(
                      color: isGlass
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.outline().withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                  size: Dimensions.size25,
                ),
              ),
      ),
    );
  }

  Color? hexToColor(String? hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString!.length == 6 || hexString.length == 7) {
        buffer.write("ff");
      }
      buffer.write(hexString.replaceFirst("#", ""));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {}

    return null;
  }

  Widget mapModeButton() {
    if (items != null && items!.isNotEmpty) {
      return iconPill(
        icon: Icons.map,
        onTap: () async {
          if (widget.dynamicFormResourceResponse.fields.any(
            (element) => StringUtils.inList(
              element.name,
              ["latitude", "longitude", "longtitude"],
            ),
          )) {
            MarkerItem? selectedMarkerItem = await Navigators.push(
              MapPage(
                markerItems: items!.where((element) => element["latitude"] != null && (element["longitude"] != null || element["longtitude"] != null)).map((element) {
                  return MarkerItem(
                    point: LatLng(
                      double.parse(element["latitude"]),
                      double.parse(
                        element["longitude"] ?? element["longtitude"],
                      ),
                    ),
                    icon: Icon(
                      Icons.location_on_outlined,
                      size: Dimensions.size30,
                      color: hexToColor(element["colorlocation"]) ?? Colors.red,
                    ),
                    extra: element,
                  );
                }).toList(),
              ),
            );

            if (selectedMarkerItem != null) {
              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                Navigators.pop(result: selectedMarkerItem.extra);
              } else {
                context.pop(selectedMarkerItem.extra);
              }
            }
          } else {
            BaseOverlays.error(
              message:
                  "map_view_can_only_be_used_if_there_is_longitude_and_latitude_data"
                      .tr(),
            );
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget bodyHost() {
    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (items == null) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [failState()],
      );
    }

    if (items != null && items!.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [emptyState()],
      );
    }

    return body();
  }

  Widget failState() {
    final Widget content = Column(
      children: [
        Icon(
          Icons.error_outline,
          size: Dimensions.size45,
          color: isGlass
              ? Colors.white.withOpacity(0.92)
              : AppColors.onSurface().withValues(alpha: 0.65),
        ),
        SizedBox(height: Dimensions.size10),
        Text(
          "common_something_wrong".tr(),
          style: TextStyle(
            fontSize: Dimensions.text16,
            fontWeight: FontWeight.w900,
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface(),
          ),
        ),
        SizedBox(height: Dimensions.size15),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => refresh(),
                icon: const Icon(Icons.refresh),
                label: Text("refresh".tr()),
              ),
            ),
          ],
        ),
      ],
    );

    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.all(Dimensions.size20),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.35),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget emptyState() {
    final Widget content = Column(
      children: [
        Icon(
          Icons.inbox_outlined,
          size: Dimensions.size45,
          color: isGlass
              ? Colors.white.withOpacity(0.92)
              : AppColors.onSurface().withValues(alpha: 0.65),
        ),
        SizedBox(height: Dimensions.size10),
        Text(
          "no_data".tr(),
          style: TextStyle(
            fontSize: Dimensions.text16,
            fontWeight: FontWeight.w900,
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface(),
          ),
        ),
        SizedBox(height: Dimensions.size5),
        Text(
          "try_adjust_filter_or_pull_to_refresh".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.all(Dimensions.size20),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.35),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget floatingActionBar() {
    final Widget inner = bottomBar();

    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.size25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: Dimensions.size15,
          sigmaY: Dimensions.size15,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size15,
            vertical: Dimensions.size10,
          ),
          decoration: BoxDecoration(
            color: isGlass
                ? Colors.white.withOpacity(0.12)
                : AppColors.surface().withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(Dimensions.size25),
            border: Border.all(
              color: isGlass
                  ? Colors.white.withOpacity(0.22)
                  : AppColors.outline().withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: Dimensions.size25,
                offset: Offset(0, Dimensions.size15),
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: inner,
        ),
      ),
    );
  }

  Widget body() {
    List<DynamicFormResourceFieldItem> dynamicFormResourceFieldItems = widget
        .dynamicFormResourceResponse.fields
        .where((element) => element.showed)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size100,
        ),
        itemCount: items!.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: gapCard);
        },
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> item = items![index];

          List<Widget> widgets = [];

          for (int i = 0; i < dynamicFormResourceFieldItems.length; i++) {
            if (i % 2 == 0) {
              List<Widget> children = [];

              DynamicFormResourceFieldItem dfrfiLeft =
                  dynamicFormResourceFieldItems[i];

              children.add(
                childrenWidget(
                  description: dfrfiLeft.description,
                  value: DynamicForms.spell(
                    type: dfrfiLeft.type,
                    value: item[dfrfiLeft.name],
                  ),
                  left: true,
                ),
              );

              if (i + 1 < dynamicFormResourceFieldItems.length) {
                DynamicFormResourceFieldItem dfrfiRight =
                    dynamicFormResourceFieldItems[i + 1];

                children
                  ..add(const SizedBox(width: gapInner))
                  ..add(
                    childrenWidget(
                      description: dfrfiRight.description,
                      value: DynamicForms.spell(
                        type: dfrfiRight.type,
                        value: item[dfrfiRight.name],
                      ),
                      left: false,
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
                widgets.add(const SizedBox(height: gapInner));
              }
            }
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                  Navigators.pop(result: item);
                } else {
                  context.pop(item);
                }
              },
              customBorder: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size20),
                smoothness: Dimensions.size1,
              ),
              child: Builder(
                builder: (context) {
                  // PERBAIKAN: Padding diperbesar sedikit agar konten di dalamnya bisa bernafas
                  final Widget content = Padding(
                    padding: EdgeInsets.all(Dimensions.size20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widgets,
                    ),
                  );

                  if (isGlass) {
                    return GlassContainer(
                      blur: Dimensions.size20,
                      borderRadius: Dimensions.size20,
                      opacity: 0.12,
                      borderOpacity: 0.22,
                      padding: EdgeInsets.zero,
                      child: content,
                    );
                  }

                  return Ink(
                    decoration: ShapeDecoration(
                      color: AppColors.surface(),
                      shadows: [
                        BoxShadow(
                          blurRadius: Dimensions.size20,
                          offset: Offset(0, Dimensions.size10),
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                      ],
                      shape: SmoothRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.size20),
                        smoothness: Dimensions.size1,
                        side: BorderSide(
                          color: AppColors.outline().withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: content,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // PERBAIKAN UTAMA: Menghilangkan wrapper kotak (Container/ShapeDecoration)
  // Menyelaraskan teks seluruhnya rata kiri layaknya grid modern yang clean
  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: isGlass
                  ? Colors.white.withOpacity(0.70)
                  : AppColors.onSurface().withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            StringUtils.isNotNullOrEmpty(value) ? value : "-",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: isGlass
                  ? Colors.white.withOpacity(0.95)
                  : AppColors.onSurface(),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomBar() {
    String dataInfo({
      required int pageIndex,
      required int pageSize,
      required int? dataSize,
    }) {
      if (dataSize != null) {
        int start = ((pageIndex - 1) * pageSize) + 1;
        int until = pageIndex * pageSize;

        if (start > dataSize) {
          start = dataSize;
        }

        if (until > dataSize) {
          until = dataSize;
        }

        return "$start - $until ${"of".tr()} $dataSize";
      } else {
        return "loading".tr();
      }
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            dataInfo(
              pageIndex: pageIndex,
              pageSize: pageSize,
              dataSize: size,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : AppColors.onSurface().withValues(alpha: 0.75),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: Dimensions.size10),
        CustomPagination(
          onPageChanged: (int pageNumber) {
            setState(() {
              pageIndex = pageNumber;
            });

            refresh();
          },
          pageTotal: (size / pageSize).ceil(),
          pageInit: pageIndex,
          colorPrimary:
              isGlass ? Colors.white.withOpacity(0.92) : AppColors.onSurface(),
          colorSub: isGlass
              ? Colors.white.withOpacity(0.12)
              : AppColors.surfaceContainerLow(),
          buttonRadius: Dimensions.size50,
          buttonElevation: 0,
          threshold: 1,
        ),
      ],
    );
  }
}

class CustomPagination extends StatefulWidget {
  const CustomPagination({
    required this.onPageChanged,
    required this.pageTotal,
    super.key,
    this.threshold = 10,
    this.pageInit = 1,
    this.colorPrimary = Colors.black,
    this.colorSub = Colors.white,
    this.controlButton,
    this.iconPrevious = const Icon(Icons.keyboard_arrow_left),
    this.iconNext = const Icon(Icons.keyboard_arrow_right),
    this.fontSize = 15,
    this.fontFamily,
    this.buttonElevation = 5,
    this.buttonRadius = 10,
    this.buttonSpacing = 4.0,
    this.groupSpacing = 10.0,
  });

  final Function(int) onPageChanged;

  final int pageTotal;

  final int pageInit;

  final int threshold;

  final Color colorPrimary;

  final Color colorSub;

  final Widget? controlButton;

  final Widget iconPrevious;

  final Widget iconNext;

  final double fontSize;

  final String? fontFamily;

  final double buttonElevation;

  final double buttonRadius;

  final double buttonSpacing;

  final double groupSpacing;

  @override
  NumberPaginationState createState() => NumberPaginationState();
}

class NumberPaginationState extends State<CustomPagination> {
  late int currentPage;

  double contrastRatio(Color a, Color b) {
    final double l1 = a.computeLuminance();
    final double l2 = b.computeLuminance();
    final double hi = l1 > l2 ? l1 : l2;
    final double lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  Color safeText(Color desired, Color bg) {
    if (contrastRatio(desired, bg) >= 3.0) {
      return desired;
    }
    return bg.computeLuminance() > 0.6
        ? Colors.black.withOpacity(0.85)
        : Colors.white.withOpacity(0.95);
  }

  // PERBAIKAN: Outline pada tombol diubah agar tidak terlalu kaku
  Color borderColor() {
    final double l1 = widget.colorPrimary.computeLuminance();
    final double l2 = widget.colorSub.computeLuminance();

    if (l1 > 0.85 && l2 > 0.85) {
      return Colors.white.withOpacity(0.18); 
    }

    return AppColors.outline().withValues(alpha: 0.15);
  }

  @override
  void initState() {
    currentPage = widget.pageInit;
    super.initState();
  }

  void changePage(int targetPage) {
    int newPage = targetPage.clamp(1, widget.pageTotal);

    if (currentPage != newPage) {
      setState(() {
        currentPage = newPage;
        widget.onPageChanged(currentPage);
      });
    }
  }

  Widget pageNumbers(int rangeStart, int rangeEnd) {
    return Flexible(
      fit: FlexFit.loose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          rangeEnd <= widget.pageTotal
              ? widget.threshold
              : widget.pageTotal % widget.threshold,
          (index) => Flexible(
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: Builder(
                builder: (context) {
                  final bool selected =
                      (currentPage - 1) % widget.threshold == index;
                  final Color bg =
                      selected ? widget.colorPrimary : widget.colorSub;
                  final Color desiredText =
                      selected ? widget.colorSub : widget.colorPrimary;
                  final Color text = safeText(desiredText, bg);

                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(widget.buttonRadius),
                        side: BorderSide(
                          color: selected ? Colors.transparent : borderColor(),
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(Dimensions.size50, Dimensions.size50),
                      foregroundColor: text,
                      backgroundColor: bg,
                    ),
                    onPressed: () => changePage(index + 1 + rangeStart),
                    child: Text(
                      "${index + 1 + rangeStart}",
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontFamily: widget.fontFamily,
                        color: text,
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget controlButton(Widget icon, bool enabled, VoidCallback onTap) {
    final Color bg = widget.colorSub;
    final Color fg = safeText(widget.colorPrimary, bg);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size10),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: borderColor(),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: Size(Dimensions.size50, Dimensions.size50),
        foregroundColor: enabled ? fg : Colors.grey,
        backgroundColor: bg,
        disabledForegroundColor: fg.withOpacity(0.55),
        disabledBackgroundColor: bg,
      ),
      onPressed: enabled ? onTap : null,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeStart = currentPage % widget.threshold == 0
        ? currentPage - widget.threshold
        : (currentPage ~/ widget.threshold) * widget.threshold;

    final rangeEnd = rangeStart + widget.threshold;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        controlButton(
          widget.iconPrevious,
          currentPage != 1,
          () => changePage(currentPage - 1),
        ),
        SizedBox(width: widget.groupSpacing),
        pageNumbers(rangeStart, rangeEnd),
        SizedBox(width: widget.groupSpacing),
        controlButton(
          widget.iconNext,
          currentPage != widget.pageTotal,
          () => changePage(currentPage + 1),
        ),
      ],
    );
  }
}