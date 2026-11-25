import '../../data/iso_639_data.dart';
import '../../cgflix/cgflix_idiomas.dart';
import '../../utils/language_codes.dart';
import '../../utils/track_label_builder.dart';

/// A barra identifica o idioma; título, região e formato ficam no menu completo.
String idiomaCurtoTv({String? idioma, String? nome}) {
  final valor = cleanTrackMetadataValue(idioma) ?? cleanTrackMetadataValue(nome);
  if (valor == null) return 'Indefinido';
  final codigo = LanguageCodes.getIso6391Code(valor);
  if (codigo != null)
    return cgflixLanguageNamePt(codigo) ?? LanguageCodes.getLanguageName(codigo) ?? codigo.toUpperCase();
  final base = valor.split(RegExp(r'\s*[\(\[·]')).first.trim();
  final normalizado = base.toLowerCase();
  for (final entrada in languageEntries.values) {
    final pt = cgflixLanguageNamePt(entrada.code1);
    if (entrada.name.toLowerCase() == normalizado || pt?.toLowerCase() == normalizado) {
      return pt ?? entrada.name;
    }
  }
  for (final entrada in _nomes.entries) {
    if (entrada.value.contains(normalizado)) return entrada.key;
  }
  // Um nome de faixa sem idioma não é um nome de idioma confiável.
  return 'Indefinido';
}

String idiomaMinimoTv(String idioma) => switch (idioma) {
  'Português' => 'PT',
  'Inglês' => 'EN',
  'Japonês' => 'JA',
  'Espanhol' => 'ES',
  'Francês' => 'FR',
  'Alemão' => 'DE',
  'Italiano' => 'IT',
  'Coreano' => 'KO',
  'Chinês' => 'ZH',
  'Indefinido' => 'UND',
  _ => idioma,
};

String legendaCurtaTv({String? idioma, String? nome, bool forcada = false, bool desligada = false}) {
  if (desligada) return 'Desligada';
  final lingua = idiomaCurtoTv(idioma: idioma, nome: nome);
  return forcada || titleSaysForced(nome) || (nome?.toLowerCase().contains('forçada') ?? false)
      ? '$lingua · forçada'
      : lingua;
}

String faixaMinimaTv(String rotulo) =>
    rotulo.split(' · ').map((parte) => parte == 'forçada' ? 'forç.' : idiomaMinimoTv(parte)).join(' · ');

const _nomes = {
  'Português': ['português', 'portuguese', 'portugues'],
  'Inglês': ['inglês', 'english', 'ingles'],
  'Japonês': ['japonês', 'japanese', 'japones'],
  'Espanhol': ['espanhol', 'spanish', 'español'],
  'Francês': ['francês', 'french', 'français'],
  'Alemão': ['alemão', 'german', 'deutsch'],
  'Italiano': ['italiano', 'italian'],
  'Coreano': ['coreano', 'korean'],
  'Chinês': ['chinês', 'chinese'],
};
