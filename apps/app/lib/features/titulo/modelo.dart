import 'package:flutter/widgets.dart';

import '../inicio/modelo.dart' show FazArte, FazLogo;

export '../inicio/modelo.dart' show FazArte, FazLogo;

/// O que a página de um título mostra na cabeça: arte, logo, dados e as ações.
///
/// Dado ausente fica `null` (ou lista vazia) e não aparece na tela. Ação ausente some com o botão dela.
@immutable
class PaginaDoTitulo {
  const PaginaDoTitulo({
    required this.chave,
    required this.titulo,
    this.arte,
    this.logo,
    this.hash,
    this.nota,
    this.anos,
    this.generos,
    this.classificacao,
    this.detalhes = const [],
    this.sinopse,
    this.rotuloDeAssistir = 'Assistir',
    this.progresso,
    this.aoAssistir,
    this.naLista = false,
    this.listaDaConta = false,
    this.aoAlternarLista,
    this.visto = false,
    this.aoAlternarVisto,
  });

  final String chave;
  final String titulo;
  final FazArte? arte;
  final FazLogo? logo;

  /// BlurHash da arte: dá a cor do pôster que tinge a tela.
  final String? hash;

  /// Nota já formatada ("8,6").
  final String? nota;

  /// Ano ou intervalo ("2000 - 2010").
  final String? anos;
  final String? generos;

  /// Classificação indicativa ("12").
  final String? classificacao;

  /// A segunda linha de dados, já em texto: "3 temporadas", "1h 2min", "1080p", "Termina às 22:40".
  final List<String> detalhes;
  final String? sinopse;

  /// O texto do botão principal: "Assistir" ou "Continuar T1:E3".
  final String rotuloDeAssistir;

  /// Quanto já foi visto do que o botão vai tocar, de 0 a 1.
  final double? progresso;
  final VoidCallback? aoAssistir;

  final bool naLista;

  /// O que o botão guarda. Falso: favorito do servidor (Jellyfin), com coração e "Favoritar". Verdadeiro: a lista
  /// da conta (Plex não tem favorito por servidor), com marcador e "Minha lista" (Caio, 13/11).
  final bool listaDaConta;
  final VoidCallback? aoAlternarLista;

  final bool visto;
  final VoidCallback? aoAlternarVisto;
}

/// Um episódio na página do título.
@immutable
class EpisodioDoTitulo {
  const EpisodioDoTitulo({
    required this.chave,
    required this.numero,
    required this.nome,
    this.arte,
    this.duracao,
    this.progresso,
    this.atual = false,
    this.aoTocar,
    this.aoSegurar,
  });

  final String chave;
  final int numero;
  final String nome;
  final FazArte? arte;

  /// Duração já em texto ("58 min").
  final String? duracao;

  /// Quanto já foi visto, de 0 a 1.
  final double? progresso;

  /// O episódio que o botão "Assistir" vai tocar: a fileira abre nele e ele ganha contorno.
  final bool atual;
  final VoidCallback? aoTocar;
  final VoidCallback? aoSegurar;

  /// O nome como aparece no cartão: "3. O acordo".
  String get rotulo => nome.trim().isEmpty ? 'Episódio $numero' : '$numero. $nome';
}

/// Uma temporada e os episódios dela.
@immutable
class TemporadaDoTitulo {
  const TemporadaDoTitulo({required this.chave, required this.nome, this.episodios});

  final String chave;

  /// "Temporada 1", "Especiais".
  final String nome;

  /// `null` enquanto os episódios não chegam; lista vazia quando a temporada não tem nenhum.
  final List<EpisodioDoTitulo>? episodios;
}

/// Alguém do elenco ou da equipe.
@immutable
class PessoaDoTitulo {
  const PessoaDoTitulo({required this.chave, required this.nome, this.papel, this.foto, this.aoTocar});

  final String chave;
  final String nome;

  /// O personagem, ou a função ("Direção").
  final String? papel;
  final FazArte? foto;
  final VoidCallback? aoTocar;

  /// Como o leitor de tela anuncia: "Ian McShane, Al Swearengen".
  String get rotulo => (papel == null || papel!.trim().isEmpty) ? nome : '$nome, ${papel!.trim()}';
}

/// Um gênero do título; com [aoTocar], leva aos títulos do mesmo gênero.
@immutable
class GeneroDoTitulo {
  const GeneroDoTitulo({required this.nome, this.aoTocar});

  final String nome;
  final VoidCallback? aoTocar;
}

/// Um cartão de dados técnicos da mídia ("Vídeo", "Áudio"): pares de nome e valor, já em texto.
///
/// Só o que interessa a quem assiste. O caminho do arquivo no servidor não entra aqui.
@immutable
class GrupoDeInfo {
  const GrupoDeInfo({required this.titulo, required this.linhas, this.icone});

  final String titulo;
  final IconData? icone;
  final List<(String nome, String valor)> linhas;
}
