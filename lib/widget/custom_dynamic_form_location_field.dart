// ignore_for_file: always_specify_types, use_build_context_synchronously, empty_catches, cascade_invocations, always_put_required_named_parameters_first, invalid_use_of_protected_member

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
    super.key,
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.template,
    required this.data,
  });

  @override
  State<CustomDynamicFormLocationField> createState() => CustomDynamicFormLocationFieldState();
}

class CustomDynamicFormLocationFieldState extends State<CustomDynamicFormLocationField> {
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
        } else if (StringUtils.inList(field.name, ["longitude", "longtitude"])) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mapWidget(),
        getLocationButton(),
      ],
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Widget mapWidget() {
    if (latLng != null) {
      return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            height: 150,
            margin: EdgeInsets.only(bottom: 10),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latLng!,
                initialZoom: 19,
              ),
              children: [
                _isOnline ? TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.sisapp.dynamic_of_things",
                ) : TileLayer(tileProvider: LocalDiskTileProvider(basePath: "${snapshot.data!.path}/offline_tiles")),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng!,
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 30,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget getLocationButton() {
    if (!widget.readOnly) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () async {
            Position? result = await showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              useRootNavigator: true,
              builder: (context) {
                return GetLocationPage(
                  locationAccuracyInMeters: widget.template.locationAccuracyInMeters,
                  locationAccuracyEfectiveDurationInSeconds: widget.template.locationAccuracyEfectiveDurationInSeconds,
                );
              },
            );

            if (result != null) {
              latLng = ll.LatLng(result.latitude, result.longitude);

              widget.template.sections.forEach((section) {
                section.fields.forEach((field) {
                  if (field.name == "latitude") {
                    field.setValue(widget.headerForm.data, latLng!.latitude.toString());
                  } else if (StringUtils.inList(field.name, ["longitude", "longtitude"])) {
                    field.setValue(widget.headerForm.data, latLng!.longitude.toString());
                  }
                });
              });

              setState(() {});
            }
          },
          child: Text("get_location".tr().toUpperCase()),
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
    final requiredSeconds = widget.locationAccuracyEfectiveDurationInSeconds ?? 1;
    final accuracy = position.accuracy;

    if (accuracy <= accuracyThreshold) {
      _accuracyStartTime ??= DateTime.now();

      final elapsed =
          DateTime.now().difference(_accuracyStartTime!).inSeconds;

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
        _status =
        "Good accuracy (${accuracy.toStringAsFixed(2)} m)\n"
            "Holding for $elapsed / $requiredSeconds seconds...";
      });
    } else {
      _accuracyStartTime = null;

      setState(() {
        _status =
        "Accuracy too high: ${accuracy.toStringAsFixed(2)} m\n"
            "Waiting for < $accuracyThreshold m";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withAlpha(20)),
          ),
          Center(
            child: Container(
              width: 300,
              height: 300,
              margin: EdgeInsets.all(20),
              decoration: ShapeDecoration(
                shape: SmoothRectangleBorder(
                  smoothness: 1,
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.outlineVariant()),
                ),
                color: AppColors.surface(),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigators.pop(context: context);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer(),
                      foregroundColor: AppColors.onSurface(),
                      fixedSize: Size.square(50),
                      iconSize: 30,
                    ),
                    icon: Icon(Icons.close),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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