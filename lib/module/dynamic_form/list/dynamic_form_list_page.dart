// ignore_for_file: deprecated_member_use, use_build_context_synchronously


import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/generals.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_event.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_state.dart";
import "package:dynamic_of_things/widget/barcode_scanner_page.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:dynamic_of_things/widget/map_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart" hide Action;
import "package:flutter_bloc/flutter_bloc.dart";
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
  bool prefsReady = false;

  TextEditingController tecSearch = TextEditingController();

  // PERBAIKAN: Spacing disesuaikan agar rapi dan tidak terlalu renggang
  static const double gapcard = 16;
  static const double gapInner = 12;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    initPrefs();

    refresh();
  }

  Future<void> initPrefs() async {
    try {
      await Preferences.getInstance().init();
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      prefsReady = true;
    });
  }

  bool get isGlass {
    if (!prefsReady) {
      return false;
    }

    final int t = Preferences.getInstance()
            .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
        1;
    return t == 2;
  }

  Widget glassBackground() {
    return Generals.orientationAwareWallpaper(context);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

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
        backgroundColor:
            glass ? Colors.transparent : AppColors.surfaceContainerLowest(),
        body: Stack(
          children: [
            if (glass) ...[
              Positioned.fill(child: glassBackground()),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color.fromRGBO(0, 0, 0, 0.55),
                        Color.fromRGBO(0, 0, 0, 0.22),
                        Color.fromRGBO(0, 0, 0, 0.40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Column(
              children: [
                SizedBox(height: safe.top),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    Dimensions.size10,
                    horizontalPadding,
                    Dimensions.size10,
                  ),
                  child: DotResponsive.centered(
                    context: context,
                    tablet: 920,
                    desktop: 1080,
                    child: Builder(
                      builder: (context) {
                        final Widget searchBar = glass
                            ? GlassContainer(
                                blur: Dimensions.size15,
                                borderRadius: Dimensions.size15,
                                opacity: 0.10,
                                borderOpacity: 0.18,
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.size15,
                                ),
                                child: SizedBox(
                                  height: Dimensions.size50,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: Colors.white.withOpacity(0.75),
                                      ),
                                      SizedBox(width: Dimensions.size10),
                                      Expanded(
                                        child: TextField(
                                          controller: tecSearch,
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.92),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "search".tr(),
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.60,
                                              ),
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      if (StringUtils.isNotNullOrEmpty(
                                        tecSearch.text,
                                      ))
                                        icon(
                                          iconData: Icons.close,
                                          onTap: () {
                                            tecSearch.clear();
                                            setState(() {});
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                height: Dimensions.size50,
                                decoration: ShapeDecoration(
                                  color: AppColors.surfaceContainerLowest(),
                                  shape: SmoothRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.size15,
                                    ),
                                    smoothness: Dimensions.size1,
                                    side: BorderSide(
                                      color: AppColors.outline()
                                          .withValues(alpha: 0.22),
                                    ),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.size15,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      color: AppColors.onSurface()
                                          .withValues(alpha: 0.65),
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
                                    if (StringUtils.isNotNullOrEmpty(
                                      tecSearch.text,
                                    ))
                                      icon(
                                        iconData: Icons.close,
                                        onTap: () {
                                          tecSearch.clear();
                                          setState(() {});
                                        },
                                      ),
                                  ],
                                ),
                              );

                        final Widget headerContent = Column(
                          children: [
                            Row(
                              children: [
                                iconPill(
                                  iconData: Icons.turn_left_rounded,
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
                                    widget.dynamicFormMenuItem.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: Dimensions.text16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                      color: glass
                                          ? Colors.white.withOpacity(0.95)
                                          : AppColors.onSurface(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: Dimensions.size10),
                                mapModeButton(),
                              ],
                            ),
                            SizedBox(height: Dimensions.size10),
                            searchBar,
                          ],
                        );

                        if (glass) {
                          return GlassContainer(
                            blur: Dimensions.size20,
                            borderRadius: Dimensions.size20,
                            opacity: 0.12,
                            borderOpacity: 0.22,
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.size15,
                              vertical: Dimensions.size10,
                            ),
                            child: headerContent,
                          );
                        }

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
                              borderRadius:
                                  BorderRadius.circular(Dimensions.size20),
                              smoothness: Dimensions.size1,
                              side: BorderSide(
                                color:
                                    AppColors.outline().withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          child: headerContent,
                        );
                      },
                    ),
                  ),
                ),
                Expanded(child: bodyHost()),
                SizedBox(height: safe.bottom),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: safe.bottom + Dimensions.size5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: DotResponsive.centered(
                  context: context,
                  tablet: 920,
                  desktop: 1080,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: bottomFloatingActionBar(),
                  ),
                ),
              ),
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
      return iconPill(
        iconData: Icons.map,
        onTap: () async {
          Field? primaryKey = listResponse!.fields
              .firstWhereOrNull((element) => element.primaryKey);

          MarkerItem? selectedMarkerItem = await Navigators.push(
            MapPage(
              markerItems: (listResponse?.data ?? [])
                  .where(
                (element) =>
                    element["latitude"] != null &&
                    (element["longitude"] != null ||
                        element["longtitude"] != null),
              )
                  .map((element) {
                return MarkerItem(
                  point: LatLng(
                    double.parse(element["latitude"]),
                    double.parse(element["longitude"] ?? element["longtitude"]),
                  ),
                  icon: Icon(
                    Icons.location_on_outlined,
                    size: Dimensions.size30,
                    color: Colors.red,
                  ),
                  extra: element,
                );
              }).toList(),
            ),
          );

          if (selectedMarkerItem != null) {
            if (primaryKey != null) {
              String id = selectedMarkerItem.extra[primaryKey.name].toString();

              bool result = false;

              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
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
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget body() {
    final bool glass = isGlass;

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
          DotResponsive.horizontalPadding(context),
          Dimensions.size10,
          DotResponsive.horizontalPadding(context),
          Dimensions.size10,
        ),
        itemCount: filteredDatas().length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: gapcard);
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
                    const SizedBox(width: gapInner),
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
                widgets.add(const SizedBox(height: gapInner));
              }
            }
          }

          final Widget cardContent = Stack(
            children: [
              pendingWidget(),
              Padding(
                padding: EdgeInsets.all(
                  Dimensions.size20,
                ), // Padding dinaikkan agar pas dengan clean UI
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widgets,
                ),
              ),
            ],
          );

          return DotResponsive.centered(
            context: context,
            tablet: 920,
            desktop: 1080,
            child: Material(
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
                        } else {
                          actionBottomSheet(menuItems);
                        }
                      }
                    }
                  }
                },
                customBorder: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size20),
                  smoothness: Dimensions.size1,
                ),
                child: glass
                    ? GlassContainer(
                        blur: Dimensions.size20,
                        borderRadius: Dimensions.size20,
                        opacity: 0.12,
                        borderOpacity: 0.22,
                        padding: EdgeInsets.zero,
                        child: cardContent,
                      )
                    : Ink(
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
                            borderRadius:
                                BorderRadius.circular(Dimensions.size20),
                            smoothness: Dimensions.size1,
                            side: BorderSide(
                              color:
                                  AppColors.outline().withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: cardContent,
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

  // PERBAIKAN UTAMA: Menghilangkan card / kontainer berlapis di childrenWidget
  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    final bool glass = isGlass;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment
            .start, // Format disamakan rata kiri semua agar terlihat bagai Grid Modern
        children: [
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: glass
                  ? Colors.white.withOpacity(0.70)
                  : AppColors.onSurface().withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            StringUtils.isNotNullOrEmpty(value) ? value : "-",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: glass
                  ? Colors.white.withOpacity(0.95)
                  : AppColors.onSurface(),
            ),
          ),
        ],
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

          if (isGlass) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: handleCreate,
                borderRadius: BorderRadius.circular(Dimensions.size30),
                child: GlassContainer(
                  blur: Dimensions.size25,
                  borderRadius: Dimensions.size30,
                  opacity: 0.18,
                  borderOpacity: 0.30,
                  padding: EdgeInsets.zero,
                  child: Container(
                    height: Dimensions.size55,
                    padding:
                        EdgeInsets.symmetric(horizontal: Dimensions.size20),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF7EF0C6).withOpacity(0.22),
                      shadows: [
                        BoxShadow(
                          blurRadius: Dimensions.size20,
                          offset: Offset(0, Dimensions.size15),
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ],
                      shape: SmoothRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.size30),
                        smoothness: Dimensions.size1,
                        side: BorderSide(
                          color: const Color(0xFF2ACB9A).withOpacity(0.30),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: Dimensions.size35,
                          height: Dimensions.size35,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white.withOpacity(0.95),
                            size: Dimensions.size20,
                          ),
                        ),
                        SizedBox(width: Dimensions.size10),
                        Text(
                          "Create".tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
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
              ),
            );
          }

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
                  color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: Dimensions.size20,
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Text(
                      "Create".tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
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

  Widget icon({
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.size5),
          child: Icon(
            iconData,
            size: Dimensions.size20,
            color: glass
                ? Colors.white.withOpacity(0.85)
                : AppColors.onSurface().withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget iconPill({
    required IconData iconData,
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
        child: isGlass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size15,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
                  child: Icon(
                    iconData,
                    color: isGlass
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.onSurface(),
                    size: Dimensions.size25,
                  ),
                ),
              )
            : Ink(
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
                  iconData,
                  color: AppColors.onSurface(),
                  size: Dimensions.size25,
                ),
              ),
      ),
    );
  }

  Widget bodyHost() {
    final bool glass = isGlass;

    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (listResponse == null) {
      final Widget emptyCard = glass
          ? GlassContainer(
              blur: Dimensions.size20,
              borderRadius: Dimensions.size20,
              opacity: 0.12,
              borderOpacity: 0.22,
              padding: EdgeInsets.all(Dimensions.size20),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: Dimensions.size45,
                    color: Colors.white.withOpacity(0.80),
                  ),
                  SizedBox(height: Dimensions.size10),
                  Text(
                    "common_something_wrong".tr(),
                    style: TextStyle(
                      fontSize: Dimensions.text16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.92),
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
            )
          : Container(
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
                    Icons.error_outline,
                    size: Dimensions.size45,
                    color: AppColors.onSurface().withValues(alpha: 0.65),
                  ),
                  SizedBox(height: Dimensions.size10),
                  Text(
                    "common_something_wrong".tr(),
                    style: TextStyle(
                      fontSize: Dimensions.text16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface(),
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

      return ListView(
        padding: EdgeInsets.fromLTRB(
          DotResponsive.horizontalPadding(context),
          Dimensions.size15,
          DotResponsive.horizontalPadding(context),
          Dimensions.size15,
        ),
        children: [
          DotResponsive.centered(
            context: context,
            tablet: 920,
            desktop: 1080,
            child: emptyCard,
          ),
        ],
      );
    }

    if (filteredDatas().isEmpty) {
      final Widget emptyCard = glass
          ? GlassContainer(
              blur: Dimensions.size20,
              borderRadius: Dimensions.size20,
              opacity: 0.12,
              borderOpacity: 0.22,
              padding: EdgeInsets.all(Dimensions.size20),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: Dimensions.size45,
                    color: Colors.white.withOpacity(0.80),
                  ),
                  SizedBox(height: Dimensions.size10),
                  Text(
                    "no_data".tr(),
                    style: TextStyle(
                      fontSize: Dimensions.text16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                  SizedBox(height: Dimensions.size5),
                  Text(
                    "try_adjust_filter_or_pull_to_refresh".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Container(
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
            );

      return ListView(
        padding: EdgeInsets.fromLTRB(
          DotResponsive.horizontalPadding(context),
          Dimensions.size15,
          DotResponsive.horizontalPadding(context),
          Dimensions.size15,
        ),
        children: [
          DotResponsive.centered(
            context: context,
            tablet: 920,
            desktop: 1080,
            child: emptyCard,
          ),
        ],
      );
    }

    return body();
  }

  Widget bottomFloatingActionBar() {
    final Widget fab = floatingActionButton();

    if (fab is SizedBox) {
      return const SizedBox.shrink();
    }

    if (!hasCreateAccess()) {
      return const SizedBox.shrink();
    }

    return fab;
  }

  void actionBottomSheet(List<MenuItem> menuItems) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        final bool glass = isGlass;

        final Color outline =
            glass ? Colors.white.withOpacity(0.20) : AppColors.outline();
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
            child: Builder(
              builder: (context) {
                final EdgeInsets sheetPadding = EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  Dimensions.size10,
                  Dimensions.size15,
                  Dimensions.size15,
                );

                final Widget sheetContent = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: Dimensions.size45,
                      height: Dimensions.size5,
                      decoration: BoxDecoration(
                        color: glass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface().withValues(alpha: 0.18),
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
                              color: glass
                                  ? Colors.white.withOpacity(0.92)
                                  : AppColors.onSurface(),
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
                                color: glass
                                    ? Colors.white.withOpacity(0.08)
                                    : AppColors.surfaceContainerLowest(),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: outline.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: Dimensions.size20,
                                color: glass
                                    ? Colors.white.withOpacity(0.92)
                                    : AppColors.onSurface(),
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
                          color: glass
                              ? Colors.white.withOpacity(0.08)
                              : AppColors.surfaceContainerLowest(),
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
                                  color: glass
                                      ? Colors.white.withOpacity(0.92)
                                      : AppColors.onSurface()
                                          .withValues(alpha: 0.70),
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
                        final IconData icon =
                            item.iconData ?? Icons.bolt_rounded;

                        final bool isFirst = i == 0;

                        final Color tileBg = enabled
                            ? (isFirst
                                ? tint(primary, 0.10)
                                : glass
                                    ? Colors.white.withOpacity(0.08)
                                    : AppColors.surfaceContainerLowest())
                            : glass
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.surfaceContainerLowest()
                                    .withValues(alpha: 0.55);

                        final Color tileBorder = enabled
                            ? (isFirst
                                ? tint(primary, 0.28)
                                : tint(outline, 0.18))
                            : tint(outline, 0.12);

                        final Color iconBg = enabled
                            ? (isFirst
                                ? tint(primary, 0.16)
                                : tint(
                                    glass
                                        ? Colors.white.withOpacity(0.92)
                                        : AppColors.onSurface(),
                                    0.06,
                                  ))
                            : tint(
                                glass
                                    ? Colors.white.withOpacity(0.92)
                                    : AppColors.onSurface(),
                                0.04,
                              );

                        final Color iconColor = enabled
                            ? (isFirst
                                ? primary
                                : glass
                                    ? Colors.white.withOpacity(0.92)
                                    : AppColors.onSurface())
                            : glass
                                ? Colors.white.withOpacity(0.92)
                                : AppColors.onSurface().withValues(alpha: 0.35);

                        final Color textColor = enabled
                            ? glass
                                ? Colors.white.withOpacity(0.92)
                                : AppColors.onSurface()
                            : glass
                                ? Colors.white.withOpacity(0.92)
                                : AppColors.onSurface().withValues(alpha: 0.35);

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
                                          blurRadius: Dimensions.size15,
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
                                          ? glass
                                              ? Colors.white.withOpacity(0.92)
                                              : AppColors.onSurface()
                                                  .withValues(alpha: 0.40)
                                          : glass
                                              ? Colors.white.withOpacity(0.92)
                                              : AppColors.onSurface()
                                                  .withValues(alpha: 0.18),
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
                );

                if (glass) {
                  return GlassContainer(
                    blur: Dimensions.size25,
                    borderRadius: Dimensions.size30,
                    opacity: 0.14,
                    borderOpacity: 0.22,
                    padding: sheetPadding,
                    child: sheetContent,
                  );
                }

                return Container(
                  padding: sheetPadding,
                  decoration: ShapeDecoration(
                    color: glass
                        ? Colors.white.withOpacity(0.12)
                        : AppColors.surface(),
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
                  child: sheetContent,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
