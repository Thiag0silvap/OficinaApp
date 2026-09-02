import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_logger.dart';

class FipeMarca {
  FipeMarca({required this.codigo, required this.nome});

  final String codigo;
  final String nome;
}

class FipeModelo {
  FipeModelo({required this.codigo, required this.nome});

  final String codigo;
  final String nome;
}

/// Cliente da API FIPE (https://fipe.parallelum.com.br/api/v2), usada como
/// fonte de marca/modelo de veículo. Segue o mesmo padrão de
/// UpdateService._fetchJson: dart:io HttpClient puro (sem dependência HTTP
/// nova), timeouts curtos, nunca lança exceção pra fora — qualquer falha
/// (sem internet, rate limit, erro de servidor) retorna null, e quem chama
/// decide o fallback.
class FipeService {
  // Token gratuito da FIPE (https://fipe.api.br/register) — OPCIONAL.
  // Sem token: limite de 500 requisições/dia (compartilhado por todo
  // dispositivo/uso anônimo). Com token gratuito: 1000/dia, mas esse limite
  // passa a ser compartilhado por TODOS os usuários do app que rodarem essa
  // mesma chave (o limite é por token, não por IP/dispositivo).
  // Preencher aqui antes de ir pra produção, se decidirem usar token —
  // deixar vazio funciona (só com o teto de 500/dia em vez de 1000/dia).
  static const String _subscriptionToken = '';

  static const String _baseUrl = 'https://fipe.parallelum.com.br/api/v2';

  static Future<List<FipeMarca>?> getMarcas({String tipo = 'cars'}) async {
    final data = await _fetchJsonList('$_baseUrl/$tipo/brands');
    if (data == null) return null;

    return data
        .whereType<Map>()
        .map(
          (e) => FipeMarca(
            codigo: (e['code'] ?? '').toString().trim(),
            nome: (e['name'] ?? '').toString().trim(),
          ),
        )
        .where((m) => m.codigo.isNotEmpty && m.nome.isNotEmpty)
        .toList();
  }

  static Future<List<FipeModelo>?> getModelos(
    String brandId, {
    String tipo = 'cars',
  }) async {
    final id = brandId.trim();
    if (id.isEmpty) return null;

    final data = await _fetchJsonList('$_baseUrl/$tipo/brands/$id/models');
    if (data == null) return null;

    return data
        .whereType<Map>()
        .map(
          (e) => FipeModelo(
            codigo: (e['code'] ?? '').toString().trim(),
            nome: (e['name'] ?? '').toString().trim(),
          ),
        )
        .where((m) => m.codigo.isNotEmpty && m.nome.isNotEmpty)
        .toList();
  }

  static Future<List<dynamic>?> _fetchJsonList(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (_subscriptionToken.isNotEmpty) {
        request.headers.set('X-Subscription-Token', _subscriptionToken);
      }

      final response =
          await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw const FormatException('Resposta FIPE inválida');
      }
      return decoded;
    } catch (e) {
      await AppLogger.instance.warning(
        'Falha ao consultar API FIPE ($url): $e',
      );
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
