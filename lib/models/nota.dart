import 'orcamento.dart';

class Nota {
  final String id;
  final String? orcamentoId;
  final String? clienteId;
  final String clienteNome;
  final String? veiculoId;
  final String? veiculoDescricao;
  final List<ItemOrcamento> itens;
  final double valorTotal;
  final DateTime dataEmissao;

  Nota({
    required this.id,
    this.orcamentoId,
    this.clienteId,
    required this.clienteNome,
    this.veiculoId,
    this.veiculoDescricao,
    this.itens = const [],
    required this.valorTotal,
    DateTime? dataEmissao,
  }) : dataEmissao = dataEmissao ?? DateTime.now();

  factory Nota.fromOrcamento(OrcamentoModel o) => Nota(
        id: o.id,
        orcamentoId: o.id,
        clienteId: o.clienteId,
        clienteNome: o.clienteNome,
        veiculoId: o.veiculoId,
        veiculoDescricao: o.veiculoDescricao,
        itens: o.itens,
        valorTotal: o.valorTotal,
        dataEmissao: o.dataConclusao ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'orcamentoId': orcamentoId,
        'clienteId': clienteId,
        'clienteNome': clienteNome,
        'veiculoId': veiculoId,
        'veiculoDescricao': veiculoDescricao,
        'itens': itens.map((i) => i.toMap()).toList(),
        'valorTotal': valorTotal,
        'dataEmissao': dataEmissao.toIso8601String(),
      };

  factory Nota.fromMap(Map<String, dynamic> m) => Nota(
        id: m['id'] ?? '',
        orcamentoId: m['orcamentoId'],
        clienteId: m['clienteId'],
        clienteNome: m['clienteNome'] ?? '',
        veiculoId: m['veiculoId'],
        veiculoDescricao: m['veiculoDescricao'],
        itens: (m['itens'] as List<dynamic>? ?? []).map((e) => ItemOrcamento.fromMap(Map<String, dynamic>.from(e))).toList(),
        valorTotal: (m['valorTotal'] ?? 0).toDouble(),
        dataEmissao: m['dataEmissao'] != null ? DateTime.parse(m['dataEmissao']) : DateTime.now(),
      );
}
