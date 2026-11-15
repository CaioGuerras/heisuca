import 'dart:async';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:drift/native.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/services/download_manager_service.dart';
import 'package:heisuca/services/download_storage_service.dart';
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
  ValueChanged<int?>? manter,
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
    grandparentTitle: 'Nome da série',
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
  Future<void>? inicializacao;
  bool falharAoApagar = false;

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
  Future<void> ensureInitialized() async {
    await inicializacao;
  }

  @override
  Future<void> deleteDownload(String chave) async {
    apagados.add(chave);
    if (falharAoApagar) throw StateError('falha simulada ao apagar');
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

Widget _ligacao(DownloadProvider baixados, _PerfisDeTeste perfis) => MultiProvider(
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
    await tester.scrollUntilVisible(find.text('Apagar vistos'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar vistos'));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-1']);
    expect(baixados.downloads.keys, ['casa:1-2']);
  });

  testWidgets('Manter N pede confirmação; remontar nunca apaga não vistos', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste();
    for (var n = 1; n <= 4; n++) {
      baixados.adicionar(n);
    }
    final perfis = _PerfisDeTeste();
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manter 3'), 150);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter 3'));
    await tester.pumpAndSettle();
    expect(baixados.apagados, isEmpty);
    expect(find.text('Apagar 1 episódio ainda não visto?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    final preferencias = await SettingsService.getInstance();
    expect(preferencias.readInt('heisuca_v2_baixados_manter:perfil-1:casa:serie'), 3);
    await tester.pumpWidget(const SizedBox.shrink());
    baixados.adicionar(5);
    baixados.adicionar(7, visto: true);
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-7']);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.selected == true), findsOneWidget);
    perfis.trocar('perfil-2');
    baixados.adicionar(6);
    baixados.notifyListeners();
    await tester.pumpAndSettle();
    expect(baixados.downloads.containsKey('casa:1-6'), isTrue);
  });

  testWidgets('limpeza automática só roda de novo quando o conjunto de vistos muda', (tester) async {
    resetSharedPreferencesForTest();
    final preferencias = await SettingsService.getInstance();
    await preferencias.writeInt('heisuca_v2_baixados_manter:perfil-1:casa:serie', 3);
    final baixados = _BaixadosDeTeste()
      ..adicionar(1, visto: true)
      ..adicionar(2)
      ..falharAoApagar = true;
    final perfis = _PerfisDeTeste();
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-1']);
    // Avisos de progresso repetidos não disparam nova tentativa sobre o mesmo conjunto.
    for (var i = 0; i < 5; i++) {
      baixados.notifyListeners();
      await tester.pumpAndSettle();
    }
    expect(baixados.apagados, ['casa:1-1']);
    // Um episódio visto novo muda o conjunto: a limpeza roda de novo.
    baixados
      ..falharAoApagar = false
      ..adicionar(3, visto: true)
      ..notifyListeners();
    await tester.pumpAndSettle();
    expect(baixados.downloads.keys, ['casa:1-2']);
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
    await tester.scrollUntilVisible(find.text('Apagar vistos'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar vistos'));
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-1']);
  });

  testWidgets('ligação usa nome da série e ordena temporada e episódio', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste();
    for (final baixa in [episodio(1, temporada: 2), episodio(3), episodio(1)]) {
      baixados.dados[baixa.chave] = baixa.item;
      baixados.progresso[baixa.chave] = baixa.progresso;
    }
    await tester.pumpWidget(_ligacao(baixados, _PerfisDeTeste()));
    await tester.pumpAndSettle();
    final grupo = tester.widget<TelaBaixados>(find.byType(TelaBaixados)).grupos.single;
    expect(grupo.titulo, 'Nome da série');
    expect(grupo.itens.map((i) => i.chave), ['casa:1-1', 'casa:1-3', 'casa:2-1']);
    final semantica = tester.ensureSemantics();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Nome da série')), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.image == true && w.properties.label == 'Nome da série',
      ),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('Manter N apaga só o conjunto confirmado; novas notificações preservam não vistos', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste();
    for (var n = 1; n <= 5; n++) {
      baixados.adicionar(n);
    }
    await tester.pumpWidget(_ligacao(baixados, _PerfisDeTeste()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manter 3'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter 3'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar 2 episódios ainda não vistos?'), findsOneWidget);
    expect(baixados.apagados, isEmpty);
    baixados.adicionar(6);
    baixados.notifyListeners();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-4', 'casa:1-5']);
    baixados.adicionar(7, visto: true);
    baixados.notifyListeners();
    await tester.pumpAndSettle();
    expect(baixados.apagados, ['casa:1-4', 'casa:1-5', 'casa:1-7']);
    expect(baixados.downloads.containsKey('casa:1-6'), isTrue);
    await tester.scrollUntilVisible(find.text('Não limpar'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não limpar'));
    await tester.pumpAndSettle();
    final prefs = await SettingsService.getInstance();
    expect(prefs.prefs.containsKey('heisuca_v2_baixados_manter:perfil-1:casa:serie'), isFalse);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.selected == true &&
            w.child is Botao &&
            (w.child as Botao).rotulo == 'Não limpar',
      ),
      findsOneWidget,
    );
    baixados.adicionar(8, visto: true);
    baixados.notifyListeners();
    await tester.pumpAndSettle();
    expect(baixados.apagados, isNot(contains('casa:1-8')));
  });

  for (final ehFilme in [false, true]) {
    testWidgets('apagar avulso com confirmação: filme=$ehFilme', (tester) async {
      resetSharedPreferencesForTest();
      final baixados = _BaixadosDeTeste()..adicionar(1);
      if (ehFilme) {
        baixados.dados['casa:1-1'] = MediaItem.plex(
          id: '1-1',
          serverId: 'casa',
          kind: MediaKind.movie,
          title: 'Um filme',
        );
      }
      await tester.pumpWidget(_ligacao(baixados, _PerfisDeTeste()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Apagar').first, 150);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').first);
      await tester.pumpAndSettle();
      expect(baixados.apagados, isEmpty);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(baixados.apagados, isEmpty);
      await tester.tap(find.text('Apagar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').last);
      await tester.pumpAndSettle();
      expect(baixados.apagados, ['casa:1-1']);
    });
  }

  testWidgets('troca de perfil durante confirmação não apaga', (tester) async {
    resetSharedPreferencesForTest();
    final baixados = _BaixadosDeTeste()
      ..adicionar(1)
      ..adicionar(2);
    final perfis = _PerfisDeTeste();
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manter 1'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter 1'));
    await tester.pumpAndSettle();
    perfis.trocar('perfil-2');
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();
    expect(baixados.apagados, isEmpty);
  });

  testWidgets('provider real: regra no perfil seguinte não toca downloads do anterior', (tester) async {
    resetSharedPreferencesForTest();
    late AppDatabase banco;
    late DownloadManagerService gerente;
    late DownloadProvider baixados;
    final perfis = _PerfisDeTeste();
    final baixa = episodio(1, visto: true);
    await tester.runAsync(() async {
      banco = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(banco);
      gerente = DownloadManagerService(
        database: banco,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
      );
      gerente.recoveryFuture = Future<void>.value();
      baixados = DownloadProvider.forTesting(downloadManager: gerente, database: banco, activeProfileId: 'perfil-1');
      await baixados.ensureInitialized();
      baixados.debugSeedState(downloads: {baixa.chave: baixa.progresso}, metadata: {baixa.chave: baixa.item});
      final prefs = await SettingsService.getInstance();
      await prefs.writeInt('heisuca_v2_baixados_manter:perfil-2:casa:serie', 1);
    });
    await tester.pumpWidget(_ligacao(baixados, perfis));
    await tester.pumpAndSettle();
    expect(baixados.downloads.keys, [baixa.chave]);
    await tester.runAsync(() async {
      baixados.setActiveProfileId('perfil-2');
      final recarregado = Completer<void>();
      void concluiu() {
        if (!recarregado.isCompleted) recarregado.complete();
      }

      baixados.addListener(concluiu);
      perfis.trocar('perfil-2');
      await recarregado.future;
      baixados.removeListener(concluiu);
    });
    await tester.pumpAndSettle();
    expect(baixados.downloads, isEmpty);
    expect(find.text('Nada baixado ainda'), findsOneWidget);
    // Voltar ao conjunto do primeiro perfil prova que o progresso não foi apagado (deleteDownload o remove).
    baixados.debugSeedState(ownedDownloadKeys: {baixa.chave}, metadata: {baixa.chave: baixa.item});
    expect(baixados.downloads.keys, [baixa.chave]);
    expect(baixados.getProgress(baixa.chave)?.status, DownloadStatus.completed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      baixados.dispose();
      gerente.dispose();
      await banco.close();
    });
  });

  testWidgets('carregando não desenha grupos parciais', (tester) async {
    await tester.pumpWidget(
      naTela(TelaBaixados(grupos: [serie(), filme], totalBytes: 123, aoExplorar: () {}, carregando: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carregando seus baixados…'), findsOneWidget);
    expect(find.text('Uma série'), findsNothing);
    expect(find.text('Um filme'), findsNothing);
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
    final escolhas = <int?>[];
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
    await tester.scrollUntilVisible(find.text('Apagar vistos'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar vistos'));
    for (final n in [1, 3, 5]) {
      await tester.scrollUntilVisible(find.text('Manter $n'), 150);
      await tester.pumpAndSettle();
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
    await tester.scrollUntilVisible(find.text('Um filme'), 200);
    await tester.scrollUntilVisible(find.text('Apagar').last, 200);
    expect(find.text('Um filme'), findsOneWidget);
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
    expect(find.byType(Botao), findsNWidgets(9));
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

  test('manter N conta somente completos não vistos', () {
    expect(
      baixasParaApagar([
        episodio(0, estado: DownloadStatus.queued),
        episodio(1, estado: DownloadStatus.downloading),
        episodio(2),
        episodio(3),
        episodio(4, estado: DownloadStatus.failed),
      ], manter: 1),
      ['casa:1-3'],
    );
  });

  test('séries agrupam por servidor; filmes e metadados ausentes ficam separados', () {
    final item = episodio(1).item;
    expect(grupoDaBaixa('casa:e1', item), 'casa:serie');
    expect(grupoDaBaixa('outra:e1', item.copyWith(serverId: 'outra')), 'outra:serie');
    expect(grupoDaBaixa('casa:f', MediaItem.plex(id: 'f', kind: MediaKind.movie)), 'casa:f');
    expect(grupoDaBaixa('casa:sem', null), 'casa:sem');
  });
}
