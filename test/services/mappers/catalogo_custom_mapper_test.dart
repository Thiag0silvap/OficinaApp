import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/services/mappers/catalogo_custom_mapper.dart';

void main() {
  test('marcaModeloFromSupabase reconstrói marca e modelo', () {
    final resultado = marcaModeloFromSupabase({
      'id': 'fiat|uno',
      'oficina_id': 'oficina-x',
      'marca': 'Fiat',
      'modelo': 'Uno',
    });

    expect(resultado, {'marca': 'Fiat', 'modelo': 'Uno'});
  });

  test('marcaModeloFromSupabase aceita modelo nulo (marca sem modelo definido)', () {
    final resultado = marcaModeloFromSupabase({
      'id': 'fiat|',
      'marca': 'Fiat',
      'modelo': null,
    });

    expect(resultado, {'marca': 'Fiat', 'modelo': null});
  });

  test('pecaFromSupabase retorna a string da peça, com default seguro se ausente', () {
    expect(pecaFromSupabase({'id': 'para-choque', 'peca': 'Para-choque'}), 'Para-choque');
    expect(pecaFromSupabase({}), '');
  });

  test('servicoFromSupabase retorna a string do serviço, com default seguro se ausente', () {
    expect(servicoFromSupabase({'id': 'funilaria', 'servico': 'Funilaria'}), 'Funilaria');
    expect(servicoFromSupabase({}), '');
  });

  test('paraSupabase -> fromSupabase é reversível para os 3 catálogos', () {
    final marcaModeloMap = marcaModeloParaSupabase(
      id: 'vw|gol',
      marca: 'VW',
      modelo: 'Gol',
      oficinaId: 'oficina-1',
    );
    expect(marcaModeloFromSupabase(marcaModeloMap), {'marca': 'VW', 'modelo': 'Gol'});

    final pecaMap = pecaParaSupabase(id: 'filtro', peca: 'Filtro', oficinaId: 'oficina-1');
    expect(pecaFromSupabase(pecaMap), 'Filtro');

    final servicoMap =
        servicoParaSupabase(id: 'troca-oleo', servico: 'Troca de óleo', oficinaId: 'oficina-1');
    expect(servicoFromSupabase(servicoMap), 'Troca de óleo');
  });
}
