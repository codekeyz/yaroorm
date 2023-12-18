import 'dart:async';

import 'package:yaroo/yaroo.dart';

import '../routes/api.dart' as api;
import '../routes/web.dart' as web;

class RouteServiceProvider extends ServiceProvider {
  /// The path to your application's "home" route.
  ///
  /// Typically, users are redirected here after authentication.
  static const home = '/home';

  @override
  FutureOr<void> boot() {
    app.useRoutes(
      () => [
        /*
    |--------------------------------------------------------------------------
    | API Routes
    |--------------------------------------------------------------------------
    */
        Route.group('api', middlewares: api.routes.middlewares)
            .routes(api.routes.reqHandlers),

        /*
    |--------------------------------------------------------------------------
    | Web Routes
    |--------------------------------------------------------------------------
    */

        Route.group('/', middlewares: web.routes.middlewares)
            .routes(web.routes.reqHandlers),
      ],
    );
  }
}
