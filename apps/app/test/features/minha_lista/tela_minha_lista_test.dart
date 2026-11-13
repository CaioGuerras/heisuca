import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/design/componentes/pilula_de_perfil.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/inicio/fileira.dart';
import 'package:heisuca/features/inicio/modelo.dart';
import 'package:heisuca/features/minha_lista/tela_minha_lista.dart';

import '../../design/componentes/apoio.dart';

FileiraDoInicio _fileira(String chave, String titulo, int quantos, {VoidCallback? aoTocar}) => FileiraDoInicio(
  chave: chave,
  titulo: titulo,
  itens: [for (var i = 0; i < quantos; i++) ItemDaFileira(chave: '$chave-$i', titulo: '$titulo $i', aoTocar: aoTocar)],
);

void main() {
  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: título da tela e uma fileira por tipo, na ordem recebida', (tester) async {
      await tester.pumpWidget(
        naTela(
          tema: tema,
          TelaMinhaLista(
            fileiras: [_fileira('series', 'Séries', 2), _fileira('filmes', 'Filmes', 1)],
            cores: CorPosterCache(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Minha lista'), findsOneWidget);
      expect(find.byType(Fileira), findsNWidgets(2));
      expect(find.byType(Cartao), findsNWidgets(3));
      expect(tester.getTopLeft(find.text('Séries')).dy, lessThan(tester.getTopLeft(find.text('Filmes')).dy));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('fileira sem cartão não aparece', (tester) async {
    await tester.pumpWidget(
      naTela(
        TelaMinhaLista(
          fileiras: [_fileira('series', 'Séries', 0), _fileira('filmes', 'Filmes', 1)],
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Séries'), findsNothing);
    expect(find.text('Filmes'), findsOneWidget);
  });

  testWidgets('carregando sem nada na tela mostra fileiras de espera, sem leitura para o leitor de tela', (
    tester,
  ) async {
    await tester.pumpWidget(naTela(TelaMinhaLista(fileiras: const [], carregando: true, cores: CorPosterCache())));
    await tester.pump();
    expect(find.byType(FileiraCarregando), findsNWidgets(TelaMinhaLista.fileirasDeEspera));
    expect(find.byType(Fileira), findsNothing);
    expect(
      find.descendant(of: find.byType(FileiraCarregando), matching: find.bySemanticsLabel(RegExp('.+'))),
      findsNothing,
      reason: 'a fileira de espera não tem nada para o leitor de tela ler',
    );
  });

  testWidgets('carregando com a lista na tela mantém a lista', (tester) async {
    await tester.pumpWidget(
      naTela(TelaMinhaLista(fileiras: [_fileira('filmes', 'Filmes', 1)], carregando: true, cores: CorPosterCache())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FileiraCarregando), findsNothing);
    expect(find.text('Filmes 0'), findsOneWidget);
  });

  testWidgets('o aviso ocupa o lugar das fileiras', (tester) async {
    await tester.pumpWidget(
      naTela(
        TelaMinhaLista(
          fileiras: [_fileira('filmes', 'Filmes', 1)],
          aviso: const Text('Nenhum favorito ainda'),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum favorito ainda'), findsOneWidget);
    expect(find.byType(Fileira), findsNothing);
    expect(find.text('Minha lista'), findsOneWidget, reason: 'o título da tela fica mesmo com aviso');
  });

  testWidgets('tocar no cartão e na busca chama quem a tela recebeu; a busca tem área de 48', (tester) async {
    var toques = 0;
    var buscas = 0;
    await tester.pumpWidget(
      naTela(
        TelaMinhaLista(
          fileiras: [_fileira('filmes', 'Filmes', 1, aoTocar: () => toques++)],
          aoBuscar: () => buscas++,
          perfil: const Text('Caio'),
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filmes 0'));
    await tester.tap(find.bySemanticsLabel('Buscar'));
    await tester.pumpAndSettle();
    expect(toques, 1);
    expect(buscas, 1);
    final busca = tester.getSize(find.bySemanticsLabel('Buscar'));
    expect(busca.width, greaterThanOrEqualTo(48));
    expect(busca.height, greaterThanOrEqualTo(48));
    expect(
      tester.getTopLeft(find.text('Caio')).dx,
      lessThan(tester.getTopLeft(find.bySemanticsLabel('Buscar')).dx),
      reason: 'perfil de um lado, busca do outro',
    );
  });

  testWidgets('puxar para baixo pede a lista de novo, mesmo com poucos títulos', (tester) async {
    var pedidos = 0;
    await tester.pumpWidget(
      naTela(
        TelaMinhaLista(
          fileiras: [_fileira('filmes', 'Filmes', 1)],
          aoAtualizar: () async => pedidos++,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.text('Filmes 0'), const Offset(0, 400), 1200);
    await tester.pumpAndSettle();
    expect(pedidos, 1);
  });

  testWidgets('letra em 200% não estoura a tela', (tester) async {
    await tester.pumpWidget(
      naTela(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: TelaMinhaLista(
              fileiras: [_fileira('series', 'Séries', 4), _fileira('filmes', 'Filmes', 4)],
              aoBuscar: () {},
              cores: CorPosterCache(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('letra em 200%: a pílula do perfil não encosta no título da tela', (tester) async {
    await tester.pumpWidget(
      naTela(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: TelaMinhaLista(
              fileiras: [_fileira('series', 'Séries', 4)],
              aoBuscar: () {},
              perfil: PilulaDePerfil(nome: 'Maria Antonieta', aoTocar: () {}),
              cores: CorPosterCache(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final pilula = tester.getRect(find.byType(PilulaDePerfil));
    final titulo = tester.getRect(find.text('Minha lista'));
    expect(pilula.bottom, lessThanOrEqualTo(titulo.top));
    expect(pilula.right, lessThanOrEqualTo(tester.getRect(find.bySemanticsLabel('Buscar')).left));
  });

  testWidgets('o fim da lista guarda espaço para a barra flutuante', (tester) async {
    final controle = ScrollController();
    addTearDown(controle.dispose);
    await tester.pumpWidget(
      naTela(
        TelaMinhaLista(
          fileiras: [for (var i = 0; i < 6; i++) _fileira('f$i', 'Fileira $i', 2)],
          controle: controle,
          folgaInferior: 96,
          cores: CorPosterCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controle.jumpTo(controle.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final fundoDaTela = tester.getBottomLeft(find.byType(TelaMinhaLista)).dy;
    expect(tester.getBottomLeft(find.byType(Fileira).last).dy, lessThanOrEqualTo(fundoDaTela - 96 + 0.5));
  });
}
