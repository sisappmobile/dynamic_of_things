import "dart:convert";
import "dart:io";

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:geocoding/geocoding.dart";

class Generals {
  static const String defaultPortraitWallpaper =
      "assets/image/wallpaper_glass.jpg";
  static const String defaultLandscapeWallpaper =
      "assets/image/wallpaper_glass_landscape.jpg";

  static const List<String> defaultAssets = <String>[
    defaultPortraitWallpaper,
    "assets/image/wallpaper_glass1.jpg",
    "assets/image/wallpaper_glass2.jpg",
    "assets/image/wallpaper_glass3.jpg",
    defaultLandscapeWallpaper,
    "assets/image/wallpaper_glass_landscape1.jpg",
    "assets/image/wallpaper_glass_landscape2.jpg",
    "assets/image/wallpaper_glass_landscape3.jpg",
  ];

  static const Map<String, String> _portraitToLandscapeBundled =
      <String, String>{
    defaultPortraitWallpaper: defaultLandscapeWallpaper,
    "assets/image/wallpaper_glass1.jpg":
        "assets/image/wallpaper_glass_landscape1.jpg",
    "assets/image/wallpaper_glass2.jpg":
        "assets/image/wallpaper_glass_landscape2.jpg",
    "assets/image/wallpaper_glass3.jpg":
        "assets/image/wallpaper_glass_landscape3.jpg",
  };

  static const Map<String, String> _landscapeToPortraitBundled =
      <String, String>{
    defaultLandscapeWallpaper: defaultPortraitWallpaper,
    "assets/image/wallpaper_glass_landscape1.jpg":
        "assets/image/wallpaper_glass1.jpg",
    "assets/image/wallpaper_glass_landscape2.jpg":
        "assets/image/wallpaper_glass2.jpg",
    "assets/image/wallpaper_glass_landscape3.jpg":
        "assets/image/wallpaper_glass3.jpg",
  };

  static Future<String?> lastPlacemarkPosition() async {
    try {
      LongLat? longLat = await Locations.lastPosition();

      if (longLat != null) {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(longLat.latitude, longLat.longitude);

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];

          return "${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}";
        }
      }
    } catch (ex) {
      if (kDebugMode) {
        print(ex);
      }
    }

    return null;
  }

  static bool usePortraitWallpaper(BuildContext context) {
    if (!Dimensions.isMobile()) {
      return false;
    }

    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static Widget orientationAwareWallpaper(BuildContext context) {
    final bool isPortrait = usePortraitWallpaper(context);
    final String wallpaperPath =
        getWallpaperForOrientation(isPortrait: isPortrait);

    if (kDebugMode) {
      print(
        "🖼️ Generals.orientationAwareWallpaper: $wallpaperPath (${isPortrait ? "portrait" : "landscape"})",
      );
    }

    return buildWallpaperWidget(
      wallpaperPath,
      isPortrait: isPortrait,
    );
  }

  static Widget wallpaperForOrientation({required bool isPortrait}) {
    final String wallpaperPath =
        getWallpaperForOrientation(isPortrait: isPortrait);

    if (kDebugMode) {
      print(
        "🖼️ Generals.wallpaperForOrientation: $wallpaperPath (${isPortrait ? "portrait" : "landscape"})",
      );
    }

    return buildWallpaperWidget(
      wallpaperPath,
      isPortrait: isPortrait,
    );
  }
  

  static String getCurrentWallpaperPath(BuildContext context) {
    final bool isPortrait = usePortraitWallpaper(context);
    return getWallpaperForOrientation(isPortrait: isPortrait);
  }

  static bool bundledDefault(String path) =>
      defaultAssets.contains(path.trim());

  static String resolveBundledWallpaperForOrientation(
    String path, {
    required bool isPortrait,
  }) {
    final String trimmedPath = path.trim();

    if (trimmedPath.isEmpty) {
      return trimmedPath;
    }

    if (trimmedPath == "wallpaper_default.jpg") {
      return isPortrait ? defaultPortraitWallpaper : defaultLandscapeWallpaper;
    }

    if (isPortrait) {
      return _landscapeToPortraitBundled[trimmedPath] ?? trimmedPath;
    }

    return _portraitToLandscapeBundled[trimmedPath] ?? trimmedPath;
  }

  static String getWallpaperForOrientation({required bool isPortrait}) {
    final Preferences prefs = Preferences.getInstance();

    final String currentSource =
        (prefs.getString(SharedPreferenceKey.GLASS_BACKGROUND_SOURCE) ?? "")
            .trim()
            .toUpperCase();

    final String userSelectedPath =
        (prefs.getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH) ?? "")
            .trim();

    final List<String> portraitPaths = _decodeStringList(
      prefs.getString(SharedPreferenceKey.GLASS_BACKGROUND_PORTRAIT_PATHS) ??
          "",
    );

    final List<String> landscapePaths = _decodeStringList(
      prefs.getString(SharedPreferenceKey.GLASS_BACKGROUND_LANDSCAPE_PATHS) ??
          "",
    );

    final List<String> portraitUrls = _decodeStringList(
      prefs.getString(SharedPreferenceKey.GLASS_BACKGROUND_PORTRAIT_URLS) ?? "",
    );

    final List<String> landscapeUrls = _decodeStringList(
      prefs.getString(SharedPreferenceKey.GLASS_BACKGROUND_LANDSCAPE_URLS) ??
          "",
    );

    String pickServerWallpaper({
      required bool primaryPortrait,
    }) {
      final List<String> primaryPaths =
          primaryPortrait ? portraitPaths : landscapePaths;
      final List<String> primaryUrls =
          primaryPortrait ? portraitUrls : landscapeUrls;
      final List<String> fallbackPaths =
          primaryPortrait ? landscapePaths : portraitPaths;
      final List<String> fallbackUrls =
          primaryPortrait ? landscapeUrls : portraitUrls;

      if (!kIsWeb) {
        for (final String path in primaryPaths) {
          final String value = path.trim();
          if (value.isNotEmpty && _looksLikeImageFile(File(value))) {
            return value;
          }
        }
      }

      for (final String url in primaryUrls) {
        final String value = url.trim();
        if (value.isNotEmpty && value.toLowerCase() != "default") {
          return value;
        }
      }

      if (!kIsWeb) {
        for (final String path in fallbackPaths) {
          final String value = path.trim();
          if (value.isNotEmpty && _looksLikeImageFile(File(value))) {
            return value;
          }
        }
      }

      for (final String url in fallbackUrls) {
        final String value = url.trim();
        if (value.isNotEmpty && value.toLowerCase() != "default") {
          return value;
        }
      }

      return "";
    }

    final bool hasOrientationWallpapers = portraitPaths.isNotEmpty ||
        landscapePaths.isNotEmpty ||
        portraitUrls.isNotEmpty ||
        landscapeUrls.isNotEmpty;

    final String preferredServerWallpaper = hasOrientationWallpapers
        ? pickServerWallpaper(primaryPortrait: isPortrait)
        : "";

    if (currentSource == "SERVER") {
      if (preferredServerWallpaper.isNotEmpty) {
        return preferredServerWallpaper;
      }

      if (userSelectedPath.isNotEmpty) {
        return bundledDefault(userSelectedPath)
            ? resolveBundledWallpaperForOrientation(
                userSelectedPath,
                isPortrait: isPortrait,
              )
            : userSelectedPath;
      }
    }

    if (userSelectedPath.isNotEmpty) {
      return bundledDefault(userSelectedPath)
          ? resolveBundledWallpaperForOrientation(
              userSelectedPath,
              isPortrait: isPortrait,
            )
          : userSelectedPath;
    }

    if (preferredServerWallpaper.isNotEmpty) {
      return preferredServerWallpaper;
    }

    return isPortrait ? defaultPortraitWallpaper : defaultLandscapeWallpaper;
  }

  static Widget buildWallpaperWidget(
    String wallpaperPath, {
    required bool isPortrait,
  }) {
    final String rawPath = wallpaperPath.trim();
    final String resolvedPath = bundledDefault(rawPath)
        ? resolveBundledWallpaperForOrientation(
            rawPath,
            isPortrait: isPortrait,
          )
        : rawPath;
    final String keyString =
        "${isPortrait ? "portrait" : "landscape"}_${resolvedPath.isEmpty ? "default" : resolvedPath}";

    if (resolvedPath.startsWith("assets/")) {
      return _assetWallpaper(
        path: resolvedPath,
        keyString: keyString,
      );
    }

    if (kIsWeb && rawPath == "wallpaper_default.jpg") {
      final Uint8List? bytes = _webWallpaperBytes(isPortrait: isPortrait);
      if (bytes != null) {
        return Image.memory(
          bytes,
          key: ValueKey(keyString),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      }
    }

    if (_isBlobOrDataPath(resolvedPath) || _isNetworkPath(resolvedPath)) {
      return Image.network(
        resolvedPath,
        key: ValueKey(keyString),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallbackWallpaper(isPortrait: isPortrait),
      );
    }

    if (kIsWeb) {
      return fallbackWallpaper(isPortrait: isPortrait);
    }

    if (resolvedPath.isNotEmpty) {
      final File wallpaperFile = File(resolvedPath);
      if (_looksLikeImageFile(wallpaperFile)) {
        return Image.file(
          wallpaperFile,
          key: ValueKey(keyString),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      }
    }

    return fallbackWallpaper(isPortrait: isPortrait);
  }

  static Widget fallbackWallpaper({required bool isPortrait}) {
    final String fallbackPath =
        isPortrait ? defaultPortraitWallpaper : defaultLandscapeWallpaper;

    return _assetWallpaper(
      path: fallbackPath,
      keyString: "fallback_${isPortrait ? "portrait" : "landscape"}",
      fallbackAssetPath: defaultPortraitWallpaper,
    );
  }

  static Widget _assetWallpaper({
    required String path,
    required String keyString,
    String? fallbackAssetPath,
  }) {
    return Image.asset(
      path,
      key: ValueKey(keyString),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        if (fallbackAssetPath != null && fallbackAssetPath != path) {
          return Image.asset(
            fallbackAssetPath,
            key: ValueKey("${keyString}_asset_fallback"),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Colors.black,
            ),
          );
        }

        return const ColoredBox(color: Colors.black);
      },
    );
  }

  static List<String> _decodeStringList(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return <String>[];
    }

    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is! List) {
        return <String>[];
      }

      return decoded
          .map((item) => (item ?? "").toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return <String>[];
    }
  }

  static bool _looksLikeImageFile(File file) {
    if (!file.existsSync()) {
      return false;
    }

    if (file.lengthSync() < 1024) {
      return false;
    }

    return true;
  }

  static bool _isNetworkPath(String path) {
    final String value = path.trim().toLowerCase();
    return value.startsWith("http://") || value.startsWith("https://");
  }

  static bool _isBlobOrDataPath(String path) {
    final String value = path.trim().toLowerCase();
    return value.startsWith("blob:") || value.startsWith("data:");
  }

  static Uint8List? _webWallpaperBytes({required bool isPortrait}) {
    final Preferences prefs = Preferences.getInstance();
    final List<String> candidates = <String>[
      prefs.getString(
            isPortrait
                ? SharedPreferenceKey.WALLPAPER_PORTRAIT_BASE64
                : SharedPreferenceKey.WALLPAPER_LANDSCAPE_BASE64,
          ) ??
          "",
      prefs.getString(SharedPreferenceKey.WALLPAPER_USER_BASE64) ?? "",
      prefs.getString(SharedPreferenceKey.WEB_WALLPAPER_BYTES) ?? "",
    ];

    for (final String candidate in candidates) {
      final Uint8List? bytes = _decodeBase64Bytes(candidate);
      if (bytes != null) {
        return bytes;
      }
    }

    return null;
  }

  static Uint8List? _decodeBase64Bytes(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final int separatorIndex = value.indexOf(",");
    final String normalized = value.startsWith("data:") && separatorIndex >= 0
        ? value.substring(separatorIndex + 1)
        : value;

    try {
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }
}
