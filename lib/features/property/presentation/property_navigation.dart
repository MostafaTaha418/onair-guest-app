import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Allows one property-details push per router until that page is dismissed.
/// Cards in retained tabs can receive nearly simultaneous pointer events.
final Expando<bool> _propertyOpen = Expando<bool>('propertyOpen');

void openPropertyDetails(
  BuildContext context,
  String location, {
  Object? extra,
}) {
  final router = GoRouter.of(context);
  if (_propertyOpen[router] == true) return;

  _propertyOpen[router] = true;
  var reachedDetails = false;
  var cleared = false;
  late VoidCallback onRouteChanged;
  void clear() {
    if (cleared) return;
    cleared = true;
    _propertyOpen[router] = false;
    router.routeInformationProvider.removeListener(onRouteChanged);
  }

  onRouteChanged = () {
    final path = router.routeInformationProvider.value.uri.path;
    if (path.startsWith('/property/')) {
      reachedDetails = true;
    } else if (reachedDetails) {
      // Auth uses go() to replace the details route, so the push Future may
      // never complete. Release the guard when the route actually leaves.
      clear();
    }
  };

  router.routeInformationProvider.addListener(onRouteChanged);
  try {
    unawaited(
      router.push<void>(location, extra: extra).whenComplete(clear),
    );
  } on Object {
    clear();
    rethrow;
  }
}
