import 'package:flutter/widgets.dart';

import '../inicio/modelo.dart' show FazArte;

/// Que tipo de título o resultado é: decide em qual pílula ele aparece.
enum TipoDoResultado { filme, serie, outro }

/// As pílulas da busca, na ordem em que aparecem.
enum FiltroDaBusca {
  todos('Todos'),
  filmes('Filmes'),
  series('Séries'),
  pessoas('Pessoas');

  const FiltroDaBusca(this.rotulo);
  final String rotulo;
}

/// Um título achado pela busca. Um por obra, mesmo quando mais de uma fonte o tem.
///
/// Dado ausente fica `null` e não aparece.
@immutable
class TituloDaBusca {
  const TituloDaBusca({
    required this.chave,
    required this.titulo,
    this.tipo = TipoDoResultado.outro,
    this.anos,
    this.origem,
    this.arte,
    this.hash,
    this.nota,
    this.visto = false,
    this.aoTocar,
    this.aoSegurar,
  });

  final String chave;
  final String titulo;
  final TipoDoResultado tipo;

  /// Ano ou intervalo ("2000 - 2010").
  final String? anos;

  /// De onde o título vem, quando há mais de uma fonte ("Casa", "2 fontes").
  final String? origem;
  final FazArte? arte;

  /// BlurHash do pôster: dá a cor do cartão e do fundo.
  final String? hash;

  /// Nota já formatada ("8,6").
  final String? nota;
  final bool visto;
  final VoidCallback? aoTocar;

  /// Toque longo: abre o menu do título.
  final VoidCallback? aoSegurar;
}

/// Uma pessoa achada pela busca (atriz, diretor).
@immutable
class PessoaDaBusca {
  const PessoaDaBusca({required this.chave, required this.nome, this.foto, this.aoTocar});

  final String chave;
  final String nome;
  final FazArte? foto;
  final VoidCallback? aoTocar;
}
