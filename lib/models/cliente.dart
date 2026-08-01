enum TipoCliente {
  particular,
  seguradora,
  oficinaParceira,
  frota;

  String get displayName {
    switch (this) {
      case TipoCliente.particular:
        return 'Cliente Particular';
      case TipoCliente.seguradora:
        return 'Seguradora';
      case TipoCliente.oficinaParceira:
        return 'Oficina Parceira';
      case TipoCliente.frota:
        return 'Frota Empresarial';
    }
  }
}

class Cliente {
  final String id;
  final String nome;
  final String telefone;
  final String? endereco;
  final DateTime dataCadastro;
  final String? observacoes;
  final TipoCliente tipo;
  final String? nomeSeguradora; // Para quando tipo for seguradora
  final String? cnpj;
  final String? contato; // Pessoa de contato na seguradora/empresa

  Cliente({
    required this.id,
    required this.nome,
    required this.telefone,
    this.endereco,
    required this.dataCadastro,
    this.observacoes,
    required this.tipo,
    this.nomeSeguradora,
    this.cnpj,
    this.contato,
  });

  Cliente copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? endereco,
    DateTime? dataCadastro,
    String? observacoes,
    TipoCliente? tipo,
    String? nomeSeguradora,
    String? cnpj,
    String? contato,
  }) {
    return Cliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      observacoes: observacoes ?? this.observacoes,
      tipo: tipo ?? this.tipo,
      nomeSeguradora: nomeSeguradora ?? this.nomeSeguradora,
      cnpj: cnpj ?? this.cnpj,
      contato: contato ?? this.contato,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'dataCadastro': dataCadastro.toIso8601String(),
      'observacoes': observacoes,
      'tipo': tipo.name,
      'nomeSeguradora': nomeSeguradora,
      'cnpj': cnpj,
      'contato': contato,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'],
      dataCadastro: DateTime.parse(map['dataCadastro']),
      observacoes: map['observacoes'],
      tipo: TipoCliente.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoCliente.particular,
      ),
      nomeSeguradora: map['nomeSeguradora'],
      cnpj: map['cnpj'],
      contato: map['contato'],
    );
  }

  // Getter para exibir o tipo de forma amigável
  String get tipoDescricao {
    switch (tipo) {
      case TipoCliente.particular:
        return 'Cliente Particular';
      case TipoCliente.seguradora:
        return nomeSeguradora ?? 'Seguradora';
      case TipoCliente.oficinaParceira:
        return 'Oficina Parceira';
      case TipoCliente.frota:
        return 'Frota';
    }
  }

  // Getter para identificar se é seguradora
  bool get isSeguradora => tipo == TipoCliente.seguradora;

  // Getter para nome completo (inclui seguradora quando aplicável)
  String get nomeCompleto {
    if (tipo == TipoCliente.seguradora && nomeSeguradora != null) {
      return '$nomeSeguradora - $nome';
    }
    return nome;
  }
}
