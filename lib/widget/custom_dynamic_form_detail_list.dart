// ignore_for_file: always_specify_types, use_build_context_synchronously, empty_catches, cascade_invocations, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_bulk_detail_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_detail_form.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class CustomDynamicFormDetailList extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final void Function()? onRefresh;

  const CustomDynamicFormDetailList({
    super.key,
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.detailForm,
    this.onRefresh,
  });

  @override
  State<CustomDynamicFormDetailList> createState() => CustomDynamicFormDetailListState();
}

class CustomDynamicFormDetailListState extends State<CustomDynamicFormDetailList> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: widget.detailForm,
      builder: (context, child) {
        if (empty()) {
          return const SizedBox.shrink();
        } else {
          List<ListColumn> columns = widget.detailForm.columns.where((element) => !element.primaryKey).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.size15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.detailForm.template.title.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary(),
                              fontSize: Dimensions.text18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        bulkEditButton(),
                      ],
                    ),
                    addButton(),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.detailForm.getData(widget.headerForm).length,
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(
                    color: AppColors.outline(),
                    height: 0,
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  Map<String, dynamic> map = widget.detailForm.getRow(widget.headerForm, index);

                  List<Widget> widgets = [];

                  for (int i = 0; i < columns.length; i++) {
                    if (i % 2 == 0) {
                      List<Widget> children = [];

                      ListColumn lcLeft = columns[i];

                      children.add(
                        childrenWidget(
                          description: lcLeft.description,
                          value: DynamicForms.spell(
                            type: lcLeft.type,
                            value: map[lcLeft.name],
                          ),
                          left: true,
                        ),
                      );

                      if (i + 1 < columns.length) {
                        ListColumn lcRight = columns[i + 1];

                        children.add(
                          SizedBox(
                            width: Dimensions.size15,
                          ),
                        );

                        children.add(
                          childrenWidget(
                            description: lcRight.description,
                            value: DynamicForms.spell(
                              type: lcRight.type,
                              value: map[lcRight.name],
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

                      if (i + 2 < columns.length) {
                        widgets.add(
                          SizedBox(
                            height: Dimensions.size15,
                          ),
                        );
                      }
                    }
                  }

                  return InkWell(
                    onTap: () {

                      BottomSheets.popupMenu(
                        context: context,
                        menuItems: [
                          MenuItem(
                            iconData: Icons.visibility,
                            title: "Lihat Data",
                            onTap: () async {
                              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                                Navigators.pop();

                                await Navigators.push(
                                  CustomDynamicFormDetailForm(
                                    customerId: widget.customerId,
                                    readOnly: true,
                                    headerForm: widget.headerForm,
                                    detailForm: widget.detailForm,
                                    data: widget.detailForm.getRow(widget.headerForm, index),
                                  ),
                                );
                              } else {
                                context.pop();

                                await context.push(
                                  "/dynamic-form-details",
                                  extra: {
                                    "customerId": widget.customerId,
                                    "readOnly": true,
                                    "headerForm": widget.headerForm,
                                    "detailForm": widget.detailForm,
                                    "data": widget.detailForm.getRow(widget.headerForm, index),
                                  },
                                );
                              }
                            },
                          ),
                          MenuItem(
                            iconData: Icons.edit,
                            title: "edit".tr(),
                            onTap: !isReadOnly() ? () async {
                              Map<String, dynamic>? result;

                              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                                Navigators.pop();

                                result = await Navigators.push(
                                  CustomDynamicFormDetailForm(
                                    customerId: widget.customerId,
                                    readOnly: false,
                                    headerForm: widget.headerForm,
                                    detailForm: widget.detailForm,
                                    data: widget.detailForm.getRow(widget.headerForm, index),
                                  ),
                                );
                              } else {
                                context.pop();

                                result = await context.push(
                                  "/dynamic-form-details",
                                  extra: {
                                    "customerId": widget.customerId,
                                    "readOnly": false,
                                    "headerForm": widget.headerForm,
                                    "detailForm": widget.detailForm,
                                    "data": widget.detailForm.getRow(widget.headerForm, index),
                                  },
                                );
                              }

                              if (result != null) {
                                widget.detailForm.updateRow(widget.headerForm, result, index);

                                if (widget.detailForm.hasOnChangeEvent) {
                                  if (widget.onRefresh != null) {
                                    widget.onRefresh!();
                                  }
                                }
                              }
                            } : null,
                          ),
                          MenuItem(
                            iconData: Icons.delete,
                            title: "delete".tr(),
                            onTap: (!isReadOnly() && hasDeleteAccess()) ? () {
                              BaseDialogs.confirmation(
                                title: "are_you_sure_want_to_proceed".tr(),
                                positiveCallback: () {
                                  if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                                    Navigators.pop();
                                  } else {
                                    context.pop();
                                  }

                                  widget.detailForm.deleteRow(widget.headerForm, index);

                                  if (widget.detailForm.hasOnChangeEvent) {
                                    if (widget.onRefresh != null) {
                                      widget.onRefresh!();
                                    }
                                  }
                                },
                              );
                            } : null,
                          ),
                        ],
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(Dimensions.size15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widgets,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

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

  Widget addButton() {
    if (!isReadOnly() && hasAddAccess()) {
      return Container(
        height: Dimensions.size50,
        margin: EdgeInsets.only(top: Dimensions.size10),
        child: OutlinedButton(
          onPressed: () async {
            Map<String, dynamic>? result;

            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              result = await Navigators.push(
                CustomDynamicFormDetailForm(
                  customerId: widget.customerId,
                  readOnly: false,
                  headerForm: widget.headerForm,
                  detailForm: widget.detailForm,
                  data: {},
                ),
              );
            } else {
              result = await context.push(
                "/dynamic-form-details",
                extra: {
                  "customerId": widget.customerId,
                  "readOnly": false,
                  "headerForm": widget.headerForm,
                  "detailForm": widget.detailForm,
                },
              );
            }

            if (result != null) {
              widget.detailForm.addRow(widget.headerForm, result);

              if (widget.detailForm.hasOnChangeEvent) {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
              ),
              SizedBox(
                width: Dimensions.size5,
              ),
              Text(
                "add".tr(),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget bulkEditButton() {
    if (!isReadOnly() && widget.detailForm.getData(widget.headerForm).length > 1) {
      return Container(
        margin: EdgeInsets.only(left: Dimensions.size10),
        child: IconButton.filledTonal(
          onPressed: () async {
            List<Map<String, dynamic>>? result;

            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              result = await Navigators.push(
                CustomDynamicFormBulkDetailForm(
                  customerId: widget.customerId,
                  readOnly: false,
                  headerForm: widget.headerForm,
                  detailForm: widget.detailForm,
                  rows: (widget.detailForm.getData(widget.headerForm) as List<Map<String, dynamic>>).mapIndexed((index, e) {
                    return widget.detailForm.getRow(widget.headerForm, index);
                  }).toList(),
                ),
              );
            } else {
              result = await context.push(
                "/dynamic-form-bulk-details",
                extra: {
                  "customerId": widget.customerId,
                  "readOnly": false,
                  "headerForm": widget.headerForm,
                  "detailForm": widget.detailForm,
                  "rows": (widget.detailForm.getData(widget.headerForm) as List<Map<String, dynamic>>).mapIndexed((index, e) {
                    return widget.detailForm.getRow(widget.headerForm, index);
                  }).toList(),
                },
              );
            }

            if (result != null) {
              result.forEachIndexed((index, element) {
                widget.detailForm.updateRow(widget.headerForm, element, index);
              });

              if (widget.detailForm.hasOnChangeEvent) {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              }
            }
          },
          icon: Icon(Icons.dynamic_form_outlined),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool isReadOnly() {
    return widget.readOnly;
  }

  bool hasAddAccess() {
    return widget.headerForm.template.actions.any((element) => element.resourceId == "BTN_ADD_DETAIL");
  }

  bool hasDeleteAccess() {
    return widget.headerForm.template.actions.any((element) => element.resourceId == "BTN_DEL_DETAIL");
  }

  bool empty() {
    return !(!isReadOnly() && hasAddAccess()) && widget.detailForm.getData(widget.headerForm).isEmpty;
  }
}