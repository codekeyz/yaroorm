import 'package:yaroo/http/http.dart';

abstract class Kernel {
  Kernel();

  /// The application's global HTTP middleware stack.
  ///
  /// These middleware are run during every request to your application.
  /// Types here must extends [Middleware].
  final List<Type> middleware = [];

  /// The application's route middleware groups.
  ///
  /// Types here must extends [Middleware].
  final Map<String, List<Type>> middlewareGroups = {};
}
