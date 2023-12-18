import 'dart:async';

import 'package:yaroo/yaroo.dart';

import '../services/service_a.dart';
import '../services/service_b.dart';

class CustomerServiceProvider extends ServiceProvider {
  CustomerServiceProvider();

  @override
  FutureOr<void> boot() {
    app
      ..singleton<UserService>(UserService())
      ..singleton<ServiceB>(ServiceB());
  }
}
