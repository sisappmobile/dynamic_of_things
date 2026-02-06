import "dart:async";
import "dart:io";
import "dart:ui";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dynamic_of_things/local_disk_tile_provider.dart";
import "package:dynamic_of_things/model/header_form.dart";
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

  bool _isOnline = true;

  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();

    if (!widget.readOnly) {
      _watchConnectivity();
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

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      context: context,
      padding: EdgeInsets.all(Dimensions.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(context),
          if (latLng != null) ...[
            SizedBox(height: Dimensions.size15),
            mapWidget(),
          ],
          if (!widget.readOnly) ...[
            SizedBox(height: Dimensions.size15),
            getLocationButton(),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();
  Color _primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color _onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  Widget _sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: ShapeDecoration(
        color: _card(context),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size25,
            offset: Offset(0, Dimensions.size15),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(Dimensions.size15),
        child: child,
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final Color primary = _primary(context);
    final Color fg = _fg(context);

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
        _statusBadge(context),
      ],
    );
  }

  Widget _statusBadge(BuildContext context) {
    final Color fg = _fg(context);
    final Color outline = _outline(context);

    final Color ok = Colors.green;
    final Color warn = Colors.orange;

    final bool online = _isOnline;
    final Color c = online ? ok : warn;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: BoxDecoration(
        color: online ? c.withValues(alpha: 0.12) : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.size100),
        border: Border.all(
          color: online ? c.withValues(alpha: 0.30) : c.withValues(alpha: 0.30),
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
                  blurRadius: 10,
                  color: c.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.size5),
          Text(
            online ? "Online" : "Offline",
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w900,
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

  Widget mapWidget() {
    if (latLng != null) {
      return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 180,
              decoration: ShapeDecoration(
                color: _soft(context),
                shape: SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                  smoothness: Dimensions.size1,
                  side: BorderSide(
                    color: _outline(context).withValues(alpha: 0.18),
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
                color: _bg(context),
                borderRadius: BorderRadius.circular(Dimensions.size15),
                border: Border.all(
                  color: _outline(context).withValues(alpha: 0.18),
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
                      _isOnline
                          ? TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName:
                                  "com.sisapp.dynamic_of_things",
                            )
                          : TileLayer(
                              tileProvider: LocalDiskTileProvider(
                                basePath:
                                    "${snapshot.data!.path}/offline_tiles",
                              ),
                            ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng!,
                            child: Icon(
                              Icons.location_on_outlined,
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
                              Colors.black.withValues(alpha: 0.10),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
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
                            color: Colors.white.withValues(alpha: 0.10),
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
      final Color primary = _primary(context);
      final Color onPrimary = _onPrimary(context);

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
          borderRadius: BorderRadius.circular(Dimensions.size30),
          child: Ink(
            height: Dimensions.size50,
            decoration: ShapeDecoration(
              color: primary,
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size30),
                smoothness: Dimensions.size1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: Dimensions.size30,
                  height: Dimensions.size30,
                  decoration: BoxDecoration(
                    color: onPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    size: Dimensions.size20,
                    color: onPrimary,
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Text(
                  "get_location".tr().toUpperCase(),
                  style: TextStyle(
                    color: onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    fontSize: Dimensions.text13,
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
  State<GetLocationPage> createState() => _GetLocationPageState();
}

class _GetLocationPageState extends State<GetLocationPage> {
  StreamSubscription<Position>? _subscription;
  DateTime? _accuracyStartTime;
  Position? _acceptedPosition;

  String _status = "Waiting for location...";

  @override
  void initState() {
    super.initState();

    _startListening();
  }

  Future<void> _startListening() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _status = "Location permission denied";
      });
      return;
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(_onLocationUpdate);
  }

  void _onLocationUpdate(Position position) {
    final accuracyThreshold = widget.locationAccuracyInMeters ?? 20;
    final requiredSeconds =
        widget.locationAccuracyEfectiveDurationInSeconds ?? 1;
    final accuracy = position.accuracy;

    if (accuracy <= accuracyThreshold) {
      _accuracyStartTime ??= DateTime.now();

      final elapsed = DateTime.now().difference(_accuracyStartTime!).inSeconds;

      if (elapsed >= requiredSeconds) {
        _acceptedPosition = position;
        _subscription?.cancel();

        if (_acceptedPosition != null) {
          Navigators.pop(context: context, result: _acceptedPosition!);
        }

        setState(() {
          _status = "✅ Location accepted!";
        });
        return;
      }

      setState(() {
        _status = "Good accuracy (${accuracy.toStringAsFixed(2)} m)\n"
            "Holding for $elapsed / $requiredSeconds seconds...";
      });
    } else {
      _accuracyStartTime = null;

      setState(() {
        _status = "Accuracy too high: ${accuracy.toStringAsFixed(2)} m\n"
            "Waiting for < $accuracyThreshold m";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color fg = AppColors.onSurface();
    final Color outline = AppColors.outline();
    final Color card = AppColors.surface();
    final Color soft = AppColors.surfaceContainerLowest();
    final Color primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withAlpha(30)),
          ),
          Center(
            child: Container(
              width: 340,
              margin: EdgeInsets.all(Dimensions.size20),
              decoration: ShapeDecoration(
                color: card,
                shadows: [
                  BoxShadow(
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ],
                shape: SmoothRectangleBorder(
                  smoothness: 1,
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: outline.withValues(alpha: 0.18)),
                ),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Column(
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(
                            Icons.my_location_rounded,
                            color: primary,
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: soft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: outline.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: fg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: outline.withValues(alpha: 0.18)),
                  Padding(
                    padding: EdgeInsets.all(Dimensions.size20),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        SizedBox(height: Dimensions.size15),
                        Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Dimensions.text14,
                            fontWeight: FontWeight.w800,
                            color: fg,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

    _subscription?.cancel();
  }
}
