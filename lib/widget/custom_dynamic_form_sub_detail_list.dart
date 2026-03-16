// ignore_for_file: deprecated_member_use

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_sub_detail_form.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
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
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.detailForm,
    required this.subDetailForm,
    required this.detailData,
    this.onRefresh,
    super.key,
  });

  @override
  State<CustomDynamicFormSubDetailList> createState() =>
      CustomDynamicFormSubDetailListState();
}

class CustomDynamicFormSubDetailListState
    extends State<CustomDynamicFormSubDetailList>
    with AutomaticKeepAliveClientMixin {
  late Map<String, dynamic> detailData;

  // PERBAIKAN: Spasi antar kartu dibuat lebih lega
  static const double gapCard = 16;
  static const double gapInner = 12;

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
              headerSection(context), // PERBAIKAN: Diubah jadi section (tanpa bungkus card tebal)
              SizedBox(height: Dimensions.size15),
              listHost(context, columns),
            ],
          );
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

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

  // PERBAIKAN UTAMA: Dihapuskannya bungkus Container/GlassContainer global 
  // agar sub-detail bisa langsung bernafas di latar belakang utamanya
  Widget headerSection(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Column(
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
              miniAddButton(context: context),
          ],
        ),
        if (!isReadOnly() && hasAddAccess()) ...[
          SizedBox(height: Dimensions.size10),
          ...addButton(),
        ],
      ],
    );
  }

  Widget miniAddButton({required BuildContext context}) {
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
          width: Dimensions.size35,
          height: Dimensions.size35,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
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

  Widget listHost(BuildContext context, List<ListColumn> columns) {
    final int count = widget.subDetailForm.getRows(detailData).length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: count,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: gapCard),
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

              children
                ..add(const SizedBox(width: gapInner))
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
              widgets.add(const SizedBox(height: gapInner));
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
            child: Builder(
              builder: (context) {
                final Widget content = Padding(
                  padding: EdgeInsets.all(Dimensions.size20), // Padding diperbesar agar nyaman dilihat
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
                  ),
                );

                if (isGlass) {
                  return GlassContainer(
                    blur: Dimensions.size20,
                    borderRadius: Dimensions.size20,
                    opacity: 0.12,
                    borderOpacity: 0.22,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: content,
                    ),
                  );
                }

                return Ink(
                  width: MediaQuery.of(context).size.width,
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
              },
            ),
          ),
        );
      },
    );
  }

  // PERBAIKAN UTAMA: Format teks disamakan, rata kiri, dan box border dibuang 
  // agar tampil murni seperti grid/tabel minimalis di atas card utamanya.
  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    final String shownValue = (value.isNotEmpty) ? value : "-";

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Format rata kiri semua untuk kerapian
        children: [
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isGlass
                  ? Colors.white.withOpacity(0.70)
                  : AppColors.onSurface().withValues(alpha: 0.65),
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            shownValue,
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

  List<Widget> addButton() {
    if (!isReadOnly() && hasAddAccess()) {
      Future<void> handleAdd() async {
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
      }

      return [
        SizedBox(height: Dimensions.size10),
        SizedBox(
          height: Dimensions.size50,
          child: isGlass
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: handleAdd,
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    child: GlassContainer(
                      blur: Dimensions.size15,
                      borderRadius: Dimensions.size15,
                      opacity: 0.10,
                      borderOpacity: 0.18,
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.size15,
                        vertical: Dimensions.size10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: isGlass
                                ? Colors.white.withOpacity(0.92)
                                : AppColors.onSurface(),
                          ),
                          SizedBox(width: Dimensions.size5),
                          Text(
                            "add".tr(),
                            style: TextStyle(
                              color: isGlass
                                  ? Colors.white.withOpacity(0.92)
                                  : AppColors.onSurface(),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: handleAdd,
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