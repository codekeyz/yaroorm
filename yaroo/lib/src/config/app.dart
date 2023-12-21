import 'package:yaroo/src/_reflector/reflector.dart';
import 'package:yaroo/src/config/config.dart';

class AppConfig {
  final String name;
  final String environment;
  final bool isDebug;
  final String url;
  final int port;
  final String timezone;
  final String locale;
  final String key;
  final List<Type> providers;

  const AppConfig({
    required this.name,
    required this.environment,
    required this.isDebug,
    required this.url,
    required this.port,
    required this.key,
    this.timezone = 'UTC',
    this.locale = 'en',
    this.providers = const [],
  });

  factory AppConfig.fromJson(Map<String, dynamic> config) {
    final providers = config.getValue<List<Type>>('providers', defaultValue: const []);
    if (providers.isNotEmpty) providers.forEach(_validateProvider);

    final Uri appUri = _validateAppUrl(config.getValue<String>('url'));

    return AppConfig(
      name: config.getValue<String>('name'),
      environment: config.getValue<String>('env'),
      isDebug: config.getValue<bool>('debug'),
      url: appUri.toString(),
      port: config.getValue<int>('port', defaultValue: appUri.port),
      key: config.getValue('key'),
      timezone: config.getValue('timezone', defaultValue: 'UTC'),
      locale: config.getValue<String>('locale', defaultValue: 'env'),
      providers: providers,
    );
  }

  static void _validateProvider(Type providerType) {
    try {
      reflectType(providerType);
    } catch (e) {
      throw ArgumentError.value(
          providerType, 'Invalid provider type provided', 'Ensure your provider extends `ServiceProvider` class');
    }
  }

  static Uri _validateAppUrl(String url) {
    try {
      return Uri.parse(url);
    } catch (e) {
      throw ArgumentError.value(url, 'Invalid app url provided', 'Ensure your app url is a valid url');
    }
  }
}
