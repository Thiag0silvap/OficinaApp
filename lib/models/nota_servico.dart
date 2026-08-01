import 'ordem_servico.dart';
import 'servico_item.dart';

class NotaServico {
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
  final String? observacoes;
  final DateTime dataEmissao;

  NotaServico({
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
    this.observacoes,
    DateTime? dataEmissao,
  })  : valorTotal = valorTotal ?? 0.0,
        dataEmissao = dataEmissao ?? DateTime.now();

  factory NotaServico.fromOrdem(OrdemServico ordem) {
    return NotaServico(
      id: ordem.id,
      cliente: ordem.cliente,
      telefone: ordem.telefone,
      placa: ordem.placa,
      modeloVeiculo: ordem.modeloVeiculo,
      cor: ordem.cor,
      itens: ordem.itens,
      valorPecas: ordem.valorPecas,
      valorServicos: ordem.valorServicos,
      valorTotal: ordem.valorTotal,
      observacoes: ordem.observacoesCliente,
      dataEmissao: ordem.dataConclusao ?? DateTime.now(),
    );
  }

  factory NotaServico.fromJson(Map<String, dynamic> json) {
    return NotaServico(
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
      observacoes: json['observacoes'] as String?,
      dataEmissao: json['dataEmissao'] != null
          ? DateTime.parse(json['dataEmissao'] as String)
          : DateTime.now(),
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
        'observacoes': observacoes,
        'dataEmissao': dataEmissao.toIso8601String(),
      };
}
