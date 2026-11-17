import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/presentation/security/change_password_cubit.dart';

class _Repository extends Fake implements AccountRepository {
  int calls = 0;
  AppFailure? failure;
  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    calls++;
    if (failure case final value?) throw value;
  }
}

void main() {
  test('requires rule, different password and matching confirmation', () {
    final cubit = ChangePasswordCubit(_Repository());
    addTearDown(cubit.close);
    cubit
      ..setCurrent('Passw0rd!')
      ..setNext('short')
      ..setConfirm('short');
    expect(cubit.state.canSubmit, isFalse);
    cubit
      ..setNext('Nextpass1')
      ..setConfirm('different1');
    expect(cubit.state.canSubmit, isFalse);
    cubit.setConfirm('Nextpass1');
    expect(cubit.state.canSubmit, isTrue);
  });

  test('incorrect current maps to the current field', () async {
    final repository = _Repository()
      ..failure = const AppFailure(
        ApiError(
          code: ErrorCode.passwordIncorrect,
          messageKey: 'accountPasswordIncorrect',
        ),
      );
    final cubit = ChangePasswordCubit(repository);
    addTearDown(cubit.close);
    cubit
      ..setCurrent('wrong')
      ..setNext('Nextpass1')
      ..setConfirm('Nextpass1');
    await cubit.submit();
    expect(cubit.state.currentError?.code, ErrorCode.passwordIncorrect);
  });

  test('rate limit has a deadline and success clears every field', () async {
    final repository = _Repository()
      ..failure = const AppFailure(
        ApiError(
          code: ErrorCode.rateLimited,
          messageKey: 'authRateLimited',
          details: {'retry_at': '2026-11-17T12:15:00Z'},
        ),
      );
    final cubit = ChangePasswordCubit(repository);
    addTearDown(cubit.close);
    cubit
      ..setCurrent('Passw0rd!')
      ..setNext('Nextpass1')
      ..setConfirm('Nextpass1');
    await cubit.submit();
    expect(cubit.state.rateLimitedUntil, isNotNull);
    repository.failure = null;
    await cubit.submit();
    expect(cubit.state.done, isTrue);
    expect(cubit.state.current, isEmpty);
    expect(cubit.state.next, isEmpty);
    expect(cubit.state.confirm, isEmpty);
  });
}
