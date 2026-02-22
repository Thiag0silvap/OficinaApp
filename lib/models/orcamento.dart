// Modelos de Orçamento

class ItemOrcamento {
  final String servico;
  final String descricao;
  final double valor;

  ItemOrcamento({
    required this.servico,
    required this.descricao,
    required this.valor,
  });

  Map<String, dynamic> toMap() => {
        'servico': servico,
        'descricao': descricao,
        'valor': valor,
      };

  factory ItemOrcamento.fromMap(Map<String, dynamic> m) => ItemOrcamento(
        servico: m['servico'] ?? '',
        descricao: m['descricao'] ?? '',
        valor: (m['valor'] ?? 0).toDouble(),
      );
}

enum OrcamentoStatus {
  pendente,
  aprovado,
  emAndamento,
  concluido,
  cancelado,
}
enum TipoAtendimento { particular, seguro }

extension OrcamentoStatusExtension on OrcamentoStatus {
  String get displayName {
    switch (this) {
      case OrcamentoStatus.pendente:
        return 'Pendente';
      case OrcamentoStatus.aprovado:
        return 'Aprovado';
      case OrcamentoStatus.emAndamento:
        return 'Em andamento';
      case OrcamentoStatus.concluido:
        return 'Concluído';
      case OrcamentoStatus.cancelado:
        return 'Cancelado';
    }
  }
}

class OrcamentoModel {
  final String id;
  final String clienteId;
  final String clienteNome;
  final String veiculoId;
  final String veiculoDescricao;
  final List<ItemOrcamento> itens;
  final double valorTotal;
  final OrcamentoStatus status;
  final DateTime dataCriacao;
  final DateTime? dataAprovacao;
  final DateTime? dataConclusao;

  /// 👇 NOVO — CONTROLE FINANCEIRO
  final bool pago;
  final DateTime? dataPagamento;

  final String? observacoes;
  /// Vai aparecer no PDF
  final String? observacoesCliente;

  /// Só a oficina vê
  final String? observacoesInternas;

  /// Prazo prometido ao cliente
  final DateTime? dataPrevistaEntrega;

  final TipoAtendimento tipoAtendimento;

  OrcamentoModel({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.veiculoId,
    required this.veiculoDescricao,
    required this.itens,
    required this.valorTotal,
    required this.status,
    required this.dataCriacao,
    this.dataAprovacao,
    this.dataConclusao,
    this.pago = false,                // 👈 padrão: não pago
    this.dataPagamento,
    this.observacoes,
    this.observacoesCliente,
    this.observacoesInternas,
    this.dataPrevistaEntrega,
    this.tipoAtendimento = TipoAtendimento.particular,
  });

  String get statusDescricao => status.displayName;

  OrcamentoModel copyWith({
    String? id,
    String? clienteId,
    String? clienteNome,
    String? veiculoId,
    String? veiculoDescricao,
    List<ItemOrcamento>? itens,
    double? valorTotal,
    OrcamentoStatus? status,
    DateTime? dataCriacao,
    DateTime? dataAprovacao,
    DateTime? dataConclusao,
    bool? pago,
    DateTime? dataPagamento,
    String? observacoes,
    String? observacoesCliente,
    String? observacoesInternas,
    DateTime? dataPrevistaEntrega,
    TipoAtendimento? tipoAtendimento,
  }) {
    return OrcamentoModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      veiculoId: veiculoId ?? this.veiculoId,
      veiculoDescricao: veiculoDescricao ?? this.veiculoDescricao,
      itens: itens ?? this.itens,
      valorTotal: valorTotal ?? this.valorTotal,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAprovacao: dataAprovacao ?? this.dataAprovacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      pago: pago ?? this.pago,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      observacoes: observacoes ?? this.observacoes,
      observacoesCliente: observacoesCliente ?? this.observacoesCliente,
      observacoesInternas: observacoesInternas ?? this.observacoesInternas,
      dataPrevistaEntrega: dataPrevistaEntrega ?? this.dataPrevistaEntrega,
      tipoAtendimento: tipoAtendimento ?? this.tipoAtendimento,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'clienteId': clienteId,
        'clienteNome': clienteNome,
        'veiculoId': veiculoId,
        'veiculoDescricao': veiculoDescricao,
        'itens': itens.map((i) => i.toMap()).toList(),
        'valorTotal': valorTotal,
        'status': status.name,
        'dataCriacao': dataCriacao.toIso8601String(),
        'dataAprovacao': dataAprovacao?.toIso8601String(),
        'dataConclusao': dataConclusao?.toIso8601String(),
        'pago': pago ? 1 : 0,
        'dataPagamento': dataPagamento?.toIso8601String(),
        'observacoes': observacoes,
        'observacoesCliente': observacoesCliente,
        'observacoesInternas': observacoesInternas,
        'dataPrevistaEntrega': dataPrevistaEntrega?.toIso8601String(),
        'tipoAtendimento': tipoAtendimento.name,
      };

  factory OrcamentoModel.fromMap(Map<String, dynamic> m) => OrcamentoModel(
        id: m['id'] ?? '',
        clienteId: m['clienteId'] ?? '',
        clienteNome: m['clienteNome'] ?? '',
        veiculoId: m['veiculoId'] ?? '',
        veiculoDescricao: m['veiculoDescricao'] ?? '',
        itens: (m['itens'] as List<dynamic>? ?? [])
            .map((e) => ItemOrcamento.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        valorTotal: (m['valorTotal'] ?? 0).toDouble(),
        status: OrcamentoStatus.values.firstWhere(
          (s) => s.name == (m['status'] ?? 'pendente'),
          orElse: () => OrcamentoStatus.pendente,
        ),
        dataCriacao: DateTime.parse(
            m['dataCriacao'] ?? DateTime.now().toIso8601String()),
        dataAprovacao: m['dataAprovacao'] != null
            ? DateTime.parse(m['dataAprovacao'])
            : null,
        dataConclusao: m['dataConclusao'] != null
          ? DateTime.parse(m['dataConclusao'])
          : null,
        pago: (m['pago'] ?? 0) == 1,
        dataPagamento: m['dataPagamento'] != null
            ? DateTime.parse(m['dataPagamento'])
            : null,
        observacoes: m['observacoes'],
        observacoesCliente: m['observacoesCliente'],
        observacoesInternas: m['observacoesInternas'],
        dataPrevistaEntrega: m['dataPrevistaEntrega'] != null
            ? DateTime.parse(m['dataPrevistaEntrega'])
            : null,
        tipoAtendimento: TipoAtendimento.values.firstWhere(
          (t) => t.name == (m['tipoAtendimento'] ?? 'particular'),
          orElse: () => TipoAtendimento.particular,
        ),
      );
}

// Compatibilidade
typedef Orcamento = OrcamentoModel;
