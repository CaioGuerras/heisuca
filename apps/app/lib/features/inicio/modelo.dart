import 'package:flutter/widgets.dart';

import '../../design/componentes/cartao.dart';

/// Monta a arte de um título no tamanho pedido. A tela não sabe de onde a imagem vem.
typedef FazArte = Widget Function(BuildContext context, Size tamanho);

/// Monta o logo de um título. [semLogo] é o que aparece quando o título não tem logo.
typedef FazLogo = Widget Function(BuildContext context, Size tamanho, Widget semLogo);

/// Um título do destaque no topo do Início.
///
/// Dado ausente fica `null` e não aparece na tela (nada de "Sem sinopse").
@immutable
class TituloEmDestaque {
  const TituloEmDestaque({
    required this.chave,
    required this.titulo,
    this.arte,
    this.logo,
    this.nota,
    this.anos,
    this.generos,
    this.classificacao,
    this.sinopse,
    this.hash,
    this.aoAbrir,
    this.aoAssistir,
    this.aoSegurar,
  });

  final String chave;
  final String titulo;
  final FazArte? arte;
  final FazLogo? logo;

  /// Nota já formatada ("8,6").
  final String? nota;

  /// Ano ou intervalo ("2000 - 2010").
  final String? anos;
  final String? generos;

  /// Classificação indicativa ("12").
  final String? classificacao;
  final String? sinopse;

  /// BlurHash da arte: dá a cor do pôster que tinge a tela.
  final String? hash;

  /// Abre a página do título (tocar no destaque não toca o vídeo).
  final VoidCallback? aoAbrir;

  /// Toca o título (botão "Assistir").
  final VoidCallback? aoAssistir;

  /// Abre o menu do título (toque longo).
  final VoidCallback? aoSegurar;
}

/// Um cartão de uma fileira do Início.
@immutable
class ItemDaFileira {
  const ItemDaFileira({
    required this.chave,
    required this.titulo,
    this.subtitulo,
    this.arte,
    this.hash,
    this.progresso,
    this.tempo,
    this.nota,
    this.aoTocar,
    this.aoSegurar,
  });

  final String chave;
  final String titulo;
  final String? subtitulo;
  final FazArte? arte;
  final String? hash;

  /// De 0 a 1; `null` não mostra a barra.
  final double? progresso;

  /// "restam 38 min".
  final String? tempo;
  final String? nota;
  final VoidCallback? aoTocar;
  final VoidCallback? aoSegurar;
}

/// Uma fileira do Início: título, cartões e, quando existe, o "Ver tudo".
@immutable
class FileiraDoInicio {
  const FileiraDoInicio({
    required this.chave,
    required this.titulo,
    required this.itens,
    this.formato = FormatoDoCartao.poster,
    this.numerada = false,
    this.aoVerTudo,
  });

  final String chave;
  final String titulo;
  final List<ItemDaFileira> itens;
  final FormatoDoCartao formato;

  /// Mostra a posição ao lado de cada cartão (1 a 10), como em "Em alta".
  final bool numerada;
  final VoidCallback? aoVerTudo;
}
