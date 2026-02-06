// ignore_for_file: use_build_context_synchronously

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_event.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_state.dart";
import "package:dynamic_of_things/widget/barcode_scanner_page.dart";
import "package:dynamic_of_things/widget/map_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Action;
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_map/flutter_map.dart";
import "package:go_router/go_router.dart";
import "package:latlong2/latlong.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:smooth_corner/smooth_corner.dart";

class DynamicFormListPage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final String? customerId;
  final bool selectorMode;
  final String? referenceId;

  const DynamicFormListPage({
    required this.dynamicFormMenuItem,
    required this.customerId,
    required this.selectorMode,
    required this.referenceId,
    super.key,
  });

  @override
  DynamicFormListPageState createState() => DynamicFormListPageState();
}

class DynamicFormListPageState extends State<DynamicFormListPage>
    with WidgetsBindingObserver {
  ListResponse? listResponse;

  bool loading = true;

  TextEditingController tecSearch = TextEditingController();

  static const double _gapCard = 10;
  static const double _gapInner = 8;

  static const double _tilePadX = 10;
  static const double _tilePadY = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return BlocListener<DynamicFormListBloc, DynamicFormListState>(
      listener: (context, state) async {
        if (state is DynamicFormListLoadLoading) {
          setState(() {
            loading = true;
            listResponse = null;
          });
        } else if (state is DynamicFormListLoadSuccess) {
          setState(() {
            listResponse = state.listResponse;
          });
        } else if (state is DynamicFormListLoadFinished) {
          setState(() {
            loading = false;
          });
        } else if (state is DynamicFormListCustomActionLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicFormListCustomActionSuccess) {
          if (state.headerForm != null) {
            bool result = false;

            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              result = await Navigators.push(
                    DynamicFormPage(
                      dynamicFormMenuItem: widget.dynamicFormMenuItem,
                      readOnly: false,
                      customerId: widget.customerId,
                      headerForm: state.headerForm,
                    ),
                  ) ??
                  false;
            } else {
              result = await context.push(
                    "/dynamic-forms",
                    extra: {
                      "dynamicFormMenuItem": widget.dynamicFormMenuItem,
                      "readOnly": false,
                      "customerId": widget.customerId,
                      "headerForm": state.headerForm,
                    },
                  ) ??
                  false;
            }

            if (result) {
              refresh();
            }
          } else {
            await BaseOverlays.success(
              message: "data_has_been_successfully_saved".tr(),
            );

            refresh();
          }
        } else if (state is DynamicFormListCustomActionFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: Scaffold(
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
              right: Dimensions.size15,
              bottom: safe.bottom + Dimensions.size5,
              child: _bottomFloatingBar(),
            ),
          ],
        ),
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

  List<Map<String, dynamic>> filteredDatas() {
    return listResponse!.data.where((element) {
      String searchKey = "";

      for (Field field in listResponse!.fields) {
        searchKey += DynamicForms.spell(
          type: field.type,
          value: element[field.name],
        );
      }

      if (searchKey.toLowerCase().contains(tecSearch.text.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    }).toList();
  }

  void refresh() {
    context.read<DynamicFormListBloc>().add(
          DynamicFormListLoad(
            id: widget.dynamicFormMenuItem.id,
            customerId: widget.customerId,
            name: widget.dynamicFormMenuItem.name,
          ),
        );
  }

  Widget mapModeButton() {
    if (listResponse != null &&
        listResponse!.fields.any(
          (element) => StringUtils.inList(
            element.name,
            ["latitude", "longitude", "longtitude"],
          ),
        )) {
      return _iconPill(
        icon: Icons.map,
        onTap: () async {
          Field? primaryKey = listResponse!.fields
              .firstWhereOrNull((element) => element.primaryKey);

          await Navigators.push(
            MapPage(
              markers: (listResponse?.data ?? [])
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
                    double.parse(element["longitude"] ?? element["longtitude"]),
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      if (primaryKey != null) {
                        String id = element[primaryKey.name].toString();

                        bool result = false;

                        if (BaseSettings.navigatorType ==
                            BaseNavigatorType.legacy) {
                          result = await Navigators.push(
                                DynamicFormPage(
                                  dynamicFormMenuItem:
                                      widget.dynamicFormMenuItem,
                                  readOnly: true,
                                  dataId: id,
                                  customerId: widget.customerId,
                                ),
                              ) ??
                              false;
                        } else {
                          result = await context.push(
                                "/dynamic-forms",
                                extra: {
                                  "dynamicFormMenuItem":
                                      widget.dynamicFormMenuItem,
                                  "readOnly": true,
                                  "dataId": id,
                                  "customerId": widget.customerId,
                                },
                              ) ??
                              false;
                        }

                        if (result) {
                          refresh();
                        }
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
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget body() {
    List<Field> fields =
        listResponse!.fields.where((element) => !element.primaryKey).toList();

    Field? primaryKey =
        listResponse!.fields.firstWhereOrNull((element) => element.primaryKey);

    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size10,
        ),
        itemCount: filteredDatas().length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: _gapCard);
        },
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> map = filteredDatas()[index];

          Widget pendingWidget() {
            if (map["_pending"] == "TRUE") {
              return Positioned(
                left: Dimensions.size10,
                top: Dimensions.size10,
                child: Container(
                  width: Dimensions.size10,
                  height: Dimensions.size10,
                  decoration: BoxDecoration(
                    color: AppColors.warning(),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          }

          List<Widget> widgets = [];

          for (int i = 0; i < fields.length; i++) {
            if (i % 2 == 0) {
              List<Widget> children = [];

              Field leftField = fields[i];

              children.add(
                childrenWidget(
                  description: leftField.description,
                  value: DynamicForms.spell(
                    type: leftField.type,
                    value: map[leftField.name],
                  ),
                  left: true,
                ),
              );

              if (i + 1 < fields.length) {
                Field rightField = fields[i + 1];

                children
                  ..add(
                    SizedBox(width: _gapInner),
                  )
                  ..add(
                    childrenWidget(
                      description: rightField.description,
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

              if (i + 2 < fields.length) {
                widgets.add(SizedBox(height: _gapInner));
              }
            }
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (primaryKey != null) {
                  String id = map[primaryKey.name].toString();

                  if (widget.selectorMode) {
                    if (BaseSettings.navigatorType ==
                        BaseNavigatorType.legacy) {
                      Navigators.pop(result: id);
                    } else {
                      context.pop(id);
                    }
                  } else {
                    List<MenuItem> menuItems = [];

                    if (hasViewAccess(id)) {
                      menuItems.add(
                        MenuItem(
                          iconData: Icons.visibility,
                          title: "Lihat Data",
                          onTap: hasViewAccess(id)
                              ? () async {
                                  await viewData(id);
                                }
                              : null,
                        ),
                      );
                    }

                    if (hasEditAccess(id)) {
                      menuItems.add(
                        MenuItem(
                          iconData: Icons.edit,
                          title: "edit".tr(),
                          onTap: hasEditAccess(id)
                              ? () async {
                                  await editData(id);
                                }
                              : null,
                        ),
                      );
                    }

                    if (DynamicForms.offline) {
                      menuItems.add(
                        MenuItem(
                          title: "send_data".tr(),
                          iconData: Icons.send,
                          onTap: () async {
                            BaseDialogs.confirmation(
                              title: "are_you_sure_want_to_proceed".tr(),
                              positiveCallback: () async {
                                try {
                                  context.loaderOverlay.show();

                                  await Offlines.send(
                                    formId: widget.dynamicFormMenuItem.id,
                                    dataId: id,
                                    customerId: widget.customerId,
                                  );

                                  BaseOverlays.success(
                                    message:
                                        "pending_data_has_been_successfully_sent"
                                            .tr(),
                                  );

                                  refresh();
                                } catch (e, s) {
                                  if (kDebugMode) {
                                    print("Caught Exception: $e");
                                    print("Stack Trace:\n$s");
                                  }

                                  BaseOverlays.error(
                                    message:
                                        "something_wrong_please_try_again".tr(),
                                  );
                                } finally {
                                  context.loaderOverlay.hide();
                                }
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      listResponse!.actions
                          .where(
                        (element) => !StringUtils.inList(
                          element.resourceId,
                          [
                            "BTN_CREATE",
                            "BTN_EDIT",
                            "BTN_VIEW",
                            "BTN_SAVE",
                            "BTN_ADD_DETAIL",
                            "BTN_DEL_DETAIL",
                          ],
                        ),
                      )
                          .forEach((element) {
                        MenuItem menuItem = MenuItem(
                          title: element.name,
                          onTap: () {
                            if (BaseSettings.navigatorType ==
                                BaseNavigatorType.legacy) {
                              Navigators.pop();
                            } else {
                              context.pop();
                            }

                            BaseDialogs.confirmation(
                              title: "are_you_sure_want_to_proceed".tr(),
                              positiveCallback: () {
                                context.read<DynamicFormListBloc>().add(
                                      DynamicFormListCustomAction(
                                        actionId: element.id,
                                        formId: widget.dynamicFormMenuItem.id,
                                        dataId: id,
                                        customerId: widget.customerId,
                                      ),
                                    );
                              },
                            );
                          },
                        );

                        menuItems.add(menuItem);
                      });
                    }

                    if (menuItems.isNotEmpty) {
                      if (menuItems.length == 1) {
                        if (hasViewAccess(id)) {
                          await viewData(id);
                          return;
                        }

                        if (hasEditAccess(id)) {
                          await editData(id);
                          return;
                        }

                        if (!DynamicForms.offline) {
                          Action? action =
                              listResponse!.actions.firstWhereOrNull(
                            (element) => !StringUtils.inList(
                              element.resourceId,
                              [
                                "BTN_CREATE",
                                "BTN_EDIT",
                                "BTN_VIEW",
                                "BTN_SAVE",
                                "BTN_ADD_DETAIL",
                                "BTN_DEL_DETAIL",
                              ],
                            ),
                          );

                          if (action != null) {
                            if (BaseSettings.navigatorType ==
                                BaseNavigatorType.legacy) {
                              Navigators.pop();
                            } else {
                              context.pop();
                            }

                            BaseDialogs.confirmation(
                              title: "are_you_sure_want_to_proceed".tr(),
                              positiveCallback: () {
                                context.read<DynamicFormListBloc>().add(
                                      DynamicFormListCustomAction(
                                        actionId: action.id,
                                        formId: widget.dynamicFormMenuItem.id,
                                        dataId: id,
                                        customerId: widget.customerId,
                                      ),
                                    );
                              },
                            );
                          }
                        }
                      } else {
                        _showActionSheet(menuItems);
                      }
                    }
                  }
                }
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
                child: Stack(
                  children: [
                    pendingWidget(),
                    Padding(
                      padding: EdgeInsets.all(Dimensions.size15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widgets,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> viewData(String id) async {
    bool result = false;

    if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
      Navigators.pop();

      result = await Navigators.push(
            DynamicFormPage(
              dynamicFormMenuItem: widget.dynamicFormMenuItem,
              readOnly: true,
              dataId: id,
              customerId: widget.customerId,
            ),
          ) ??
          false;
    } else {
      context.pop();

      result = await context.push(
            "/dynamic-forms",
            extra: {
              "dynamicFormMenuItem": widget.dynamicFormMenuItem,
              "readOnly": true,
              "dataId": id,
              "customerId": widget.customerId,
            },
          ) ??
          false;
    }

    if (result) {
      refresh();
    }
  }

  Future<void> editData(String id) async {
    bool result = false;

    if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
      Navigators.pop();

      result = await Navigators.push(
            DynamicFormPage(
              dynamicFormMenuItem: widget.dynamicFormMenuItem,
              readOnly: false,
              dataId: id,
              customerId: widget.customerId,
            ),
          ) ??
          false;
    } else {
      context.pop();

      result = await context.push(
            "/dynamic-forms",
            extra: {
              "dynamicFormMenuItem": widget.dynamicFormMenuItem,
              "readOnly": false,
              "dataId": id,
              "customerId": widget.customerId,
            },
          ) ??
          false;
    }

    if (result) {
      refresh();
    }
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

  Widget floatingActionButton() {
    if (hasCreateAccess()) {
      return Builder(
        builder: (context) {
          Future<void> handleCreate() async {
            if (listResponse?.createUsingScanQr ?? false) {
              Navigators.push(
                BarcodeScannerPage(
                  silent: true,
                  onSuccess: (data) {
                    create(data);
                  },
                ),
              );
            } else {
              create();
            }
          }

          final Color primary = Theme.of(context).colorScheme.primary;
          final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: handleCreate,
              borderRadius: BorderRadius.circular(Dimensions.size30),
              child: Ink(
                height: Dimensions.size55,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size20,
                ),
                decoration: ShapeDecoration(
                  color: primary,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size30),
                    smoothness: Dimensions.size1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: Dimensions.size35,
                      height: Dimensions.size35,
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: onPrimary,
                        size: Dimensions.size20,
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Text(
                      "Create",
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: Dimensions.text14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: Dimensions.size2),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  bool hasCreateAccess() {
    return !widget.selectorMode &&
        listResponse != null &&
        listResponse!.actions
            .any((element) => element.resourceId == "BTN_CREATE");
  }

  bool hasViewAccess(String id) {
    return !widget.selectorMode &&
            (listResponse != null &&
                listResponse!.actions
                    .any((element) => element.resourceId == "BTN_VIEW")) ||
        id.contains("*");
  }

  bool hasEditAccess(String id) {
    return !widget.selectorMode &&
            (listResponse != null &&
                listResponse!.actions
                    .any((element) => element.resourceId == "BTN_EDIT")) ||
        id.contains("*");
  }

  void create([String? extra]) async {
    bool result = false;

    if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
      result = await Navigators.push(
            DynamicFormPage(
              dynamicFormMenuItem: widget.dynamicFormMenuItem,
              customerId: widget.customerId,
              extra: extra,
              referenceId: widget.referenceId,
            ),
          ) ??
          false;
    } else {
      result = await context.push(
            "/dynamic-forms",
            extra: {
              "dynamicFormMenuItem": widget.dynamicFormMenuItem,
              "customerId": widget.customerId,
              "extra": extra,
              "referenceId": widget.referenceId,
            },
          ) ??
          false;
    }

    if (result) {
      refresh();
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
          smoothness: Dimensions.size1,
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
                  widget.dynamicFormMenuItem.name,
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
              mapModeButton(),
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
          smoothness: Dimensions.size1,
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
                setState(() {});
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
          smoothness: Dimensions.size1,
        ),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: _soft(context),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
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

  Widget _bodyHost() {
    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (listResponse == null) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [_failState()],
      );
    }

    if (filteredDatas().isEmpty) {
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
          smoothness: Dimensions.size1,
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
          smoothness: Dimensions.size1,
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
    final Widget fab = floatingActionButton();

    if (fab is SizedBox) {
      return const SizedBox.shrink();
    }

    if (!hasCreateAccess()) {
      return const SizedBox.shrink();
    }

    return Center(
      child: fab,
    );
  }

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  void _showActionSheet(List<MenuItem> menuItems) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        final Color card = _card(ctx);
        final Color soft = _soft(ctx);
        final Color fg = _fg(ctx);
        final Color outline = _outline(ctx);
        final Color primary = Theme.of(ctx).colorScheme.primary;

        Color tint(Color c, double a) => c.withValues(alpha: a);

        final bool hasView = menuItems.any(
          (m) =>
              m.iconData == Icons.visibility ||
              m.title.toLowerCase().contains("lihat"),
        );
        final bool hasEdit = menuItems.any(
          (m) =>
              m.iconData == Icons.edit ||
              m.title.toLowerCase().contains("edit") ||
              m.title.toLowerCase().contains("ubah"),
        );
        final bool noViewEdit = !hasView && !hasEdit;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Dimensions.size15,
              Dimensions.size10,
              Dimensions.size15,
              Dimensions.size15,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                Dimensions.size15,
                Dimensions.size10,
                Dimensions.size15,
                Dimensions.size15,
              ),
              decoration: ShapeDecoration(
                color: card,
                shadows: [
                  BoxShadow(
                    blurRadius: Dimensions.size30,
                    offset: Offset(0, Dimensions.size20),
                    color: Colors.black.withValues(alpha: 0.16),
                  ),
                ],
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size30),
                  smoothness: Dimensions.size1,
                  side: BorderSide(color: outline.withValues(alpha: 0.16)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: Dimensions.size45,
                    height: Dimensions.size5,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(Dimensions.size15),
                    ),
                  ),
                  SizedBox(height: Dimensions.size15),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Aksi",
                          style: TextStyle(
                            fontSize: Dimensions.text14,
                            fontWeight: FontWeight.w900,
                            color: fg,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx),
                          customBorder: const CircleBorder(),
                          child: Ink(
                            width: Dimensions.size40,
                            height: Dimensions.size40,
                            decoration: BoxDecoration(
                              color: soft,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: outline.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: Dimensions.size20,
                              color: fg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (noViewEdit) ...[
                    SizedBox(height: Dimensions.size10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.size15,
                        vertical: Dimensions.size10,
                      ),
                      decoration: ShapeDecoration(
                        color: soft,
                        shape: SmoothRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.size20),
                          smoothness: Dimensions.size1,
                          side: BorderSide(
                            color: outline.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: Dimensions.size30,
                            height: Dimensions.size30,
                            decoration: BoxDecoration(
                              color: tint(primary, 0.10),
                              shape: BoxShape.circle,
                              border: Border.all(color: tint(primary, 0.25)),
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: Dimensions.size20,
                              color: primary,
                            ),
                          ),
                          SizedBox(width: Dimensions.size10),
                          Expanded(
                            child: Text(
                              "Tidak ada akses untuk melihat atau mengubah data",
                              style: TextStyle(
                                fontSize: Dimensions.text12,
                                fontWeight: FontWeight.w700,
                                color: fg.withValues(alpha: 0.70),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: Dimensions.size15),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: menuItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.35,
                    ),
                    itemBuilder: (_, i) {
                      final MenuItem item = menuItems[i];
                      final bool enabled = item.onTap != null;
                      final IconData icon = item.iconData ?? Icons.bolt_rounded;

                      final bool isFirst = i == 0;

                      final Color tileBg = enabled
                          ? (isFirst ? tint(primary, 0.10) : soft)
                          : soft.withValues(alpha: 0.55);

                      final Color tileBorder = enabled
                          ? (isFirst
                              ? tint(primary, 0.28)
                              : tint(outline, 0.18))
                          : tint(outline, 0.12);

                      final Color iconBg = enabled
                          ? (isFirst ? tint(primary, 0.16) : tint(fg, 0.06))
                          : tint(fg, 0.04);

                      final Color iconColor = enabled
                          ? (isFirst ? primary : fg)
                          : fg.withValues(alpha: 0.35);

                      final Color textColor =
                          enabled ? fg : fg.withValues(alpha: 0.35);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: enabled ? item.onTap : null,
                          borderRadius:
                              BorderRadius.circular(Dimensions.size20),
                          child: Ink(
                            decoration: ShapeDecoration(
                              color: tileBg,
                              shadows: enabled
                                  ? [
                                      BoxShadow(
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                        color: Colors.black
                                            .withValues(alpha: 0.07),
                                      ),
                                    ]
                                  : const [],
                              shape: SmoothRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Dimensions.size20),
                                smoothness: Dimensions.size1,
                                side: BorderSide(color: tileBorder),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.size10,
                                vertical: Dimensions.size10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: Dimensions.size35,
                                    height: Dimensions.size35,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isFirst
                                            ? tint(primary, 0.30)
                                            : outline.withValues(alpha: 0.16),
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: Dimensions.size20,
                                      color: iconColor,
                                    ),
                                  ),
                                  SizedBox(width: Dimensions.size10),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: Dimensions.text12,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: Dimensions.size20,
                                    color: enabled
                                        ? fg.withValues(alpha: 0.40)
                                        : fg.withValues(alpha: 0.18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
