import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/core/utils/text_normalize.dart';

void main() {
  test('remove acentos das vogais e do c cedilhado', () {
    expect(normalizeText('á'), 'a');
    expect(normalizeText('à'), 'a');
    expect(normalizeText('â'), 'a');
    expect(normalizeText('ã'), 'a');
    expect(normalizeText('ä'), 'a');
    expect(normalizeText('é'), 'e');
    expect(normalizeText('í'), 'i');
    expect(normalizeText('ó'), 'o');
    expect(normalizeText('õ'), 'o');
    expect(normalizeText('ú'), 'u');
    expect(normalizeText('ç'), 'c');
  });

  test('remove acentos preservando o resto da palavra', () {
    expect(normalizeText('Peças'), 'pecas');
    expect(normalizeText('café com leite'), 'cafe com leite');
    expect(normalizeText('AÇÃO'), 'acao');
  });

  test('e case-insensitive (maiuscula e minuscula normalizam igual)', () {
    expect(normalizeText('PEÇAS'), normalizeText('peças'));
    expect(normalizeText('ABC'), 'abc');
    expect(normalizeText('abc'), 'abc');
  });

  test('remove espaços nas bordas (trim)', () {
    expect(normalizeText('  café  '), 'cafe');
    expect(normalizeText('\tPeças\n'), 'pecas');
  });

  test('string vazia retorna vazia', () {
    expect(normalizeText(''), '');
  });

  test('string só com espaços retorna vazia', () {
    expect(normalizeText('   '), '');
    expect(normalizeText('\t\n  '), '');
  });
}
