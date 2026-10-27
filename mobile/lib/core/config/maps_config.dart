/// Google Maps Platform API key for Places Web Service (client-side).
///
/// Restrict this key in Google Cloud Console (Android/iOS apps + Places API).
/// Maps SDK key is configured separately in native projects (see README).
abstract final class MapsConfig {
  static const apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAs0_6rqdueGA5KSuHqQ8y-caG3Aota680',
  );

  static bool get hasPlacesApiKey =>
      apiKey.isNotEmpty && !apiKey.startsWith('PASTE_YOUR_') && !apiKey.startsWith('YOUR_');
}
