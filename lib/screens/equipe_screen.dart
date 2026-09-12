import 'package:flutter/material.dart';

import '../core/components/responsive_components.dart';
import '../core/theme/app_theme.dart';
import '../services/supabase_client.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key});

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  bool _loading = true;
  String? _erro;
  List<Map<String, dynamic>> _perfis = [];

  @override
  void initState() {
    super.initState();
    _carregarEquipe();
  }

  Future<void> _carregarEquipe() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final perfilAtual = await SupabaseService.client
            .from('perfis')
            .select()
            .eq('id', userId)
            .maybeSingle();
        final oficinaId = perfilAtual?['oficina_id'] as String?;

        if (oficinaId != null) {
          final resultado = await SupabaseService.client
              .from('perfis')
              .select()
              .eq('oficina_id', oficinaId);

          final lista = List<Map<String, dynamic>>.from(resultado as List);
          lista.sort((a, b) {
            final roleA = (a['role'] as String?) ?? 'colaborador';
            final roleB = (b['role'] as String?) ?? 'colaborador';
            if (roleA != roleB) return roleA == 'admin' ? -1 : 1;

            final nomeA = ((a['nome'] as String?) ?? '').toLowerCase();
            final nomeB = ((b['nome'] as String?) ?? '').toLowerCase();
            return nomeA.compareTo(nomeB);
          });

          _perfis = lista;
        }
      }
    } catch (e) {
      _erro = 'Erro ao carregar a equipe: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipe'), centerTitle: true),
      body: ResponsiveContainer(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_erro!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_perfis.isEmpty) {
      return const Center(child: Text('Nenhum integrante encontrado.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _perfis.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final perfil = _perfis[index];
        final nome = (perfil['nome'] as String?)?.trim();
        final nomeExibido = (nome == null || nome.isEmpty)
            ? '(sem nome)'
            : nome;
        final isAdmin = (perfil['role'] as String?) == 'admin';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryYellow,
              child: Text(
                nomeExibido.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(nomeExibido),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppColors.primaryYellow.withValues(alpha: 0.15)
                    : AppColors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'Colaborador',
                style: TextStyle(
                  color: isAdmin
                      ? AppColors.primaryYellow
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
