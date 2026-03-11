// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import "dart:io";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class SimpleSpinnerPage extends StatefulWidget {
  final String title;
  final List<SpinnerItem> spinnerItems;

  const SimpleSpinnerPage({
    required this.title,
    required this.spinnerItems,
    super.key,
  });

  @override
  SimpleSpinnerPageState createState() => SimpleSpinnerPageState();
}

class SimpleSpinnerPageState extends State<SimpleSpinnerPage> with WidgetsBindingObserver {
  bool prefsReady = false;

  TextEditingController tecSearch = TextEditingController();

  static const double gapCard = 10;
  static const double gapInner = 8;

  static const double tilePadX = 10;
  static const double tilePadY = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initPrefs();
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
    Theme.of(context);

    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;

    return Scaffold(
      backgroundColor: glass
          ? Colors.transparent
          : isGlass
              ? Colors.white.withOpacity(0.06)
              : AppColors.surfaceContainerLowest(),
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
                  Dimensions.size10,
                  Dimensions.size15,
                  Dimensions.size10,
                ),
                child: topBar(),
              ),
              Expanded(child: bodyHost()),
              SizedBox(height: safe.bottom),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
    tecSearch.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  Widget topBar() {
    final bool glass = isGlass;

    final Widget content = Column(
      children: [
        Row(
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
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Dimensions.size10),
        searchBox(),
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
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
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
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.35),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget searchBox() {
    return Container(
      height: Dimensions.size50,
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
                : AppColors.outline().withValues(alpha: 0.22),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(alpha: 0.65),
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
            iconTiny(
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

  Widget iconTiny({
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
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color iconColor = glass
        ? Colors.white.withOpacity(0.92)
        : isGlass
            ? Colors.white.withOpacity(0.92)
            : AppColors.onSurface();

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
                    icon,
                    color: iconColor,
                    size: Dimensions.size25,
                  ),
                ),
              )
            : Ink(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: ShapeDecoration(
                  color: isGlass
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: 1,
                    side: BorderSide(
                      color: isGlass
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.outline().withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                  size: Dimensions.size25,
                ),
              ),
      ),
    );
  }

  Iterable<SpinnerItem> filteredItems() {
    return widget.spinnerItems.where((element) => element.description.toLowerCase().contains(tecSearch.text.toLowerCase()));
  }

  Widget bodyHost() {
    if (filteredItems().isNotEmpty) {
      return body();
    } else {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [emptyState()],
      );
    }
  }

  Widget emptyState() {
    final Widget content = Column(
      children: [
        Icon(
          Icons.inbox_outlined,
          size: Dimensions.size45,
          color: isGlass
              ? Colors.white.withOpacity(0.92)
              : AppColors.onSurface().withValues(alpha: 0.65),
        ),
        SizedBox(height: Dimensions.size10),
        Text(
          "no_data".tr(),
          style: TextStyle(
            fontSize: Dimensions.text16,
            fontWeight: FontWeight.w900,
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface(),
          ),
        ),
        SizedBox(height: Dimensions.size5),
        Text(
          "try_adjust_filter_or_pull_to_refresh".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.all(Dimensions.size20),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
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
  }

  Widget body() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        Dimensions.size15,
        Dimensions.size10,
        Dimensions.size15,
        Dimensions.size100,
      ),
      itemCount: filteredItems().length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: gapCard);
      },
      itemBuilder: (BuildContext context, int index) {
        SpinnerItem spinnerItem = filteredItems().elementAt(index);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                Navigators.pop(result: spinnerItem);
              } else {
                context.pop(spinnerItem);
              }
            },
            customBorder: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size20),
              smoothness: Dimensions.size1,
            ),
            child: Builder(
              builder: (context) {
                final Widget content = Padding(
                  padding: EdgeInsets.all(Dimensions.size15),
                  child: Text(
                    spinnerItem.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Dimensions.text12,
                      fontWeight: FontWeight.w700,
                      color: isGlass
                          ? Colors.white.withOpacity(0.92)
                          : AppColors.onSurface().withValues(alpha: 0.65),
                    ),
                  ),
                );

                if (isGlass) {
                  return GlassContainer(
                    blur: Dimensions.size20,
                    borderRadius: Dimensions.size20,
                    opacity: 0.12,
                    borderOpacity: 0.22,
                    padding: EdgeInsets.zero,
                    child: content,
                  );
                }

                return Ink(
                  decoration: ShapeDecoration(
                    color: isGlass
                        ? Colors.white.withOpacity(0.10)
                        : AppColors.surface(),
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
}