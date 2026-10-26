import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

final class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<Object> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
