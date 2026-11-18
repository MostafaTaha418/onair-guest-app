import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/auth/domain/password_rule.dart';

final class ChangePasswordState {
  const ChangePasswordState({
    this.current = '',
    this.next = '',
    this.confirm = '',
    this.submitting = false,
    this.done = false,
    this.currentError,
    this.error,
    this.rateLimitedUntil,
  });

  final String current;
  final String next;
  final String confirm;
  final bool submitting;
  final bool done;
  final ApiError? currentError;
  final ApiError? error;
  final DateTime? rateLimitedUntil;

  bool get newPasswordValid => PasswordRule.isValid(next) && next != current;
  bool get confirmValid => confirm == next && confirm.isNotEmpty;
  bool get canSubmit =>
      current.isNotEmpty && newPasswordValid && confirmValid && !submitting;

  ChangePasswordState copyWith({
    String? current,
    String? next,
    String? confirm,
    bool? submitting,
    bool? done,
    ApiError? currentError,
    ApiError? error,
    DateTime? rateLimitedUntil,
    bool clearErrors = false,
  }) => ChangePasswordState(
    current: current ?? this.current,
    next: next ?? this.next,
    confirm: confirm ?? this.confirm,
    submitting: submitting ?? this.submitting,
    done: done ?? this.done,
    currentError: currentError ?? (clearErrors ? null : this.currentError),
    error: error ?? (clearErrors ? null : this.error),
    rateLimitedUntil:
        rateLimitedUntil ?? (clearErrors ? null : this.rateLimitedUntil),
  );
}

final class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const ChangePasswordState());

  ChangePasswordCubit.seeded(
    this.repository,
    ChangePasswordState state, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(state);

  final AccountRepository repository;
  final DateTime Function() _now;

  void setCurrent(String value) => emit(
    state.copyWith(current: value, done: false, clearErrors: true),
  );
  void setNext(String value) => emit(
    state.copyWith(next: value, done: false, clearErrors: true),
  );
  void setConfirm(String value) => emit(
    state.copyWith(confirm: value, done: false, clearErrors: true),
  );

  Future<void> submit() async {
    final current = state;
    if (!current.canSubmit) return;
    emit(current.copyWith(submitting: true, clearErrors: true));
    try {
      await repository.changePassword(
        current: current.current,
        next: current.next,
      );
      if (!isClosed) emit(const ChangePasswordState(done: true));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      final error = failure.error;
      if (error.code == ErrorCode.passwordIncorrect) {
        emit(current.copyWith(currentError: error, clearErrors: true));
      } else if (error.code == ErrorCode.rateLimited) {
        final raw = error.details?['retry_at'];
        final parsed = raw == null
            ? null
            : DateTime.tryParse('$raw')?.toLocal();
        emit(
          current.copyWith(
            error: error,
            rateLimitedUntil:
                parsed ??
                _now().add(error.retryAfter ?? const Duration(minutes: 15)),
            clearErrors: true,
          ),
        );
      } else {
        emit(current.copyWith(error: error, clearErrors: true));
      }
    }
  }

  @override
  Future<void> close() {
    if (!isClosed) emit(const ChangePasswordState());
    return super.close();
  }
}
