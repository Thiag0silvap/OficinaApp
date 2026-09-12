import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/id_generator.dart';
import 'core/widgets/update_gate.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/empresa_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/supabase_client.dart';
import 'services/supabase_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://57a3d543d67783271471f88d3975123f@o4512053697773568.ingest.us.sentry.io/4512053720711168';
      options.tracesSampleRate = 1.0;
      options.environment = kReleaseMode ? 'production' : 'development';
    },
    appRunner: () async {
      await Supabase.initialize(
        url: 'https://gjuiniwuljlxfvzyepwy.supabase.co',
        publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqdWluaXd1bGpseGZ2enllcHd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxNzQ4NjQsImV4cCI6MjEwNDc1MDg2NH0.47xiDoEWA3A2tUh3hViXb1-kQFCZC77qncMfo36tN8Y',
        authOptions: FlutterAuthClientOptions(
          localStorage: SupabaseSecureLocalStorage(),
        ),
      );
      runApp(const MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),
        home: const WebNotSupportedScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AppProvider>(
          create: (_) => AppProvider()..initApp(),
          update: (_, auth, app) {
            app ??= AppProvider()..initApp();
            app.syncAuthUser(auth.currentUser);
            return app;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),
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
    if (!auth.isAuthenticated) return const LoginScreen();
    return OnboardingGate(
      key: ValueKey(auth.currentUser!.id),
      userId: auth.currentUser!.id,
      nome: auth.currentUser!.nome,
      convite: auth.currentUser!.convite,
    );
  }
}

/// Erro de negócio (código de convite inválido/expirado) — distinto de uma
/// falha genérica de rede/servidor, pra decidir a UI certa no FutureBuilder.
class _ConviteInvalidoException implements Exception {
  _ConviteInvalidoException(this.message);
  final String message;
}

/// Garante, para todo usuário autenticado, que existe uma oficina + perfil
/// em Supabase (cria na primeira vez que houver sessão, cobrindo tanto o
/// pós-cadastro imediato quanto o primeiro login após confirmação de
/// e-mail) e decide se falta completar o cadastro da empresa. Quando o
/// cadastro veio com um código de convite, aceita o convite (via RPC) em
/// vez de criar uma oficina nova.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.userId,
    required this.nome,
    this.convite,
  });

  final String userId;
  final String nome;
  final String? convite;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final Future<bool> _precisaEmpresaFuture = _ensureOnboarding();

  Future<bool> _ensureOnboarding() async {
    final client = SupabaseService.client;
    // Capturado antes de qualquer await: só chama métodos nele depois,
    // nunca usa `context` de novo — seguro entre os awaits que seguem.
    final authProvider = context.read<AuthProvider>();

    final perfil = await client
        .from('perfis')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();

    final String oficinaId;
    if (perfil == null) {
      final convite = widget.convite;
      if (convite != null && convite.isNotEmpty) {
        oficinaId = await _aceitarConvite(client, convite);
      } else {
        final novaOficinaId = gerarId();
        await client.from('oficinas').insert({
          'id': novaOficinaId,
          'nome': widget.nome,
        });

        await client.from('perfis').insert({
          'id': widget.userId,
          'oficina_id': novaOficinaId,
          'nome': widget.nome,
        });
        oficinaId = novaOficinaId;
      }
      // Perfil acabou de ser criado agora (fluxo normal ou RPC de
      // convite) — não temos o role em mãos, busca do banco.
      await authProvider.refreshRole();
    } else {
      oficinaId = perfil['oficina_id'] as String;
      // Já buscamos o perfil inteiro acima (inclui role) — evita um
      // round-trip extra só pra isso.
      authProvider.applyRole(perfil['role'] as String?);
    }

    final empresa = await client
        .from('empresa')
        .select()
        .eq('oficina_id', oficinaId)
        .maybeSingle();

    return empresa == null;
  }

  /// Chama a RPC aceitar_convite, que valida o código e cria o perfil
  /// vinculado à oficina do convite. Se o código for inválido/expirado,
  /// desloga o usuário (não faz sentido deixá-lo autenticado sem perfil
  /// nem oficina) e deixa uma mensagem pro LoginScreen mostrar.
  Future<String> _aceitarConvite(
    SupabaseClient client,
    String codigo,
  ) async {
    var mensagemErro = '';
    try {
      final resultado = await client.rpc(
        'aceitar_convite',
        params: {'p_codigo': codigo, 'p_nome': widget.nome},
      );
      return _extrairOficinaId(resultado);
    } on _ConviteInvalidoException catch (e) {
      mensagemErro = e.message;
    } on PostgrestException catch (e) {
      // RAISE EXCEPTION dentro de aceitar_convite (código inválido,
      // expirado, já usado etc.) chega aqui — mensagem vinda do banco.
      mensagemErro = e.message;
    }
    // Qualquer outra exceção (rede, timeout, etc.) não é problema de
    // convite — não é capturada aqui, propaga pro FutureBuilder mostrar o
    // erro genérico, sem sign-out: vale a pena o usuário tentar de novo.

    if (mounted) {
      context.read<AuthProvider>().setPendingNotice(mensagemErro);
    }
    await client.auth.signOut();
    throw _ConviteInvalidoException(mensagemErro);
  }

  /// A RPC pode ter sido declarada retornando o uuid direto (escalar), um
  /// objeto {oficina_id: ...} ou uma linha de tabela — aceita as três
  /// formas mais comuns em vez de travar numa suposição só.
  String _extrairOficinaId(dynamic resultado) {
    if (resultado is String) return resultado;
    if (resultado is Map) {
      final valor = resultado['oficina_id'] ?? resultado['id'];
      if (valor is String) return valor;
    }
    if (resultado is List && resultado.isNotEmpty) {
      final primeira = resultado.first;
      if (primeira is Map) {
        final valor = primeira['oficina_id'] ?? primeira['id'];
        if (valor is String) return valor;
      }
    }
    throw _ConviteInvalidoException(
      'Não foi possível validar o convite (resposta inesperada).',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _precisaEmpresaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          // Convite inválido: já deslogamos e deixamos um aviso pro
          // LoginScreen mostrar — o AuthWrapper troca pra lá assim que
          // isAuthenticated virar false, então aqui só evita piscar uma
          // tela de erro genérica enquanto isso acontece.
          if (snapshot.error is _ConviteInvalidoException) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar dados da sua conta: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return (snapshot.data ?? false)
            ? const EmpresaScreen(onboarding: true)
            : const HomeScreen();
      },
    );
  }
}
