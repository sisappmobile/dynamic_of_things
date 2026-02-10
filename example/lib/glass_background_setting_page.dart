// ignore_for_file: deprecated_member_use

import "dart:io";

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

class GlassBackgroundSettingPage extends StatefulWidget {
  const GlassBackgroundSettingPage({super.key});

  @override
  State<GlassBackgroundSettingPage> createState() =>
      _GlassBackgroundSettingPageState();
}

class _GlassBackgroundSettingPageState
    extends State<GlassBackgroundSettingPage> {
  final ImagePicker _picker = ImagePicker();

  String? _path;
  bool _busy = false;

  final List<String> _defaultWallpapers = <String>[
    "assets/image/wallpaper_glass.jpg",
    "assets/image/wallpaper_glass2.jpg",
    "assets/image/wallpaper_glass3.jpg",
    "assets/image/wallpaper_glass4.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _path = Preferences.getInstance()
        .getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH);

    if (_path == null || _path!.trim().isEmpty) {
      _path = _defaultWallpapers.first;
    }
  }

  bool _isSelectedAsset(String assetPath) {
    return _path != null && _path!.trim() == assetPath.trim();
  }

  Widget glassBackground() {
    final String p = (_path ?? "").trim();

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

  Widget glassOverlay() {
    return const DecoratedBox(
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
    );
  }

  Widget glassSection({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      blur: Dimensions.size20,
      borderRadius: Dimensions.size20,
      opacity: 0.10,
      borderOpacity: 0.18,
      padding: padding ?? EdgeInsets.all(Dimensions.size15),
      child: child,
    );
  }

  Future<void> pickFromGallery() async {
    try {
      setState(() => _busy = true);

      final XFile? x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (x == null) {
        setState(() => _busy = false);
        return;
      }

      final String newPath = x.path;

      await Preferences.getInstance().setString(
        SharedPreferenceKey.GLASS_BACKGROUND_PATH,
        newPath,
      );
      await Preferences.getInstance().reload();

      setState(() {
        _path = newPath;
        _busy = false;
      });
    } catch (_) {
      setState(() => _busy = false);
    }
  }

  Future<void> defaultAssets(String assetPath) async {
    await Preferences.getInstance().setString(
      SharedPreferenceKey.GLASS_BACKGROUND_PATH,
      assetPath,
    );
    await Preferences.getInstance().reload();

    if (!mounted) {
      return;
    }
    setState(() => _path = assetPath);
  }

  Future<void> removeBackground() async {
    final String assetPath = _defaultWallpapers.first;

    await Preferences.getInstance().setString(
      SharedPreferenceKey.GLASS_BACKGROUND_PATH,
      assetPath,
    );
    await Preferences.getInstance().reload();

    if (!mounted) {
      return;
    }
    setState(() => _path = assetPath);
  }

  Widget glassHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          0,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: GlassContainer(
            blur: Dimensions.size20,
            borderRadius: Dimensions.size20,
            opacity: 0.12,
            borderOpacity: 0.22,
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.size10,
              vertical: Dimensions.size5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.turn_left_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: Dimensions.size30,
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.size5),
                Text(
                  "glass_background".tr(),
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                SizedBox(width: Dimensions.size10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget cardWallpaper({
    required String assetPath,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(right: Dimensions.size10),
        width: Dimensions.size100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.85)
                : Colors.white.withOpacity(0.10),
            width: selected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.22 : 0.12),
              blurRadius: selected ? Dimensions.size15 : Dimensions.size10,
              offset: Offset(0, Dimensions.size10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(assetPath, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withOpacity(0.10),
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  right: Dimensions.size10,
                  top: Dimensions.size10,
                  child: Container(
                    padding: EdgeInsets.all(Dimensions.size5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: Dimensions.size15,
                      color: Colors.black.withOpacity(0.85),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: Dimensions.text16,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        if (subtitle != null) ...<Widget>[
          SizedBox(height: Dimensions.size5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: Dimensions.text12,
              height: 1.25,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget actionButtons() {
    Widget glassTintButton({
      required VoidCallback? onTap,
      required IconData icon,
      required String text,
      required Color tint,
      required Color border,
      bool loading = false,
    }) {
      return SizedBox(
        width: double.infinity,
        height: Dimensions.size50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          child: Stack(
            children: [
              Positioned.fill(
                child: GlassContainer(
                  blur: Dimensions.size20,
                  borderRadius: Dimensions.size15,
                  opacity: 0.15,
                  borderOpacity: 0.0,
                  padding: EdgeInsets.zero,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    border: Border.all(color: border, width: Dimensions.size1),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loading)
                          SizedBox(
                            width: Dimensions.size20,
                            height: Dimensions.size20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          )
                        else
                          Icon(
                            icon,
                            color: Colors.white.withOpacity(0.95),
                            size: Dimensions.size20,
                          ),
                        SizedBox(width: Dimensions.size10),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: Dimensions.text14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Color greenTint =
        const Color.fromARGB(255, 70, 0, 55).withOpacity(0.18);
    final Color greenBorder =
        const Color.fromARGB(255, 70, 0, 55).withOpacity(0.30);

    final Color darkTint = Colors.black.withOpacity(0.18);
    final Color darkBorder = Colors.white.withOpacity(0.18);

    return glassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "glass_background_actions".tr(),
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.90),
            ),
          ),
          SizedBox(height: Dimensions.size10),
          glassTintButton(
            onTap: _busy ? null : pickFromGallery,
            icon: Icons.photo_library,
            text: "choose_from_gallery".tr(),
            tint: greenTint,
            border: greenBorder,
            loading: _busy,
          ),
          SizedBox(height: Dimensions.size10),
          glassTintButton(
            onTap: _busy ? null : removeBackground,
            icon: Icons.restart_alt,
            text: "use_default_background".tr(),
            tint: darkTint,
            border: darkBorder,
            loading: false,
          ),
          SizedBox(height: Dimensions.size15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: Dimensions.size20,
                color: Colors.white.withOpacity(0.70),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Text(
                  "glass_background_note".tr(),
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_path == null || _path!.trim().isEmpty) {
      _path = _defaultWallpapers.first;
    }

    final double topInset = MediaQuery.of(context).padding.top;
    final double headerPadTop = topInset + Dimensions.size70;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: glassBackground()),
          Positioned.fill(child: glassOverlay()),
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                Dimensions.size20,
                headerPadTop,
                Dimensions.size20,
                MediaQuery.of(context).padding.bottom + Dimensions.size20,
              ),
              children: <Widget>[
                SizedBox(height: Dimensions.size20),
                glassSection(
                  padding: EdgeInsets.all(Dimensions.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle(
                        "default_wallpapers".tr(),
                        subtitle: "default_wallpapers_hint".tr(),
                      ),
                      SizedBox(height: Dimensions.size15),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _defaultWallpapers.map((String assetPath) {
                            final bool selected = _isSelectedAsset(assetPath);
                            return cardWallpaper(
                              assetPath: assetPath,
                              selected: selected,
                              onTap: () async {
                                await defaultAssets(assetPath);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.size20),
                glassSection(
                  padding: EdgeInsets.all(Dimensions.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle(
                        "custom_wallpaper".tr(),
                        subtitle: "custom_wallpaper_hint".tr(),
                      ),
                      SizedBox(height: Dimensions.size15),
                      actionButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: glassHeader(),
          ),
        ],
      ),
    );
  }
}
