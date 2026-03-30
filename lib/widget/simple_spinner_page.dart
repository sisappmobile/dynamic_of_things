// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/generals.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
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

class SimpleSpinnerPageState extends State<SimpleSpinnerPage>
    with WidgetsBindingObserver {
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
    return Generals.orientationAwareWallpaper(context);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

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
                  horizontalPadding,
                  Dimensions.size10,
                  horizontalPadding,
                  Dimensions.size10,
                ),
                child: centeredContent(
                  context: context,
                  child: topBar(),
                ),
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

  Widget centeredContent({
    required BuildContext context,
    required Widget child,
  }) {
    return DotResponsive.centered(
      context: context,
      tablet: 920,
      desktop: 1080,
      child: child,
    );
  }

  Widget stateList({
    required BuildContext context,
    required Widget child,
  }) {
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        Dimensions.size10,
        horizontalPadding,
        Dimensions.size20,
      ),
      children: [
        centeredContent(
          context: context,
          child: child,
        ),
      ],
    );
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
            SizedBox(width: Dimensions.size10),
            resultBadge(filteredItems().length),
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

  Widget resultBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: 8,
      ),
      decoration: ShapeDecoration(
        color: isGlass
            ? Colors.white.withOpacity(0.10)
            : AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size100),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Text(
        "$count",
        style: TextStyle(
          fontSize: Dimensions.text12,
          fontWeight: FontWeight.w900,
          color:
              isGlass ? Colors.white.withOpacity(0.92) : AppColors.onSurface(),
        ),
      ),
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
    return widget.spinnerItems.where(
      (element) => element.description
          .toLowerCase()
          .contains(tecSearch.text.toLowerCase()),
    );
  }

  Widget bodyHost() {
    if (filteredItems().isNotEmpty) {
      return body();
    } else {
      return stateList(
        context: context,
        child: emptyState(),
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
    final List<SpinnerItem> items = filteredItems().toList();
    final DotScreenType screenType = DotResponsive.sizeOf(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        DotResponsive.horizontalPadding(context),
        Dimensions.size10,
        DotResponsive.horizontalPadding(context),
        Dimensions.size100,
      ),
      children: [
        centeredContent(
          context: context,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount = screenType == DotScreenType.mobile
                  ? 1
                  : DotResponsive.gridColumnCount(
                      availableWidth: constraints.maxWidth,
                      minItemWidth: 260,
                      min: 2,
                      max: 3,
                    );

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: Dimensions.size10,
                  crossAxisSpacing: Dimensions.size10,
                  mainAxisExtent: screenType == DotScreenType.mobile ? 92 : 102,
                ),
                itemBuilder: (context, index) {
                  return spinnerCard(
                    spinnerItem: items[index],
                    index: index,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget spinnerCard({
    required SpinnerItem spinnerItem,
    required int index,
  }) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final String label = spinnerItem.description.trim();
    final String initials =
        label.isNotEmpty ? label.substring(0, 1).toUpperCase() : "${index + 1}";

    final Widget content = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      child: Row(
        children: [
          Container(
            width: Dimensions.size40,
            height: Dimensions.size40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.18),
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  fontSize: Dimensions.text14,
                ),
              ),
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Expanded(
            child: Text(
              spinnerItem.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Dimensions.text13,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: isGlass
                    ? Colors.white.withOpacity(0.94)
                    : AppColors.onSurface(),
              ),
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: Dimensions.size15,
            color: isGlass
                ? Colors.white.withOpacity(0.60)
                : AppColors.onSurface().withValues(alpha: 0.45),
          ),
        ],
      ),
    );

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
        child: isGlass
            ? GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size20,
                opacity: 0.12,
                borderOpacity: 0.22,
                padding: EdgeInsets.zero,
                child: content,
              )
            : Ink(
                decoration: ShapeDecoration(
                  color: AppColors.surface(),
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
                      color: AppColors.outline().withValues(alpha: 0.22),
                    ),
                  ),
                ),
                child: content,
              ),
      ),
    );
  }
}
