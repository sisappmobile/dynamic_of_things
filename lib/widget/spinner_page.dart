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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return BaseScaffold(
      context: context,
      appBar: appBar(),
      contentBuilder: body,
      bottomNavigationBar: bottomBar(),
      onRefresh: () async {
        refresh();
      },
      statusBuilder: () {
        if (loading) {
          return BaseBodyStatus.loading;
        } else {
          if (items != null) {
            if (items!.isNotEmpty) {
              return BaseBodyStatus.loaded;
            } else {
              return BaseBodyStatus.empty;
            }
          } else {
            return BaseBodyStatus.fail;
          }
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
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

  BaseAppBar appBar() {
    Widget mapModeButton() {
      if (items != null) {
        return IconButton(
          onPressed: () async {
            if (widget.dynamicFormResourceResponse.fields.any((element) =>
                StringUtils.inList(
                    element.name, ["latitude", "longitude", "longtitude"]))) {
              Map<String, dynamic>? result = await Navigators.push(
                MapPage(
                  markers: items!
                      .where((element) =>
                          element["latitude"] != null &&
                          (element["longitude"] != null ||
                              element["longtitude"] != null))
                      .map((element) {
                    return Marker(
                      point: LatLng(
                        double.parse(element["latitude"]),
                        double.parse(
                            element["longitude"] ?? element["longtitude"]),
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
                          .tr());
            }
          },
          icon: const Icon(Icons.map),
        );
      }

      return const SizedBox.shrink();
    }

    return BaseAppBar(
      context: context,
      name: widget.title,
      searchOption: SearchOption(
        controller: tecSearch,
        onSubmitted: (value) {
          refresh();
        },
      ),
      trailings: [
        mapModeButton(),
      ],
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
        itemCount: items!.length,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            color: AppColors.outline(),
            height: 0,
          );
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
                DynamicFormResourceFieldItem dfrfiRight =
                    dynamicFormResourceFieldItems[i + 1];

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
              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                Navigators.pop(result: item);
              } else {
                context.pop(item);
              }
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

    return BaseBottomBar(
      borderColor: AppColors.outline().withValues(alpha: 0.2),
      children: [
        Text(
          dataInfo(
            pageIndex: pageIndex,
            pageSize: pageSize,
            dataSize: size,
          ),
        ),
        Spacer(),
        CustomPagination(
          onPageChanged: (int pageNumber) {
            setState(() {
              pageIndex = pageNumber;
            });

            refresh();
          },
          pageTotal: (size / pageSize).ceil(),
          pageInit: pageIndex,
          colorPrimary: AppColors.onSurface(),
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
