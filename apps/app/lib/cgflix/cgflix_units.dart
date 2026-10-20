// CGFLIX (1.5.0): nada de "ms" na tela em português. Os valores continuam guardados em
// milissegundos (nada muda para quem já ajustou); só o texto vira segundos.
import '../i18n/strings.g.dart';

/// Ajuste de sincronia de áudio/legenda em segundos: "+0,15 s", "-1,2 s", "0 s".
String cgflixFormatSyncOffsetSeconds(double offsetMs) {
  final ms = offsetMs.round();
  if (ms == 0) return '0 s';
  final sign = ms > 0 ? '+' : '-';
  var text = (ms.abs() / 1000).toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '$sign${text.replaceAll('.', ',')} s';
}

/// Letra da temporada nos rótulos curtos do upstream ("S1 E3"): em português é "T" (temporada).
String get cgflixSeasonLetter => LocaleSettings.currentLocale == AppLocale.pt ? 'T' : 'S';
