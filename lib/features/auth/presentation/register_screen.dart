import 'package:flutter/material.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';

final class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginScreen(registration: true);
}
