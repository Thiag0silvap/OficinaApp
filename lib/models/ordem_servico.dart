import 'servico_item.dart';

enum OrdemStatus { orcamento, emAndamento, finalizada, entregue }

enum EtapaOS {
  avaliacao,
  orcamentoEnviado,
  aprovado,
  funilaria,
  preparacao,
  pintura,
  secagem,
  polimento,
  montagem,
  finalizado,
}

class OrdemServico {
  final String id;
  final String cliente;
  final String? telefone;
  final String? placa;
  final String? modeloVeiculo;
  final String? cor;

  final List<ServicoItem> itens;

  final double? valorPecas;
  final double? valorServicos;
  final double valorTotal;

  /// Observação que aparece para o cliente (PDF)
  final String? observacoesCliente;

  /// Observação interna da oficina
  final String? observacoesInternas;

  final DateTime dataCriacao;
  final DateTime? dataAprovacao;
  final DateTime? dataConclusao;

  /// Previsão de entrega do veículo
  final DateTime? dataPrevistaEntrega;

  /// Etapa atual do processo produtivo
  final EtapaOS etapaAtual;

  /// Caso esteja parado, por quê?
  final String? motivoPausa;

  final OrdemStatus status;

  OrdemServico({
    required this.id,
    required this.cliente,
    this.telefone,
    this.placa,
    this.modeloVeiculo,
    this.cor,
    this.itens = const [],
    this.valorPecas,
    this.valorServicos,
    double? valorTotal,
    this.observacoesCliente,
    this.observacoesInternas,
    DateTime? dataCriacao,
    this.dataAprovacao,
    this.dataConclusao,
    this.dataPrevistaEntrega,
    this.etapaAtual = EtapaOS.avaliacao,
    this.motivoPausa,
    this.status = OrdemStatus.orcamento,
  })  : valorTotal = valorTotal ?? 0.0,
        dataCriacao = dataCriacao ?? DateTime.now();

  OrdemServico copyWith({
    String? id,
    String? cliente,
    String? telefone,
    String? placa,
    String? modeloVeiculo,
    String? cor,
    List<ServicoItem>? itens,
    double? valorPecas,
    double? valorServicos,
    double? valorTotal,
    String? observacoesCliente,
    String? observacoesInternas,
    DateTime? dataCriacao,
    DateTime? dataAprovacao,
    DateTime? dataConclusao,
    DateTime? dataPrevistaEntrega,
    EtapaOS? etapaAtual,
    String? motivoPausa,
    OrdemStatus? status,
  }) {
    return OrdemServico(
      id: id ?? this.id,
      cliente: cliente ?? this.cliente,
      telefone: telefone ?? this.telefone,
      placa: placa ?? this.placa,
      modeloVeiculo: modeloVeiculo ?? this.modeloVeiculo,
      cor: cor ?? this.cor,
      itens: itens ?? this.itens,
      valorPecas: valorPecas ?? this.valorPecas,
      valorServicos: valorServicos ?? this.valorServicos,
      valorTotal: valorTotal ?? this.valorTotal,
      observacoesCliente: observacoesCliente ?? this.observacoesCliente,
      observacoesInternas: observacoesInternas ?? this.observacoesInternas,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAprovacao: dataAprovacao ?? this.dataAprovacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      dataPrevistaEntrega: dataPrevistaEntrega ?? this.dataPrevistaEntrega,
      etapaAtual: etapaAtual ?? this.etapaAtual,
      motivoPausa: motivoPausa ?? this.motivoPausa,
      status: status ?? this.status,
    );
  }

  factory OrdemServico.fromJson(Map<String, dynamic> json) {
    return OrdemServico(
      id: json['id'] as String? ?? '',
      cliente: json['cliente'] as String? ?? '',
      telefone: json['telefone'] as String?,
      placa: json['placa'] as String?,
      modeloVeiculo: json['modeloVeiculo'] as String?,
      cor: json['cor'] as String?,
      itens: (json['itens'] as List<dynamic>?)
              ?.map((e) => ServicoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      valorPecas: (json['valorPecas'] as num?)?.toDouble(),
      valorServicos: (json['valorServicos'] as num?)?.toDouble(),
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0.0,
      observacoesCliente: json['observacoesCliente'] as String?,
      observacoesInternas: json['observacoesInternas'] as String?,
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.parse(json['dataCriacao'])
          : DateTime.now(),
      dataAprovacao: json['dataAprovacao'] != null
          ? DateTime.parse(json['dataAprovacao'])
          : null,
      dataConclusao: json['dataConclusao'] != null
          ? DateTime.parse(json['dataConclusao'])
          : null,
      dataPrevistaEntrega: json['dataPrevistaEntrega'] != null
          ? DateTime.parse(json['dataPrevistaEntrega'])
          : null,
      etapaAtual: _etapaFromString(json['etapaAtual']),
      motivoPausa: json['motivoPausa'],
      status: _statusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': cliente,
        'telefone': telefone,
        'placa': placa,
        'modeloVeiculo': modeloVeiculo,
        'cor': cor,
        'itens': itens.map((e) => e.toJson()).toList(),
        'valorPecas': valorPecas,
        'valorServicos': valorServicos,
        'valorTotal': valorTotal,
        'observacoesCliente': observacoesCliente,
        'observacoesInternas': observacoesInternas,
        'dataCriacao': dataCriacao.toIso8601String(),
        'dataAprovacao': dataAprovacao?.toIso8601String(),
        'dataConclusao': dataConclusao?.toIso8601String(),
        'dataPrevistaEntrega': dataPrevistaEntrega?.toIso8601String(),
        'etapaAtual': etapaAtual.name,
        'motivoPausa': motivoPausa,
        'status': _statusToString(status),
      };

  static EtapaOS _etapaFromString(String? s) =>
      EtapaOS.values.firstWhere((e) => e.name == s,
          orElse: () => EtapaOS.avaliacao);

  static OrdemStatus _statusFromString(String? s) {
    switch (s) {
      case 'emAndamento':
        return OrdemStatus.emAndamento;
      case 'finalizada':
        return OrdemStatus.finalizada;
      case 'entregue':
        return OrdemStatus.entregue;
      default:
        return OrdemStatus.orcamento;
    }
  }

  static String _statusToString(OrdemStatus status) => status.name;
}
