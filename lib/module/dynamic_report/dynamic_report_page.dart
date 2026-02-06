// ignore_for_file: constant_identifier_names, depend_on_referenced_packages, use_build_context_synchronously

import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_report_data.dart";
import "package:dynamic_of_things/model/dynamic_report_template.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_bloc.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_event.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_state.dart";
import "package:dynamic_of_things/widget/custom_pagination.dart";
import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:jiffy/jiffy.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:path/path.dart" as path;
import "package:pattern_formatter/pattern_formatter.dart";
import "package:smooth_corner/smooth_corner.dart";

enum SortDirection { ASC, DESC }

class DynamicReportPage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final DynamicFormCategoryItem dynamicFormCategoryItem;

  const DynamicReportPage({
    required this.dynamicFormMenuItem,
    required this.dynamicFormCategoryItem,
    super.key,
  });

  @override
  DynamicReportPageState createState() => DynamicReportPageState();
}

class DynamicReportPageState extends State<DynamicReportPage>
    with WidgetsBindingObserver {
  Template? template;
  DataResponse? dataResponse;

  bool loading = true;

  String? sortField;
  SortDirection? sortDirection;

  int size = 0;
  int pageSize = 20;
  int pageIndex = 1;

  static const double _gapCard = 10;
  static const double _gapInner = 5;

  static const double _tilePadX = 10;
  static const double _tilePadY = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    context.read<DynamicReportBloc>().add(
          DynamicReportTemplate(id: widget.dynamicFormMenuItem.id),
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return BlocListener<DynamicReportBloc, DynamicReportState>(
      listener: (context, state) async {
        if (state is DynamicReportTemplateLoading) {
          context.loaderOverlay.show();
          setState(() {
            template = null;
          });
        } else if (state is DynamicReportTemplateSuccess) {
          template = state.template;
          refresh();
        } else if (state is DynamicReportTemplateFinished) {
          context.loaderOverlay.hide();
        } else if (state is DynamicReportDataLoading) {
          setState(() {
            size = 0;
            loading = true;
            dataResponse = null;
          });
        } else if (state is DynamicReportDataSuccess) {
          setState(() {
            size = state.dataResponse.size;
            dataResponse = state.dataResponse;
          });
        } else if (state is DynamicReportDataFinished) {
          setState(() {
            loading = false;
          });
        } else if (state is DynamicReportExportLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicReportExportSuccess) {
          await download(
            context: context,
            bytes: state.bytes,
            fileName: state.fileName,
          );
        } else if (state is DynamicReportExportFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLowest(),
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
                  child: appbar(),
                ),
                Expanded(child: body()),
                SizedBox(height: safe.bottom + Dimensions.size75),
              ],
            ),
            Positioned(
              left: Dimensions.size15,
              right: Dimensions.size15,
              bottom: safe.bottom + Dimensions.size2,
              child: floatingactionbar(),
            ),
          ],
        ),
      ),
    );
  }

  void refresh() {
    if (template == null) {
      return;
    }

    context.read<DynamicReportBloc>().add(
          DynamicReportData(
            id: widget.dynamicFormMenuItem.id,
            dataRequest: DataRequest(
              size: pageSize,
              index: pageIndex - 1,
              sortField: sortField,
              sortDirection: sortDirection?.name,
              filters: Map.fromEntries(
                template!.filters
                    .where((element) => element.value != null)
                    .map((e) => MapEntry(e.id, e.value)),
              ),
            ),
          ),
        );
  }

  Future<void> download({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
  }) async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      String filePath = path.join(directoryPath, fileName);

      bool fileExists = await File(filePath).exists();

      if (fileExists) {
        int count = 1;
        String newFileName = "1-$fileName";

        while (await File(path.join(directoryPath, newFileName)).exists()) {
          count++;
          newFileName = "$count-$fileName";
        }

        fileName = newFileName;
        filePath = path.join(directoryPath, fileName);
      }

      await File(filePath).writeAsBytes(bytes);

      Future.delayed(const Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("file_has_been_successfully_downloaded".tr()),
                Text(filePath),
              ],
            ),
            duration: const Duration(milliseconds: 2000),
          ),
        );
      });
    } else {
      BaseOverlays.error(message: "error_occured_when_saving_file".tr());
    }
  }

  Widget appbar() {
    final String title = (template?.title.isNotEmpty ?? false)
        ? template!.title
        : widget.dynamicFormMenuItem.name;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
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
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: AppColors.onSurface(),
                  ),
                ),
                SizedBox(height: Dimensions.size2),
                Text(
                  widget.dynamicFormCategoryItem.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface().withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.size10),
          iconPill(
            icon: Icons.tune,
            onTap: () async => openFilter(),
          ),
          SizedBox(width: Dimensions.size10),
          iconPill(
            icon: Icons.file_download_outlined,
            onTap: () async {
              if (template == null) {
                return;
              }

              context.read<DynamicReportBloc>().add(
                    DynamicReportExport(
                      id: widget.dynamicFormMenuItem.id,
                      dataRequest: DataRequest(
                        size: pageSize,
                        index: pageIndex - 1,
                        sortField: sortField,
                        sortDirection: sortDirection?.name,
                        filters: Map.fromEntries(
                          template!.filters
                              .where((element) => element.value != null)
                              .map((e) => MapEntry(e.id, e.value)),
                        ),
                      ),
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: AppColors.surfaceContainerLowest(),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: AppColors.outline().withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.onSurface(),
            size: Dimensions.size25,
          ),
        ),
      ),
    );
  }

  Widget body() {
    if (template == null) {
      return BaseWidgets.shimmer();
    }

    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (dataResponse == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.size20),
          child: Text(
            "common_something_wrong".tr(),
            style: TextStyle(
              color: AppColors.onSurface().withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (dataResponse!.rows.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.size20),
            decoration: ShapeDecoration(
              color: AppColors.surface(),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size20),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: Dimensions.size45,
                  color: AppColors.onSurface().withValues(alpha: 0.65),
                ),
                SizedBox(height: Dimensions.size10),
                Text(
                  "no_data".tr(),
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface(),
                  ),
                ),
                SizedBox(height: Dimensions.size5),
                Text(
                  "try_adjust_filter_or_pull_to_refresh".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface().withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size10,
        ),
        itemCount: dataResponse!.rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: _gapCard),
        itemBuilder: (context, index) {
          final Map<String, dynamic> map = dataResponse!.rows[index];
          return cardDynamic(
            index: index + 1,
            row: map,
          );
        },
      ),
    );
  }

  bool empthyValue(String v) {
    final String s = v.trim();
    return s.isEmpty || s == "-" || s == "null";
  }

  Widget cardDynamic({
    required int index,
    required Map<String, dynamic> row,
  }) {
    String valueOf(String fieldName) {
      final dynamic v = row[fieldName];
      if (v == null) {
        return "-";
      }

      String s = v.toString();

      s = s.replaceAll(RegExp(r"\s+"), " ").trim();

      return StringUtils.isNotNullOrEmpty(s) ? s : "-";
    }

    String title = "-";
    final Field? itemDescField = template!.fields
        .where((f) => f.name == "item_desc")
        .cast<Field?>()
        .firstWhere((e) => e != null, orElse: () => null);

    if (itemDescField != null) {
      title = valueOf(itemDescField.name);
    } else if (template!.fields.isNotEmpty) {
      title = valueOf(template!.fields.first.name);
    }

    final Field? qtyField = template!.fields
        .where((f) => f.name == "qty")
        .cast<Field?>()
        .firstWhere((e) => e != null, orElse: () => null);

    final String? qtyValue = qtyField != null ? valueOf(qtyField.name) : null;

    final bool showQty = qtyValue != null && !empthyValue(qtyValue);

    final List<Field> fields = template!.fields.toList();
    if (itemDescField != null) {
      fields.removeWhere((f) => f.name == itemDescField.name);
    }

    return Container(
      padding: EdgeInsets.all(Dimensions.size15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              chipQuantity("#$index"),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    color: AppColors.onSurface(),
                  ),
                ),
              ),
              if (showQty) ...[
                SizedBox(width: Dimensions.size10),
                chipCompatQuantity(label: "Qty", value: qtyValue),
              ],
            ],
          ),
          SizedBox(height: Dimensions.size10),
          Divider(
            height: 0,
            color: AppColors.outline().withValues(alpha: 0.30),
          ),
          SizedBox(height: Dimensions.size10),
          LayoutBuilder(
            builder: (context, c) {
              final double rowW = c.maxWidth;

              final bool can3 = rowW >= 340;
              final int colsDefault = can3 ? 3 : 2;

              final double gap = _gapInner;

              double colW(int cols) => (rowW - gap * (cols - 1)) / cols;

              final List<Widget> blocks = [];
              final List<Widget> bucket = [];

              void flushBucket({required int cols}) {
                if (bucket.isEmpty) {
                  return;
                }

                final double w = colW(cols);

                blocks.add(
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: bucket
                        .map((child) => SizedBox(width: w, child: child))
                        .toList(),
                  ),
                );

                bucket.clear();
              }

              final List<Field> ordered = [...fields]..sort((a, b) {
                  final aa = isTricMetric(a) ? 0 : 1;
                  final bb = isTricMetric(b) ? 0 : 1;
                  return aa.compareTo(bb);
                });

              bool metricMode = false;

              for (final Field f in ordered) {
                if (qtyField != null && f.name == qtyField.name) {
                  continue;
                }

                final String val = valueOf(f.name);
                final bool empty = empthyValue(val);
                final bool isMetric = isTricMetric(f);

                if (isMetric) {
                  if (!metricMode) {
                    flushBucket(cols: colsDefault);
                    metricMode = true;
                  }

                  bucket.add(
                    kvSmart(f.caption, empty ? "-" : val, compact: true),
                  );

                  if (bucket.length == 3) {
                    flushBucket(cols: can3 ? 3 : 2);
                    metricMode = false;
                  }
                  continue;
                }

                if (metricMode) {
                  flushBucket(cols: can3 ? 3 : 2);
                  metricMode = false;
                }

                final bool full = forceFullWidth(f, val);

                if (full) {
                  flushBucket(cols: colsDefault);

                  blocks.add(
                    SizedBox(
                      width: rowW,
                      child: kvSmart(
                        f.caption,
                        empty ? "-" : val,
                        compact: false,
                      ),
                    ),
                  );
                } else {
                  bucket.add(
                    kvSmart(f.caption, empty ? "-" : val, compact: true),
                  );

                  if (bucket.length == colsDefault) {
                    flushBucket(cols: colsDefault);
                  }
                }
              }

              if (metricMode) {
                flushBucket(cols: can3 ? 3 : 2);
              } else {
                flushBucket(cols: colsDefault);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < blocks.length; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    blocks[i],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget kvSmart(
    String k,
    String v, {
    required bool compact,
  }) {
    final bool empty = empthyValue(v);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _tilePadX,
        vertical: _tilePadY,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface().withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            empty ? "-" : v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: AppColors.onSurface().withValues(alpha: empty ? 0.35 : 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget chipQuantity(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size50),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Dimensions.text12,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface().withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget chipCompatQuantity({
    required String label,
    required String value,
  }) {
    final bool empty = empthyValue(value);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size50),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface().withValues(alpha: 0.70),
            ),
          ),
          SizedBox(width: Dimensions.size5),
          Text(
            empty ? "-" : value,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              color:
                  AppColors.onSurface().withValues(alpha: empty ? 0.40 : 0.90),
            ),
          ),
        ],
      ),
    );
  }

  Widget floatingactionbar() {
    final String info = dataInfo(
      pageIndex: pageIndex,
      pageSize: pageSize,
      dataSize: dataResponse?.size,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surface(),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size25,
            offset: Offset(0, Dimensions.size15),
            color: Colors.black.withValues(alpha: 0.14),
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.size10,
                vertical: Dimensions.size10,
              ),
              decoration: ShapeDecoration(
                color: AppColors.surfaceContainerLowest(),
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: AppColors.outline().withValues(alpha: 0.22),
                  ),
                ),
              ),
              child: Text(
                info,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Dimensions.text12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface().withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Expanded(
            flex: 4,
            child: CustomPagination(
              onPageChanged: (int pageNumber) {
                setState(() {
                  pageIndex = pageNumber;
                });
                refresh();
              },
              pageTotal: (size / pageSize).ceil(),
              pageInit: pageIndex,
              colorPrimary: AppColors.onSurface(),
              colorSub: AppColors.surfaceContainerLowest(),
              buttonRadius: Dimensions.size50,
              buttonElevation: 0,
              threshold: 1,
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Container(
            height: Dimensions.size40,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
            decoration: ShapeDecoration(
              color: AppColors.surfaceContainerLowest(),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size15),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.22),
                ),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: pageSize,
                borderRadius: BorderRadius.circular(Dimensions.size15),
                icon: Icon(Icons.expand_more, size: Dimensions.size20),
                items: const [
                  DropdownMenuItem(value: 20, child: Text("20")),
                  DropdownMenuItem(value: 50, child: Text("50")),
                  DropdownMenuItem(value: 100, child: Text("100")),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    pageSize = value;
                    pageIndex = 1;
                  });

                  refresh();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

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

      return "$start - $until ${"of".tr().toLowerCase()} $dataSize";
    } else {
      return "loading".tr();
    }
  }

  Future<void> openFilter() async {
    final GlobalKey<FormState> formState =
        GlobalKey<FormState>(debugLabel: "formState");

    if (template == null) {
      return;
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black26,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final EdgeInsets insets = MediaQuery.of(context).viewInsets;
        final EdgeInsets safe = MediaQuery.of(context).padding;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final bool hasActiveFilter = template!.filters.any(
              (filter) =>
                  filter.value != null ||
                  (filter.controller != null &&
                      StringUtils.isNotNullOrEmpty(filter.controller!.text)),
            );

            final int count = template!.filters.length;
            final bool compact = count <= 3;
            final double maxH =
                MediaQuery.of(context).size.height * (compact ? 0.62 : 0.90);

            return Padding(
              padding: EdgeInsets.only(bottom: insets.bottom),
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: Container(
                      margin: EdgeInsets.all(Dimensions.size15),
                      decoration: ShapeDecoration(
                        color: AppColors.surface(),
                        shape: SmoothRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.size25),
                          smoothness: Dimensions.size1,
                          side: BorderSide(
                            color: AppColors.outline().withValues(alpha: 0.35),
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            blurRadius: Dimensions.size30,
                            offset: const Offset(0, 16),
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              Dimensions.size15,
                              Dimensions.size15,
                              Dimensions.size15,
                              Dimensions.size10,
                            ),
                            child: Row(
                              children: [
                                iconPill(
                                  icon: Icons.close,
                                  onTap: () {
                                    if (BaseSettings.navigatorType ==
                                        BaseNavigatorType.legacy) {
                                      Navigators.pop();
                                    } else {
                                      context.pop();
                                    }
                                  },
                                ),
                                SizedBox(width: Dimensions.size10),
                                Expanded(
                                  child: Text(
                                    "filter".tr(),
                                    style: TextStyle(
                                      fontSize: Dimensions.text18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.onSurface(),
                                    ),
                                  ),
                                ),
                                if (hasActiveFilter)
                                  TextButton.icon(
                                    onPressed: () {
                                      BaseDialogs.confirmation(
                                        title:
                                            "are_you_sure_want_to_proceed".tr(),
                                        positiveCallback: () {
                                          for (Filter filter
                                              in template!.filters) {
                                            filter
                                              ..value = null
                                              ..controller = null;
                                          }
                                          setStateSheet(() {});
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.clear_all),
                                    label: Text("clear".tr()),
                                  ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 0,
                            color: AppColors.outline().withValues(alpha: 0.35),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Padding(
                              padding: EdgeInsets.all(Dimensions.size15),
                              child: Form(
                                key: formState,
                                autovalidateMode: AutovalidateMode.always,
                                child: ListView.separated(
                                  shrinkWrap: compact,
                                  physics: compact
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom: Dimensions.size15,
                                  ),
                                  itemCount: template!.filters.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: Dimensions.size15),
                                  itemBuilder: (context, index) {
                                    final Filter filter =
                                        template!.filters[index];

                                    if (filter.controller == null) {
                                      filter.controller =
                                          TextEditingController();

                                      if (filter.value != null) {
                                        if (filter.type == "DATE") {
                                          filter.controller!.text =
                                              Formats.dateTime(filter.value);
                                        } else if (filter.type == "NUMERIC") {
                                          filter.controller!.text =
                                              Formats.tryParseNumber(
                                            filter.value,
                                          ).currency();
                                        } else if (filter.type == "STRING") {
                                          filter.controller!.text =
                                              filter.value;
                                        } else if (StringUtils.inList(
                                          filter.type,
                                          ["DATA", "COMBOBOX"],
                                        )) {
                                          filter.controller!.text =
                                              filter.value;
                                        }
                                      }
                                    }

                                    return filterCard(
                                      title: filter.caption,
                                      canClear: filter.value != null ||
                                          StringUtils.isNotNullOrEmpty(
                                            filter.controller!.text,
                                          ),
                                      onClear: () {
                                        filter
                                          ..value = null
                                          ..controller = null;
                                        setStateSheet(() {});
                                      },
                                      child: filterInput(
                                        filter: filter,
                                        setStateSheet: setStateSheet,
                                        onChanged: () => setStateSheet(() {}),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              Dimensions.size15,
                              Dimensions.size5,
                              Dimensions.size15,
                              Dimensions.size15 + safe.bottom * 0.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (BaseSettings.navigatorType ==
                                          BaseNavigatorType.legacy) {
                                        Navigators.pop();
                                      } else {
                                        context.pop();
                                      }
                                    },
                                    icon: const Icon(Icons.close),
                                    label: Text("close".tr()),
                                  ),
                                ),
                                SizedBox(width: Dimensions.size10),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      if (formState.currentState != null &&
                                          formState.currentState!.validate()) {
                                        formState.currentState!.save();

                                        setState(() {
                                          pageIndex = 1;
                                        });

                                        refresh();
                                      }

                                      if (BaseSettings.navigatorType ==
                                          BaseNavigatorType.legacy) {
                                        Navigators.pop();
                                      } else {
                                        context.pop();
                                      }
                                    },
                                    icon: const Icon(Icons.search),
                                    label: Text("search".tr()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget filterCard({
    required String title,
    required Widget child,
    required bool canClear,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: EdgeInsets.all(Dimensions.size15),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: 1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface(),
                  ),
                ),
              ),
              IconButton(
                onPressed: canClear ? onClear : null,
                icon: const Icon(Icons.backspace),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          child,
        ],
      ),
    );
  }

  Widget filterInput({
    required Filter filter,
    required void Function(void Function()) setStateSheet,
    required VoidCallback onChanged,
  }) {
    Widget widget = const SizedBox.shrink();

    if (filter.type == "STRING") {
      widget = TextFormField(
        controller: filter.controller,
        decoration: inputDecoration(hint: filter.caption),
        keyboardType: TextInputType.text,
        onChanged: (_) => onChanged(),
        onSaved: (newValue) {
          if (StringUtils.isNotNullOrEmpty(newValue)) {
            filter.value = newValue;
          } else {
            filter.value = null;
          }
        },
      );
    } else if (filter.type == "NUMERIC") {
      widget = TextFormField(
        controller: filter.controller,
        decoration: inputDecoration(hint: filter.caption),
        inputFormatters: [
          ThousandsFormatter(
            allowFraction: true,
            formatter: NumberFormat.decimalPattern("id_ID"),
          ),
        ],
        keyboardType: TextInputType.number,
        onChanged: (_) => onChanged(),
        onSaved: (newValue) {
          filter.value = int.tryParse(newValue ?? "");
        },
      );
    } else if (filter.type == "CHECKBOX") {
      widget = Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: Dimensions.size25,
          height: Dimensions.size25,
          child: Checkbox(
            tristate: true,
            value: filter.value,
            onChanged: (value) {
              setStateSheet(() {
                filter.value = value;
              });
            },
          ),
        ),
      );
    } else if (filter.type == "DATE") {
      widget = TextFormField(
        controller: filter.controller,
        decoration: inputDecoration(
          hint: filter.caption,
          suffixIcon: const Icon(Icons.event),
        ),
        onTap: () {
          BaseSheets.date(
            jiffy: filter.value ?? Jiffy.now(),
            min: Jiffy.parseFromDateTime(DateTime(1900, 1, 1)),
            max: Jiffy.parseFromDateTime(DateTime(2099, 12, 31)),
            onSelected: (jiffy) {
              setStateSheet(() {
                filter.value = jiffy;
                filter.controller!.text = Formats.date(
                  filter.value,
                  defaultString: "",
                );
              });
            },
          );
        },
        readOnly: true,
      );
    } else if (StringUtils.inList(filter.type, ["DATA", "COMBOBOX"])) {
      widget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Map<String, String>? items;

            try {
              context.loaderOverlay.show();

              items = await DotApis.getInstance().dynamicReportResource(
                id: template!.id,
                field: filter.name,
              );
            } catch (e) {
              BaseOverlays.error(
                message: "something_wrong_please_try_again".tr(),
              );
            } finally {
              context.loaderOverlay.hide();
            }

            if (items != null) {
              final List<SpinnerItem> spinnerItems = [];

              for (MapEntry<String, String> mapEntry in items.entries) {
                spinnerItems.add(
                  SpinnerItem(
                    identity: mapEntry.key,
                    description: mapEntry.value,
                  ),
                );
              }

              final SpinnerItem? selectedItem = await BaseSheets.spinner(
                context: context,
                title: filter.caption,
                spinnerItems: spinnerItems,
              );

              if (selectedItem != null) {
                setStateSheet(() {
                  filter.value = selectedItem.identity;
                  filter.controller!.text = selectedItem.description;
                });
              } else {
                setStateSheet(() {
                  filter.value = null;
                  filter.controller!.text = "";
                });
              }
            }
          },
          customBorder: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.size15),
            smoothness: Dimensions.size1,
          ),
          child: Ink(
            width: double.infinity,
            height: Dimensions.size55,
            decoration: ShapeDecoration(
              color: AppColors.surface(),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size15),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.35),
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    StringUtils.isNotNullOrEmpty(filter.controller!.text)
                        ? filter.controller!.text
                        : "choose".tr(),
                    style: TextStyle(
                      fontSize: Dimensions.text16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface().withValues(
                        alpha: StringUtils.isNotNullOrEmpty(
                          filter.controller!.text,
                        )
                            ? 1
                            : 0.65,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Icon(Icons.unfold_more, size: Dimensions.size25),
              ],
            ),
          ),
        ),
      );
    }

    return widget;
  }

  InputDecoration inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    final OutlineInputBorder outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.size20),
      borderSide: BorderSide(
        color: AppColors.outline().withValues(alpha: 0.45),
        width: 1,
      ),
    );

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface(),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size15,
      ),
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
        borderSide: BorderSide(
          color: AppColors.onSurface().withValues(alpha: 0.60),
          width: 1.2,
        ),
      ),
      errorBorder: outline.copyWith(
        borderSide: BorderSide(
          color: Colors.red.withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      focusedErrorBorder: outline.copyWith(
        borderSide: BorderSide(
          color: Colors.red.withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  bool isTricMetric(Field f) {
    final k = f.name.toLowerCase();
    final c = f.caption.toLowerCase();

    bool hit(String s) => k.contains(s) || c.contains(s);

    return hit("qty_alloc") ||
        hit("alloc") ||
        hit("qty_transit") ||
        hit("transit") ||
        hit("booked_total") ||
        hit("booked total") ||
        hit("booked");
  }

  bool forceFullWidth(Field f, String v) {
    final k = f.name.toLowerCase();

    if (k.contains("booking")) {
      return true;
    }

    if (k == "itemdesc" || k == "item_desc") {
      return false;
    }

    if (k.contains("remark") || k.contains("note")) {
      return true;
    }
    if (v.length > 30) {
      return true;
    }

    return false;
  }
}
