import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show OnboardingGate;
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return const LoginScreen();
    return OnboardingGate(
      key: ValueKey(auth.currentUser!.id),
      userId: auth.currentUser!.id,
      nome: auth.currentUser!.nome,
      convite: auth.currentUser!.convite,
    );
  }
}
