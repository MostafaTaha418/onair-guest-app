import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/application/personal_data_resetter.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

enum SessionEndEvent { refreshFailed, signedOutByServer }

abstract interface class SessionEventSource {
  Stream<SessionEndEvent> get events;
}

final class NoopSessionEventSource implements SessionEventSource {
  const NoopSessionEventSource();

  @override
  Stream<SessionEndEvent> get events => const Stream.empty();
}

final class SupabaseSessionEventSource implements SessionEventSource {
  SupabaseSessionEventSource(supa.GoTrueClient auth) {
    _subscription = auth.onAuthStateChange.listen(
      (state) {
        if (state.event != supa.AuthChangeEvent.signedOut) return;
        switch (state.signOutReason) {
          case supa.SignOutReason.userInitiated:
            return;
          case supa.SignOutReason.sessionExpired:
            _controller.add(SessionEndEvent.refreshFailed);
          case supa.SignOutReason.sessionMissing:
          case null:
            _controller.add(SessionEndEvent.signedOutByServer);
        }
      },
      onError: (Object _, StackTrace _) {
        _controller.add(SessionEndEvent.refreshFailed);
      },
    );
  }

  final _controller = StreamController<SessionEndEvent>.broadcast();
  late final StreamSubscription<supa.AuthState> _subscription;

  @override
  Stream<SessionEndEvent> get events => _controller.stream;

  Future<void> close() async {
    await _subscription.cancel();
    await _controller.close();
  }
}

final class SessionListener extends StatefulWidget {
  const SessionListener({
    required this.router,
    required this.eventSource,
    required this.personalDataResetter,
    required this.child,
    this.deviceRegistrationService,
    super.key,
  });

  final GoRouter router;
  final SessionEventSource eventSource;
  final PersonalDataResetter personalDataResetter;
  final DeviceRegistrationService? deviceRegistrationService;
  final Widget child;

  @override
  State<SessionListener> createState() => _SessionListenerState();
}

final class _SessionListenerState extends State<SessionListener> {
  late final StreamSubscription<SessionEndEvent> _subscription;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    _subscription = widget.eventSource.events.listen((_) {
      if (cubit.state is SignedIn) {
        cubit.sessionEnded(widget.router.state.uri.toString());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        current is SessionEnded ||
        (previous is SigningOut && current is SignedOut) ||
        (current is SignedIn && previous is! SignedIn),
    listener: (context, state) async {
      if (state is SignedIn) {
        try {
          await widget.deviceRegistrationService?.registerAfterSignIn();
        } on Object {
          // Best effort: retried on the next sign-in or token refresh.
        }
        return;
      }
      await widget.personalDataResetter.resetPersonalData();
      if (!context.mounted || state is! SessionEnded) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorUnauthenticated),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<AuthCubit>().acknowledgeSessionEnded();
        }
      });
    },
    child: widget.child,
  );
}
