import "package:base/base.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_sub_detail_form.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class CustomDynamicFormSubDetailList extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final SubDetailForm subDetailForm;
  final Map<String, dynamic> detailData;
  final void Function()? onRefresh;

  const CustomDynamicFormSubDetailList({
    super.key,
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.detailForm,
    required this.subDetailForm,
    required this.detailData,
    this.onRefresh,
  });

  @override
  State<CustomDynamicFormSubDetailList> createState() =>
      CustomDynamicFormSubDetailListState();
}

class CustomDynamicFormSubDetailListState
    extends State<CustomDynamicFormSubDetailList>
    with AutomaticKeepAliveClientMixin {
  late Map<String, dynamic> detailData;

  static const double _gapCard = 10;
  static const double _gapInner = 8;

  static const double _tilePadX = 10;
  static const double _tilePadY = 10;

  @override
  void initState() {
    super.initState();

    detailData = widget.detailData;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: widget.subDetailForm,
      builder: (context, child) {
        if (empty()) {
          return const SizedBox.shrink();
        } else {
          List<ListColumn> columns = widget.subDetailForm.columns
              .where((element) => !element.primaryKey)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(context),
              SizedBox(height: Dimensions.size10),
              _listHost(context, columns),
            ],
          );
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  Widget _headerCard(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(Dimensions.size15),
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
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.35),
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
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(Dimensions.size100),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.layers_rounded,
                      size: Dimensions.size15,
                      color: primary,
                    ),
                    SizedBox(width: Dimensions.size5),
                    Text(
                      widget.subDetailForm.template.title.toUpperCase(),
                      style: TextStyle(
                        color: primary,
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!isReadOnly() && hasAddAccess())
                _miniAddButton(context: context),
            ],
          ),
          if (!isReadOnly() && hasAddAccess()) ...[
            SizedBox(height: Dimensions.size10),
            ...addButton(),
          ],
        ],
      ),
    );
  }

  Widget _miniAddButton({required BuildContext context}) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Map<String, dynamic>? result;

          if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
            result = await Navigators.push(
              CustomDynamicFormSubDetailForm(
                customerId: widget.customerId,
                readOnly: false,
                headerForm: widget.headerForm,
                detailForm: widget.detailForm,
                subDetailForm: widget.subDetailForm,
                data: {},
              ),
            );
          } else {
            result = await context.push(
              "/dynamic-form-sub-details",
              extra: {
                "customerId": widget.customerId,
                "readOnly": false,
                "headerForm": widget.headerForm,
                "detailForm": widget.detailForm,
                "subDetailForm": widget.subDetailForm,
              },
            );
          }

          if (result != null) {
            widget.subDetailForm.addRow(detailData, result);

            if (widget.subDetailForm.hasOnChangeEvent) {
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
            }
          }
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            size: Dimensions.size20,
            color: onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _listHost(BuildContext context, List<ListColumn> columns) {
    final int count = widget.subDetailForm.getRows(detailData).length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: _gapCard),
      itemBuilder: (BuildContext context, int index) {
        Map<String, dynamic> map =
            widget.subDetailForm.getRow(detailData, index);

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

              children.add(const SizedBox(width: _gapInner));

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
              widgets.add(const SizedBox(height: _gapInner));
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
                          CustomDynamicFormSubDetailForm(
                            customerId: widget.customerId,
                            readOnly: true,
                            headerForm: widget.headerForm,
                            detailForm: widget.detailForm,
                            subDetailForm: widget.subDetailForm,
                            data:
                                widget.subDetailForm.getRow(detailData, index),
                          ),
                        );
                      } else {
                        context.pop();

                        await context.push(
                          "/dynamic-form-sub-details",
                          extra: {
                            "customerId": widget.customerId,
                            "readOnly": true,
                            "headerForm": widget.headerForm,
                            "detailForm": widget.detailForm,
                            "subDetailForm": widget.subDetailForm,
                            "data":
                                widget.subDetailForm.getRow(detailData, index),
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
                                CustomDynamicFormSubDetailForm(
                                  customerId: widget.customerId,
                                  readOnly: false,
                                  headerForm: widget.headerForm,
                                  detailForm: widget.detailForm,
                                  subDetailForm: widget.subDetailForm,
                                  data: widget.subDetailForm
                                      .getRow(detailData, index),
                                ),
                              );
                            } else {
                              context.pop();

                              result = await context.push(
                                "/dynamic-form-sub-details",
                                extra: {
                                  "customerId": widget.customerId,
                                  "readOnly": false,
                                  "headerForm": widget.headerForm,
                                  "detailForm": widget.detailForm,
                                  "subDetailForm": widget.subDetailForm,
                                  "data": widget.subDetailForm
                                      .getRow(detailData, index),
                                },
                              );
                            }

                            if (result != null) {
                              widget.subDetailForm
                                  .updateRow(detailData, result, index);

                              if (widget.subDetailForm.hasOnChangeEvent) {
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
                              title: "are_you_sure_want_to_proceed".tr(),
                              positiveCallback: () {
                                if (BaseSettings.navigatorType ==
                                    BaseNavigatorType.legacy) {
                                  Navigators.pop();
                                } else {
                                  context.pop();
                                }

                                widget.subDetailForm
                                    .deleteRow(detailData, index);

                                if (widget.subDetailForm.hasOnChangeEvent) {
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
                  smoothness: Dimensions.size1,
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
    );
  }

  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _tilePadX,
          vertical: _tilePadY,
        ),
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
              (value.isNotEmpty) ? value : "-",
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

  List<Widget> addButton() {
    if (!isReadOnly() && hasAddAccess()) {
      return [
        SizedBox(height: Dimensions.size10),
        SizedBox(
          height: Dimensions.size50,
          child: OutlinedButton(
            onPressed: () async {
              Map<String, dynamic>? result;

              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                result = await Navigators.push(
                  CustomDynamicFormSubDetailForm(
                    customerId: widget.customerId,
                    readOnly: false,
                    headerForm: widget.headerForm,
                    detailForm: widget.detailForm,
                    subDetailForm: widget.subDetailForm,
                    data: {},
                  ),
                );
              } else {
                result = await context.push(
                  "/dynamic-form-sub-details",
                  extra: {
                    "customerId": widget.customerId,
                    "readOnly": false,
                    "headerForm": widget.headerForm,
                    "detailForm": widget.detailForm,
                    "subDetailForm": widget.subDetailForm,
                  },
                );
              }

              if (result != null) {
                widget.subDetailForm.addRow(detailData, result);

                if (widget.subDetailForm.hasOnChangeEvent) {
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add),
                SizedBox(width: Dimensions.size5),
                Text("add".tr()),
              ],
            ),
          ),
        ),
      ];
    }

    return [];
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
        widget.subDetailForm.getRows(detailData).isEmpty;
  }
}
