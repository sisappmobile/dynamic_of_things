// ignore_for_file: unrelated_type_equality_checks

import "dart:async";
import "dart:io";
import "dart:ui";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:geolocator/geolocator.dart";
import "package:go_router/go_router.dart";
import "package:latlong2/latlong.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:smooth_corner/smooth_corner.dart";

String get offlineMapBaseFolder => "offline_maps";

class MarkerItem {
  final LatLng point;
  final Icon icon;
  final Map<String, dynamic>? info;
  final dynamic extra;

  MarkerItem({
    required this.point,
    required this.icon,
    this.info,
    this.extra,
  });
}

class MapPage extends StatefulWidget {
  final List<MarkerItem>? markerItems;

  const MapPage({
    this.markerItems,
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

  StreamSubscription<Position>? positionSubscription;

  LatLng? currentPosition;
  MarkerItem? selectedMarker;

  String baseMap = "satellite";

  @override
  void initState() {
    super.initState();

    watchConnectivity();
    checkLocationPermission();

    alignPositionOnUpdate = AlignOnUpdate.once;
    alignPositionStreamController = StreamController<double?>();
  }

  void onLocationUpdate(Position position) {
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
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

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(onLocationUpdate);
  }

  void watchConnectivity() {
    final connectivity = Connectivity();

    connectivitySub = connectivity.onConnectivityChanged.listen((result) {
      if (!mounted) {
        return;
      }

      isOnline = result.any((element) => element != ConnectivityResult.none);

      setState(() {});
    });

    connectivity.checkConnectivity().then((result) {
      if (!mounted) {
        return;
      }

      isOnline = result.any((element) => element != ConnectivityResult.none);

      setState(() {});
    });
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Widget glassTopBar(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            safe.top > 0 ? Dimensions.size10 : Dimensions.size15,
            horizontalPadding,
            Dimensions.size10,
          ),
          child: DotResponsive.centered(
            context: context,
            tablet: 960,
            desktop: 1120,
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
                    color: AppColors.surface().withValues(alpha: isDark ? 0.78 : 0.90),
                    borderRadius: BorderRadius.circular(Dimensions.size25),
                    border: Border.all(
                      color: AppColors.outline().withValues(alpha: isDark ? 0.22 : 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: Dimensions.size25,
                        offset: Offset(0, Dimensions.size15),
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.12),
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
            color: AppColors.surfaceContainerLowest().withValues(alpha: isDark ? 0.72 : 1),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: AppColors.outline().withValues(alpha: isDark ? 0.22 : 0.18),
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
    final IconData icon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest().withValues(alpha: isDark ? 0.72 : 1),
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
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: safe.bottom + Dimensions.size15,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: DotResponsive.centered(
          context: context,
          tablet: 960,
          desktop: 1120,
          child: Align(
            alignment: Alignment.centerRight,
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
          ),
        ),
      ),
    );
  }

  Widget fabSelectCurrentMarker(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    Widget childWidget() {
      if (selectedMarker!.info != null) {
        List<Widget> widgets = [];

        for (int i = 0; i < selectedMarker!.info!.entries.length; i++) {
          if (i % 2 == 0) {
            List<Widget> children = [];

            MapEntry<String, dynamic> dfrfiLeft = selectedMarker!.info!.entries.elementAt(i);

            children.add(
              childrenWidget(
                description: dfrfiLeft.key,
                value: dfrfiLeft.value,
                left: true,
              ),
            );

            if (i + 1 < selectedMarker!.info!.entries.length) {
              MapEntry<String, dynamic> dfrfiRight = selectedMarker!.info!.entries.elementAt(i + 1);

              children
                ..add(SizedBox(width: Dimensions.size5))
                ..add(
                  childrenWidget(
                    description: dfrfiRight.key,
                    value: dfrfiRight.value,
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

            if (i + 2 < selectedMarker!.info!.entries.length) {
              widgets.add(SizedBox(height: Dimensions.size5));
            }
          }
        }

        return SizedBox(
          width: 250,
          child: Card(
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  ...widgets,
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                          Navigators.pop(result: selectedMarker);
                        } else {
                          context.pop(selectedMarker);
                        }
                      },
                      child: Text("Gunakan marker terpilih"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return FloatingActionButton(
          onPressed: () {
            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              Navigators.pop(result: selectedMarker);
            } else {
              context.pop(selectedMarker);
            }
          },
          child: Text("Gunakan marker terpilih"),
        );
      }
    }

    return Positioned(
      left: 0,
      right: 0,
      top: safe.top + 90,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: DotResponsive.centered(
          context: context,
          tablet: 960,
          desktop: 1120,
          child: Align(
            alignment: Alignment.centerLeft,
            child: childWidget(),
          ),
        ),
      ),
    );
  }

  Widget selectLayer(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    return Positioned(
      left: 0,
      right: 0,
      top: safe.top + 90,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: DotResponsive.centered(
          context: context,
          tablet: 960,
          desktop: 1120,
          child: Align(
            alignment: Alignment.centerRight,
            child: Builder(
              builder: (targetContext) {
                return FilledButton.icon(
                  onPressed: () async {
                    String? selectedValue = await BasePopupMenus.show(
                      context: context,
                      targetContext: targetContext,
                      items: [
                        PopupMenuItem<String>(
                          enabled: true,
                          value: "nonsatellite",
                          child: Text(
                            "Non-satellite",
                            style: TextStyle(
                              color: AppColors.onTertiaryContainer(),
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          enabled: true,
                          value: "satellite",
                          child: Text(
                            "Satellite",
                            style: TextStyle(
                              color: AppColors.onTertiaryContainer(),
                            ),
                          ),
                        ),
                      ],
                      value: baseMap,
                    );

                    if (selectedValue != null) {
                      setState(() {
                        baseMap = selectedValue;
                      });
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(5, 5, 10, 5),
                    backgroundColor: AppColors.tertiary(),
                    foregroundColor: AppColors.onTertiary(),
                    iconColor: AppColors.onTertiary(),
                  ),
                  label: Text(baseMap),
                  icon: Icon(Icons.arrow_drop_down),
                );
              },
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

        double? minZoom;

        if (!isOnline) {
          try {
            List<double> zoomVarieties = Directory("${snapshot.data!.path}/$offlineMapBaseFolder/$baseMap")
                .listSync()
                .where(
                  (element) => element is Directory && double.tryParse(p.basename(element.path)) != null,
            )
                .map((element) => double.parse(p.basename(element.path)))
                .sorted((a, b) => a.compareTo(b));

            minZoom = zoomVarieties.first;
          } catch (_) {}
        }

        return FlutterMap(
          options: MapOptions(
            initialZoom: minZoom ?? 14,
          ),
          children: [
            TileLayer(
              tileProvider: isOnline ? NetworkTileProvider() : FileTileProvider(),
              urlTemplate: tileUrlTemplate(snapshot.data!.path),
              userAgentPackageName: "com.sisapp.dynamic_of_things",
            ),
            TileLayer(
              urlTemplate: "${snapshot.data!.path}/$offlineMapBaseFolder/custom/{z}/{x}/{y}.png",
              tileProvider: FileTileProvider(),
              tms: true,
              tileBuilder: (context, tileWidget, tile) {
                return Opacity(
                  opacity: 0.7,
                  child: tileWidget,
                );
              },
            ),
            CurrentLocationLayer(
              alignPositionStream: alignPositionStreamController.stream,
              alignPositionOnUpdate: alignPositionOnUpdate,
            ),
            PolylineLayer(
              polylines: buildPolylines(),
            ),
            MarkerLayer(
              markers: (widget.markerItems ?? []).map((e) {
                return Marker(
                  point: e.point,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMarker = e;
                      });
                    },
                    child: e.icon,
                  ),
                );
              }).toList(),
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
            if (selectedMarker != null) fabSelectCurrentMarker(context),
            selectLayer(context),
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

  String tileUrlTemplate(String path) {
    if (isOnline) {
      if (baseMap == "satellite") {
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
      } else {
        return "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      }
    } else {
      return "$path/$offlineMapBaseFolder/$baseMap/{z}/{x}/{y}.png";
    }
  }

  List<Polyline> buildPolylines() {
    if (currentPosition == null || selectedMarker == null) {
      return [];
    }

    return [
      Polyline(
        points: [
          currentPosition!,
          selectedMarker!.point,
        ],
        strokeWidth: 4,
        color: Colors.blue,
      ),
    ];
  }

  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface(),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: Dimensions.size2),
          Text(
            StringUtils.isNotNullOrEmpty(value) ? value : "-",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface(),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
