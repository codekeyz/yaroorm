import 'package:yaroo/yaroo.dart';

List<RouteDefinition> routes = [
  Route.func(HTTPMethod.GET, '/', (req, res) {
    return res.render('welcome', {'app_name': 'Yaroo', 'app_version': '1.0.0'});
  }),
];
