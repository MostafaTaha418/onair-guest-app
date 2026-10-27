enum PasswordStrength { weak, medium, strong }

abstract final class PasswordRule {
  static final _letter = RegExp('[A-Za-z]');
  static final _digit = RegExp(r'\d');

  static bool isValid(String value) =>
      value.length >= 8 && _letter.hasMatch(value) && _digit.hasMatch(value);

  static PasswordStrength strengthOf(String value) {
    if (!isValid(value)) return PasswordStrength.weak;
    return value.length >= 12
        ? PasswordStrength.strong
        : PasswordStrength.medium;
  }
}
