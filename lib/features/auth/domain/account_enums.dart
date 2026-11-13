/// Server-side account completeness (`profiles.status`,
/// `common_get_my_context`): only an `active` account may use the app.
enum AccountStatus {
  incomplete,
  active,
  suspended,
  deleted,
  unknown;

  /// Forward-compatible: a state the installed build does not know yet stays
  /// `unknown` and never counts as complete.
  static AccountStatus fromJson(String? value) => switch (value) {
    'incomplete' => incomplete,
    'active' => active,
    'suspended' => suspended,
    'deleted' => deleted,
    _ => unknown,
  };
}

/// How the account can sign in (`auth.identities.provider`).
enum AuthProvider {
  email,
  google,
  apple;

  /// Unknown providers are ignored instead of failing the whole profile.
  static AuthProvider? fromJson(String value) => switch (value) {
    'email' => email,
    'google' => google,
    'apple' => apple,
    _ => null,
  };
}
