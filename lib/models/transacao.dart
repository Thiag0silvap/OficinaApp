enum TipoTransacao { entrada, saida }

class Transacao {
  final String id;
  final TipoTransacao tipo;
  final String descricao;
  final double valor;
  final String categoria;
  final DateTime data;
  final String? orcamentoId;
  final String? observacoes;

  Transacao({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.categoria,
    required this.data,
    this.orcamentoId,
    this.observacoes,
  });

  Transacao copyWith({
    String? id,
    TipoTransacao? tipo,
    String? descricao,
    double? valor,
    String? categoria,
    DateTime? data,
    String? orcamentoId,
    String? observacoes,
  }) {
    return Transacao(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      orcamentoId: orcamentoId ?? this.orcamentoId,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'descricao': descricao,
      'valor': valor,
      'categoria': categoria,
      'data': data.toIso8601String(),
      'orcamentoId': orcamentoId,
      'observacoes': observacoes,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'] ?? '',
      tipo: TipoTransacao.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoTransacao.entrada,
      ),
      descricao: map['descricao'] ?? '',
      valor: _toDouble(map['valor']),
      categoria: map['categoria'] ?? '',
      data: DateTime.parse(map['data']),
      orcamentoId: map['orcamentoId'],
      observacoes: map['observacoes'],
    );
  }
}
