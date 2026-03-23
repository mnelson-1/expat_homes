import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android: same key as Maps SDK (from `local.properties` → Gradle → [BuildConfig]).
/// Other platforms: optional `--dart-define=GOOGLE_MAPS_API_KEY=...` for Places HTTP.
class MapsApiKeyChannel {
  MapsApiKeyChannel._();

  static const MethodChannel _channel = MethodChannel('com.expathomes/maps');

  /// Key used for Places REST calls (must match the Maps SDK key restrictions).
  static Future<String> resolvePlacesApiKey() async {
    const fromDefine = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final key = await _channel.invokeMethod<String>('getMapsApiKey');
        if (key != null && key.isNotEmpty) return key;
      } on PlatformException catch (_) {
        // Channel missing or native error
      }
    }

    return '';
  }
}
