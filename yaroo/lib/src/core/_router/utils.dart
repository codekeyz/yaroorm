import 'dart:io';

String cleanRoute(String route) {
  return route.replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'/+'), '/');
}

String symbolToString(Symbol symbol) {
  final str = symbol.toString();
  return str.substring(8, str.length - 2);
}

Future<void> launchUrl(String url) async {
  if (Platform.isLinux) {
    await Process.run('xdg-open', [url]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [url]);
  } else if (Platform.isWindows) {
    await Process.run('start', [url], runInShell: true);
  }
}
