import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';

/// Short link resolver: `/damage-claims/:claimId` looks the claim up and
/// replaces itself with the in-booking claim route.
final class DamageClaimResolverScreen extends StatefulWidget {
  const DamageClaimResolverScreen({required this.claimId, super.key});

  final String claimId;

  @override
  State<DamageClaimResolverScreen> createState() =>
      _DamageClaimResolverScreenState();
}

final class _DamageClaimResolverScreenState
    extends State<DamageClaimResolverScreen> {
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    try {
      final claim = await context.read<StayRepository>().getDamageClaim(
        widget.claimId,
      );
      if (!mounted) return;
      context.replace(AppRoutes.damageClaim(claim.bookingId, claim.id));
    } on AppFailure {
      if (!mounted) return;
      setState(() => _missing = true);
    }
  }

  @override
  Widget build(BuildContext context) => _missing
      ? const NotAvailableScreen()
      : const Scaffold(body: Center(child: CircularProgressIndicator()));
}
