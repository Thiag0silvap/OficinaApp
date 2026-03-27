class Empresa {
  final String id;
  final String nome;
  final String telefone;
  final String endereco;
  final String? cnpj;

  Empresa({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
    this.cnpj,
  });

  Empresa copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? endereco,
    String? cnpj,
  }) {
    return Empresa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      cnpj: cnpj ?? this.cnpj,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'cnpj': cnpj,
    };
  }

  factory Empresa.fromMap(Map<String, dynamic> map) {
    return Empresa(
      id: map['id']?.toString() ?? 'empresa_principal',
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      cnpj: map['cnpj'],
    );
  }
}
