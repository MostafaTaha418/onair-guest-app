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
  try {
    unawaited(
      router.push<void>(location, extra: extra).whenComplete(() {
        _propertyOpen[router] = false;
      }),
    );
  } on Object {
    _propertyOpen[router] = false;
    rethrow;
  }
}
