import 'package:pharaoh/pharaoh.dart' show Middleware;

export 'package:pharaoh/pharaoh.dart' hide Middleware, Body;

typedef HandlerFunc = Middleware;
