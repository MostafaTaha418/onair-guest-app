import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/domain/password_rule.dart';

void main() {
  group('PasswordRule', () {
    test('requires eight characters, one letter, and one digit', () {
      expect(PasswordRule.isValid('short1'), isFalse);
      expect(PasswordRule.isValid('12345678'), isFalse);
      expect(PasswordRule.isValid('abcdefgh'), isFalse);
      expect(PasswordRule.isValid('password1'), isTrue);
    });

    test('reports weak, medium, and strong strength levels', () {
      expect(PasswordRule.strengthOf('abc'), PasswordStrength.weak);
      expect(PasswordRule.strengthOf('password1'), PasswordStrength.medium);
      expect(
        PasswordRule.strengthOf('long-password-123'),
        PasswordStrength.strong,
      );
    });
  });
}
