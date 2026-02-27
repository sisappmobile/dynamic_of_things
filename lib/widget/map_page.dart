// ignore_for_file: unrelated_type_equality_checks

import "dart:async";
import "dart:io";
import "dart:ui";

import "package:base/base.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dynamic_of_things/local_disk_tile_provider.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:geolocator/geolocator.dart";
import "package:path_provider/path_provider.dart";
import "package:smooth_corner/smooth_corner.dart";

final int minZoom = 14;
final int maxZoom = 19;

class MapPage extends StatefulWidget {
  final List<Marker>? markers;

  const MapPage({
    this.markers,
    super.key,
  });

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  bool isOnline = true;

  StreamSubscription? connectivitySub;

  late AlignOnUpdate alignPositionOnUpdate;
  late final StreamController<double?> alignPositionStreamController;

  @override
  void initState() {
    super.initState();

    watchConnectivity();
    checkLocationPermission();

    alignPositionOnUpdate = AlignOnUpdate.always;
    alignPositionStreamController = StreamController<double?>();
  }

  Future<void> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void watchConnectivity() {
    final connectivity = Connectivity();

    connectivitySub = connectivity.onConnectivityChanged.listen((result) {
      if (!mounted) {
        return;
      }
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    });

    connectivity.checkConnectivity().then((result) {
      if (!mounted) {
        return;
      }

      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    });
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Widget glassTopBar(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            safe.top > 0 ? Dimensions.size10 : Dimensions.size15,
            Dimensions.size15,
            Dimensions.size10,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.size25),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: Dimensions.size15,
                sigmaY: Dimensions.size15,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface()
                      .withValues(alpha: isDark ? 0.78 : 0.90),
                  borderRadius: BorderRadius.circular(Dimensions.size25),
                  border: Border.all(
                    color: AppColors.outline()
                        .withValues(alpha: isDark ? 0.22 : 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: Dimensions.size25,
                      offset: Offset(0, Dimensions.size15),
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.18 : 0.12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    iconPill(
                      context: context,
                      icon: Icons.turn_left_rounded,
                      onTap: () {
                        Navigator.of(context).maybePop();
                      },
                    ),
                    SizedBox(width: Dimensions.size10),
                    Expanded(
                      child: Text(
                        "map".tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Dimensions.text16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          color: AppColors.onSurface(),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    statusChip(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget iconPill({
    required BuildContext context,
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
            color: AppColors.surfaceContainerLowest()
                .withValues(alpha: isDark ? 0.72 : 1),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color:
                    AppColors.outline().withValues(alpha: isDark ? 0.22 : 0.18),
              ),
            ),
          ),
          child: Icon(
            icon,
            size: Dimensions.size25,
            color: AppColors.onSurface(),
          ),
        ),
      ),
    );
  }

  Widget statusChip(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    final String label = isOnline ? "Online" : "Offline";
    final IconData icon =
        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest()
            .withValues(alpha: isDark ? 0.72 : 1),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: isDark ? 0.22 : 0.18),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Dimensions.size25,
            height: Dimensions.size25,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: Dimensions.size15, color: primary),
          ),
          SizedBox(width: Dimensions.size10),
          Text(
            label,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: AppColors.onSurface(),
            ),
          ),
        ],
      ),
    );
  }

  Widget fabLocate(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Positioned(
      right: Dimensions.size15,
      bottom: safe.bottom + Dimensions.size15,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            alignPositionOnUpdate = AlignOnUpdate.always;
            alignPositionStreamController.add(18);
            setState(() {});
          },
          borderRadius: BorderRadius.circular(Dimensions.size30),
          child: Ink(
            height: Dimensions.size55,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
            decoration: ShapeDecoration(
              color: primary,
              shadows: [
                BoxShadow(
                  blurRadius: Dimensions.size20,
                  offset: Offset(0, Dimensions.size10),
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.16),
                ),
              ],
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
                    Icons.my_location_rounded,
                    color: onPrimary,
                    size: Dimensions.size20,
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Text(
                  "Lokasi Saya",
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget mapHost() {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FlutterMap(
          options: MapOptions(
            initialZoom: minZoom.toDouble(),
            minZoom: isOnline ? null : minZoom.toDouble(),
            maxZoom: maxZoom.toDouble(),
          ),
          children: [
            isOnline
                ? TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.sisapp.dynamic_of_things",
                  )
                : TileLayer(
                    tileProvider: LocalDiskTileProvider(
                      basePath: "${snapshot.data!.path}/offline_tiles",
                    ),
                  ),
            CurrentLocationLayer(
              alignPositionStream: alignPositionStreamController.stream,
              alignPositionOnUpdate: alignPositionOnUpdate,
            ),
            MarkerLayer(
              markers: widget.markers ?? [],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      context: context,
      contentBuilder: () {
        return Stack(
          children: [
            Positioned.fill(child: mapHost()),
            glassTopBar(context),
            fabLocate(context),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    connectivitySub?.cancel();
    alignPositionStreamController.close();
    super.dispose();
  }
}
