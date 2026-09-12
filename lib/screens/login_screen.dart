import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/components/app_buttons.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_feedback.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    // Mensagem deixada por um logout forçado (ex.: código de convite
    // inválido/expirado no OnboardingGate) — o widget que detectou o erro
    // já foi desmontado a essa altura, então a mensagem viaja pelo
    // AuthProvider em vez de um SnackBar direto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notice = context.read<AuthProvider>().consumePendingNotice();
      if (notice != null) {
        AppFeedback.showError(context, notice);
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: AppText.display,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'E-mail e obrigatorio';
                            if (!_emailRegex.hasMatch(value)) {
                              return 'Informe um e-mail valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                              tooltip: _obscurePassword
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            final value = v ?? '';
                            if (value.isEmpty) return 'Senha e obrigatoria';
                            if (value.length < 6) {
                              return 'Senha deve ter ao menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _loading
                            ? const SizedBox(
                                height: 48,
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : PrimaryButton(
                                label: 'Entrar',
                                onPressed: _submit,
                                expanded: true,
                              ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : _esqueciSenha,
                            child: Text(
                              'Esqueci minha senha',
                              style: AppText.bodySecondary,
                            ),
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          children: [
                            Text(
                              'Ainda nao tem conta?',
                              style: AppText.bodySecondary,
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/register'),
                              child: const Text('Criar conta'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      email: emailController.text.trim(),
      password: passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      AppFeedback.showError(context, err);
      return;
    }
    // Volta pra '/' (AuthWrapper) em vez de ir direto pra '/home': o
    // OnboardingGate precisa rodar em todo login pra decidir entre
    // EmpresaScreen (onboarding pendente) e o dashboard.
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _esqueciSenha() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      AppFeedback.showError(
        context,
        'Informe seu e-mail no campo acima para receber as instrucoes.',
      );
      return;
    }

    setState(() => _loading = true);
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final err = await provider.resetPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      AppFeedback.showError(context, err);
      return;
    }
    AppFeedback.showSuccess(
      context,
      'Enviamos um e-mail com instrucoes para redefinir sua senha.',
    );
  }
}
