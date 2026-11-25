import 'package:flutter/material.dart';

import '../../features/titulo/ligacao.dart';
import '../../media/media_item.dart';

/// Página do título na TV (filme, série, temporada ou episódio).
///
/// É a mesma ligação da ficha do celular ([LigacaoDoTitulo]: dados reais, Assistir, Minha lista, Já vi,
/// episódios, elenco, parecidos e dados da mídia), no desenho da TV (`TelaTituloTv`). Episódio e temporada abrem a
/// série, com aquele episódio como o próximo a tocar ou aquela temporada aberta.
class HeisucaTvTitleScreen extends StatelessWidget {
  const HeisucaTvTitleScreen({super.key, required this.item, this.episodio});

  final MediaItem item;

  /// O episódio que o Assistir deve tocar, quando quem abriu já sabe qual é.
  final MediaItem? episodio;

  static Future<void> show(BuildContext context, MediaItem item, {MediaItem? episodio}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HeisucaTvTitleScreen(item: item, episodio: episodio),
    ),
  );

  @override
  Widget build(BuildContext context) => LigacaoDoTitulo(item: item, episodio: episodio, naTv: true);
}
