import 'package:yaroo/http/http.dart';

abstract class Kernel {
  Kernel();

  /// The application's global HTTP middleware stack.
  ///
  /// These middleware are run during every request to your application.
  final List<Middleware> middleware = [];

  /// The application's route middleware groups.
  final Map<String, List<Middleware>> middlewareGroups = {};

  /// The application's middleware aliases.
  ///
  /// Aliases may be used instead of class names to conveniently assign middleware to routes and groups.
  final Map<String, List<Middleware>> middlewareAliases = {};
}
