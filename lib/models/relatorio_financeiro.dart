/// Presets de período do Relatório Financeiro.
enum PeriodoRelatorio { tresMeses, seisMeses, dozeMeses, anoAtual }

extension PeriodoRelatorioX on PeriodoRelatorio {
  String get label {
    switch (this) {
      case PeriodoRelatorio.tresMeses:
        return 'Últimos 3 meses';
      case PeriodoRelatorio.seisMeses:
        return 'Últimos 6 meses';
      case PeriodoRelatorio.dozeMeses:
        return 'Últimos 12 meses';
      case PeriodoRelatorio.anoAtual:
        return 'Ano atual';
    }
  }

  /// Intervalo (início, fim) do preset, ambos como dia 1 do respectivo mês.
  /// O fim é sempre o mês atual — nenhum preset inclui meses futuros.
  (DateTime, DateTime) intervalo() {
    final now = DateTime.now();
    final fim = DateTime(now.year, now.month, 1);
    switch (this) {
      case PeriodoRelatorio.tresMeses:
        return (DateTime(now.year, now.month - 2, 1), fim);
      case PeriodoRelatorio.seisMeses:
        return (DateTime(now.year, now.month - 5, 1), fim);
      case PeriodoRelatorio.dozeMeses:
        return (DateTime(now.year, now.month - 11, 1), fim);
      case PeriodoRelatorio.anoAtual:
        return (DateTime(now.year, 1, 1), fim);
    }
  }
}

/// Resumo de entradas/saídas de um mês (usado na tabela mensal e no gráfico).
class ResumoMensal {
  final DateTime mes;
  final double entradas;
  final double saidas;

  ResumoMensal({
    required this.mes,
    required this.entradas,
    required this.saidas,
  });

  double get saldo => entradas - saidas;
}

/// Resumo de entradas/saídas agregado por categoria (grafia normalizada).
class ResumoCategoria {
  final String categoria;
  final double entradas;
  final double saidas;

  ResumoCategoria({
    required this.categoria,
    required this.entradas,
    required this.saidas,
  });

  double get total => entradas + saidas;
}
