// Ganchos do CGFLIX na página do título (media_detail_screen.dart chama daqui):
// transição do pôster, texto do botão principal e selos Dublado/Legendado.
import 'package:flutter/material.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_stream.dart';
import 'cgflix_palette.dart';
import 'home/cgflix_actions.dart';

/// Fundo da página "voando" a partir do cartão que a abriu (quando foi um cartão do CGFLIX).
Widget cgflixDetailHero(MediaItem item, Widget child) {
  final tag = cgflixDetailHeroTag(item);
  if (tag == null) return child;
  return Hero(tag: tag, transitionOnUserGestures: true, child: child);
}

/// Texto do botão principal: "Assistir"/"Continuar" e, em séries, o episódio ("Continuar T2:E5").
/// [episode] é o episódio que o botão toca (séries); [fresh] devolve o estado de exibição atual.
String cgflixPlayButtonLabel(MediaItem metadata, MediaItem? episode, MediaItem Function(MediaItem) fresh) {
  if (metadata.kind == MediaKind.show) {
    if (episode == null) return 'Assistir';
    final current = fresh(episode);
    final code = cgflixEpisodeCode(current);
    final started = (current.viewOffsetMs ?? 0) > 0 || (current.parentIndex ?? 1) > 1 || (current.index ?? 1) > 1;
    final verb = started ? 'Continuar' : 'Assistir';
    return code.isEmpty ? verb : '$verb $code';
  }
  return (metadata.viewOffsetMs ?? 0) > 0 ? 'Continuar' : 'Assistir';
}

const _portugueseCodes = {'por', 'pob', 'pt', 'pt-br', 'pt_br', 'ptbr', 'pt-pt', 'portuguese', 'português'};

bool _isPortuguese(MediaStream stream) {
  final code = stream.languageCode?.trim().toLowerCase();
  if (code != null && _portugueseCodes.contains(code)) return true;
  final language = stream.language?.trim().toLowerCase() ?? '';
  return language.startsWith('portug');
}

/// Dublado = tem áudio em português; Legendado = tem legenda em português (`por`/`pob`).
({bool dubbed, bool subtitled}) cgflixLanguageFlags(MediaItem? item) {
  var dubbed = false;
  var subtitled = false;
  for (final version in item?.mediaVersions ?? const []) {
    for (final part in version.parts) {
      for (final stream in part.streams) {
        if (!_isPortuguese(stream)) continue;
        if (stream.kind == MediaStreamKind.audio) dubbed = true;
        if (stream.kind == MediaStreamKind.subtitle) subtitled = true;
      }
    }
  }
  return (dubbed: dubbed, subtitled: subtitled);
}

/// Selos para a linha de gêneros do topo da página (vazio quando não há informação das faixas).
List<Widget> cgflixLanguageBadges(MediaItem? item) {
  final flags = cgflixLanguageFlags(item);
  return [if (flags.dubbed) const _Badge('Dublado'), if (flags.subtitled) const _Badge('Legendado')];
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.cgflix.badgeBorder),
      color: context.cgflix.badge,
    ),
    child: Text(
      label,
      style: TextStyle(color: context.cgflix.onBadge, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
