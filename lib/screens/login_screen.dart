import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Prefill saved credentials if available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final creds = await provider.getSavedCredentials();
      if (creds != null) {
        nameController.text = creds['name'] ?? '';
        passwordController.text = creds['password'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: AppColors.secondaryGray,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login', style: TextStyle(fontSize: 20, color: AppColors.white)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome de usuário'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty) ? 'Senha é obrigatória' : null,
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const CircularProgressIndicator()
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Entrar'),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final err = await provider.login(name: nameController.text.trim(), password: passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pushReplacementNamed(context, '/home');
  }
}
