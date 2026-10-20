// Dados da Início do CGFLIX: cada linha vem do cache do aparelho na hora (a Início abre
// rápido) e depois é atualizada pela rede, sem bloquear a tela. Um arquivo por servidor
// e usuário na pasta de suporte do app.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../media/media_item.dart';
import '../../media/media_library.dart';
import '../../services/jellyfin_client.dart';
import '../../utils/app_logger.dart';
import 'cgflix_home_logic.dart';

/// Uma linha pronta para a tela.
class CgflixRowData {
  const CgflixRowData({required this.items, this.title, this.fromCache = false});
  final List<MediaItem> items;

  /// Título vindo do servidor (só o "Em alta" usa).
  final String? title;
  final bool fromCache;
}

class CgflixHomeRepository {
  CgflixHomeRepository(this.client, {Future<Directory> Function()? cacheDir})
    : _cacheDir = cacheDir ?? getApplicationSupportDirectory;

  final JellyfinClient client;
  final Future<Directory> Function() _cacheDir;

  Map<String, dynamic>? _cache;

  /// Linhas já buscadas nesta sessão: rolar para longe e voltar não vai à rede de novo.
  final _memory = <String, ({CgflixRowData data, DateTime at})>{};
  static const _memoryTtl = Duration(minutes: 10);

  /// "Puxar para atualizar": esquece a memória (o cache em disco continua valendo
  /// para a tela não ficar vazia enquanto a rede responde).
  void forgetMemory() {
    _memory.clear();
    _continueMemory.clear();
  }

  Future<void>? _cacheLoad;
  Timer? _saveTimer;

  String get _fileName {
    final raw = '${client.serverId.value}_${client.cgflixUserId}';
    return 'home_${raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.json';
  }

  Future<File> _file() async {
    final dir = Directory('${(await _cacheDir()).path}/cgflix');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  Future<void> _ensureCache() => _cacheLoad ??= () async {
    try {
      final file = await _file();
      if (file.existsSync()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) _cache = decoded;
      }
    } catch (e) {
      appLogger.w('CGFLIX: cache da Início ilegível, começando do zero', error: e);
    }
    _cache ??= <String, dynamic>{};
  }();

  ({List<Map<String, dynamic>> raw, DateTime savedAt, String? title})? _cached(String key) {
    final entry = _cache?[key];
    if (entry is! Map) return null;
    final items = entry['items'];
    final savedAt = DateTime.tryParse('${entry['savedAt']}');
    if (items is! List || savedAt == null) return null;
    return (raw: items.whereType<Map<String, dynamic>>().toList(), savedAt: savedAt, title: entry['title'] as String?);
  }

  void _store(String key, List<Map<String, dynamic>> raw, {String? title}) {
    _cache?[key] = {'savedAt': DateTime.now().toIso8601String(), 'title': ?title, 'items': raw};
    _saveTimer?.cancel();
    // Junta as gravações das linhas que chegam quase juntas numa só escrita.
    _saveTimer = Timer(const Duration(seconds: 2), () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    final cache = _cache;
    if (cache == null) return;
    try {
      await (await _file()).writeAsString(jsonEncode(cache), flush: true);
    } catch (e) {
      appLogger.w('CGFLIX: não deu para salvar o cache da Início', error: e);
    }
  }

  /// Última gravação pedida pelo [dispose] (os testes esperam por ela antes de apagar a pasta).
  Future<void> _lastFlush = Future<void>.value();
  Future<void> get flushed => _lastFlush;

  void dispose() {
    _saveTimer?.cancel();
    _lastFlush = _flush();
    unawaited(_lastFlush);
  }

  /// Tempo máximo de uma linha da Início na rede.
  static const cgflixRowTimeout = Duration(seconds: 30);

  /// Cache primeiro (se houver), depois a rede. Se a rede falhar e havia cache, fica o cache.
  /// [maxAge]: se o cache for mais novo que isso, nem vai à rede.
  Stream<CgflixRowData> _cachedThenNetwork(
    String key,
    Future<({List<Map<String, dynamic>> raw, String? title})> Function() fetch, {
    Duration? maxAge,
  }) async* {
    final remembered = _memory[key];
    if (remembered != null && DateTime.now().difference(remembered.at) < _memoryTtl) {
      yield remembered.data;
      return;
    }
    await _ensureCache();
    final cached = _cached(key);
    if (cached != null && cached.raw.isNotEmpty) {
      yield CgflixRowData(items: client.cgflixMapItems(cached.raw), title: cached.title, fromCache: true);
      if (maxAge != null && DateTime.now().difference(cached.savedAt) < maxAge) return;
    }
    try {
      // Teto de espera: sem ele, servidor que aceita a conexão e não responde deixava a linha
      // no esqueleto para sempre.
      final fresh = await fetch().timeout(cgflixRowTimeout);
      _store(key, fresh.raw, title: fresh.title);
      final data = CgflixRowData(items: client.cgflixMapItems(fresh.raw), title: fresh.title);
      _memory[key] = (data: data, at: DateTime.now());
      yield data;
    } catch (e) {
      appLogger.w('CGFLIX: linha "$key" falhou', error: e);
      // Nada foi mostrado ainda (sem cache, ou cache salvo vazio): emite vazio para a linha sair
      // do esqueleto (some). Antes, cache vazio + rede fora = esqueleto para sempre.
      if (cached == null || cached.raw.isEmpty) yield const CgflixRowData(items: []);
    }
  }

  /// Linha de consulta direta (Lançamentos, Novidades, gêneros...). Com [filter] (chip ativo),
  /// só da biblioteca escolhida; linha sem sentido para ela devolve vazio (some).
  Stream<CgflixRowData> watchRow(CgflixRowKind kind, {String? genre, CgflixHomeFilter? filter}) {
    final query = cgflixRowQuery(kind, genre: genre, filter: filter);
    if (query == null) return Stream.value(const CgflixRowData(items: []));
    final key = '${genre == null ? kind.name : '${kind.name}:$genre'}${filter?.cacheSuffix ?? ''}';
    return _cachedThenNetwork(key, () async => (raw: await client.cgflixFetchRawItems(query), title: null));
  }

  /// Destaque do topo.
  Stream<CgflixRowData> watchHero({CgflixHomeFilter? filter}) => _cachedThenNetwork(
    'hero${filter?.cacheSuffix ?? ''}',
    () async => (raw: await client.cgflixFetchRawItems(cgflixHeroQuery(filter: filter)), title: null),
    maxAge: const Duration(minutes: 30),
  );

  /// Em alta no Brasil: emalta.json do servidor; se falhar, a coleção "Em alta no Brasil";
  /// se nenhum, linha vazia (some). Vale por 1 h no aparelho. Com [filter], o ranking da
  /// própria categoria (ver [CgflixTrending.idsFor]); com menos de 3 títulos, some.
  Stream<CgflixRowData> watchTrending({CgflixHomeFilter? filter}) => _cachedThenNetwork(
    'trending${filter?.cacheSuffix ?? ''}',
    filter == null ? _fetchTrending : () => _fetchTrendingIn(filter),
    maxAge: cgflixTrendingCacheTtl,
  );

  static const _noRow = (raw: <Map<String, dynamic>>[], title: null);

  Future<CgflixTrending?> _readTrending() async {
    try {
      return CgflixTrending.parse(await client.cgflixGetJson(cgflixTrendingPath));
    } catch (e) {
      appLogger.i('CGFLIX: emalta.json indisponível', error: e);
      return null;
    }
  }

  /// Etapa 1E: antes o filtro pedia `Ids` + `ParentId`, mas o Jellyfin ignora o `ParentId`
  /// quando recebe `Ids`, e o tipo "Series" serve para Séries e Animes: Animes mostrava as
  /// séries em alta. Agora a categoria vem do próprio ranking, nunca do tipo do item.
  Future<({List<Map<String, dynamic>> raw, String? title})> _fetchTrendingIn(CgflixHomeFilter filter) async {
    final trending = await _readTrending();
    if (trending == null) {
      // Sem o arquivo: só Filmes ainda dá para separar (pela coleção, só os filmes).
      if (!filter.isMovies) return _noRow;
      final fallback = await _fetchTrendingCollection();
      final movies = fallback.raw.where((r) => r['Type'] == 'Movie').toList();
      return movies.length < cgflixTrendingMinItems ? _noRow : (raw: movies, title: fallback.title);
    }
    final ids = trending.idsFor(filter.kind);
    if (ids == null) return _noRow;
    final raw = await client.cgflixFetchRawItems({'Ids': ids.join(','), 'Limit': '${ids.length}'});
    // Filme é sempre "Movie"; Séries e Animes são sempre "Series" (o ranking já separou as duas).
    final ofType = raw.where((r) => r['Type'] == filter.itemType).toList();
    final ordered = cgflixOrderByIds(ofType, ids, (r) => '${r['Id']}');
    return ordered.length < cgflixTrendingMinItems ? _noRow : (raw: ordered, title: trending.title);
  }

  Future<({List<Map<String, dynamic>> raw, String? title})> _fetchTrending() async {
    final trending = await _readTrending();
    if (trending != null && trending.ids.isNotEmpty) {
      final raw = await client.cgflixFetchRawItems({'Ids': trending.ids.join(','), 'Limit': '${trending.ids.length}'});
      final ordered = cgflixOrderByIds(raw, trending.ids, (r) => '${r['Id']}');
      if (ordered.isNotEmpty) return (raw: ordered, title: trending.title);
    }
    return _fetchTrendingCollection();
  }

  /// Plano B: coleção do Jellyfin chamada "Em alta no Brasil".
  Future<({List<Map<String, dynamic>> raw, String? title})> _fetchTrendingCollection() async {
    final collections = await client.cgflixFetchRawItems({
      'IncludeItemTypes': 'BoxSet',
      'SearchTerm': cgflixTrendingTitle,
      'Limit': '5',
    });
    final match = collections.where((c) => cgflixNormalize('${c['Name']}') == cgflixNormalize(cgflixTrendingTitle));
    if (match.isEmpty) return _noRow;
    final items = await client.cgflixFetchRawItems({
      'ParentId': '${match.first['Id']}',
      'IncludeItemTypes': 'Movie,Series',
      'Limit': '10',
    });
    return (raw: items.take(10).toList(), title: cgflixTrendingTitle);
  }

  /// Continuar assistindo de uma categoria, pedido ao servidor com o `ParentId` da biblioteca
  /// (os itens do "Continuar" geral não dizem a biblioteca: Séries mostrava os animes).
  /// Guardado 1 min na memória para trocar de chip sem ir à rede toda hora.
  Future<List<MediaItem>> continueWatchingIn(CgflixHomeFilter filter, {bool fresh = false}) async {
    final key = 'continue${filter.cacheSuffix}';
    final remembered = _continueMemory[key];
    if (!fresh && remembered != null && DateTime.now().difference(remembered.at) < const Duration(minutes: 1)) {
      return remembered.items;
    }
    final items = await client.cgflixFetchContinueWatchingIn(filter.libraryId).timeout(cgflixRowTimeout);
    _continueMemory[key] = (items: items, at: DateTime.now());
    return items;
  }

  final _continueMemory = <String, ({List<MediaItem> items, DateTime at})>{};

  /// Gêneros que viram linhas (cache primeiro). Com [filter], só os da biblioteca escolhida.
  Stream<List<String>> watchGenres({CgflixHomeFilter? filter}) async* {
    await _ensureCache();
    final key = 'genres${filter?.cacheSuffix ?? ''}';
    final cached = _cached(key);
    if (cached != null && cached.raw.isNotEmpty) yield cgflixPickGenres(cached.raw);
    try {
      final raw = await client.cgflixFetchRawGenres(parentId: filter?.libraryId, itemTypes: filter?.itemType);
      _store(key, raw);
      yield cgflixPickGenres(raw);
    } catch (e) {
      appLogger.w('CGFLIX: gêneros falharam', error: e);
      if (cached == null) yield const [];
    }
  }

  /// Bibliotecas para os chips (o cliente já tem cache próprio).
  Future<List<CgflixLibraryChip>> chips() async {
    try {
      final List<MediaLibrary> libraries = await client.fetchLibraries();
      return cgflixLibraryChips(libraries);
    } catch (e) {
      appLogger.w('CGFLIX: bibliotecas para os chips falharam', error: e);
      return const [];
    }
  }
}
