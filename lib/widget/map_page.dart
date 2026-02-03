import "dart:async";
import "dart:io";
import "package:base/base.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dynamic_of_things/local_disk_tile_provider.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:geolocator/geolocator.dart";
import "package:path_provider/path_provider.dart";

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

  // Fungsi cek izin lokasi saat aplikasi dibuka
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

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      context: context,
      appBar: BaseAppBar(
        context: context,
        name: "map".tr(),
      ),
      contentBuilder: () {
        return FutureBuilder<Directory>(
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
                _isOnline ? TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.sisapp.dynamic_of_things",
                ) : TileLayer(tileProvider: LocalDiskTileProvider(basePath: "${snapshot.data!.path}/offline_tiles")),
                CurrentLocationLayer(
                  alignPositionStream: _alignPositionStreamController.stream,
                  alignPositionOnUpdate: _alignPositionOnUpdate,
                ),
                MarkerLayer(
                  markers: widget.markers ?? [],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _alignPositionStreamController.close();
    super.dispose();
  }
}