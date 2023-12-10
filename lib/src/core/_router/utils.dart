String cleanRoute(String route) {
  return route.replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'/+'), '/');
}

String symbolToString(Symbol symbol) {
  final str = symbol.toString();
  return '#${str.substring(8, str.length - 1)}';
}
