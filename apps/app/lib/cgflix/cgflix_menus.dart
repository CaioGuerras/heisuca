// Ordem dos menus do CGFLIX (refino 2): o que uma pessoa comum usa toda semana em cima, o técnico
// embaixo, com um traço entre os assuntos. Vale para o menu do cartão (tocar e segurar) e para o
// "⋮" da página do título, que no Plezy são o mesmo menu (`media_context_menu.dart`, 1 gancho).
// Nada sai do menu: só muda a ordem.
import 'package:flutter/material.dart';

import '../widgets/app_menu.dart';

/// Grupos do menu de um título, na ordem em que aparecem. Cada valor é o `value` da ação do Plezy.
const cgflixTitleMenuGroups = <List<String>>[
  // Assistir
  ['details', 'play_from_beginning', 'series', 'shuffle_play', 'play_trailer'],
  // Guardar para depois
  ['download', 'delete_download', 'manage_sync', 'remove_sync', 'toggle_watchlist', 'add_to'],
  // Marcar
  ['watch', 'unwatch', 'remove_from_continue_watching', 'rate'],
  // Técnico (versão do arquivo, detalhes do arquivo, outro player)
  ['play_version', 'fileinfo', 'play_external'],
  // Administração do servidor (só para quem administra)
  ['edit_metadata', 'quick_tag', 'match', 'unmatch', 'remove_from_collection'],
  // Apagar do servidor: sempre o último
  ['delete_media'],
];

int? _groupOf(String value) {
  for (final (i, group) in cgflixTitleMenuGroups.indexed) {
    if (group.contains(value)) return i;
  }
  return null;
}

int _rankOf(String value) {
  for (final (i, group) in cgflixTitleMenuGroups.indexed) {
    final j = group.indexOf(value);
    if (j >= 0) return i * 100 + j;
  }
  return -1;
}

/// Reordena os itens do menu de um título e põe um traço entre os grupos. Menus que não são de
/// título (música, coleção, playlist) e itens desconhecidos ficam como o Plezy montou; itens
/// desconhecidos (extras de cada tela) vão antes do grupo "Apagar".
List<AppMenuEntry<String>> cgflixArrangeTitleMenu(List<AppMenuItem<String>> items) {
  final known = items.where((i) => _groupOf(i.value) != null).toList();
  // Música/coleção/playlist: sem nenhum item conhecido de vídeo, o menu fica igual.
  if (known.isEmpty || items.any((i) => i.value.startsWith('music_'))) return items;
  known.sort((a, b) => _rankOf(a.value).compareTo(_rankOf(b.value)));
  final extras = items.where((i) => _groupOf(i.value) == null).toList();
  final deleteGroup = cgflixTitleMenuGroups.length - 1;

  final out = <AppMenuEntry<String>>[];
  int? lastGroup;
  void add(AppMenuItem<String> item, int group) {
    if (lastGroup != null && lastGroup != group) out.add(const AppMenuDivider<String>());
    out.add(item);
    lastGroup = group;
  }

  for (final item in known.where((i) => _groupOf(i.value) != deleteGroup)) {
    add(item, _groupOf(item.value)!);
  }
  for (final item in extras) {
    add(item, -1);
  }
  for (final item in known.where((i) => _groupOf(i.value) == deleteGroup)) {
    add(item, deleteGroup);
  }
  return out;
}

/// Cabeçalho curto entre os grupos das folhas do player ("Som e legenda", "Imagem e técnico").
/// O player é sempre escuro: texto branco suave.
class CgflixSheetHeader extends StatelessWidget {
  const CgflixSheetHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
    );
  }
}

const cgflixSheetHeaderSound = 'Som e legenda';
const cgflixSheetHeaderPicture = 'Imagem e técnico';
