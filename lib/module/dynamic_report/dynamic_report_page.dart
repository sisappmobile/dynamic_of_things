// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, empty_catches, use_build_context_synchronously

import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
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

class DynamicReportPageState extends State<DynamicReportPage> with WidgetsBindingObserver {
  Template? template;

  DataResponse? dataResponse;

  bool loading = true;

  String? sortField;
  SortDirection? sortDirection;

  int size = 0;
  int pageSize = 20;
  int pageIndex = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    context.read<DynamicReportBloc>().add(
      DynamicReportTemplate(
        id: widget.dynamicFormMenuItem.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: BaseScaffold(
        context: context,
        statusBuilder: () {
          if (template != null) {
            if (loading) {
              return BaseBodyStatus.loading;
            } else {
              if (dataResponse != null) {
                return BaseBodyStatus.loaded;
              } else {
                return BaseBodyStatus.fail;
              }
            }
          }

          return BaseBodyStatus.loading;
        },
        appBar: BaseAppBar(
          context: context,
          name: widget.dynamicFormMenuItem.name,
          description: widget.dynamicFormCategoryItem.name,
          trailings: [
            IconButton(
              onPressed: () async {
                await openFilter();
              },
              icon: const Icon(Icons.filter_alt),
            ),
            IconButton(
              onPressed: () async {
                context.read<DynamicReportBloc>().add(
                  DynamicReportExport(
                    id: widget.dynamicFormMenuItem.id,
                    dataRequest: DataRequest(
                      size: pageSize,
                      index: pageIndex - 1,
                      sortField: sortField,
                      sortDirection: sortDirection?.name,
                      filters: Map.fromEntries(
                        template!.filters.where((element) => element.value != null).map((e) {
                          return MapEntry(e.id, e.value);
                        }),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.cloud_download_outlined),
            ),
          ],
        ),
        contentBuilder: body,
        bottomNavigationBar: bottomBar(),
      ),
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

  void refresh() {
    context.read<DynamicReportBloc>().add(
      DynamicReportData(
        id: widget.dynamicFormMenuItem.id,
        dataRequest: DataRequest(
          size: pageSize,
          index: pageIndex - 1,
          sortField: sortField,
          sortDirection: sortDirection?.name,
          filters: Map.fromEntries(
            template!.filters.where((element) => element.value != null).map((e) {
              return MapEntry(e.id, e.value);
            }),
          ),
        ),
      ),
    );
  }

  Widget body() {
    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: dataResponse!.rows.length,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            color: AppColors.outline(),
            height: 0,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> map = dataResponse!.rows[index];

          List<Widget> widgets = [];

          for (int i = 0; i < template!.fields.length; i++) {
            if (i % 2 == 0) {
              List<Widget> children = [];

              Field leftField = template!.fields[i];

              children.add(
                childrenWidget(
                  description: leftField.caption,
                  value: DynamicForms.spell(
                    type: leftField.type,
                    value: map[leftField.name],
                  ),
                  left: true,
                ),
              );

              if (i + 1 < template!.fields.length) {
                Field rightField = template!.fields[i + 1];

                children.add(
                  SizedBox(
                    width: Dimensions.size20,
                  ),
                );

                children.add(
                  childrenWidget(
                    description: rightField.caption,
                    value: DynamicForms.spell(
                      type: rightField.type,
                      value: map[rightField.name],
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

              if (i + 2 < template!.fields.length) {
                widgets.add(
                  SizedBox(
                    height: Dimensions.size10,
                  ),
                );
              }
            }
          }

          return Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(Dimensions.size20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            ),
          );
        },
      ),
    );
  }

  Widget bottomBar() {
    return BaseBottomBar(
        children: [
          Text(
            dataInfo(
              pageIndex: pageIndex,
              pageSize: pageSize,
              dataSize: dataResponse?.size,
            ),
          ),
          Expanded(
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
              colorSub: AppColors.surface(),
              buttonRadius: Dimensions.size50,
              buttonElevation: 0,
              threshold: 1,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicWidth(
                child: Container(
                  height: Dimensions.size35,
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.size10),
                      smoothness: 1,
                      side: BorderSide(
                        color: AppColors.outline(),
                      ),
                    ),
                    color: AppColors.surface(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      isExpanded: true,
                      borderRadius: BorderRadius.all(
                        Radius.circular(Dimensions.size5),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.size10,
                      ),
                      value: pageSize,
                      items: const [
                        DropdownMenuItem(value: 20, child: Text("20")),
                        DropdownMenuItem(value: 50, child: Text("50")),
                        DropdownMenuItem(value: 100, child: Text("100")),
                      ],
                      onChanged: (value) {
                        pageSize = value!;

                        refresh();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            description,
            textAlign: left ? TextAlign.start : TextAlign.end,
          ),
          Text(
            value,
            textAlign: left ? TextAlign.start : TextAlign.end,
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openFilter() async {
    final GlobalKey<FormState> formState = GlobalKey<FormState>(debugLabel: "formState");

    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: SmoothRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.size20),
          topRight: Radius.circular(Dimensions.size20),
        ),
        smoothness: 1,
        side: BorderSide(color: AppColors.outline()),
      ),
      barrierColor: Colors.black12,
      backgroundColor: AppColors.surface(),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.size20,
                      vertical: Dimensions.size10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.outline(),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(
                            Icons.turn_left,
                          ),
                          iconSize: Dimensions.size30,
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: Dimensions.size10,
                            ),
                            child: Text(
                              "filter".tr(),
                              style: TextStyle(
                                fontSize: Dimensions.text20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(Dimensions.size20),
                      color: AppColors.surface(),
                      child: Form(
                        key: formState,
                        autovalidateMode: AutovalidateMode.always,
                        child: ListView.separated(
                          itemCount: template!.filters.length,
                          padding: EdgeInsets.only(
                            bottom: Dimensions.size100,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            Filter filter = template!.filters[index];

                            if (filter.controller == null) {
                              filter.controller = TextEditingController();

                              if (filter.value != null) {
                                if (filter.type == "DATE") {
                                  filter.controller!.text = Formats.dateTime(filter.value);
                                } else if (filter.type == "NUMERIC") {
                                  filter.controller!.text = Formats.tryParseNumber(filter.value).currency();
                                } else if (filter.type == "STRING") {
                                  filter.controller!.text = filter.value;
                                }
                              }
                            }

                            Widget widget = const SizedBox.shrink();

                            if (filter.type == "STRING") {
                              widget = TextFormField(
                                controller: filter.controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  filled: true,
                                ),
                                keyboardType: TextInputType.text,
                                onChanged: (value) {
                                  setState(() {});
                                },
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
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  filled: true,
                                ),
                                inputFormatters: [
                                  ThousandsFormatter(
                                    allowFraction: true,
                                    formatter: NumberFormat.decimalPattern("id_ID"),
                                  ),
                                ],
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {});
                                },
                                onSaved: (newValue) {
                                  filter.value = int.tryParse(newValue ?? "");
                                },
                              );
                            } else if (filter.type == "CHECKBOX") {
                              widget = Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: Dimensions.size20,
                                  height: Dimensions.size20,
                                  child: Checkbox(
                                    tristate: true,
                                    value: filter.value,
                                    onChanged: (value) {
                                      setState(() {
                                        filter.value = value;
                                      });
                                    },
                                  ),
                                ),
                              );
                            } else if (filter.type == "DATE") {
                              widget = TextFormField(
                                controller: filter.controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  suffixIcon: Icon(
                                    Icons.event,
                                  ),
                                ),
                                onTap: () {
                                  BaseSheets.date(
                                    jiffy: filter.value ?? Jiffy.now(),
                                    min: Jiffy.parseFromDateTime(DateTime(1900, 1, 1)),
                                    max: Jiffy.parseFromDateTime(DateTime(2099, 12, 31)),
                                    onSelected: (jiffy) {
                                      setState(() {
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
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      filter.caption,
                                      style: TextStyle(
                                        fontSize: Dimensions.text16,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: AppColors.outline().withValues(alpha: 0.5),
                                        indent: Dimensions.size10,
                                        height: 0,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: filter.value != null ||
                                          StringUtils.isNotNullOrEmpty(
                                            filter.controller!.text,
                                          )
                                          ? () {
                                        filter.value = null;
                                        filter.controller = null;

                                        setState(() {});
                                      }
                                          : null,
                                      icon: const Icon(Icons.backspace),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: Dimensions.size10,
                                ),
                                widget,
                              ],
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(
                              height: Dimensions.size10,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.size20,
                      vertical: Dimensions.size15,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          width: 0.2,
                          color: AppColors.outline(),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Visibility(
                          visible: template!.filters.any((filter) => filter.value != null || (filter.controller != null && StringUtils.isNotNullOrEmpty(filter.controller!.text))),
                          child: TextButton(
                            onPressed: () async {
                              BaseDialogs.confirmation(
                                title: "are_you_sure_want_to_proceed".tr(),
                                positiveCallback: () {
                                  for (Filter filter in template!.filters) {
                                    filter.value = null;
                                    filter.controller = null;
                                  }

                                  setState(() {});
                                },
                              );
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(Dimensions.size5),
                                ),
                              ),
                              padding: EdgeInsets.all(
                                Dimensions.size10,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.clear_all,
                                ),
                                SizedBox(width: Dimensions.size5),
                                Text("clear".tr()),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            if (formState.currentState != null && formState.currentState!.validate()) {
                              formState.currentState!.save();

                              refresh();
                            }

                            context.pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary(),
                            foregroundColor: AppColors.onPrimary(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(Dimensions.size5),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.size10,
                              horizontal: Dimensions.size10,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                              ),
                              SizedBox(width: Dimensions.size5),
                              Text("search".tr()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
