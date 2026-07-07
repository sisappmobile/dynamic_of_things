// ignore_for_file: unrelated_type_equality_checks

import "dart:async";
import "dart:ui";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dynamic_of_things/helper/map_tile_storage.dart"
    hide offlineMapBaseFolder;
import "package:dynamic_of_things/helper/responsive_layout.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:geolocator/geolocator.dart";
import "package:go_router/go_router.dart";
import "package:latlong2/latlong.dart";
import "package:smooth_corner/smooth_corner.dart";

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

String get offlineMapBaseFolder => "offline_maps";

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
  bool isLocateButtonVisible = true;

  StreamSubscription? connectivitySub;
  final MapController mapController = MapController();
  final TextEditingController tecSearch = TextEditingController();
  Timer? locateButtonRestoreTimer;

  late Future<({String? storagePath, double? minZoom})> mapSourceFuture;

  StreamSubscription<Position>? positionSubscription;

  LatLng? currentPosition;
  MarkerItem? selectedMarker;
  String? lastFocusedMarkerSignature;
  bool followCurrentLocation = true;

  String baseMap = "satellite";

  @override
  void initState() {
    super.initState();

    watchConnectivity();
    checkLocationPermission();

    mapSourceFuture = loadMapSource();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusSingleVisibleMarkerIfNeeded(markerItems);
    });
  }

  void onLocationUpdate(Position position) {
    final LatLng nextPosition = LatLng(position.latitude, position.longitude);
    final LatLng? previousPosition = currentPosition;
    final bool isFirstLocationFix = previousPosition == null;

    currentPosition = nextPosition;

    if (followCurrentLocation) {
      focusMapOnPoint(
        nextPosition,
        zoom: isFirstLocationFix ? 18 : null,
        id: isFirstLocationFix ? "initial-location-focus" : "follow-location",
      );
    }

    if (!mounted || selectedMarker == null) {
      return;
    }

    if (previousPosition != null &&
        previousPosition.latitude == nextPosition.latitude &&
        previousPosition.longitude == nextPosition.longitude) {
      return;
    }

    setState(() {});
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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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

      final bool nextIsOnline =
          result.any((element) => element != ConnectivityResult.none);

      if (isOnline == nextIsOnline) {
        return;
      }

      setState(() {
        isOnline = nextIsOnline;
        mapSourceFuture = loadMapSource();
      });
    });

    connectivity.checkConnectivity().then((result) {
      if (!mounted) {
        return;
      }

      final bool nextIsOnline =
          result.any((element) => element != ConnectivityResult.none);

      if (isOnline == nextIsOnline) {
        return;
      }

      setState(() {
        isOnline = nextIsOnline;
        mapSourceFuture = loadMapSource();
      });
    });
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<MarkerItem> get markerItems => widget.markerItems ?? <MarkerItem>[];

  bool get isSatelliteMap => baseMap == "satellite";

  String get mapTypeLabel => isSatelliteMap ? "Satelit" : "Peta";

  IconData get mapTypeIcon =>
      isSatelliteMap ? Icons.satellite_alt_rounded : Icons.map_rounded;

  double topFloatingActionsOffset(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return safe.top + 145;
  }

  List<MarkerItem> filteredMarkerItems({
    String? query,
  }) {
    final String normalizedQuery =
        (query ?? tecSearch.text).trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return markerItems;
    }

    return markerItems.where((markerItem) {
      return markerSearchText(markerItem).contains(normalizedQuery);
    }).toList();
  }

  String markerSearchText(MarkerItem markerItem) {
    return [
      ...collectSearchTokens(markerItem.info),
      ...collectSearchTokens(markerItem.extra),
      markerItem.point.latitude.toString(),
      markerItem.point.longitude.toString(),
    ].join(" ").toLowerCase();
  }

  String markerSignature(MarkerItem markerItem) {
    return "${markerItem.point.latitude}|${markerItem.point.longitude}|${markerSearchText(markerItem)}";
  }

  List<String> collectSearchTokens(dynamic value) {
    if (value == null) {
      return <String>[];
    }

    if (value is Map) {
      final List<String> items = <String>[];

      for (final MapEntry<dynamic, dynamic> entry in value.entries) {
        final String key = entry.key.toString().trim();

        if (key.isNotEmpty) {
          items.add(key);
        }

        items.addAll(collectSearchTokens(entry.value));
      }

      return items;
    }

    if (value is Iterable) {
      return value.expand(collectSearchTokens).toList();
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == "null") {
      return <String>[];
    }

    return <String>[text];
  }

  void updateVisibleMarkerState(String value) {
    final List<MarkerItem> visibleMarkers = filteredMarkerItems(query: value);

    setState(() {
      if (visibleMarkers.length != 1) {
        lastFocusedMarkerSignature = null;
      }

      if (selectedMarker != null && !visibleMarkers.contains(selectedMarker)) {
        selectedMarker = null;
      }
    });
  }

  void clearSearch() {
    tecSearch.clear();
    updateVisibleMarkerState("");
  }

  void onSearchChanged(String value) {
    updateVisibleMarkerState(value);
  }

  void onSearchSubmitted(String value) {
    final List<MarkerItem> visibleMarkers = filteredMarkerItems(query: value);

    FocusScope.of(context).unfocus();

    setState(() {
      followCurrentLocation = false;

      if (visibleMarkers.length != 1) {
        lastFocusedMarkerSignature = null;
      }

      if (selectedMarker != null && !visibleMarkers.contains(selectedMarker)) {
        selectedMarker = null;
      }
    });

    focusSingleVisibleMarkerIfNeeded(visibleMarkers, force: true);
  }

  double currentMapZoom({double fallback = 18}) {
    try {
      return mapController.camera.zoom;
    } catch (_) {
      return fallback;
    }
  }

  void focusMapOnPoint(
    LatLng point, {
    required String id,
    double? zoom,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      try {
        mapController.move(point, zoom ?? currentMapZoom(), id: id);
      } catch (_) {}
    });
  }

  void hideLocateButton() {
    locateButtonRestoreTimer?.cancel();

    if (!mounted || !isLocateButtonVisible) {
      return;
    }

    setState(() {
      isLocateButtonVisible = false;
    });
  }

  void showLocateButton() {
    locateButtonRestoreTimer?.cancel();

    if (!mounted || isLocateButtonVisible) {
      return;
    }

    setState(() {
      isLocateButtonVisible = true;
    });
  }

  void scheduleShowLocateButton({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    locateButtonRestoreTimer?.cancel();
    locateButtonRestoreTimer = Timer(delay, showLocateButton);
  }

  void handleMapInteractionEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      if (event.source == MapEventSource.dragStart ||
          event.source == MapEventSource.multiFingerGestureStart) {
        hideLocateButton();
      }

      return;
    }

    if (event is MapEventFlingAnimationStart) {
      hideLocateButton();
      return;
    }

    if (event is MapEventMoveEnd) {
      if (event.source == MapEventSource.dragEnd ||
          event.source == MapEventSource.multiFingerEnd) {
        scheduleShowLocateButton();
      }

      return;
    }

    if (event is MapEventFlingAnimationEnd ||
        event is MapEventFlingAnimationNotStarted) {
      showLocateButton();
    }
  }

  void focusSingleVisibleMarkerIfNeeded(
    List<MarkerItem> visibleMarkers, {
    bool force = false,
  }) {
    if (visibleMarkers.length != 1) {
      lastFocusedMarkerSignature = null;
      return;
    }

    final MarkerItem markerItem = visibleMarkers.first;
    final String signature = markerSignature(markerItem);

    if (!force && lastFocusedMarkerSignature == signature) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      try {
        final double currentZoom = currentMapZoom(fallback: 16);
        final double targetZoom = currentZoom < 16 ? 16 : currentZoom;

        final bool moved = mapController.move(
          markerItem.point,
          targetZoom,
          id: "search-focus",
        );

        if (moved) {
          lastFocusedMarkerSignature = signature;
        }
      } catch (_) {}
    });
  }

  Future<LatLng?> resolveCurrentLocation() async {
    if (currentPosition != null) {
      return currentPosition;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      final LatLng nextPosition = LatLng(position.latitude, position.longitude);

      currentPosition = nextPosition;
      return nextPosition;
    } catch (_) {
      return currentPosition;
    }
  }

  Future<void> focusCurrentLocation() async {
    final double currentZoom = currentMapZoom();
    final double targetZoom = currentZoom < 18 ? 18 : currentZoom;

    final LatLng? targetPosition = await resolveCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      followCurrentLocation = true;
      lastFocusedMarkerSignature = null;
      selectedMarker = null;
    });

    if (targetPosition != null) {
      focusMapOnPoint(
        targetPosition,
        zoom: targetZoom,
        id: "my-location-focus",
      );
    }
  }

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
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.18 : 0.12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              mapTypeChip(context),
                              SizedBox(width: Dimensions.size5),
                              statusChip(context),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: Dimensions.size10),
                      searchBox(),
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
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
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
            width: Dimensions.size20,
            height: Dimensions.size20,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 12, color: primary),
          ),
          SizedBox(width: Dimensions.size5),
          Text(
            label,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: AppColors.onSurface(),
            ),
          ),
        ],
      ),
    );
  }

  Widget mapTypeChip(BuildContext context) {
    return Builder(
      builder: (targetContext) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              String? selectedValue = await BasePopupMenus.show(
                context: context,
                targetContext: targetContext,
                items: [
                  PopupMenuItem<String>(
                    enabled: true,
                    value: "nonsatellite",
                    child: mapTypeMenuItem(
                      label: "Peta",
                      icon: Icons.map_rounded,
                      selected: baseMap == "nonsatellite",
                    ),
                  ),
                  PopupMenuItem<String>(
                    enabled: true,
                    value: "satellite",
                    child: mapTypeMenuItem(
                      label: "Satelit",
                      icon: Icons.satellite_alt_rounded,
                      selected: baseMap == "satellite",
                    ),
                  ),
                ],
                value: baseMap,
              );

              if (selectedValue == null || selectedValue == baseMap) {
                return;
              }

              setState(() {
                baseMap = selectedValue;
                mapSourceFuture = loadMapSource();
              });
            },
            borderRadius: BorderRadius.circular(Dimensions.size15),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.size10,
                vertical: Dimensions.size5,
              ),
              decoration: ShapeDecoration(
                color: AppColors.surfaceContainerLowest()
                    .withValues(alpha: isDark ? 0.72 : 1),
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: AppColors.outline()
                        .withValues(alpha: isDark ? 0.22 : 0.18),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: Dimensions.size20,
                    height: Dimensions.size20,
                    decoration: BoxDecoration(
                      color:
                          mapTypeAccentColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Dimensions.size100),
                      border: Border.all(
                        color:
                            mapTypeAccentColor(context).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      mapTypeIcon,
                      size: 12,
                      color: mapTypeAccentColor(context),
                    ),
                  ),
                  SizedBox(width: Dimensions.size5),
                  Text(
                    mapTypeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Dimensions.text11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      color: AppColors.onSurface(),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.onSurface().withValues(alpha: 0.72),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget mapTypeMenuItem({
    required String label,
    required IconData icon,
    required bool selected,
  }) {
    final Color accent = icon == Icons.satellite_alt_rounded
        ? Colors.orange.shade700
        : Colors.green.shade700;

    return Row(
      children: [
        Container(
          width: Dimensions.size25,
          height: Dimensions.size25,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dimensions.size100),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 15, color: accent),
        ),
        SizedBox(width: Dimensions.size10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.onTertiaryContainer(),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (selected)
          Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }

  Color mapTypeAccentColor(BuildContext context) {
    if (isSatelliteMap) {
      return Colors.orange.shade700;
    }

    return Colors.green.shade700;
  }

  Widget searchBox() {
    final List<MarkerItem> visibleMarkers = filteredMarkerItems();

    return Container(
      height: Dimensions.size50,
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
      padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppColors.onSurface().withValues(alpha: 0.70),
          ),
          SizedBox(width: Dimensions.size10),
          Expanded(
            child: TextField(
              controller: tecSearch,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              decoration: InputDecoration(
                hintText: "search".tr(),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (StringUtils.isNotNullOrEmpty(tecSearch.text))
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: clearSearch,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(Dimensions.size5),
                  child: Icon(
                    Icons.close_rounded,
                    size: Dimensions.size20,
                    color: AppColors.onSurface().withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          SizedBox(width: Dimensions.size5),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.size10,
              vertical: Dimensions.size5,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.10,
                  ),
              borderRadius: BorderRadius.circular(Dimensions.size100),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.18,
                    ),
              ),
            ),
            child: Text(
              "${visibleMarkers.length}/${markerItems.length}",
              style: TextStyle(
                fontSize: Dimensions.text11,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
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
            child: IgnorePointer(
              ignoring: !isLocateButtonVisible,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                offset: Offset(0, isLocateButtonVisible ? 0 : 1.35),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: isLocateButtonVisible ? 1 : 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: focusCurrentLocation,
                      borderRadius: BorderRadius.circular(Dimensions.size30),
                      child: Ink(
                        height: Dimensions.size55,
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.size20,
                        ),
                        decoration: ShapeDecoration(
                          color: primary,
                          shadows: [
                            BoxShadow(
                              blurRadius: Dimensions.size20,
                              offset: Offset(0, Dimensions.size10),
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.22 : 0.16),
                            ),
                          ],
                          shape: SmoothRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.size30),
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
                              "my_location".tr(),
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
          ),
        ),
      ),
    );
  }

  Widget fabSelectCurrentMarker(BuildContext context) {
    final double horizontalPadding = DotResponsive.horizontalPadding(context);

    Widget childWidget() {
      if (selectedMarker!.info != null) {
        List<Widget> widgets = [];

        for (int i = 0; i < selectedMarker!.info!.entries.length; i++) {
          if (i % 2 == 0) {
            List<Widget> children = [];

            MapEntry<String, dynamic> dfrfiLeft =
                selectedMarker!.info!.entries.elementAt(i);

            children.add(
              childrenWidget(
                description: dfrfiLeft.key,
                value: dfrfiLeft.value,
                left: true,
              ),
            );

            if (i + 1 < selectedMarker!.info!.entries.length) {
              MapEntry<String, dynamic> dfrfiRight =
                  selectedMarker!.info!.entries.elementAt(i + 1);

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
              padding: EdgeInsets.all(Dimensions.size10),
              child: Column(
                children: [
                  ...widgets,
                  SizedBox(height: Dimensions.size10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (BaseSettings.navigatorType ==
                            BaseNavigatorType.legacy) {
                          Navigators.pop(result: selectedMarker);
                        } else {
                          context.pop(selectedMarker);
                        }
                      },
                      child: Text("use_selected_marker".tr()),
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
          child: Text("use_selected_marker".tr()),
        );
      }
    }

    return Positioned(
      left: 0,
      right: 0,
      top: topFloatingActionsOffset(context),
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

  Future<({String? storagePath, double? minZoom})> loadMapSource() async {
    final String? storagePath = await getOfflineMapStoragePath();
    final bool canUseOfflineTiles =
        !isOnline && supportsOfflineMapStorage && storagePath != null;

    final double? minZoom = canUseOfflineTiles
        ? await getOfflineMapMinZoom(baseMap: baseMap)
        : null;

    return (
      storagePath: storagePath,
      minZoom: minZoom,
    );
  }

  Widget offlineUnavailableNotice() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: Dimensions.size20),
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size15,
            vertical: Dimensions.size10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface().withValues(alpha: isDark ? 0.92 : 0.95),
            borderRadius: BorderRadius.circular(Dimensions.size15),
            border: Border.all(
              color:
                  AppColors.outline().withValues(alpha: isDark ? 0.22 : 0.18),
            ),
          ),
          child: Text(
            "offline_map_unavailable".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface(),
            ),
          ),
        ),
      ),
    );
  }

  Widget mapHost() {
    final List<MarkerItem> visibleMarkers = filteredMarkerItems();

    return FutureBuilder<({String? storagePath, double? minZoom})>(
      future: mapSourceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final String? storagePath = snapshot.data?.storagePath;
        final bool canUseOfflineTiles =
            !isOnline && supportsOfflineMapStorage && storagePath != null;
        final bool canShowCustomOverlay =
            supportsOfflineMapStorage && storagePath != null;

        return Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialZoom: snapshot.data?.minZoom ?? 14,
                onPositionChanged: (_, hasGesture) {
                  if (!hasGesture || !followCurrentLocation) {
                    return;
                  }

                  setState(() {
                    followCurrentLocation = false;
                  });
                },
                onMapEvent: handleMapInteractionEvent,
              ),
              children: [
                TileLayer(
                  tileProvider: canUseOfflineTiles
                      ? FileTileProvider()
                      : NetworkTileProvider(),
                  urlTemplate: tileUrlTemplate(
                    storagePath: storagePath,
                    useOfflineTiles: canUseOfflineTiles,
                  ),
                  userAgentPackageName: "com.sisapp.dynamic_of_things",
                ),
                if (canShowCustomOverlay)
                  TileLayer(
                    urlTemplate:
                        "$storagePath/$offlineMapBaseFolder/custom/{z}/{x}/{y}.png",
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
                  alignPositionOnUpdate: AlignOnUpdate.never,
                ),
                PolylineLayer(
                  polylines: buildPolylines(),
                ),
                MarkerLayer(
                  markers: visibleMarkers.map((e) {
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
            ),
            if (!isOnline && !canUseOfflineTiles) offlineUnavailableNotice(),
            if (tecSearch.text.trim().isNotEmpty && visibleMarkers.isEmpty)
              searchEmptyNotice(),
          ],
        );
      },
    );
  }

  Widget searchEmptyNotice() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: Dimensions.size20),
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size15,
            vertical: Dimensions.size10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface().withValues(alpha: isDark ? 0.92 : 0.95),
            borderRadius: BorderRadius.circular(Dimensions.size15),
            border: Border.all(
              color:
                  AppColors.outline().withValues(alpha: isDark ? 0.22 : 0.18),
            ),
          ),
          child: Text(
            "search_empty_notice".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface(),
            ),
          ),
        ),
      ),
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
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    connectivitySub?.cancel();
    locateButtonRestoreTimer?.cancel();
    positionSubscription?.cancel();
    tecSearch.dispose();
    mapController.dispose();
    super.dispose();
  }

  String tileUrlTemplate({
    required String? storagePath,
    required bool useOfflineTiles,
  }) {
    if (!useOfflineTiles) {
      if (baseMap == "satellite") {
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
      } else {
        return "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      }
    }

    return "$storagePath/$offlineMapBaseFolder/$baseMap/{z}/{x}/{y}.png";
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
