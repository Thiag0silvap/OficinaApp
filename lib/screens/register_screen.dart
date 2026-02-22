import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberCredentials = true;

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
                constraints: const BoxConstraints(maxWidth: 480),
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
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Voltar',
                                    onPressed: _loading ? null : () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                  const Expanded(
                                    child: Center(
                                      child: SizedBox(height: 140, child: SplashLogo()),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Criar conta',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cadastre um usuário para acessar o sistema.',
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
                                autofillHints: const [AutofillHints.newUsername],
                                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Usuário',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Usuário é obrigatório'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: passwordController,
                                focusNode: _passwordFocus,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.newPassword],
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
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Senha é obrigatória' : null,
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
                                      : const Text('Criar conta'),
                                ),
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
    final err = await provider.register(
      name: nameController.text.trim(),
      password: passwordController.text,
      rememberCredentials: _rememberCredentials,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pop(context);
    }
  }
}
