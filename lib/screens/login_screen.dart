import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberCredentials = true;

  @override
  void initState() {
    super.initState();
    // Prefill saved credentials if available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final creds = await provider.getSavedCredentials();
      if (!mounted) return;
      if (creds != null) {
        nameController.text = creds['name'] ?? '';
        passwordController.text = creds['password'] ?? '';
        setState(() => _rememberCredentials = true);
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, Color(0xFF111111)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryYellow,
                                  Colors.transparent,
                                ],
                                radius: 1.2,
                                center: Alignment.topLeft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 140,
                                child: Center(child: SplashLogo()),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Acesse sua conta',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Use seu usuário e senha para entrar no sistema.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.white.withValues(alpha: 0.75)),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Usuário',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Usuário é obrigatório' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: passwordController,
                                focusNode: _passwordFocus,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                obscureText: _obscurePassword,
                                onFieldSubmitted: (_) => _submit(),
                                onEditingComplete: _submit,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Senha é obrigatória' : null,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberCredentials,
                                    onChanged: (v) =>
                                        setState(() => _rememberCredentials = v ?? true),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Lembrar credenciais neste computador',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Entrar'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    'Ainda não tem conta?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/register'),
                                    child: const Text('Criar conta'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

    FocusManager.instance.primaryFocus?.unfocus();

    final err = await provider.login(
      name: nameController.text.trim(),
      password: passwordController.text,
      rememberCredentials: _rememberCredentials,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pushReplacementNamed(context, '/home');
  }
}
