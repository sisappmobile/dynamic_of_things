// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, use_build_context_synchronously

import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_page.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_event.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_state.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_page.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_page.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class DynamicFormMenuPage extends StatefulWidget {
  final String? customerId;

  const DynamicFormMenuPage({
    super.key,
    this.customerId,
  });

  @override
  DynamicFormMenuPageState createState() => DynamicFormMenuPageState();
}

class DynamicFormMenuPageState extends State<DynamicFormMenuPage>
    with WidgetsBindingObserver {
  DynamicFormMenuResponse? dynamicFormMenuResponse;

  bool loading = true;
  bool prefsReady = false;

  TextEditingController tecSearch = TextEditingController();

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
    final String p = (Preferences.getInstance()
                .getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH) ??
            "")
        .trim();

    if (p.isEmpty) {
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }

    if (kIsWeb) {
      if (p == "wallpaper_default.jpg") {
        final String base64Data = Preferences.getInstance().getStringDynamicForm("WEB_WALLPAPER_BYTES") ?? "";
        if (base64Data.isNotEmpty) {
          try {
            final Uint8List bytes = base64Decode(base64Data);
            return Image.memory(bytes, fit: BoxFit.cover);
          } catch (_) {}
        }
      }
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }

    if (p.startsWith("assets/")) {
      return Image.asset(p, fit: BoxFit.cover);
    }

    final File f = File(p);
    if (f.existsSync()) {
      return Image.file(f, fit: BoxFit.cover);
    }

    return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;

    return BlocListener<DynamicFormMenuBloc, DynamicFormMenuState>(
      listener: (context, state) async {
        if (state is DynamicFormMenuLoadLoading) {
          setState(() {
            loading = true;
            dynamicFormMenuResponse = null;
          });
        } else if (state is DynamicFormMenuLoadSuccess) {
          setState(() {
            dynamicFormMenuResponse = state.dynamicFormMenuResponse;
          });
        } else if (state is DynamicFormMenuLoadFinished) {
          setState(() {
            loading = false;
          });
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
                    Dimensions.size15,
                    Dimensions.size5,
                    Dimensions.size15,
                    Dimensions.size10,
                  ),
                  child: headerCard(),
                ),
                Expanded(child: bodyHost()),
                SizedBox(height: safe.bottom),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tecSearch.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  List<DynamicFormCategoryItem> filteredDynamicFormCategoryItems() {
    return dynamicFormMenuResponse!.categories
        .where(
          (element1) => element1.menus.any(
            (element2) => element2.name
                .toLowerCase()
                .contains(tecSearch.text.toLowerCase()),
          ),
        )
        .toList();
  }

  List<DynamicFormMenuItem> filteredDynamicFormMenuItems({
    required DynamicFormCategoryItem dynamicFormCategoryItem,
  }) {
    return dynamicFormCategoryItem.menus
        .where(
          (element) =>
              element.name.toLowerCase().contains(tecSearch.text.toLowerCase()),
        )
        .toList();
  }

  void refresh() {
    context.read<DynamicFormMenuBloc>().add(
          DynamicFormMenuLoad(
            customerId: widget.customerId,
          ),
        );
  }

  Widget bodyHost() {
    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (dynamicFormMenuResponse == null) {
      return statusCard(
        icon: Icons.error_outline,
        title: "failed_to_load_data".tr(),
        subtitle: "failed_to_load_data_hint".tr(),
      );
    }

    List<DynamicFormCategoryItem> categories =
        filteredDynamicFormCategoryItems();

    if (categories.isEmpty) {
      return statusCard(
        icon: Icons.inbox_outlined,
        title: "no_data".tr(),
        subtitle: StringUtils.isNotNullOrEmpty(tecSearch.text)
            ? "try_adjust_filter_or_pull_to_refresh".tr()
            : "no_data_hint".tr(),
      );
    }

    return body(categories: categories);
  }

  Widget statusCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool glass = isGlass;

    final Widget card = glass
        ? GlassContainer(
            blur: Dimensions.size20,
            borderRadius: Dimensions.size20,
            opacity: 0.12,
            borderOpacity: 0.22,
            padding: EdgeInsets.all(Dimensions.size20),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: Dimensions.size45,
                  color: Colors.white.withValues(alpha: 0.80),
                ),
                SizedBox(height: Dimensions.size10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                SizedBox(height: Dimensions.size5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: Dimensions.size15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: refresh,
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
                  color: AppColors.outline().withValues(alpha: 0.22),
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: Dimensions.size45,
                  color: AppColors.onSurface().withValues(alpha: 0.80),
                ),
                SizedBox(height: Dimensions.size10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface(),
                  ),
                ),
                SizedBox(height: Dimensions.size5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface().withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: Dimensions.size15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: refresh,
                        icon: const Icon(Icons.refresh),
                        label: Text("refresh".tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(Dimensions.size10),
        children: [
          SizedBox(height: Dimensions.size1),
          card,
        ],
      ),
    );
  }

  Widget body({
    required List<DynamicFormCategoryItem> categories,
  }) {
    final bool glass = isGlass;

    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(Dimensions.size15),
        itemCount: categories.length,
        separatorBuilder: (context, index) {
          return SizedBox(height: Dimensions.size15);
        },
        itemBuilder: (context, index1) {
          DynamicFormCategoryItem dynamicFormCategoryItem = categories[index1];

          List<DynamicFormMenuItem> menuItems = filteredDynamicFormMenuItems(
            dynamicFormCategoryItem: dynamicFormCategoryItem,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dynamicFormCategoryItem.name.toUpperCase(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.bold,
                  color: glass
                      ? Colors.white.withValues(alpha: 0.95)
                      : AppColors.onSurface(),
                ),
              ),
              SizedBox(height: Dimensions.size1),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(top:Dimensions.size10),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: Dimensions.size55 * 2,
                  crossAxisSpacing: Dimensions.size10,
                  mainAxisSpacing: Dimensions.size10,
                ),
                itemBuilder: (BuildContext context, int index2) {
                  DynamicFormMenuItem dynamicFormMenuItem = menuItems[index2];

                  return menuCard(
                    dynamicFormMenuItem: dynamicFormMenuItem,
                    onTap: () async {
                      await openMenuItem(
                        dynamicFormCategoryItem: dynamicFormCategoryItem,
                        dynamicFormMenuItem: dynamicFormMenuItem,
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget headerCard() {
    final bool glass = isGlass;

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
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  SizedBox(width: Dimensions.size10),
                  Expanded(
                    child: TextField(
                      controller: tecSearch,
                      onChanged: (value) {
                        setState(() {});
                      },
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      decoration: InputDecoration(
                        hintText: "search".tr(),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (StringUtils.isNotNullOrEmpty(tecSearch.text))
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
                borderRadius: BorderRadius.circular(Dimensions.size15),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.22),
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
                  color: AppColors.onSurface().withValues(alpha: 0.65),
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
                "menu".tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: glass
                      ? Colors.white.withValues(alpha: 0.95)
                      : AppColors.onSurface(),
                ),
              ),
            ),
            SizedBox(width: Dimensions.size10),
            iconPill(
              iconData: Icons.refresh,
              onTap: refresh,
            ),
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
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: 0.35),
          ),
        ),
      ),
      child: headerContent,
    );
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
                ? Colors.white.withValues(alpha: 0.85)
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
    final bool glass = isGlass;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: glass
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
                    color: Colors.white.withValues(alpha: 0.92),
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

  Widget menuCard({
    required DynamicFormMenuItem dynamicFormMenuItem,
    required Future<void> Function() onTap,
  }) {
    final bool glass = isGlass;

    final SmoothRectangleBorder shape = SmoothRectangleBorder(
      borderRadius: BorderRadius.circular(Dimensions.size15),
      smoothness: Dimensions.size1,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: glass
            ? GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size15,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.size10,
                  horizontal: Dimensions.size5,
                ),
                child: Center(
                  child: Text(
                    dynamicFormMenuItem.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: Dimensions.text14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Ink(
                width: double.infinity,
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.onPrimaryContainer(),
                    ),
                  ),
                  color: AppColors.primaryContainer(),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.size10,
                  horizontal: Dimensions.size5,
                ),
                child: Center(
                  child: Text(
                    dynamicFormMenuItem.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onPrimaryContainer(),
                      fontSize: Dimensions.text14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> openMenuItem({
    required DynamicFormCategoryItem dynamicFormCategoryItem,
    required DynamicFormMenuItem dynamicFormMenuItem,
  }) async {
    if (dynamicFormMenuItem.type == "REPORT") {
      if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
        await Navigators.push(
          DynamicReportPage(
            dynamicFormMenuItem: dynamicFormMenuItem,
            dynamicFormCategoryItem: dynamicFormCategoryItem,
          ),
        );
      } else {
        await context.push(
          "/dynamic-reports",
          extra: {
            "dynamicFormMenuItem": dynamicFormMenuItem,
            "dynamicFormCategoryItem": dynamicFormCategoryItem,
          },
        );
      }
    } else if (dynamicFormMenuItem.type == "SCHEDULE") {
      if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
        await Navigators.push(
          DynamicSchedulePage(
            dynamicFormMenuItem: dynamicFormMenuItem,
            customerId: widget.customerId,
          ),
        );
      } else {
        await context.push(
          "/dynamic-schedules",
          extra: {
            "dynamicFormMenuItem": dynamicFormMenuItem,
            "customerId": widget.customerId,
          },
        );
      }
    } else {
      String? referenceId;

      if (StringUtils.isNotNullOrEmpty(
        dynamicFormMenuItem.referenceId,
      )) {
        if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
          referenceId = await Navigators.push(
            DynamicFormListPage(
              dynamicFormMenuItem: DynamicFormMenuItem(
                id: dynamicFormMenuItem.referenceId!,
                name: dynamicFormMenuItem.referenceName!,
                index: 0,
                type: "",
                icon: "",
                referenceId: null,
                referenceName: null,
              ),
              customerId: widget.customerId,
              selectorMode: true,
              referenceId: null,
            ),
          );
        } else {
          referenceId = await context.push(
            "/dynamic-forms/list",
            extra: {
              "dynamicFormMenuItem": DynamicFormMenuItem(
                id: dynamicFormMenuItem.referenceId!,
                name: dynamicFormMenuItem.referenceName!,
                index: 0,
                type: "",
                icon: "",
                referenceId: null,
                referenceName: null,
              ),
              "customerId": widget.customerId,
              "selectorMode": true,
              "referenceId": null,
            },
          );
        }

        if (referenceId == null) {
          return;
        }
      }

      if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
        await Navigators.push(
          DynamicFormListPage(
            dynamicFormMenuItem: dynamicFormMenuItem,
            customerId: widget.customerId,
            selectorMode: false,
            referenceId: referenceId,
          ),
        );
      } else {
        await context.push(
          "/dynamic-forms/list",
          extra: {
            "dynamicFormMenuItem": dynamicFormMenuItem,
            "customerId": widget.customerId,
            "selectorMode": false,
            "referenceId": referenceId,
          },
        );
      }
    }
  }
}
