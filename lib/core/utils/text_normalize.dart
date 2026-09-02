/// Remove acentos e normaliza para minúsculas/trim — usado para comparação
/// de texto tolerante a variação de grafia (ex: "Peças" == "pecas").
String normalizeText(String input) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

  var out = input;
  for (int i = 0; i < comAcento.length; i++) {
    out = out.replaceAll(comAcento[i], semAcento[i]);
  }
  return out.toLowerCase().trim();
}
