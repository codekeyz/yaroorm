class AppConfig {
  final String name;
  final String environment;
  final bool isDebug;
  final String timezone;
  final String locale;
  final String key;
  final int? _port;
  final String? _url;

  Uri get _uri {
    final uri = Uri.parse(_url!);
    return _port == null ? uri : uri.replace(port: _port);
  }

  int get port => _uri.port;

  String get url => _uri.toString();

  const AppConfig({
    required this.name,
    required this.environment,
    required this.isDebug,
    required this.key,
    this.timezone = 'UTC',
    this.locale = 'en',
    int? port,
    String? url,
  })  : _port = port,
        _url = url;
}
