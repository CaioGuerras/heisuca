// Ícones do CGFLIX (refino 2). Estilo único no app: Material Symbols Rounded, preenchido quando
// ATIVO (ligado/selecionado) e em contorno quando inativo; 24 dp nas listas e 28 dp nos controles
// do player no celular, sempre com 48 dp de toque.
//
// Os controles do player são do Plezy: aqui só trocamos o desenho dos que não diziam o que fazem
// (gancho de 1 linha em `video_control_button.dart`). TV e computador mantêm o tamanho do upstream
// (o foco do controle remoto da TV depende dele).
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../utils/platform_detector.dart';

/// Ícone do player do Plezy → ícone mais claro para o público.
IconData cgflixPlayerIcon(IconData icon) {
  // `IconData` não é constante em switch; compara pelo código.
  if (icon == Symbols.tune_rounded) return Symbols.settings_rounded; // Ajustes do vídeo: engrenagem
  if (icon == Symbols.audiotrack_rounded) return Symbols.voice_selection_rounded; // Áudio (sem legenda)
  if (icon == Symbols.bookmarks_rounded) return Symbols.toc_rounded; // Capítulos: lista
  if (icon == Symbols.queue_rounded) return Symbols.playlist_play_rounded; // Lista de episódios
  return icon;
}

/// Preenchido quando ativo; contorno quando é uma chave desligada (`checked == false`).
double cgflixPlayerIconFill({required bool? checked, required bool isActive}) =>
    (checked == false && !isActive) ? 0 : 1;

/// Controles do player no celular: 28 dp de desenho e 48 dp de toque. Fora do celular, o do upstream.
bool cgflixPlayerTouchSized(BuildContext context, {required bool hasFocusNode}) =>
    !hasFocusNode && PlatformDetector.isMobile(context);

const double cgflixPlayerIconSize = 28;
const double cgflixPlayerTouchTarget = 48;
