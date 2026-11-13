import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/providers/download_provider.dart';
import 'package:heisuca/providers/offline_watch_provider.dart';
import 'package:heisuca/services/download_manager_service.dart';
import 'package:heisuca/services/download_storage_service.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/offline_watch_sync_service.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/services/watch_actions.dart';
import 'package:provider/provider.dart';

/// A marcação de "visto" sem conexão pertence ao perfil que tocou, mesmo quando a gravação roda depois.
void main() {
  late AppDatabase banco;
  late MultiServerManager gerente;
  late OfflineWatchSyncService fila;
  late DownloadManagerService baixador;
  late DownloadProvider baixados;
  late OfflineWatchProvider semConexao;

  final item = MediaItem(
    id: 'filme-1',
    backend: MediaBackend.jellyfin,
    kind: MediaKind.movie,
    title: 'Título',
    serverId: 'casa',
  );

  Future<BuildContext> montar(WidgetTester tester) async {
    await tester.runAsync(() async {
      banco = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(banco);
      gerente = MultiServerManager();
      fila = OfflineWatchSyncService(database: banco, serverManager: gerente);
      baixador = DownloadManagerService(
        database: banco,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
      );
      baixador.recoveryFuture = Future<void>.value();
      baixados = DownloadProvider.forTesting(downloadManager: baixador, database: banco);
      await baixados.ensureInitialized();
      semConexao = OfflineWatchProvider(syncService: fila, downloadProvider: baixados);
    });
    late BuildContext contexto;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: semConexao,
        child: Builder(
          builder: (context) {
            contexto = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return contexto;
  }

  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      semConexao.dispose();
      baixados.dispose();
      baixador.dispose();
      fila.dispose();
      gerente.dispose();
      await banco.close();
    });
  }

  testWidgets('gravação preparada no perfil A e executada com o B ativo é recusada e não grava em nenhum dos dois', (
    tester,
  ) async {
    final contexto = await montar(tester);
    fila.setActiveProfileId('perfil-a');
    final gravar = WatchActions.prepare(contexto, item, offline: true);

    // O perfil muda enquanto a gravação espera a vez dela.
    fila.setActiveProfileId('perfil-b');

    Object? erro;
    await tester.runAsync(() async {
      try {
        await gravar(watched: true);
      } catch (e) {
        erro = e;
      }
    });

    expect(erro, isStateError);
    await tester.runAsync(() async {
      expect(await banco.getPendingWatchActions(profileId: 'perfil-b'), isEmpty);
      expect(await banco.getPendingWatchActions(profileId: 'perfil-a'), isEmpty);
    });
    await desmontar(tester);
  });

  testWidgets('sem troca de perfil, a gravação preparada entra na fila do perfil que tocou', (tester) async {
    final contexto = await montar(tester);
    fila.setActiveProfileId('perfil-a');
    final gravar = WatchActions.prepare(contexto, item, offline: true);

    WatchMarkOutcome? resultado;
    await tester.runAsync(() async {
      resultado = await gravar(watched: true);
    });

    expect(resultado, WatchMarkOutcome.queuedOffline);
    await tester.runAsync(() async {
      final pendentes = await banco.getPendingWatchActions(profileId: 'perfil-a');
      expect(pendentes, hasLength(1));
      expect(pendentes.single.ratingKey, 'filme-1');
      expect(pendentes.single.actionType, 'watched');
      expect(await banco.getPendingWatchActions(profileId: 'perfil-b'), isEmpty);
    });
    await desmontar(tester);
  });
}
