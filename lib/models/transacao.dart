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
  final double? valorOriginal;
  final DateTime? editadoEm;

  Transacao({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.categoria,
    required this.data,
    this.orcamentoId,
    this.observacoes,
    this.valorOriginal,
    this.editadoEm,
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
    double? valorOriginal,
    DateTime? editadoEm,
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
      valorOriginal: valorOriginal ?? this.valorOriginal,
      editadoEm: editadoEm ?? this.editadoEm,
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
      'valorOriginal': valorOriginal,
      'editadoEm': editadoEm?.toIso8601String(),
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    final rawTipo = map['tipo'];
    final tipoName = switch (rawTipo) {
      String value => value,
      int value when value == 1 => TipoTransacao.saida.name,
      int _ => TipoTransacao.entrada.name,
      _ => TipoTransacao.entrada.name,
    };

    return Transacao(
      id: map['id'] ?? '',
      tipo: TipoTransacao.values.firstWhere(
        (e) => e.name == tipoName,
        orElse: () => TipoTransacao.entrada,
      ),
      descricao: map['descricao'] ?? '',
      valor: _toDouble(map['valor']),
      categoria: map['categoria'] ?? '',
      data: DateTime.parse(map['data']),
      orcamentoId: map['orcamentoId'],
      observacoes: map['observacoes'],
      valorOriginal:
          map['valorOriginal'] != null ? _toDouble(map['valorOriginal']) : null,
      editadoEm: map['editadoEm'] != null
          ? DateTime.parse(map['editadoEm'])
          : null,
    );
  }
}
