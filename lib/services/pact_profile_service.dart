import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_service.dart';
import 'backend_service.dart';

class PactProfileService {
  static const _apiOrigin = String.fromEnvironment(
    'PACT_API_URL',
    defaultValue: 'https://dwelling-iq-app.pages.dev',
  );
  static Uri get _endpoint =>
      Uri.parse('${kIsWeb ? Uri.base.origin : _apiOrigin}/api/profile-media');

  static Future<bool> pickImage(String slot) async {
    if (!['avatar', 'cover'].contains(slot)) {
      throw ArgumentError('Invalid photo slot');
    }
    final owner = BackendService.user?.id;
    if (owner == null) throw StateError('Sign in to edit your profile.');
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 88,
      requestFullMetadata: false,
    );
    if (file == null) return false;
    if (await file.length() > 24 * 1024 * 1024) {
      throw StateError('Choose an image under 24 MB.');
    }
    // Normalize library formats (including iPhone HEIC via the system picker),
    // preserve aspect ratio, strip source metadata, and never upload active SVG.
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      await file.readAsBytes(),
    );
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    Uint8List bytes;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final edge = slot == 'avatar' ? 768 : 1800;
      final scale = math.min(
        1.0,
        edge / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null) throw StateError('Could not prepare this image.');
      bytes = encoded.buffer.asUint8List(
        encoded.offsetInBytes,
        encoded.lengthInBytes,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
    if (bytes.length > 8 * 1024 * 1024) {
      throw StateError(
        'Choose a smaller image. The prepared photo must be under 8 MB.',
      );
    }
    if (BackendService.user?.id != owner) {
      throw StateError('Your account changed. Please try again.');
    }
    final session = await Supabase.instance.client.auth.refreshSession();
    if (session.session?.user.id != owner) {
      throw StateError('Sign in again to save this image.');
    }
    final response = await http
        .post(
          _endpoint.replace(queryParameters: {'slot': slot}),
          headers: {
            'Authorization': 'Bearer ${session.session!.accessToken}',
            'Content-Type': 'image/png',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 201) {
      throw StateError(
        'Could not save the image. Your existing photo is safe; please retry.',
      );
    }
    return true;
  }

  static Future<void> save({
    required AccountProfile profile,
    required Map<String, dynamic> details,
  }) async {
    if (BackendService.user?.id != profile.id) {
      throw StateError('Sign in again to edit your profile.');
    }
    await Supabase.instance.client.rpc(
      'pact_save_profile',
      params: {'payload': details, 'expected_updated_at': profile.updatedAt},
    );
  }
}
