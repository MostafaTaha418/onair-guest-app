import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

sealed class DeletionState {
  const DeletionState();
}

/// The explanation step (FR-017): the three bullets and the finality
/// checkbox; «احذف حسابي» arms the request.
final class DeletionExplain extends DeletionState {
  const DeletionExplain({this.understood = false, this.error});

  final bool understood;
  final ApiError? error;

  DeletionExplain copyWith({bool? understood, ApiError? error}) =>
      DeletionExplain(
        understood: understood ?? this.understood,
        error: error ?? this.error,
      );
}

final class DeletionChecking extends DeletionState {
  const DeletionChecking();
}

/// The server refused (data-model §6): the reasons with their links.
final class DeletionBlocked extends DeletionState {
  const DeletionBlocked(this.blockers);

  final List<DeletionBlocker> blockers;
}

/// The email-code step (contracts U5): the masked destination, the server's
/// send window for the resend countdown, and the typed code.
final class DeletionCodeStep extends DeletionState {
  const DeletionCodeStep({
    required this.challengeId,
    required this.maskedEmail,
    required this.window,
    this.code = '',
    this.verifying = false,
    this.resending = false,
    this.error,
  });

  final String challengeId;
  final String maskedEmail;
  final SendWindow window;
  final String code;
  final bool verifying;
  final bool resending;
  final ApiError? error;

  bool get canConfirm => !verifying && code.length == 6;

  DeletionCodeStep copyWith({
    SendWindow? window,
    String? code,
    bool? verifying,
    bool? resending,
    ApiError? error,
    bool clearError = false,
  }) => DeletionCodeStep(
    challengeId: challengeId,
    maskedEmail: maskedEmail,
    window: window ?? this.window,
    code: code ?? this.code,
    verifying: verifying ?? this.verifying,
    resending: resending ?? this.resending,
    error: clearError ? null : error ?? this.error,
  );
}

final class DeletionDeleted extends DeletionState {
  const DeletionDeleted();
}

/// US4: explanation → server blocker check → email code → immediate
/// deletion → visitor home (data-model §6). The sign-out goes through
/// `AuthCubit.signOut`, which runs the app's SignOutCoordinator — the
/// SignOutService — exactly once, and lands on `SignedOut` even when the
/// server cleanup itself fails.
final class DeleteAccountCubit extends Cubit<DeletionState> {
  DeleteAccountCubit({required this.repository, required this.auth})
    : super(const DeletionExplain());

  /// Starts from a fully formed state; goldens and previews only.
  DeleteAccountCubit.seeded({
    required this.repository,
    required this.auth,
    required DeletionState state,
  }) : super(state);

  final AccountRepository repository;
  final AuthCubit auth;

  /// Guards the request chain («احذف حسابي» is one intent: request + send).
  bool _arming = false;

  void setUnderstood({required bool value}) {
    final current = state;
    if (current is DeletionExplain && current.understood != value) {
      emit(current.copyWith(understood: value));
    }
  }

  /// «احذف حسابي»: request → blockers | send → code step. A second tap
  /// while the chain is running is one tap too many (T065).
  Future<void> start() async {
    final current = state;
    if (current is! DeletionExplain ||
        !current.understood ||
        _arming ||
        isClosed) {
      return;
    }
    _arming = true;
    emit(const DeletionChecking());
    try {
      final request = await repository.requestDeletion();
      final window = await repository.sendDeletionCode(request.challengeId);
      if (!isClosed) {
        emit(
          DeletionCodeStep(
            challengeId: request.challengeId,
            maskedEmail: request.maskedEmail,
            window: window,
          ),
        );
      }
    } on DeletionBlockedException catch (exception) {
      if (!isClosed) emit(DeletionBlocked(exception.blockers));
    } on AppFailure catch (failure) {
      // The checkbox choice survives a failed attempt.
      if (!isClosed) emit(current.copyWith(error: failure.error));
    } finally {
      _arming = false;
    }
  }

  Future<void> resend() async {
    final current = state;
    if (current is! DeletionCodeStep ||
        current.resending ||
        current.verifying ||
        isClosed) {
      return;
    }
    emit(current.copyWith(resending: true, clearError: true));
    try {
      final window = await repository.sendDeletionCode(current.challengeId);
      if (!isClosed) {
        emit(
          current.copyWith(
            window: window,
            code: '',
            resending: false,
            clearError: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(current.copyWith(resending: false, error: failure.error));
      }
    }
  }

  void updateCode(String value) {
    final current = state;
    if (current is DeletionCodeStep && !current.verifying) {
      emit(current.copyWith(code: value, clearError: true));
    }
  }

  Future<void> confirm() async {
    final current = state;
    if (current is! DeletionCodeStep || !current.canConfirm) return;
    emit(current.copyWith(verifying: true, clearError: true));
    try {
      await repository.confirmDeletion(current.challengeId, current.code);
      // The account is gone server-side; the app-side session must go even
      // if the coordinator fails (AuthCubit always lands on SignedOut) —
      // its rethrown error never traps the flow (T065).
      try {
        await auth.signOut();
      } on Object {
        // Still deleted: keep going to the visitor home.
      }
      if (!isClosed) emit(const DeletionDeleted());
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          current.copyWith(verifying: false, error: failure.error, code: ''),
        );
      }
    }
  }
}
