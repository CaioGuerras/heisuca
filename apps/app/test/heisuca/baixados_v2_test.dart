import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/botao.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/baixados/ligacao.dart';
import 'package:heisuca/features/baixados/modelo.dart';
import 'package:heisuca/features/baixados/tela_baixados.dart';
import 'package:heisuca/features/fundo_tingido.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/providers/download_provider.dart';
import 'package:heisuca/services/background_work_diagnostics_service.dart';
import 'package:heisuca/services/settings_service.dart';
import 'package:provider/provider.dart';
import '../test_helpers/prefs.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/models/download_models.dart';

import '../design/componentes/apoio.dart';

GrupoBaixado serie({
  VoidCallback? apagar,
  ValueChanged<int>? manter,
  VoidCallback? pausar,
  VoidCallback? retomar,
  int? escolha,
}) => GrupoBaixado(
  chave: 'casa:serie',
  titulo: 'Uma série',
  serie: true,
  bytes: 1024 * 1024,
  aoApagarVistos: apagar,
  aoManter: manter,
  manter: escolha,
  itens: [
    ItemBaixado(
      chave: 'casa:e1',
      titulo: 'Primeiro episódio',
      estado: EstadoDaBaixa.baixando,
      progresso: 42,
      aoPausar: pausar,
    ),
    ItemBaixado(chave: 'casa:e2', titulo: 'Segundo episódio', estado: EstadoDaBaixa.interrompido, aoRetomar: retomar),
  ],
);
final filme = GrupoBaixado(
  chave: 'casa:filme',
  titulo: 'Um filme',
  serie: false,
  bytes: 512,
  itens: [ItemBaixado(chave: 'casa:filme', titulo: 'Um filme', estado: EstadoDaBaixa.pronto, aoAssistir: () {})],
);

({String chave, MediaItem item, DownloadProgress progresso}) episodio(
  int n, {
  bool visto = false,
  int temporada = 1,
  DownloadStatus estado = DownloadStatus.completed,
}) => (
  chave: 'casa:$temporada-$n',
  item: MediaItem.plex(
    id: '$temporada-$n',
    kind: MediaKind.episode,
    title: 'Episódio $n',
    serverId: 'casa',
    grandparentId: 'serie',
    parentIndex: temporada,
    index: n,
    viewCount: visto ? 1 : 0,
  ),
  progresso: DownloadProgress(globalKey: 'casa:$temporada-$n', status: estado),
);

class _BaixadosDeTeste extends ChangeNotifier implements DownloadProvider {
  final dados = <String, MediaItem>{};
  final progresso = <String, DownloadProgress>{};
  final apagados = <String>[];
  Future<void> Function()? depoisDeApagar;

  void adicionar(int n, {bool visto = false}) {
    final baixa = episodio(n, visto: visto);
    dados[baixa.chave] = baixa.item;
    progresso[baixa.chave] = baixa.progresso;
  }

  @override
  Map<String, DownloadProgress> get downloads => Map.of(progresso);
  @override
  MediaItem? getMetadata(String chave) => dados[chave];
  @override
  DownloadProgress? getProgress(String chave) => progresso[chave];
  @override
  String? getArtworkLocalPath(ServerId id, String? caminho) => null;
  @override
  Future<void> ensureInitialized() async {}
  @override
  Future<void> deleteDownload(String chave) async {
    apagados.add(chave);
    progresso.remove(chave);
    notifyListeners();
    await depoisDeApagar?.call();
  }

  @override
  DownloadActivitySnapshot downloadActivitySnapshot() => (
    activeTasks: 0,
    completedTasks: progresso.length,
    failedTasks: 0,
    downloadedBytes: 123,
    progressUnits: 0,
    networkAvailable: false,
    networkStateGeneration: 0,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PerfisDeTeste extends ChangeNotifier implements ActiveProfileProvider {
  String id = 'perfil-1';
  @override
  String? get activeId => id;
  void trocar(String novo) {
    id = novo;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _ligacao(_BaixadosDeTeste baixados, _PerfisDeTeste perfis) => MultiProvider(
  providers: [
    ChangeNotifierProvider<DownloadProvider>.value(value: baixados),
    ChangeNotifierProvider<ActiveProfileProvider>.value(value: perfis),
  ],
  child: naTela(LigacaoDosBaixados(aoExplorar: () {})),
);

void main() {
  testWidgets('ligação apaga os vistos usando o provider', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste()
      ..adicionar(1, visto: true)
      ..adicionar(2);
    final perfis = _PerfisDeTeste();
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apagar vistos'));
    await tester.tap(find.text('Apagar vistos'));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-1']);
    expect(baixados.downloads.keys, ['casa:1-2']);
  });

  testWidgets('ligação grava Manter N e reaplica depois de remontar a tela', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste();
    for (var n = 1; n <= 4; n++) {
      baixados.adicionar(n);
    }
    final perfis = _PerfisDeTeste();
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Manter 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter 3'));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-4']);
    final preferencias = await SettingsService.getInstance();
    expect(preferencias.readInt('heisuca_v2_baixados_manter:perfil-1:casa:serie'), 3);
    await tester.pumpWidget(const SizedBox.shrink());
    baixados.adicionar(5);
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-4', 'casa:1-5']);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.selected == true), findsOneWidget);
    perfis.trocar('perfil-2');
    baixados.adicionar(6);
    baixados.notifyListeners();
    await tester.pumpAndSettle();
    expect(baixados.downloads.containsKey('casa:1-6'), isTrue);
  });

  testWidgets('callback da tela anterior não opera sobre outro perfil', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste()..adicionar(1, visto: true);
    final perfis = _PerfisDeTeste();
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    final apagarAnterior = tester.widget<TelaBaixados>(find.byType(TelaBaixados)).grupos.single.aoApagarVistos!;
    perfis.trocar('perfil-2');
    apagarAnterior();
    await tester.pumpAndSettle();
    expect(baixados.apagados, isEmpty);
  });

  testWidgets('trocar perfil durante a limpeza impede apagar os próximos itens', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste()
      ..adicionar(1, visto: true)
      ..adicionar(2, visto: true);
    final perfis = _PerfisDeTeste();
    baixados.depoisDeApagar = () async => perfis.trocar('perfil-2');
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apagar vistos'));
    await tester.tap(find.text('Apagar vistos'));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-1']);
  });

  for (final tema in [TemaHeisuca.shikkoku, TemaHeisuca.hisui, TemaHeisuca.sumi]) {
    testWidgets('${tema.nome}: vazio leva ao Explorar', (tester) async {
      var explorou = false;
      await tester.pumpWidget(
        naTela(
          TelaBaixados(grupos: const [], totalBytes: 0, aoExplorar: () => explorou = true),
          tema: tema,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nada baixado ainda'), findsOneWidget);
      expect(find.text('0 B em baixados no app'), findsOneWidget);
      await tester.tap(find.text('Explorar'));
      expect(explorou, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${tema.nome}: série, filme, espaço e progresso', (tester) async {
      await tester.pumpWidget(
        naTela(
          TelaBaixados(grupos: [serie(), filme], totalBytes: 1024 * 1024 + 512, aoExplorar: () {}),
          tema: tema,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Uma série'), findsOneWidget);
      expect(find.text('2 episódios'), findsOneWidget);
      expect(find.text('1,0 MB'), findsOneWidget);
      expect(find.text('42 %'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, .42);
      expect(find.byType(FundoTingido), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Um filme'), 250);
      expect(find.text('Um filme'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pausar, retomar, apagar vistos e escolher 1, 3 ou 5', (tester) async {
    var pausas = 0;
    var retomadas = 0;
    var limpezas = 0;
    final escolhas = <int>[];
    await tester.pumpWidget(
      naTela(
        TelaBaixados(
          grupos: [
            serie(pausar: () => pausas++, retomar: () => retomadas++, apagar: () => limpezas++, manter: escolhas.add),
          ],
          totalBytes: 0,
          aoExplorar: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar'));
    await tester.tap(find.text('Retomar'));
    await tester.ensureVisible(find.text('Apagar vistos'));
    await tester.tap(find.text('Apagar vistos'));
    for (final n in [1, 3, 5]) {
      await tester.ensureVisible(find.text('Manter $n'));
      await tester.tap(find.text('Manter $n'));
    }
    expect(pausas, 1);
    expect(retomadas, 1);
    expect(limpezas, 1);
    expect(escolhas, [1, 3, 5]);
  });

  testWidgets('pausado também oferece Retomar', (tester) async {
    var retomou = false;
    await tester.pumpWidget(
      naTela(
        TelaBaixados(
          grupos: [
            GrupoBaixado(
              chave: 'f',
              titulo: 'Filme',
              serie: false,
              bytes: 0,
              itens: [
                ItemBaixado(
                  chave: 'f',
                  titulo: 'Filme',
                  estado: EstadoDaBaixa.pausado,
                  aoRetomar: () => retomou = true,
                ),
              ],
            ),
          ],
          totalBytes: 0,
          aoExplorar: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retomar'));
    expect(retomou, isTrue);
  });

  testWidgets('letra 200 %, largura de celular e remover animações', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      naTela(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: TelaBaixados(
              grupos: [
                serie(escolha: 3, manter: (_) {}),
                filme,
              ],
              totalBytes: 123,
              aoExplorar: () {},
            ),
          ),
        ),
        semAnimacao: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manter 5'), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('área mínima de 48 e semântica de botão e seleção', (tester) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      naTela(
        TelaBaixados(
          grupos: [serie(escolha: 3, manter: (_) {}, pausar: () {}, retomar: () {}, apagar: () {})],
          totalBytes: 0,
          aoExplorar: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final toque in find.byType(Toque).evaluate()) {
      final tamanho = tester.getSize(find.byWidget(toque.widget));
      expect(tamanho.width, greaterThanOrEqualTo(48));
      expect(tamanho.height, greaterThanOrEqualTo(48));
    }
    expect(find.byType(Botao), findsNWidgets(6));
    expect(
      tester.getSemantics(find.text('Retomar')),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Retomar',
      ),
    );
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.selected == true), findsOneWidget);
    semantica.dispose();
  });

  test('apagar vistos só seleciona episódios vistos e completos', () {
    expect(
      baixasParaApagar([
        episodio(1, visto: true),
        episodio(2),
        episodio(3, visto: true, estado: DownloadStatus.downloading),
      ]),
      ['casa:1-1'],
    );
  });

  for (final n in [1, 3, 5]) {
    test('manter $n em ordem de temporada e episódio; vistos não contam', () {
      final itens = [episodio(1, temporada: 2), for (var i = 6; i >= 1; i--) episodio(i), episodio(0, visto: true)];
      expect(baixasParaApagar(itens, manter: n), [
        'casa:1-0',
        for (var i = n + 1; i <= 6; i++) 'casa:1-$i',
        'casa:2-1',
      ]);
    });
  }

  test('manter N preserva baixa em andamento e usa sua posição na fila', () {
    expect(baixasParaApagar([episodio(1, estado: DownloadStatus.downloading), episodio(2), episodio(3)], manter: 1), [
      'casa:1-2',
      'casa:1-3',
    ]);
  });

  test('séries agrupam por servidor; filmes e metadados ausentes ficam separados', () {
    final item = episodio(1).item;
    expect(grupoDaBaixa('casa:e1', item), 'casa:serie');
    expect(grupoDaBaixa('outra:e1', item.copyWith(serverId: 'outra')), 'outra:serie');
    expect(grupoDaBaixa('casa:f', MediaItem.plex(id: 'f', kind: MediaKind.movie)), 'casa:f');
    expect(grupoDaBaixa('casa:sem', null), 'casa:sem');
  });
}
