import "package:base/base.dart";
import "package:flutter/foundation.dart";
import "package:geocoding/geocoding.dart";

class Generals {
  static Future<String?> lastPlacemarkPosition() async {
    try {
      LongLat? longLat = await Locations.lastPosition();

      if (longLat != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(longLat.latitude, longLat.longitude);

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
}