// ignore_for_file: deprecated_member_use, unrelated_type_equality_checks

import "dart:async";
import "dart:io";
import "dart:ui";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:dynamic_of_things/widget/map_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:geolocator/geolocator.dart";
import "package:latlong2/latlong.dart" as ll;
import "package:path_provider/path_provider.dart";
import "package:smooth_corner/smooth_corner.dart";

class CustomDynamicFormLocationField extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final Template template;
  final Map<String, dynamic> data;

  const CustomDynamicFormLocationField({
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.template,
    required this.data,
    super.key,
  });

  @override
  State<CustomDynamicFormLocationField> createState() =>
      CustomDynamicFormLocationFieldState();
}

class CustomDynamicFormLocationFieldState
    extends State<CustomDynamicFormLocationField> {
  ll.LatLng? latLng;

  bool isOnline = true;

  String baseMap = "satellite";

  StreamSubscription? connectivitySub;

  @override
  void initState() {
    super.initState();

    if (!widget.readOnly) {
      watchConnectivity();
    }

    num? latitude;
    num? longitude;

    for (Section section in widget.template.sections) {
      for (Field field in section.fields) {
        if (field.name == "latitude") {
          latitude = num.tryParse(field.getValue(widget.data) ?? "");
        } else if (StringUtils.inList(
          field.name,
          ["longitude", "longtitude"],
        )) {
          longitude = num.tryParse(field.getValue(widget.data) ?? "");
        }
      }
    }

    if (latitude != null && longitude != null) {
      latLng = ll.LatLng(latitude.toDouble(), longitude.toDouble());
    }
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

  bool get isGlass {
    try {
      return (Preferences.getInstance()
                  .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
              1) ==
          2;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Menghilangkan efek shadow dan menjadikan container mirip seperti form input biasa
    final bool glass = isGlass;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerRow(context),
        if (latLng != null) ...[
          SizedBox(height: Dimensions.size15),
          mapWidget(),
        ],
        if (!widget.readOnly) ...[
          SizedBox(height: Dimensions.size15),
          getLocationButton(),
        ],
      ],
    );

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size15,
        borderRadius: Dimensions.size15,
        opacity: 0.05,
        borderOpacity: 0.15,
        padding: EdgeInsets.all(Dimensions.size15),
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.size15),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.10,
            ),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget headerRow(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color fg =
        isGlass ? Colors.white.withOpacity(0.92) : AppColors.onSurface();

    return Row(
      children: [
        Container(
          width: Dimensions.size35,
          height: Dimensions.size35,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: primary.withValues(alpha: 0.22)),
          ),
          child: Icon(
            Icons.location_on_rounded,
            size: Dimensions.size20,
            color: primary,
          ),
        ),
        SizedBox(width: Dimensions.size10),
        Expanded(
          child: Text(
            "Location",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ),
        statusBadge(context),
      ],
    );
  }

  Widget statusBadge(BuildContext context) {
    final Color fg =
        isGlass ? Colors.white.withOpacity(0.92) : AppColors.onSurface();
    final Color outline =
        isGlass ? Colors.white.withOpacity(0.18) : AppColors.outline();

    final Color ok = Colors.green;
    final Color warn = Colors.orange;

    final bool online = isOnline;
    final Color c = online ? ok : warn;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.size100),
        border: Border.all(
          color: c.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Dimensions.size10,
            height: Dimensions.size10,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: c.withValues(alpha: 0.40),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.size5),
          Text(
            online ? "Online" : "Offline",
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          SizedBox(width: Dimensions.size5),
          Icon(
            online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: Dimensions.size15,
            color: outline.withValues(alpha: 0.75),
          ),
        ],
      ),
    );
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

  Widget mapWidget() {
    if (latLng != null) {
      return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 180,
              decoration: ShapeDecoration(
                color: isGlass
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.surfaceContainerLowest(),
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: isGlass
                        ? Colors.white.withOpacity(0.12)
                        : AppColors.outline().withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.size15),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: isGlass
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.surfaceContainerLowest(),
                borderRadius: BorderRadius.circular(Dimensions.size15),
                border: Border.all(
                  color: isGlass
                      ? Colors.white.withOpacity(0.18)
                      : AppColors.outline().withValues(alpha: 0.15),
                  width: Dimensions.size1,
                ),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: latLng!,
                      initialZoom: 19,
                    ),
                    children: [
                      TileLayer(
                        tileProvider: isOnline ? NetworkTileProvider() : FileTileProvider(),
                        urlTemplate: tileUrlTemplate(snapshot.data!.path),
                        userAgentPackageName: "com.sisapp.dynamic_of_things",
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng!,
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 34,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: Dimensions.size10,
                    bottom: Dimensions.size10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.size100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.size10,
                            vertical: Dimensions.size5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.40),
                            borderRadius:
                                BorderRadius.circular(Dimensions.size100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            "${latLng!.latitude.toStringAsFixed(6)}, ${latLng!.longitude.toStringAsFixed(6)}",
                            style: TextStyle(
                              fontSize: Dimensions.text11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget getLocationButton() {
    if (!widget.readOnly) {
      final Color primary = Theme.of(context).colorScheme.primary;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Position? result = await showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              useRootNavigator: true,
              builder: (context) {
                return GetLocationPage(
                  locationAccuracyInMeters:
                      widget.template.locationAccuracyInMeters,
                  locationAccuracyEfectiveDurationInSeconds:
                      widget.template.locationAccuracyEfectiveDurationInSeconds,
                );
              },
            );

            if (result != null) {
              latLng = ll.LatLng(result.latitude, result.longitude);

              widget.template.sections.forEach((section) {
                section.fields.forEach((field) {
                  if (field.name == "latitude") {
                    field.setValue(
                      widget.headerForm.data,
                      latLng!.latitude.toString(),
                    );
                  } else if (StringUtils.inList(
                    field.name,
                    ["longitude", "longtitude"],
                  )) {
                    field.setValue(
                      widget.headerForm.data,
                      latLng!.longitude.toString(),
                    );
                  }
                });
              });

              setState(() {});
            }
          },
          borderRadius: BorderRadius.circular(Dimensions.size15),
          child: Ink(
            height: Dimensions.size45,
            decoration: ShapeDecoration(
              color: isGlass
                  ? Colors.white.withOpacity(0.08)
                  : primary.withOpacity(0.12),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size15),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: isGlass
                      ? Colors.white.withOpacity(0.18)
                      : primary.withOpacity(0.20),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.my_location_rounded,
                  size: Dimensions.size20,
                  color: isGlass ? Colors.white.withOpacity(0.92) : primary,
                ),
                SizedBox(width: Dimensions.size10),
                Text(
                  "get_location".tr().toUpperCase(),
                  style: TextStyle(
                    color: isGlass ? Colors.white.withOpacity(0.92) : primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    fontSize: Dimensions.text12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class GetLocationPage extends StatefulWidget {
  final num? locationAccuracyInMeters;
  final num? locationAccuracyEfectiveDurationInSeconds;

  const GetLocationPage({
    super.key,
    this.locationAccuracyInMeters,
    this.locationAccuracyEfectiveDurationInSeconds,
  });

  @override
  State<GetLocationPage> createState() => GetLocationPageState();
}

class GetLocationPageState extends State<GetLocationPage> {
  StreamSubscription<Position>? subscription;
  DateTime? accuracyStartTime;
  Position? acceptedPosition;

  String status = "Waiting for location...";
  bool prefsReady = false;

  @override
  void initState() {
    super.initState();
    initPrefs();
    startListening();
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

  Future<void> startListening() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        status = "Location permission denied";
      });
      return;
    }

    subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(onLocationUpdate);
  }

  void onLocationUpdate(Position position) {
    final accuracyThreshold = widget.locationAccuracyInMeters ?? 20;
    final requiredSeconds =
        widget.locationAccuracyEfectiveDurationInSeconds ?? 1;
    final accuracy = position.accuracy;

    if (accuracy <= accuracyThreshold) {
      accuracyStartTime ??= DateTime.now();

      final elapsed = DateTime.now().difference(accuracyStartTime!).inSeconds;

      if (elapsed >= requiredSeconds) {
        acceptedPosition = position;
        subscription?.cancel();

        if (acceptedPosition != null) {
          Navigators.pop(context: context, result: acceptedPosition!);
        }

        setState(() {
          status = "✅ Location accepted!";
        });
        return;
      }

      setState(() {
        status = "Good accuracy (${accuracy.toStringAsFixed(2)} m)\n"
            "Holding for $elapsed / $requiredSeconds seconds...";
      });
    } else {
      accuracyStartTime = null;

      setState(() {
        status = "Accuracy too high: ${accuracy.toStringAsFixed(2)} m\n"
            "Waiting for < $accuracyThreshold m";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool glass = isGlass;
    final Color fg =
        glass ? Colors.white.withOpacity(0.95) : AppColors.onSurface();
    final Color outline =
        glass ? Colors.white.withOpacity(0.22) : AppColors.outline();
    final Color card =
        glass ? Colors.white.withOpacity(0.12) : AppColors.surface();
    final Color primary = Theme.of(context).colorScheme.primary;

    final Widget dialogContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size10,
          ),
          child: Row(
            children: [
              Container(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: glass ? Colors.white : primary,
                  size: Dimensions.size20,
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Text(
                  "get_location".tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigators.pop(context: context);
                  },
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: Dimensions.size40,
                    height: Dimensions.size40,
                    decoration: BoxDecoration(
                      color: glass
                          ? Colors.white.withOpacity(0.10)
                          : AppColors.surfaceContainerLowest(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: fg,
                      size: Dimensions.size20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: outline.withValues(alpha: 0.25)),
        Padding(
          padding: EdgeInsets.all(Dimensions.size25),
          child: Column(
            children: [
              Container(
                width: Dimensions.size50,
                height: Dimensions.size50,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: glass ? Colors.white.withOpacity(0.90) : primary,
                  ),
                ),
              ),
              SizedBox(height: Dimensions.size20),
              Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Dimensions.text13,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: Dimensions.size10,
              sigmaY: Dimensions.size10,
            ),
            child: Container(color: Colors.black.withAlpha(80)),
          ),
          Center(
            child: Container(
              width: 340,
              margin: EdgeInsets.all(Dimensions.size20),
              child: glass
                  ? GlassContainer(
                      blur: Dimensions.size25,
                      borderRadius: Dimensions.size25,
                      opacity: 0.15,
                      borderOpacity: 0.25,
                      padding: EdgeInsets.zero,
                      child: dialogContent,
                    )
                  : Container(
                      decoration: ShapeDecoration(
                        color: card,
                        shadows: [
                          BoxShadow(
                            blurRadius: Dimensions.size30,
                            offset: Offset(0, Dimensions.size20),
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                        ],
                        shape: SmoothRectangleBorder(
                          smoothness: Dimensions.size1,
                          borderRadius:
                              BorderRadius.circular(Dimensions.size25),
                          side: BorderSide(
                            color: outline.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: dialogContent,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }
}
