import 'package:geolocator/geolocator.dart';

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
  static Future<DeviceLocationResult> locateCanadianCity() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are turned off on this device.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission was not allowed. You can still choose a city manually.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final city = await MarketplaceService.cityNearCoordinates(
      position.latitude,
      position.longitude,
    );
    if (city == null) {
      throw StateError(
        'We found your device, but could not match it to a Canadian community.',
      );
    }
    return DeviceLocationResult(
      city: city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
