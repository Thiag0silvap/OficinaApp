import 'dart:math';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/components/responsive_components.dart';
import '../core/theme/app_theme.dart';
import '../services/supabase_client.dart';

class ConvidarColaboradorScreen extends StatefulWidget {
  const ConvidarColaboradorScreen({super.key});

  @override
  State<ConvidarColaboradorScreen> createState() =>
      _ConvidarColaboradorScreenState();
}

class _ConvidarColaboradorScreenState
    extends State<ConvidarColaboradorScreen> {
  // Sem O/0, I/1/L — evita ambiguidade ao digitar o código de outro
  // aparelho.
  static const _caracteres = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const _tamanhoCodigo = 6;
  static const _maxTentativas = 3;
  static final _random = Random.secure();

  bool _carregandoOficina = true;
  bool _gerando = false;
  String? _oficinaId;
  String? _oficinaNome;
  String? _codigoGerado;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarOficina();
  }

  Future<void> _carregarOficina() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final perfil = await SupabaseService.client
            .from('perfis')
            .select()
            .eq('id', userId)
            .maybeSingle();
        final oficinaId = perfil?['oficina_id'] as String?;

        if (oficinaId != null) {
          final oficina = await SupabaseService.client
              .from('oficinas')
              .select()
              .eq('id', oficinaId)
              .maybeSingle();
          _oficinaId = oficinaId;
          _oficinaNome = oficina?['nome'] as String?;
        }
      }
    } catch (e) {
      _erro = 'Erro ao carregar dados da oficina: $e';
    } finally {
      if (mounted) setState(() => _carregandoOficina = false);
    }
  }

  String _gerarCodigo() {
    return List.generate(
      _tamanhoCodigo,
      (_) => _caracteres[_random.nextInt(_caracteres.length)],
    ).join();
  }

  Future<void> _gerarConvite() async {
    final oficinaId = _oficinaId;
    if (oficinaId == null) return;

    setState(() {
      _gerando = true;
      _erro = null;
    });

    try {
      String? codigoCriado;
      for (var tentativa = 0; tentativa < _maxTentativas; tentativa++) {
        final codigo = _gerarCodigo();
        try {
          await SupabaseService.client.from('convites').insert({
            'oficina_id': oficinaId,
            'codigo': codigo,
            'expira_em': DateTime.now()
                .toUtc()
                .add(const Duration(hours: 24))
                .toIso8601String(),
          });
          codigoCriado = codigo;
          break;
        } on PostgrestException catch (e) {
          // 23505 = unique_violation no Postgres (código já existe em uso).
          final isUltimaTentativa = tentativa == _maxTentativas - 1;
          if (e.code != '23505' || isUltimaTentativa) rethrow;
        }
      }

      if (!mounted) return;
      if (codigoCriado == null) {
        setState(
          () => _erro =
              'Não foi possível gerar um código único. Tente novamente.',
        );
      } else {
        setState(() => _codigoGerado = codigoCriado);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Erro ao gerar convite: $e');
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _compartilhar() async {
    final codigo = _codigoGerado;
    if (codigo == null) return;
    final nomeOficina = _oficinaNome?.trim();
    final referenciaOficina = (nomeOficina == null || nomeOficina.isEmpty)
        ? 'nossa oficina'
        : nomeOficina;

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Você foi convidado para a oficina $referenciaOficina. '
            'Use o código $codigo ao criar sua conta no app. Válido por 24h.',
        subject: 'Convite OficinaApp',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convidar Colaborador'),
        centerTitle: true,
      ),
      body: ResponsiveContainer(
        child: _carregandoOficina
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 700 : 520,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Convide um colaborador',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Gere um código de uso único, válido por 24 '
                              'horas, para alguém criar uma conta vinculada '
                              'à sua oficina.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_erro != null) ...[
                            Text(
                              _erro!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_codigoGerado == null)
                            ElevatedButton(
                              onPressed: (_gerando || _oficinaId == null)
                                  ? null
                                  : _gerarConvite,
                              child: _gerando
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Gerar código de convite'),
                            )
                          else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _codigoGerado!,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Válido por 24 horas.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _gerando ? null : _gerarConvite,
                                    child: const Text('Gerar novo código'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _compartilhar,
                                    icon: const Icon(Icons.share),
                                    label: const Text('Compartilhar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
