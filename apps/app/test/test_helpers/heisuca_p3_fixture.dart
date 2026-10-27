import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/connection/connection.dart';
import 'package:heisuca/connection/connection_registry.dart';
import 'package:heisuca/database/app_database.dart';
import 'package:heisuca/focus/input_mode_tracker.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/navigation/main_screen_scope.dart';
import 'package:heisuca/providers/discover_provider.dart';
import 'package:heisuca/providers/download_provider.dart';
import 'package:heisuca/providers/hidden_libraries_provider.dart';
import 'package:heisuca/providers/libraries_provider.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/providers/theme_provider.dart';
import 'package:heisuca/providers/account_preferences_controller.dart';
import 'package:heisuca/providers/seerr_account_provider.dart';
import 'package:heisuca/providers/trackers_provider.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile.dart';
import 'package:heisuca/profiles/profile_connection.dart';

import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/services/download_manager_service.dart';
import 'package:heisuca/services/download_storage_service.dart';
import 'package:heisuca/services/jellyfin_api_cache.dart';
import 'package:heisuca/services/plex_api_cache.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/music/music_playback_service.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/widgets/overlay_sheet.dart';
import 'backend_client_fixtures.dart';
import 'http_fixtures.dart';
import 'io_fakes.dart';
import 'stub_music_playback_service.dart';

class _Registry extends ConnectionRegistry {
  _Registry(super.db);
  @override Stream<List<Connection>> watchConnections() => Stream.value(const []);
}
class _Discover extends ChangeNotifier implements DiscoverProvider {
  @override Future<void> load() async {}
  @override List<MediaItem> get onDeck => const [];
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles extends ChangeNotifier implements ActiveProfileProvider {
  final family = Profile.local(id: 'familia', displayName: 'Família', createdAt: DateTime.utc(2026));
  @override Profile get active => family;
  @override String get activeId => family.id;
  @override List<Profile> get profiles => [family];
  @override bool get isBinding => false;
  @override bool get isInitialized => true;
  @override bool get hasMultipleProfiles => false;
  @override String? avatarUrlFor(String profileId) => null;
  @override Map<String, Connection> get connectionsById => const {};
  @override Map<String, List<ProfileConnection>> get connectionsByProfile => const {};
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Dados locais determinísticos nas TELAS REAIS, sem conta/servidor reais.
/// Não comprova rede, vídeo nativo, downloads nem revisão física.
class HeisucaP3Fixture {
  HeisucaP3Fixture({this.scenario = 'normal'});
  final String scenario;
  final _pendingResponses = <Completer<http.Response>>[];
  bool _released = false;

  void releasePendingResponses() {
    _released = true;
    for (final response in _pendingResponses) {
      if (!response.isCompleted) response.complete(jsonResponse({'Items': [], 'TotalRecordCount': 0}));
    }
    _pendingResponses.clear();
  }
  late final Directory temporary;
  late final PathProviderPlatform originalPaths;
  late final AppDatabase db;
  late final MultiServerManager manager;
  late final MultiServerProvider servers;
  late final HiddenLibrariesProvider hidden;
  late final LibrariesProvider libraries;
  late final DownloadManagerService downloadsManager;
  late final DownloadProvider downloads;
  late final ThemeProvider theme;
  late final _Discover discover;
  late final StubMusicPlaybackService music;
  late final _Registry registry;
  late final _Profiles profiles;
  late final SeerrAccountProvider seerr;
  late final TrackersProvider trackers;
  late final AccountPreferencesController accounts;

  final movie = MediaItem.jellyfin(id: 'filme', serverId: 'srv-1', kind: MediaKind.movie,
      title: 'Uma viagem para lembrar', year: 2026, summary: 'Uma história para assistir em família.',
      durationMs: 5400000, rating: 8.2);
  final show = MediaItem.jellyfin(id: 'serie', serverId: 'srv-1', kind: MediaKind.show,
      title: 'Histórias da nossa família', summary: 'Um novo capítulo a cada encontro.', year: 2026);

  Future<void> initialize(settings.ThemeMode mode) async {
    temporary = Directory.systemTemp.createTempSync('heisuca-p3-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(temporary);
    final service = await settings.SettingsService.getInstance();
    await service.write(settings.SettingsService.themeMode, mode);
    await service.write(settings.SettingsService.hideSpoilers, false);
    DownloadStorageService.resetForTesting();
    await DownloadStorageService.instance.initialize(service);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    PlexApiCache.initialize(db);
    manager = MultiServerManager();
    final client = testJellyfinClient(connection: testJellyfinConnection(serverName: 'Acervo da família'), handler: (request) async {
      final path = request.url.path;
      if (scenario == 'erro') return jsonResponse({'Message': 'Falha do servidor de teste'}, status: 500);
      if (scenario == 'vazio') return jsonResponse(path.endsWith('/Latest') ? [] : {'Items': [], 'TotalRecordCount': 0});
      if (scenario == 'carregando' && !_released && path.endsWith('/Items')) {
        final pending = Completer<http.Response>();
        _pendingResponses.add(pending);
        return pending.future;
      }
      final parent = request.url.queryParameters['ParentId'] ?? request.url.queryParameters['parentId'];
      final rawMovie = {'Id': 'filme', 'Name': movie.title, 'Type': 'Movie', 'ProductionYear': 2026,
        'Overview': movie.summary, 'CommunityRating': 8.2, 'RunTimeTicks': 54000000000,
        'ImageTags': <String, String>{}, 'UserData': {'Played': false},
        'MediaSources': [{'Id': 'arquivo', 'Container': 'mkv', 'MediaStreams': [
          {'Type': 'Video', 'Index': 0, 'Codec': 'h264', 'Width': 1920, 'Height': 1080},
          {'Type': 'Audio', 'Index': 1, 'Codec': 'aac', 'Language': 'por', 'Channels': 2}]}]};
      final rawShow = {'Id': 'serie', 'Name': show.title, 'Type': 'Series', 'Overview': show.summary,
        'ProductionYear': 2026, 'ChildCount': 1, 'ImageTags': <String, String>{}};
      final season = {'Id': 'temporada', 'Name': 'Temporada 1', 'Type': 'Season', 'IndexNumber': 1,
        'SeriesId': 'serie', 'SeriesName': show.title, 'ChildCount': 3};
      if (path.endsWith('/Views')) return jsonResponse({'Items': [
        {'Id': 'filmes', 'Name': 'Filmes', 'Type': 'CollectionFolder', 'CollectionType': 'movies'},
        {'Id': 'series', 'Name': 'Séries', 'Type': 'CollectionFolder', 'CollectionType': 'tvshows'}]});
      if (path.contains('/cgflix/')) return jsonResponse({});
      if (path.endsWith('/Items/filme')) return jsonResponse(rawMovie);
      if (path.endsWith('/Items/serie')) return jsonResponse(rawShow);
      if (path.endsWith('/Items/temporada')) return jsonResponse(season);
      if (parent == 'serie') return jsonResponse({'Items': [season]});
      if (parent == 'temporada') return jsonResponse({'Items': [for (var n = 1; n <= 3; n++)
        {'Id': 'episodio$n', 'Name': 'Um encontro para lembrar $n', 'Type': 'Episode', 'IndexNumber': n,
          'ParentIndexNumber': 1, 'SeriesId': 'serie', 'SeriesName': show.title, 'ParentId': 'temporada',
          'RunTimeTicks': 18000000000}]});
      if (path.endsWith('/Latest')) return jsonResponse([parent == 'series' ? rawShow : rawMovie]);
      if (path.contains('Resume') || path.contains('NextUp') || path.contains('Upcoming') || path.contains('Ancestors')) {
        return jsonResponse({'Items': []});
      }
      if (path.endsWith('/Items')) return jsonResponse({'Items': [parent == 'series' ? rawShow : rawMovie], 'TotalRecordCount': 1});
      return jsonResponse({'Items': []});
    });
    manager.debugRegisterClientForTesting(client, online: scenario != 'offline');
    manager.setNavigationSource(this, 'srv-1');
    final aggregation = DataAggregationService(manager);
    servers = MultiServerProvider(manager, aggregation);
    servers.setExpectedVisibleServerIds({'srv-1'});
    servers.setVisibleServerIds({'srv-1'});
    hidden = HiddenLibrariesProvider();
    await hidden.ensureInitialized();
    libraries = LibrariesProvider()..initialize(aggregation);
    await libraries.loadLibraries();
    downloadsManager = DownloadManagerService(database: db, storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null);
    downloads = DownloadProvider.forTesting(downloadManager: downloadsManager, database: db);
    await downloads.ensureInitialized();
    theme = ThemeProvider();
    discover = _Discover();
    music = StubMusicPlaybackService();
    registry = _Registry(db);
    profiles = _Profiles();
    seerr = SeerrAccountProvider();
    trackers = TrackersProvider();
    accounts = AccountPreferencesController();
  }

  Widget wrap(Widget child) => InputModeTracker(child: MultiProvider(providers: [
    ChangeNotifierProvider<ThemeProvider>.value(value: theme),
    ChangeNotifierProvider<MultiServerProvider>.value(value: servers),
    ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hidden),
    ChangeNotifierProvider<LibrariesProvider>.value(value: libraries),
    ChangeNotifierProvider<DiscoverProvider>.value(value: discover),
    ChangeNotifierProvider<DownloadProvider>.value(value: downloads),
    ChangeNotifierProvider<MusicPlaybackService>.value(value: music),
    Provider<ConnectionRegistry>.value(value: registry),
    ChangeNotifierProvider<ActiveProfileProvider>.value(value: profiles),
    ChangeNotifierProvider<SeerrAccountProvider>.value(value: seerr),
    ChangeNotifierProvider<TrackersProvider>.value(value: trackers),
    ChangeNotifierProvider<AccountPreferencesController>.value(value: accounts),
  ], child: TranslationProvider(child: child)));

  Widget scope(Widget child) => MainScreenFocusScope(focusSidebar: () {}, sideNavigationWidth: 0,
      child: OverlaySheetHost(child: child));

  Future<void> dispose() async {
    releasePendingResponses();
    accounts.dispose();
    profiles.dispose();
    seerr.dispose();
    trackers.dispose();
    theme.dispose();
    discover.dispose();
    hidden.dispose();
    libraries.dispose();
    downloads.dispose();
    downloadsManager.dispose();
    servers.dispose();
    music.dispose();
    manager.dispose();
    await db.close();
    DownloadStorageService.resetForTesting();
    PathProviderPlatform.instance = originalPaths;
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  }
}
