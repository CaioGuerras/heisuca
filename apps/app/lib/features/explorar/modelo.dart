import 'package:flutter/widgets.dart';

import '../inicio/modelo.dart' show FazArte;

/// Uma biblioteca que o Explorar oferece (Filmes, Séries, Animes; nos Plex, o nome que o servidor der).
@immutable
class BibliotecaDoExplorar {
  const BibliotecaDoExplorar({required this.chave, required this.titulo});

  final String chave;
  final String titulo;
}

/// Um gênero da biblioteca aberta.
@immutable
class GeneroDoExplorar {
  const GeneroDoExplorar({required this.chave, required this.nome});

  final String chave;
  final String nome;
}

/// As ordens da grade, na ordem em que a folha as mostra.
enum OrdemDoExplorar {
  titulo('Título A–Z'),
  recentes('Adicionados recentemente'),
  lancamento('Lançamento'),
  nota('Nota');

  const OrdemDoExplorar(this.rotulo);
  final String rotulo;
}

/// Um cartão da grade do Explorar.
///
/// Dado ausente fica `null` e não aparece (nada de "Sem ano").
@immutable
class ItemDoExplorar {
  const ItemDoExplorar({
    required this.chave,
    required this.titulo,
    this.anos,
    this.arte,
    this.hash,
    this.nota,
    this.visto = false,
    this.aoTocar,
    this.aoSegurar,
  });

  final String chave;
  final String titulo;

  /// Ano ou intervalo ("2000 - 2010"), embaixo do nome.
  final String? anos;
  final FazArte? arte;

  /// BlurHash do pôster: dá a cor do cartão enquanto a arte não chega.
  final String? hash;

  /// Nota já formatada ("8,6").
  final String? nota;

  /// Já foi visto até o fim (a série inteira, no caso de série).
  final bool visto;
  final VoidCallback? aoTocar;

  /// Toque longo: abre o menu do título.
  final VoidCallback? aoSegurar;
}
