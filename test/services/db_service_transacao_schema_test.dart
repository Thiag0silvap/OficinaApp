import 'package:flutter_test/flutter_test.dart';

import 'package:oficina_app/models/transacao.dart';
import 'package:oficina_app/services/db_service.dart';

import 'db_service_test_utils.dart';

/// Regressão do bug: CREATE TABLE transacoes (em _onCreate) nunca teve as
/// colunas valorOriginal/editadoEm, mas Transacao.toMap() sempre inclui
/// essas chaves — insertTransacao/updateTransacao quebravam com
/// "table transacoes has no column named valorOriginal" em qualquer banco,
/// novo ou existente, até _ensureColumnExists cobrir as duas colunas.
void main() {
  setUpAll(setUpDbServiceTests);
  tearDown(tearDownDbServiceTests);

  test(
    'insertTransacao e updateTransacao persistem valorOriginal e editadoEm preenchidos',
    () async {
      await freshTestUserId();

      final original = Transacao(
        id: 't1',
        tipo: TipoTransacao.saida,
        descricao: 'Troca de óleo',
        valor: 150.0,
        categoria: 'Serviço',
        data: DateTime(2026, 9, 17),
      );

      await DBService.instance.insertTransacao(original);

      final editadoEm = DateTime(2026, 9, 18, 10, 30);
      final editada = original.copyWith(
        valor: 180.0,
        valorOriginal: 150.0,
        editadoEm: editadoEm,
      );

      await DBService.instance.updateTransacao(editada);

      final persistida = await DBService.instance.getTransacaoById('t1');

      expect(persistida, isNotNull);
      expect(persistida!.valor, 180.0);
      expect(persistida.valorOriginal, 150.0);
      expect(persistida.editadoEm, editadoEm);
    },
  );
}
