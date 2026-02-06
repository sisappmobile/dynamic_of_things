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

final int _minZoom = 14;
final int _maxZoom = 19;

class MapPage extends StatefulWidget {
  final List<Marker>? markers;

  const MapPage({
    this.markers,
    super.key,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _isOnline = true;

  StreamSubscription? _connectivitySub;

  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;

  @override
  void initState() {
    super.initState();

    _watchConnectivity();
    _checkLocationPermission();

    _alignPositionOnUpdate = AlignOnUpdate.always;
    _alignPositionStreamController = StreamController<double?>();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _watchConnectivity() {
    final connectivity = Connectivity();

    _connectivitySub = connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });

    connectivity.checkConnectivity().then((result) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  Widget _glassBar({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return SafeArea(
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
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: padding ??
                  EdgeInsets.symmetric(
                    horizontal: Dimensions.size15,
                    vertical: Dimensions.size10,
                  ),
              decoration: BoxDecoration(
                color: _card(context).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(Dimensions.size25),
                border: Border.all(
                  color: _outline(context).withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: Dimensions.size25,
                    offset: Offset(0, Dimensions.size15),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconPill({
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
          smoothness: 1,
        ),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: _soft(context),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: 1,
              side: BorderSide(
                color: _outline(context).withValues(alpha: 0.22),
              ),
            ),
          ),
          child: Icon(
            icon,
            size: Dimensions.size25,
            color: _fg(context),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    final String label = _isOnline ? "Online" : "Offline";
    final IconData icon =
        _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _soft(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: 1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.18),
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
            child: Icon(
              icon,
              size: 16,
              color: primary,
            ),
          ),
          SizedBox(width: Dimensions.size10),
          Text(
            label,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: _fg(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fabLocate(BuildContext context) {
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
            _alignPositionOnUpdate = AlignOnUpdate.always;
            _alignPositionStreamController.add(18);
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
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withValues(alpha: 0.16),
                ),
              ],
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size30),
                smoothness: 1,
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

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<Directory>(
              future: getApplicationDocumentsDirectory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FlutterMap(
                  options: MapOptions(
                    initialZoom: _minZoom.toDouble(),
                    minZoom: _isOnline ? null : _minZoom.toDouble(),
                    maxZoom: _maxZoom.toDouble(),
                  ),
                  children: [
                    _isOnline
                        ? TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName:
                                "com.sisapp.dynamic_of_things",
                          )
                        : TileLayer(
                            tileProvider: LocalDiskTileProvider(
                              basePath: "${snapshot.data!.path}/offline_tiles",
                            ),
                          ),
                    CurrentLocationLayer(
                      alignPositionStream:
                          _alignPositionStreamController.stream,
                      alignPositionOnUpdate: _alignPositionOnUpdate,
                    ),
                    MarkerLayer(
                      markers: widget.markers ?? [],
                    ),
                  ],
                );
              },
            ),
          ),
          _glassBar(
            context: context,
            child: Row(
              children: [
                _iconPill(
                  context: context,
                  icon: Icons.turn_left_rounded,
                  onTap: () {
                    if (BaseSettings.navigatorType ==
                        BaseNavigatorType.legacy) {
                      Navigators.pop();
                    } else {
                      Navigator.of(context).pop();
                    }
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
                      color: _fg(context),
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                _statusChip(context),
              ],
            ),
          ),
          _fabLocate(context),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(height: safe.bottom),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _alignPositionStreamController.close();
    super.dispose();
  }
}
