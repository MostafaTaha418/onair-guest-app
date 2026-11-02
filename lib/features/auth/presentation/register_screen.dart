import 'package:flutter/material.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';

final class RegisterScreen extends StatelessWidget {
  const RegisterScreen({this.phoneAuthEnabled = true, super.key});

  final bool phoneAuthEnabled;

  @override
  Widget build(BuildContext context) => LoginScreen(
    registration: true,
    phoneAuthEnabled: phoneAuthEnabled,
  );
}
