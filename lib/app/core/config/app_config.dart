/// Build-time configuration. Values are public identifiers, not secrets.
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.placeSlug,
    this.locale = 'ar',
    this.requestTimeout = const Duration(seconds: 20),
    this.uploadTimeout = const Duration(seconds: 60),
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://dori.toldpath.com/api/v1',
    ),
    placeSlug: String.fromEnvironment('PLACE_SLUG', defaultValue: 'elora'),
  );

  final String baseUrl;
  final String placeSlug;
  final String locale;
  final Duration requestTimeout;
  final Duration uploadTimeout;
}
