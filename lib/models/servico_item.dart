class ServicoItem {
  final int quantidade;
  final String descricao;
  final double? valorUnitario;
  final double? valorTotal;

  ServicoItem({
    required this.quantidade,
    required this.descricao,
    this.valorUnitario,
    this.valorTotal,
  });

  ServicoItem copyWith({
    int? quantidade,
    String? descricao,
    double? valorUnitario,
    double? valorTotal,
  }) {
    return ServicoItem(
      quantidade: quantidade ?? this.quantidade,
      descricao: descricao ?? this.descricao,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }

  factory ServicoItem.fromJson(Map<String, dynamic> json) => ServicoItem(
        quantidade: json['quantidade'] as int? ?? 0,
        descricao: json['descricao'] as String? ?? '',
        valorUnitario: (json['valorUnitario'] as num?)?.toDouble(),
        valorTotal: (json['valorTotal'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'quantidade': quantidade,
        'descricao': descricao,
        'valorUnitario': valorUnitario,
        'valorTotal': valorTotal,
      };
}
