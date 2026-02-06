// ignore_for_file: use_build_context_synchronously

import "dart:ui";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/map_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
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

  List<Map<String, dynamic>>? items;

  TextEditingController tecSearch = TextEditingController();

  static const double _gapCard = 10;
  static const double _gapInner = 8;

  static const double _tilePadX = 10;
  static const double _tilePadY = 10;

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(
        children: [
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
                child: _topBar(),
              ),
              Expanded(child: _bodyHost()),
              SizedBox(height: safe.bottom),
            ],
          ),
          Positioned(
            left: Dimensions.size15,
            right: Dimensions.size15,
            bottom: safe.bottom + Dimensions.size10,
            child: _bottomFloatingBar(),
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

  Widget _topBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _card(context),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: 1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconPill(
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
                    color: _fg(context),
                  ),
                ),
              ),
              SizedBox(width: Dimensions.size10),
              _mapModeButton(),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          _searchBox(),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: Dimensions.size50,
      decoration: ShapeDecoration(
        color: _soft(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: 1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.22),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: _fg(context).withValues(alpha: 0.65),
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
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (StringUtils.isNotNullOrEmpty(tecSearch.text))
            _iconTiny(
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

  Widget _iconTiny({
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
            color: _fg(context).withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: 1,
        ),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: _soft(context),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: 1,
              side: BorderSide(
                color: _outline(context).withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Icon(
            icon,
            color: _fg(context),
            size: Dimensions.size25,
          ),
        ),
      ),
    );
  }

  Widget _mapModeButton() {
    if (items != null && items!.isNotEmpty) {
      return _iconPill(
        icon: Icons.map,
        onTap: () async {
          if (widget.dynamicFormResourceResponse.fields.any(
            (element) => StringUtils.inList(
              element.name,
              ["latitude", "longitude", "longtitude"],
            ),
          )) {
            Map<String, dynamic>? result = await Navigators.push(
              MapPage(
                markers: items!
                    .where(
                  (element) =>
                      element["latitude"] != null &&
                      (element["longitude"] != null ||
                          element["longtitude"] != null),
                )
                    .map((element) {
                  return Marker(
                    point: LatLng(
                      double.parse(element["latitude"]),
                      double.parse(
                        element["longitude"] ?? element["longtitude"],
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        if (BaseSettings.navigatorType ==
                            BaseNavigatorType.legacy) {
                          Navigators.pop(result: element);
                        } else {
                          context.pop(element);
                        }
                      },
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 30,
                        color: Colors.red,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );

            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              Navigators.pop(result: result);
            } else {
              context.pop(result);
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

  Widget _bodyHost() {
    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (items == null) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [_failState()],
      );
    }

    if (items != null && items!.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [_emptyState()],
      );
    }

    return body();
  }

  Widget _failState() {
    return Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: _card(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: 1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: Dimensions.size45,
            color: _fg(context).withValues(alpha: 0.65),
          ),
          SizedBox(height: Dimensions.size10),
          Text(
            "common_something_wrong".tr(),
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.w900,
              color: _fg(context),
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
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: _card(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: 1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: Dimensions.size45,
            color: _fg(context).withValues(alpha: 0.65),
          ),
          SizedBox(height: Dimensions.size10),
          Text(
            "no_data".tr(),
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.w900,
              color: _fg(context),
            ),
          ),
          SizedBox(height: Dimensions.size5),
          Text(
            "try_adjust_filter_or_pull_to_refresh".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _fg(context).withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomFloatingBar() {
    final Widget inner = bottomBar();

    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.size25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size15,
            vertical: Dimensions.size10,
          ),
          decoration: BoxDecoration(
            color: _card(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(Dimensions.size25),
            border: Border.all(
              color: _outline(context).withValues(alpha: 0.18),
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
          return const SizedBox(height: _gapCard);
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
                  ..add(SizedBox(width: _gapInner))
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
                widgets.add(SizedBox(height: _gapInner));
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
                smoothness: 1,
              ),
              child: Ink(
                decoration: ShapeDecoration(
                  color: _card(context),
                  shadows: [
                    BoxShadow(
                      blurRadius: Dimensions.size20,
                      offset: Offset(0, Dimensions.size10),
                      color: Colors.black.withValues(alpha: 0.10),
                    ),
                  ],
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size20),
                    smoothness: 1,
                    side: BorderSide(
                      color: _outline(context).withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(Dimensions.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widgets,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _tilePadX,
          vertical: _tilePadY,
        ),
        decoration: ShapeDecoration(
          color: _soft(context),
          shape: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.size15),
            smoothness: 1,
            side: BorderSide(
              color: _outline(context).withValues(alpha: 0.20),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: left ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w700,
                color: _fg(context).withValues(alpha: 0.65),
              ),
            ),
            SizedBox(height: Dimensions.size4),
            Text(
              StringUtils.isNotNullOrEmpty(value) ? value : "-",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: left ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: _fg(context),
              ),
            ),
          ],
        ),
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
              color: _fg(context).withValues(alpha: 0.75),
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
          colorPrimary: _fg(context),
          colorSub: AppColors.surfaceContainerLow(),
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

  @override
  void initState() {
    currentPage = widget.pageInit;
    super.initState();
  }

  void _changePage(int targetPage) {
    int newPage = targetPage.clamp(1, widget.pageTotal);

    if (currentPage != newPage) {
      setState(() {
        currentPage = newPage;
        widget.onPageChanged(currentPage);
      });
    }
  }

  Widget _buildPageNumbers(int rangeStart, int rangeEnd) {
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
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.buttonRadius),
                    side: BorderSide(color: AppColors.outline()),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  foregroundColor: (currentPage - 1) % widget.threshold == index
                      ? widget.colorSub
                      : widget.colorPrimary,
                  backgroundColor: (currentPage - 1) % widget.threshold == index
                      ? widget.colorPrimary
                      : widget.colorSub,
                ),
                onPressed: () => _changePage(index + 1 + rangeStart),
                child: Text(
                  "${index + 1 + rangeStart}",
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontFamily: widget.fontFamily,
                    color: (currentPage - 1) % widget.threshold == index
                        ? widget.colorSub
                        : widget.colorPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(Widget icon, bool enabled, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size10),
          smoothness: 1,
          side: BorderSide(
            color: AppColors.outline(),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        foregroundColor: enabled ? widget.colorPrimary : Colors.grey,
        backgroundColor: widget.colorSub,
        disabledForegroundColor: widget.colorPrimary,
        disabledBackgroundColor: widget.colorSub,
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
        _buildControlButton(
          widget.iconPrevious,
          currentPage != 1,
          () => _changePage(currentPage - 1),
        ),
        SizedBox(width: widget.groupSpacing),
        _buildPageNumbers(rangeStart, rangeEnd),
        SizedBox(width: widget.groupSpacing),
        _buildControlButton(
          widget.iconNext,
          currentPage != widget.pageTotal,
          () => _changePage(currentPage + 1),
        ),
      ],
    );
  }
}
