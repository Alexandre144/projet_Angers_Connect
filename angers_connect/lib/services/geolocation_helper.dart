import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeolocationHelper {
  static Future<Position?> getCurrentPosition() async {
    try {
      if (kIsWeb) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Timeout'),
          );
          return position;
        } catch (_) {
          return null;
        }
      } else {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: false,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Délai dépassé'),
        );
      }
    } catch (e) {
      if (kIsWeb) {
        return null;
      }
      rethrow;
    }
  }
}

