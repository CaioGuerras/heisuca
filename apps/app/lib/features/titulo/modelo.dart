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
  final VoidCallback? aoAlternarLista;

  final bool visto;
  final VoidCallback? aoAlternarVisto;
}
