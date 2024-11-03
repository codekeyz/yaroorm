String symbolToString(Symbol symbol) {
  final symbolAsString = symbol.toString();
  return symbolAsString.substring(8, symbolAsString.length - 2);
}
