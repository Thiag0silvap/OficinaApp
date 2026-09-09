import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/relatorio_financeiro.dart';

void main() {
  test('label retorna o texto esperado para os 4 presets', () {
    expect(PeriodoRelatorio.tresMeses.label, 'Últimos 3 meses');
    expect(PeriodoRelatorio.seisMeses.label, 'Últimos 6 meses');
    expect(PeriodoRelatorio.dozeMeses.label, 'Últimos 12 meses');
    expect(PeriodoRelatorio.anoAtual.label, 'Ano atual');
  });

  test(
    'intervalo() calcula início/fim corretos para os 4 presets, '
    'construído dinamicamente a partir de DateTime.now()',
    () {
      final now = DateTime.now();
      DateTime mesesAtras(int meses) => DateTime(now.year, now.month - meses, 1);
      final fimEsperado = DateTime(now.year, now.month, 1);

      final (inicio3, fim3) = PeriodoRelatorio.tresMeses.intervalo();
      expect(inicio3, mesesAtras(2));
      expect(fim3, fimEsperado);

      final (inicio6, fim6) = PeriodoRelatorio.seisMeses.intervalo();
      expect(inicio6, mesesAtras(5));
      expect(fim6, fimEsperado);

      final (inicio12, fim12) = PeriodoRelatorio.dozeMeses.intervalo();
      expect(inicio12, mesesAtras(11));
      expect(fim12, fimEsperado);

      final (inicioAno, fimAno) = PeriodoRelatorio.anoAtual.intervalo();
      expect(inicioAno, DateTime(now.year, 1, 1));
      expect(fimAno, fimEsperado);
    },
  );

  test(
    'caso de borda: início calculado cruza corretamente a virada de ano '
    'quando o mês atual é janeiro ou fevereiro',
    () {
      final now = DateTime.now();

      // Só roda as asserções específicas de virada de ano quando o teste
      // de fato executa em janeiro/fevereiro — nos demais meses o teste
      // acima já cobre a mesma fórmula sem cruzar ano. Isso evita valor
      // fixo (hardcoded) que quebraria em execuções futuras fora dessa
      // janela, mas ainda documenta e verifica o comportamento exato
      // esperado na virada quando ela de fato ocorre.
      if (now.month == 1) {
        final (inicio3, _) = PeriodoRelatorio.tresMeses.intervalo();
        expect(inicio3.year, now.year - 1);
        expect(inicio3.month, 11);

        final (inicio6, _) = PeriodoRelatorio.seisMeses.intervalo();
        expect(inicio6.year, now.year - 1);
        expect(inicio6.month, 8);

        final (inicio12, _) = PeriodoRelatorio.dozeMeses.intervalo();
        expect(inicio12.year, now.year - 1);
        expect(inicio12.month, 2);
      } else if (now.month == 2) {
        final (inicio3, _) = PeriodoRelatorio.tresMeses.intervalo();
        expect(inicio3.year, now.year - 1);
        expect(inicio3.month, 12);

        final (inicio6, _) = PeriodoRelatorio.seisMeses.intervalo();
        expect(inicio6.year, now.year - 1);
        expect(inicio6.month, 9);

        final (inicio12, _) = PeriodoRelatorio.dozeMeses.intervalo();
        expect(inicio12.year, now.year - 1);
        expect(inicio12.month, 3);
      }

      // anoAtual nunca cruza virada de ano por definição (início é sempre
      // 1º de janeiro do ano corrente).
      final (inicioAno, _) = PeriodoRelatorio.anoAtual.intervalo();
      expect(inicioAno.year, now.year);
      expect(inicioAno.month, 1);
    },
  );
}
