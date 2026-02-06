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
import "package:smooth_corner/smooth_corner.dart";

class CustomDynamicFormDetailList extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final void Function()? onRefresh;

  const CustomDynamicFormDetailList({
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.detailForm,
    this.onRefresh,
    super.key,
  });

  @override
  State<CustomDynamicFormDetailList> createState() =>
      CustomDynamicFormDetailListState();
}

class CustomDynamicFormDetailListState
    extends State<CustomDynamicFormDetailList>
    with AutomaticKeepAliveClientMixin {
  static const double _gapCard = 10;
  static const double _gapInner = 8;

  static const double _tilePadX = 10;
  static const double _tilePadY = 10;

  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();
  Color _primary(BuildContext context) => Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: widget.detailForm,
      builder: (context, child) {
        if (empty()) {
          return const SizedBox.shrink();
        } else {
          List<ListColumn> columns = widget.detailForm.columns
              .where((element) => !element.primaryKey)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  Dimensions.size10,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                child: Container(
                  padding: EdgeInsets.all(Dimensions.size15),
                  decoration: ShapeDecoration(
                    color: _card(context),
                    shadows: [
                      BoxShadow(
                        blurRadius: Dimensions.size20,
                        offset: Offset(0, Dimensions.size10),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.size20),
                      smoothness: Dimensions.size1,
                      side: BorderSide(
                        color: _outline(context).withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.size10,
                                    vertical: Dimensions.size5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary(context)
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.size100,
                                    ),
                                    border: Border.all(
                                      color: _primary(context)
                                          .withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.list_alt_rounded,
                                        size: Dimensions.size15,
                                        color: _primary(context),
                                      ),
                                      SizedBox(width: Dimensions.size5),
                                      Text(
                                        widget.detailForm.template.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _primary(context),
                                          fontSize: Dimensions.text13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          bulkEditButton(),
                        ],
                      ),
                      SizedBox(height: Dimensions.size10),
                      addButton(),
                    ],
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  0,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                itemCount: widget.detailForm.getData(widget.headerForm).length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(height: _gapCard);
                },
                itemBuilder: (BuildContext context, int index) {
                  Map<String, dynamic> map =
                      widget.detailForm.getRow(widget.headerForm, index);

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

                        children
                          ..add(SizedBox(width: _gapInner))
                          ..add(
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
                        widgets.add(SizedBox(height: _gapInner));
                      }
                    }
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        BottomSheets.popupMenu(
                          context: context,
                          menuItems: [
                            MenuItem(
                              iconData: Icons.visibility,
                              title: "Lihat Data",
                              onTap: () async {
                                if (BaseSettings.navigatorType ==
                                    BaseNavigatorType.legacy) {
                                  Navigators.pop();

                                  await Navigators.push(
                                    CustomDynamicFormDetailForm(
                                      customerId: widget.customerId,
                                      readOnly: true,
                                      headerForm: widget.headerForm,
                                      detailForm: widget.detailForm,
                                      data: widget.detailForm
                                          .getRow(widget.headerForm, index),
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
                                      "data": widget.detailForm
                                          .getRow(widget.headerForm, index),
                                    },
                                  );
                                }
                              },
                            ),
                            MenuItem(
                              iconData: Icons.edit,
                              title: "edit".tr(),
                              onTap: !isReadOnly()
                                  ? () async {
                                      Map<String, dynamic>? result;

                                      if (BaseSettings.navigatorType ==
                                          BaseNavigatorType.legacy) {
                                        Navigators.pop();

                                        result = await Navigators.push(
                                          CustomDynamicFormDetailForm(
                                            customerId: widget.customerId,
                                            readOnly: false,
                                            headerForm: widget.headerForm,
                                            detailForm: widget.detailForm,
                                            data: widget.detailForm.getRow(
                                              widget.headerForm,
                                              index,
                                            ),
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
                                            "data": widget.detailForm.getRow(
                                              widget.headerForm,
                                              index,
                                            ),
                                          },
                                        );
                                      }

                                      if (result != null) {
                                        widget.detailForm.updateRow(
                                          widget.headerForm,
                                          result,
                                          index,
                                        );

                                        if (widget
                                            .detailForm.hasOnChangeEvent) {
                                          if (widget.onRefresh != null) {
                                            widget.onRefresh!();
                                          }
                                        }
                                      }
                                    }
                                  : null,
                            ),
                            MenuItem(
                              iconData: Icons.delete,
                              title: "delete".tr(),
                              onTap: (!isReadOnly() && hasDeleteAccess())
                                  ? () {
                                      BaseDialogs.confirmation(
                                        title:
                                            "are_you_sure_want_to_proceed".tr(),
                                        positiveCallback: () {
                                          if (BaseSettings.navigatorType ==
                                              BaseNavigatorType.legacy) {
                                            Navigators.pop();
                                          } else {
                                            context.pop();
                                          }

                                          widget.detailForm.deleteRow(
                                            widget.headerForm,
                                            index,
                                          );

                                          if (widget
                                              .detailForm.hasOnChangeEvent) {
                                            if (widget.onRefresh != null) {
                                              widget.onRefresh!();
                                            }
                                          }
                                        },
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        );
                      },
                      customBorder: SmoothRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.size20),
                        smoothness: Dimensions.size1,
                      ),
                      child: Ink(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.all(Dimensions.size15),
                        decoration: ShapeDecoration(
                          color: _card(context),
                          shadows: [
                            BoxShadow(
                              blurRadius: Dimensions.size20,
                              offset: Offset(0, Dimensions.size10),
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ],
                          shape: SmoothRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.size20),
                            smoothness: Dimensions.size1,
                            side: BorderSide(
                              color: _outline(context).withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.size10,
                                    vertical: Dimensions.size5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _soft(context),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.size100,
                                    ),
                                    border: Border.all(
                                      color: _outline(context)
                                          .withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Text(
                                    "#${index + 1}",
                                    style: TextStyle(
                                      fontSize: Dimensions.text12,
                                      fontWeight: FontWeight.w900,
                                      color: _fg(context),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.more_horiz_rounded,
                                  color: _fg(context).withValues(alpha: 0.45),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimensions.size15),
                            ...widgets,
                          ],
                        ),
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
    final String shownValue = (value.isNotEmpty) ? value : "-";

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
            smoothness: Dimensions.size1,
            side: BorderSide(
              color: _outline(context).withValues(alpha: 0.16),
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
                color: _fg(context).withValues(alpha: 0.65),
                fontSize: Dimensions.text12,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: Dimensions.size4),
            Text(
              shownValue,
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

  Widget addButton() {
    if (!isReadOnly() && hasAddAccess()) {
      return SizedBox(
        height: Dimensions.size50,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
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
            borderRadius: BorderRadius.circular(Dimensions.size20),
            child: Ink(
              decoration: ShapeDecoration(
                color: _soft(context),
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size20),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: _outline(context).withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: Dimensions.size30,
                    height: Dimensions.size30,
                    decoration: BoxDecoration(
                      color: _primary(context).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primary(context).withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: _primary(context),
                      size: Dimensions.size20,
                    ),
                  ),
                  SizedBox(width: Dimensions.size10),
                  Text(
                    "add".tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      color: _fg(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget bulkEditButton() {
    if (!isReadOnly() &&
        widget.detailForm.getData(widget.headerForm).length > 1) {
      return Container(
        margin: EdgeInsets.only(left: Dimensions.size10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              List<Map<String, dynamic>>? result;

              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                result = await Navigators.push(
                  CustomDynamicFormBulkDetailForm(
                    customerId: widget.customerId,
                    readOnly: false,
                    headerForm: widget.headerForm,
                    detailForm: widget.detailForm,
                    rows: (widget.detailForm.getData(widget.headerForm)
                            as List<Map<String, dynamic>>)
                        .mapIndexed((index, e) {
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
                    "rows": (widget.detailForm.getData(widget.headerForm)
                            as List<Map<String, dynamic>>)
                        .mapIndexed((index, e) {
                      return widget.detailForm.getRow(widget.headerForm, index);
                    }).toList(),
                  },
                );
              }

              if (result != null) {
                result.forEachIndexed((index, element) {
                  widget.detailForm
                      .updateRow(widget.headerForm, element, index);
                });

                if (widget.detailForm.hasOnChangeEvent) {
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                }
              }
            },
            borderRadius: BorderRadius.circular(Dimensions.size15),
            child: Ink(
              width: Dimensions.size40,
              height: Dimensions.size40,
              decoration: ShapeDecoration(
                color: _soft(context),
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: _outline(context).withValues(alpha: 0.20),
                  ),
                ),
              ),
              child: Icon(
                Icons.dynamic_form_outlined,
                color: _fg(context),
                size: Dimensions.size20,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool isReadOnly() {
    return widget.readOnly;
  }

  bool hasAddAccess() {
    return widget.headerForm.template.actions
        .any((element) => element.resourceId == "BTN_ADD_DETAIL");
  }

  bool hasDeleteAccess() {
    return widget.headerForm.template.actions
        .any((element) => element.resourceId == "BTN_DEL_DETAIL");
  }

  bool empty() {
    return !(!isReadOnly() && hasAddAccess()) &&
        widget.detailForm.getData(widget.headerForm).isEmpty;
  }
}
