import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'marketplace_service.dart';

class DeviceLocationResult {
  const DeviceLocationResult({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final MarketplaceCity city;
  final double latitude;
  final double longitude;
}

class DeviceLocationService {
  static Future<({double latitude, double longitude})> locate() async {
    final completer = Completer<({double latitude, double longitude})>();
    web.window.navigator.geolocation.getCurrentPosition(
      (web.GeolocationPosition position) {
        completer.complete((
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        ));
      }.toJS,
      (web.GeolocationPositionError error) {
        final message = error.code == 1
            ? 'Location permission was not allowed. You can still choose a city manually.'
            : 'Your location could not be determined. Check location services and try again.';
        completer.completeError(StateError(message));
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: false,
        timeout: 12000,
        maximumAge: 60000,
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 14),
      onTimeout: () => throw StateError(
        'Location request timed out. You can still choose a city manually.',
      ),
    );
  }

  static Future<DeviceLocationResult> locateCanadianCity() async {
    final coordinates = await locate();
    final city = await MarketplaceService.cityNearCoordinates(
      coordinates.latitude,
      coordinates.longitude,
    );
    if (city == null) {
      throw StateError(
        'We found your device, but could not match it to a Canadian community.',
      );
    }
    return DeviceLocationResult(
      city: city,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }
}
