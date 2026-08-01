class Veiculo {
  final String id;
  final String clienteId;
  final String marca;
  final String modelo;
  final String cor;
  final String placa;
  final int? ano;
  final String? observacoes;

  Veiculo({
    required this.id,
    required this.clienteId,
    required this.marca,
    required this.modelo,
    required this.cor,
    required this.placa,
    this.ano,
    this.observacoes,
  });

  Veiculo copyWith({
    String? id,
    String? clienteId,
    String? marca,
    String? modelo,
    String? cor,
    String? placa,
    int? ano,
    String? observacoes,
  }) {
    return Veiculo(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      cor: cor ?? this.cor,
      placa: placa ?? this.placa,
      ano: ano ?? this.ano,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  String get descricaoCompleta => '$marca $modelo - $cor ($placa)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'marca': marca,
      'modelo': modelo,
      'cor': cor,
      'placa': placa,
      'ano': ano,
      'observacoes': observacoes,
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      id: map['id'] ?? '',
      clienteId: map['clienteId'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      cor: map['cor'] ?? '',
      placa: map['placa'] ?? '',
      ano: map['ano'],
      observacoes: map['observacoes'],
    );
  }
}
