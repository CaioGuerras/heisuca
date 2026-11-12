import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/cartao.dart';
import 'package:heisuca/features/inicio/fileira.dart';
import 'package:heisuca/features/titulo/elenco.dart';
import 'package:heisuca/features/titulo/episodios.dart';
import 'package:heisuca/features/titulo/generos.dart';
import 'package:heisuca/features/titulo/info_da_midia.dart';
import 'package:heisuca/features/titulo/ligacao.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_file_info.dart';
import 'package:heisuca/media/media_hub.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_role.dart';
import 'package:heisuca/media/media_server_client.dart';

import '../../design/componentes/apoio.dart';

MediaItem _item(
  String id,
  MediaKind tipo, {
  String? titulo,
  int? numero,
  String? pai,
  int? numeroDoPai,
  String? avo,
  String? nomeDoAvo,
  int? duracao,
  int? visto,
}) => PlexMediaItem(
  id: id,
  kind: tipo,
  title: titulo,
  index: numero,
  parentId: pai,
  parentIndex: numeroDoPai,
  grandparentId: avo,
  grandparentTitle: nomeDoAvo,
  durationMs: duracao,
  viewOffsetMs: visto,
  serverId: 'casa',
);

final _serie = _item('serie', MediaKind.show, titulo: 'Frieren');
final _especiais = _item('t0', MediaKind.season, titulo: 'Specials', numero: 0, pai: 'serie');
final _primeira = _item('t1', MediaKind.season, numero: 1, pai: 'serie');
final _segunda = _item('t2', MediaKind.season, numero: 2, pai: 'serie');

MediaItem _episodio(String temporada, int numeroDaTemporada, int numero, {int? visto}) => _item(
  '$temporada-e$numero',
  MediaKind.episode,
  titulo: 'Capítulo $numero',
  numero: numero,
  pai: temporada,
  numeroDoPai: numeroDaTemporada,
  avo: 'serie',
  nomeDoAvo: 'Frieren',
  duracao: 24 * 60000,
  visto: visto,
);

/// Um servidor de mentira: responde com o que o teste guardou e anota o que foi pedido.
class _Servidor extends MediaServerClient {
  final itens = <String, MediaItem>{};
  final filhos = <String, List<MediaItem>>{};
  final pedidos = <String>[];
  MediaItem? proximo;
  int falhas = 0;

  @override
  ServerId get serverId => ServerId('casa');
  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem)? onItemReady,
  }) async {
    pedidos.add('item:$id');
    if (falhas > 0) {
      falhas--;
      throw StateError('fora do ar');
    }
    return (item: itens[id], onDeckEpisode: itens[id]?.kind == MediaKind.show ? proximo : null);
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    pedidos.add('filhos:$parentId');
    return filhos[parentId] ?? const [];
  }

  /// Sem resposta guardada, o servidor falha: a página tem de seguir sem a seção.
  List<MediaHub>? parecidos;
  final info = <String, MediaFileInfo>{};
  final pedidosDeInfo = <String>[];

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async =>
      parecidos ?? (throw StateError('sem parecidos'));

  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async {
    pedidosDeInfo.add(item.id);
    return info[item.id] ?? (throw StateError('sem dados do arquivo'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

_Servidor _servidorDaSerie() => _Servidor()
  ..itens['serie'] = _serie
  ..filhos['serie'] = [_segunda, _especiais, _primeira]
  ..filhos['t1'] = [_episodio('t1', 1, 2), _episodio('t1', 1, 1)]
  ..filhos['t2'] = [_episodio('t2', 2, 1)];

Future<void> _abrir(WidgetTester tester, MediaItem item, _Servidor servidor, {List<MediaItem>? vistos}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    naTela(
      LigacaoDoTitulo(
        item: item,
        clienteDe: (_, _) => servidor,
        alternarVisto: vistos == null ? null : (_, marcado) async => vistos.add(marcado),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('rótulo do botão', () {
    test('filme: "Continuar" só com posição salva', () {
      expect(rotuloDeAssistirDe(_item('f', MediaKind.movie), null), 'Assistir');
      expect(rotuloDeAssistirDe(_item('f', MediaKind.movie, visto: 5000), null), 'Continuar');
    });

    test('série: sem episódio escolhido é "Assistir"; com episódio leva o código dele', () {
      expect(rotuloDeAssistirDe(_serie, null), 'Assistir');
      expect(rotuloDeAssistirDe(_serie, _episodio('t1', 1, 3)), 'Assistir T1:E3');
      expect(rotuloDeAssistirDe(_serie, _episodio('t2', 2, 5, visto: 9000)), 'Continuar T2:E5');
    });
  });

  test('a duração sai em minutos e, a partir de uma hora, em horas', () {
    expect(duracaoDe(null), isNull);
    expect(duracaoDe(59000), isNull);
    expect(duracaoDe(24 * 60000), '24 min');
    expect(duracaoDe(120 * 60000), '2 h');
    expect(duracaoDe(105 * 60000), '1 h 45 min');
  });

  test('o nome do episódio fica vazio quando só repete o nome da série', () {
    expect(nomeDoEpisodio(_episodio('t1', 1, 1)), 'Capítulo 1');
    expect(nomeDoEpisodio(_item('e', MediaKind.episode, titulo: 'Frieren', nomeDoAvo: 'Frieren')), '');
    expect(nomeDoEpisodio(_item('e', MediaKind.episode)), '');
  });

  group('temporada que abre primeiro', () {
    final temporadas = [_especiais, _primeira, _segunda];

    test('a pedida vence; depois a do episódio que vai tocar', () {
      expect(temporadaInicialDe(temporadas, pedida: 't2', alvo: _episodio('t1', 1, 1)), 2);
      expect(temporadaInicialDe(temporadas, alvo: _episodio('t2', 2, 1)), 2);
      expect(temporadaInicialDe(temporadas, pedida: 'sumiu', alvo: _episodio('t1', 1, 1)), 1);
    });

    test('sem nada escolhido, pula os especiais; só especiais, fica neles; vazia, zero', () {
      expect(temporadaInicialDe(temporadas), 1);
      expect(temporadaInicialDe([_especiais]), 0);
      expect(temporadaInicialDe(const []), 0);
    });
  });

  test('temporadas e episódios saem filtrados e na ordem do número', () {
    final misto = [_segunda, _episodio('t1', 1, 2), _especiais, _primeira, _episodio('t1', 1, 1)];
    expect(soTemporadas(misto).map((t) => t.id), ['t0', 't1', 't2']);
    expect(soEpisodios(misto).map((e) => e.id), ['t1-e1', 't1-e2']);
  });

  testWidgets('série: mostra o título na hora e carrega só a temporada que abre', (tester) async {
    final servidor = _servidorDaSerie();
    await _abrir(tester, _serie, servidor);

    expect(find.text('Frieren'), findsWidgets);
    expect(find.byType(Episodios), findsOneWidget);
    expect(servidor.pedidos, containsAll(['item:serie', 'filhos:serie', 'filhos:t1']));
    expect(servidor.pedidos, isNot(contains('filhos:t2')), reason: 'a outra temporada só carrega quando for aberta');
    expect(servidor.pedidos, isNot(contains('filhos:t0')));
    // Sem "próximo" do servidor, o botão aponta para o primeiro episódio ainda não visto.
    expect(find.text('Assistir T1:E1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('série com episódio em andamento: o botão continua de onde parou, na temporada dele', (tester) async {
    final servidor = _servidorDaSerie()..proximo = _episodio('t2', 2, 1, visto: 60000);
    await _abrir(tester, _serie, servidor);

    expect(find.text('Continuar T2:E1'), findsOneWidget);
    expect(servidor.pedidos, contains('filhos:t2'));
    expect(servidor.pedidos, isNot(contains('filhos:t1')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('aberta por um episódio: vira a página da série e o botão toca aquele episódio', (tester) async {
    final servidor = _servidorDaSerie();
    await _abrir(tester, _episodio('t1', 1, 2), servidor);

    expect(servidor.pedidos.first, anyOf('item:serie', 'filhos:serie'));
    expect(servidor.pedidos, isNot(contains('item:t1-e2')));
    expect(find.byType(Episodios), findsOneWidget);
    expect(find.text('Assistir T1:E2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('"Já vi"', () {
    testWidgets('na cabeça de uma série marca a série toda, não o episódio do botão', (tester) async {
      final vistos = <MediaItem>[];
      final servidor = _servidorDaSerie()..proximo = _episodio('t1', 1, 2, visto: 60000);
      await _abrir(tester, _serie, servidor, vistos: vistos);
      servidor.pedidos.clear();

      await tester.tap(find.byTooltip('Já vi'));
      await tester.pumpAndSettle();

      expect([for (final item in vistos) (item.id, item.kind)], [('serie', MediaKind.show)]);
      expect(servidor.pedidos, contains('item:serie'), reason: 'a página se atualiza depois de marcar');
      expect(tester.takeException(), isNull);
    });

    testWidgets('página aberta por um episódio: a cabeça continua valendo para a série', (tester) async {
      final vistos = <MediaItem>[];
      await _abrir(tester, _episodio('t1', 1, 2), _servidorDaSerie(), vistos: vistos);

      await tester.tap(find.byTooltip('Já vi'));
      await tester.pumpAndSettle();

      expect([for (final item in vistos) item.id], ['serie']);
    });

    testWidgets('no menu de um episódio marca só aquele episódio', (tester) async {
      final vistos = <MediaItem>[];
      await _abrir(tester, _serie, _servidorDaSerie(), vistos: vistos);

      await tester.longPress(find.descendant(of: find.byType(Episodios), matching: find.byType(Cartao)).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar como visto'));
      await tester.pumpAndSettle();

      expect([for (final item in vistos) item.kind], [MediaKind.episode]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('num filme marca o filme', (tester) async {
      final vistos = <MediaItem>[];
      final filme = _item('filme', MediaKind.movie, titulo: 'A Viagem', duracao: 105 * 60000);
      await _abrir(tester, filme, _Servidor()..itens['filme'] = filme, vistos: vistos);

      await tester.tap(find.byTooltip('Já vi'));
      await tester.pumpAndSettle();

      expect([for (final item in vistos) item.id], ['filme']);
    });
  });

  testWidgets('filme: sem episódios, com a duração e o botão de assistir', (tester) async {
    final filme = _item('filme', MediaKind.movie, titulo: 'A Viagem', duracao: 105 * 60000);
    final servidor = _Servidor()..itens['filme'] = filme;
    await _abrir(tester, filme, servidor);

    expect(find.byType(Episodios), findsNothing);
    expect(find.text('Assistir'), findsOneWidget);
    expect(find.textContaining('1 h 45 min'), findsOneWidget);
    expect(servidor.pedidos, ['item:filme']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('servidor fora do ar: avisa, e "Tentar de novo" carrega a página', (tester) async {
    final servidor = _servidorDaSerie()..falhas = 1;
    await _abrir(tester, _serie, servidor);

    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text('Frieren'), findsWidgets, reason: 'o que já se sabia do título continua na tela');

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.byType(Episodios), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('complementos', () {
    test('parecidos: junta os grupos sem repetir e sem o próprio título', () {
      final a = _item('a', MediaKind.movie), b = _item('b', MediaKind.movie), eu = _item('eu', MediaKind.movie);
      final grupos = [
        MediaHub(id: '1', title: 'Parecidos', type: 'movie', items: [a, eu, b]),
        MediaHub(id: '2', title: 'Do mesmo diretor', type: 'movie', items: [b, a]),
      ];
      expect(parecidosDe(grupos, 'eu').map((item) => item.id), ['a', 'b']);
      expect(parecidosDe(const [], 'eu'), isEmpty);
    });

    test('dados do arquivo: só grupos com linha, da primeira versão', () {
      expect(gruposDeInfoDe(null), isEmpty);
      expect(gruposDeInfoDe(const MediaFileInfo()), isEmpty);
      final grupos = gruposDeInfoDe(_arquivo);
      expect(grupos.map((grupo) => grupo.titulo), ['Vídeo']);
      expect(grupos.single.linhas, contains(('Resolução', '1920 × 1080')));
      expect(grupos.single.linhas.every((linha) => linha.$2.trim().isNotEmpty), isTrue);
    });

    testWidgets('filme com tudo: elenco, parecidos, gêneros e dados do arquivo, nesta ordem', (tester) async {
      final filme = PlexMediaItem(
        id: 'filme',
        kind: MediaKind.movie,
        title: 'A Viagem',
        serverId: 'casa',
        genres: const ['Animação', ' ', 'Fantasia'],
        roles: const [
          MediaRole(id: 'p1', tag: 'Rumi Hiiragi', role: 'Chihiro'),
          MediaRole(tag: 'Miyu Irino'),
          MediaRole(tag: '  '),
        ],
      );
      final servidor = _Servidor()
        ..itens['filme'] = filme
        ..parecidos = [
          MediaHub(
            id: '1',
            title: 'Parecidos',
            type: 'movie',
            items: [
              _item('outro', MediaKind.movie, titulo: 'O Castelo Animado'),
              filme,
            ],
          ),
        ]
        ..info['filme'] = _arquivo;
      await _abrir(tester, filme, servidor);

      expect(find.text('Rumi Hiiragi'), findsOneWidget);
      expect(find.text('Chihiro'), findsOneWidget);
      expect(find.text('Miyu Irino'), findsOneWidget);
      expect(find.text('Mais como este'), findsOneWidget);
      expect(find.text('O Castelo Animado'), findsOneWidget);
      expect(find.descendant(of: find.byType(Generos), matching: find.text('Fantasia')), findsOneWidget);
      expect(find.text('Sobre a mídia'), findsOneWidget);
      expect(find.textContaining('1920 × 1080', findRichText: true), findsOneWidget);

      double topo(Type secao) => tester.getTopLeft(find.byType(secao)).dy;
      expect(topo(Elenco), lessThan(topo(Fileira)));
      expect(topo(Fileira), lessThan(topo(Generos)));
      expect(topo(Generos), lessThan(topo(InfoDaMidia)));
      expect(servidor.pedidosDeInfo, ['filme']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('servidor sem parecidos nem dados do arquivo: as seções somem e a página não acusa falha', (
      tester,
    ) async {
      final filme = _item('filme', MediaKind.movie, titulo: 'A Viagem');
      await _abrir(tester, filme, _Servidor()..itens['filme'] = filme);

      expect(find.text('Assistir'), findsOneWidget);
      expect(find.byType(Elenco), findsNothing);
      expect(find.byType(Fileira), findsNothing);
      expect(find.byType(Generos), findsNothing);
      expect(find.byType(InfoDaMidia), findsNothing);
      expect(find.text('Tentar de novo'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('série: os dados do arquivo são os do episódio do botão, com o código no título', (tester) async {
      final servidor = _servidorDaSerie()
        ..proximo = _episodio('t1', 1, 2, visto: 60000)
        ..info['t1-e2'] = _arquivo;
      await _abrir(tester, _serie, servidor);

      expect(servidor.pedidosDeInfo, ['t1-e2']);
      expect(find.textContaining('Sobre a mídia · '), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

const _arquivo = MediaFileInfo(
  versions: [MediaFileVersion(container: 'mkv', width: 1920, height: 1080, videoCodec: 'hevc', bitrateKbps: 4200)],
);
