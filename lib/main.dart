import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/widgets/update_gate.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const WebNotSupportedScreen(),
      );
    }

    return MultiProvider(
      providers: [
        // ✅ importante: init() é async, mas pode ser chamado assim mesmo
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (_) => const UpdateGate(child: AuthWrapper()),
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
        },
      ),
    );
  }
}

class WebNotSupportedScreen extends StatelessWidget {
  const WebNotSupportedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plataforma não suportada'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este app usa banco local (SQLite) e recursos de arquivos (dart:io).\n'
            'Nesta versão, o Flutter Web não é suportado.\n\n'
            'Use Android/iOS/Windows/Linux/macOS para rodar o sistema.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
