import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/veiculo.dart';
import 'package:oficina_app/services/mappers/veiculo_mapper.dart';

void main() {
  test('veiculoFromSupabase reconstrói todos os campos a partir do formato snake_case', () {
    final map = {
      'id': 'v1',
      'oficina_id': 'oficina-x',
      'cliente_id': 'c1',
      'marca': 'Fiat',
      'modelo': 'Uno',
      'cor': 'Branco',
      'placa': 'ABC1234',
      'ano': 2018,
      'observacoes': 'revisado',
      'ativo': true,
    };

    final veiculo = veiculoFromSupabase(map);

    expect(veiculo.id, 'v1');
    expect(veiculo.clienteId, 'c1');
    expect(veiculo.marca, 'Fiat');
    expect(veiculo.modelo, 'Uno');
    expect(veiculo.cor, 'Branco');
    expect(veiculo.placa, 'ABC1234');
    expect(veiculo.ano, 2018);
    expect(veiculo.observacoes, 'revisado');
    expect(veiculo.ativo, true);
  });

  test('veiculoFromSupabase não lança em campos ausentes/nulos e aplica defaults seguros', () {
    final veiculo = veiculoFromSupabase({});

    expect(veiculo.id, '');
    expect(veiculo.clienteId, '');
    expect(veiculo.ano, isNull);
    expect(veiculo.observacoes, isNull);
    expect(veiculo.ativo, true);
  });

  test('paraSupabase -> veiculoFromSupabase é reversível (round-trip)', () {
    final original = Veiculo(
      id: 'v2',
      clienteId: 'c2',
      marca: 'VW',
      modelo: 'Gol',
      cor: 'Prata',
      placa: 'XYZ9876',
      ano: 2020,
      ativo: false,
    );

    final supabaseMap = paraSupabase(original, 'oficina-1');
    final restaurado = veiculoFromSupabase(supabaseMap);

    expect(restaurado.id, original.id);
    expect(restaurado.clienteId, original.clienteId);
    expect(restaurado.marca, original.marca);
    expect(restaurado.modelo, original.modelo);
    expect(restaurado.cor, original.cor);
    expect(restaurado.placa, original.placa);
    expect(restaurado.ano, original.ano);
    expect(restaurado.ativo, original.ativo);
  });
}
