// ignore_for_file: deprecated_member_use

import "package:base/base.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_bulk_detail_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_detail_form.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
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
  static const double gapCard = 10;
  static const double gapInner = 8;

  static const double tilePadX = 10;
  static const double tilePadY = 10;

  bool get isGlass {
    try {
      return (Preferences.getInstance()
                  .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
              1) ==
          2;
    } catch (_) {
      return false;
    }
  }

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
                child: Builder(
                  builder: (context) {
                    final Widget headerContent = Column(
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.size100,
                                      ),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.list_alt_rounded,
                                          size: Dimensions.size15,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        SizedBox(width: Dimensions.size5),
                                        Text(
                                          widget.detailForm.template.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
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
                    );

                    if (isGlass) {
                      return GlassContainer(
                        blur: Dimensions.size20,
                        borderRadius: Dimensions.size20,
                        opacity: 0.12,
                        borderOpacity: 0.22,
                        padding: EdgeInsets.all(Dimensions.size15),
                        child: headerContent,
                      );
                    }

                    return Container(
                      padding: EdgeInsets.all(Dimensions.size15),
                      decoration: ShapeDecoration(
                        color: isGlass
                            ? Colors.white.withOpacity(0.10)
                            : AppColors.surface(),
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
                            color: isGlass
                                ? Colors.white.withOpacity(0.18)
                                : AppColors.outline().withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: headerContent,
                    );
                  },
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
                  return const SizedBox(height: gapCard);
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
                          ..add(SizedBox(width: gapInner))
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
                        widgets.add(SizedBox(height: gapInner));
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
                      child: Builder(
                        builder: (context) {
                          final Widget content = Column(
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
                                      color: isGlass
                                          ? Colors.white.withOpacity(0.08)
                                          : AppColors.surfaceContainerLowest(),
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.size100,
                                      ),
                                      border: Border.all(
                                        color: isGlass
                                            ? Colors.white.withOpacity(0.18)
                                            : AppColors.outline()
                                                .withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Text(
                                      "#${index + 1}",
                                      style: TextStyle(
                                        fontSize: Dimensions.text12,
                                        fontWeight: FontWeight.w900,
                                        color: isGlass
                                            ? Colors.white.withOpacity(0.92)
                                            : AppColors.onSurface(),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.more_horiz_rounded,
                                    color: isGlass
                                        ? Colors.white.withOpacity(0.92)
                                        : AppColors.onSurface()
                                            .withValues(alpha: 0.45),
                                  ),
                                ],
                              ),
                              SizedBox(height: Dimensions.size15),
                              ...widgets,
                            ],
                          );

                          if (isGlass) {
                            return GlassContainer(
                              blur: Dimensions.size20,
                              borderRadius: Dimensions.size20,
                              opacity: 0.12,
                              borderOpacity: 0.22,
                              padding: EdgeInsets.all(Dimensions.size15),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: content,
                              ),
                            );
                          }

                          return Ink(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(Dimensions.size15),
                            decoration: ShapeDecoration(
                              color: isGlass
                                  ? Colors.white.withOpacity(0.10)
                                  : AppColors.surface(),
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
                                  color: isGlass
                                      ? Colors.white.withOpacity(0.18)
                                      : AppColors.outline()
                                          .withValues(alpha: 0.18),
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
          horizontal: tilePadX,
          vertical: tilePadY,
        ),
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
                  : AppColors.outline().withValues(alpha: 0.16),
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
                color: isGlass
                    ? Colors.white.withOpacity(0.92)
                    : AppColors.onSurface().withValues(alpha: 0.65),
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
                color: isGlass
                    ? Colors.white.withOpacity(0.92)
                    : AppColors.onSurface(),
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
            child: Builder(
              builder: (context) {
                final Widget content = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: Dimensions.size30,
                      height: Dimensions.size30,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: Dimensions.size20,
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Text(
                      "add".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: isGlass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface(),
                      ),
                    ),
                  ],
                );

                if (isGlass) {
                  return GlassContainer(
                    blur: Dimensions.size15,
                    borderRadius: Dimensions.size20,
                    opacity: 0.10,
                    borderOpacity: 0.18,
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.size15,
                      vertical: Dimensions.size10,
                    ),
                    child: content,
                  );
                }

                return Ink(
                  decoration: ShapeDecoration(
                    color: isGlass
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.surfaceContainerLowest(),
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.size20),
                      smoothness: Dimensions.size1,
                      side: BorderSide(
                        color: isGlass
                            ? Colors.white.withOpacity(0.18)
                            : AppColors.outline().withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  child: content,
                );
              },
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
            child: Builder(
              builder: (context) {
                final Widget icon = SizedBox(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
                  child: Icon(
                    Icons.dynamic_form_outlined,
                    color: isGlass
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.onSurface(),
                    size: Dimensions.size20,
                  ),
                );

                if (isGlass) {
                  return GlassContainer(
                    blur: Dimensions.size15,
                    borderRadius: Dimensions.size15,
                    opacity: 0.10,
                    borderOpacity: 0.18,
                    padding: EdgeInsets.zero,
                    child: icon,
                  );
                }

                return Ink(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
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
                            : AppColors.outline().withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.dynamic_form_outlined,
                    color: isGlass
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.onSurface(),
                    size: Dimensions.size20,
                  ),
                );
              },
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
