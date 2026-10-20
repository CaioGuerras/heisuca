// Etapa 1E: pedidos (Seerr) embutidos na busca, sem tela de login.
//
// Por que antes caía no formulário: o "Pedir" da 1C/1D abria a tela de conectar do upstream
// (SeerrConnectScreen) sempre que não havia sessão salva, e essa tela pede o endereço do Seerr e
// usuário/senha (ou um código para aprovar à mão). Não existia entrada automática nenhuma.
//
// Agora o app entra sozinho, igual ao site:
//   1. acha o Seerr ao lado do Jellyfin (netflix.docaio.com.br → pedidos.docaio.com.br; testa
//      `/api/v1/settings/public` em poucos nomes comuns), sem nada pré-preenchido no código;
//   2. `POST /api/v1/auth/jellyfin/quickconnect/initiate` → {code, secret};
//   3. aprova o código no Jellyfin com o token da própria pessoa (`POST /QuickConnect/Authorize`);
//   4. `.../quickconnect/authenticate` com o secret → cookie `connect.sid`.
// O cookie fica no armazenamento seguro (cgflix_secure_store.dart) e é renovado sozinho quando o
// Seerr responde 401/403. Se algo falhar, a busca só esconde "Disponível para pedir".
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/seerr/seerr_request.dart';
import '../../services/seerr/seerr_auth_service.dart';
import '../../services/seerr/seerr_http_client.dart';
import '../../utils/app_logger.dart';
import '../../utils/log_redaction_manager.dart';
import 'cgflix_secure_store.dart';

// ---------------------------------------------------------------------------
// Modelos

/// Situação de um título do Seerr na busca.
enum CgflixRequestState {
  /// Ninguém pediu ainda: botão "Pedir".
  requestable,

  /// Já pedido, esperando (selo "Pedido").
  requested,

  /// Aprovado e baixando (selo "Baixando").
  downloading,
}

class CgflixRequestable {
  const CgflixRequestable({
    required this.tmdbId,
    required this.isMovie,
    required this.title,
    this.year,
    this.posterUrl,
    this.overview,
    this.state = CgflixRequestState.requestable,
  });

  final int tmdbId;
  final bool isMovie;
  final String title;
  final int? year;
  final String? posterUrl;
  final String? overview;
  final CgflixRequestState state;

  CgflixRequestable copyWith({CgflixRequestState? state}) => CgflixRequestable(
    tmdbId: tmdbId,
    isMovie: isMovie,
    title: title,
    year: year,
    posterUrl: posterUrl,
    overview: overview,
    state: state ?? this.state,
  );
}

/// Uma temporada na escolha do pedido de série.
class CgflixSeasonChoice {
  const CgflixSeasonChoice({required this.number, required this.name, this.episodes, this.lockedLabel});
  final int number;
  final String name;
  final int? episodes;

  /// Já pedida, baixando ou disponível: aparece marcada e não dá para tirar ("Pedido", "Já temos"...).
  final String? lockedLabel;
}

/// Um pedido da pessoa ("Meus pedidos").
class CgflixMyRequest {
  const CgflixMyRequest({
    required this.id,
    required this.tmdbId,
    required this.isMovie,
    required this.status,
    this.title,
    this.posterUrl,
    this.year,
    this.createdAt,
    this.seasons = const [],
  });

  final int id;
  final int tmdbId;
  final bool isMovie;
  final CgflixMyRequestStatus status;

  /// O Seerr não manda o nome no pedido: quando vier nulo, a tela busca com [CgflixRequestsBackend.titleInfo].
  final String? title;
  final String? posterUrl;
  final int? year;
  final DateTime? createdAt;
  final List<int> seasons;
}

enum CgflixMyRequestStatus { waitingApproval, approved, downloading, partiallyAvailable, available, declined, failed }

String cgflixMyRequestStatusLabel(CgflixMyRequestStatus status) => switch (status) {
  CgflixMyRequestStatus.waitingApproval => 'Aguardando aprovação',
  CgflixMyRequestStatus.approved => 'Aprovado',
  CgflixMyRequestStatus.downloading => 'Baixando',
  CgflixMyRequestStatus.partiallyAvailable => 'Chegou em parte',
  CgflixMyRequestStatus.available => 'Disponível',
  CgflixMyRequestStatus.declined => 'Recusado',
  CgflixMyRequestStatus.failed => 'Falhou',
};

/// Nome, ano e capa de um título do Seerr (para "Meus pedidos").
typedef CgflixTitleInfo = ({String title, int? year, String? posterUrl});

/// Os pedidos não estão disponíveis agora (Seerr fora do ar, Quick Connect desligado...).
class CgflixRequestsUnavailable implements Exception {
  const CgflixRequestsUnavailable(this.reason);
  final String reason;

  @override
  String toString() => 'CgflixRequestsUnavailable($reason)';
}

/// O Seerr recusou o pedido (sem permissão, limite de pedidos...). [message] já em português.
class CgflixRequestRejected implements Exception {
  const CgflixRequestRejected(this.message);
  final String message;

  @override
  String toString() => 'CgflixRequestRejected($message)';
}

/// O que a busca e "Meus pedidos" usam. O app de teste do emulador e os testes trocam por um falso.
abstract class CgflixRequestsBackend {
  /// Resultados do Seerr para [query] que ainda NÃO estão no servidor (disponível/parcial ficam
  /// de fora: já aparecem como nossos). Lança [CgflixRequestsUnavailable] se não der.
  Future<List<CgflixRequestable>> search(String query);

  /// Temporadas de uma série (sem os especiais), para a escolha do pedido.
  Future<List<CgflixSeasonChoice>> seasons(int tmdbId);

  /// Faz o pedido. Filme: direto; série: [seasons] (null = todas).
  Future<void> request(CgflixRequestable item, {List<int>? seasons});

  /// Pedidos da pessoa, mais novos primeiro.
  Future<List<CgflixMyRequest>> myRequests();

  Future<CgflixTitleInfo> titleInfo(int tmdbId, {required bool isMovie});
}

// ---------------------------------------------------------------------------
// Regras sem rede (testáveis)

/// `mediaInfo.status` do Seerr → situação na busca; `null` = já é nosso (ou bloqueado): não mostrar.
/// 1/ausente = pedir; 2 = "Pedido"; 3 = "Baixando"; 4/5 = disponível (já aparece como nosso);
/// 6 = bloqueado; 7 = apagado do servidor (dá para pedir de novo).
CgflixRequestState? cgflixRequestStateFor(int? mediaStatus) => switch (mediaStatus) {
  null || 1 || 7 => CgflixRequestState.requestable,
  2 => CgflixRequestState.requested,
  3 => CgflixRequestState.downloading,
  _ => null,
};

CgflixMyRequestStatus cgflixMyRequestStatusFor({required int? requestStatus, required int? mediaStatus}) =>
    switch (requestStatus) {
      3 => CgflixMyRequestStatus.declined,
      4 => CgflixMyRequestStatus.failed,
      1 => CgflixMyRequestStatus.waitingApproval,
      _ => switch (mediaStatus) {
        5 => CgflixMyRequestStatus.available,
        4 => CgflixMyRequestStatus.partiallyAvailable,
        3 => CgflixMyRequestStatus.downloading,
        _ => requestStatus == 5 ? CgflixMyRequestStatus.available : CgflixMyRequestStatus.approved,
      },
    };

/// Onde procurar o Seerr a partir do endereço do Jellyfin: troca o primeiro nome do domínio por
/// nomes comuns ("pedidos" primeiro, o do CGFLIX). Sem domínio com 3 partes (IP, "localhost"),
/// tenta só a porta padrão do Seerr no mesmo host.
List<String> cgflixSeerrCandidates(String jellyfinBaseUrl) {
  final uri = Uri.tryParse(jellyfinBaseUrl.trim());
  if (uri == null || uri.host.isEmpty) return const [];
  final host = uri.host;
  final isIp = RegExp(r'^[0-9.]+$').hasMatch(host) || host.contains(':');
  final labels = host.split('.');
  if (isIp || labels.length < 3) {
    return ['${uri.scheme}://$host:5055'];
  }
  final parent = labels.skip(1).join('.');
  return [
    for (final name in const ['pedidos', 'seerr', 'jellyseerr', 'requests', 'overseerr']) 'https://$name.$parent',
  ];
}

String? cgflixTmdbPoster(Object? path, {String size = 'w342'}) =>
    path is String && path.isNotEmpty ? 'https://image.tmdb.org/t/p/$size$path' : null;

int? _yearOf(Object? date) => date is String && date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;

// ---------------------------------------------------------------------------
// Seerr de verdade

/// Sessão guardada no armazenamento seguro (JSON pequeno; o cookie nunca vai para o log).
class _Session {
  const _Session({required this.baseUrl, required this.cookie, required this.userId});
  final String baseUrl;
  final String cookie;
  final int userId;

  String encode() => jsonEncode({'url': baseUrl, 'cookie': cookie, 'user': userId});

  static _Session? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final url = json['url'], cookie = json['cookie'], user = json['user'];
      if (url is! String || cookie is! String || user is! int) return null;
      return _Session(baseUrl: url, cookie: cookie, userId: user);
    } catch (_) {
      return null;
    }
  }
}

class CgflixSeerrRequests implements CgflixRequestsBackend {
  CgflixSeerrRequests({
    required this.jellyfinBaseUrl,
    required this.accountKey,
    required this.authorizeQuickConnect,
    CgflixSecureStore? store,
    this.httpClientFactory,
    this.quickConnectTimeout = const Duration(seconds: 20),
  }) : _store = store ?? CgflixSecureStore.platform(),
       _auth = SeerrAuthService(httpClientFactory: httpClientFactory);

  /// Endereço em uso do Jellyfin (de onde o endereço do Seerr é tirado).
  final String jellyfinBaseUrl;

  /// Servidor + usuário: separa a sessão de cada conta no aparelho.
  final String accountKey;

  /// Aprova o código do Quick Connect no Jellyfin com o token da pessoa.
  final Future<void> Function(String code) authorizeQuickConnect;

  final http.Client Function()? httpClientFactory;
  final Duration quickConnectTimeout;
  final CgflixSecureStore _store;
  final SeerrAuthService _auth;

  _Session? _session;
  Future<_Session>? _signingIn;

  /// Última vez que a entrada falhou: por [_retryAfter] a busca nem tenta (mostra o aviso na hora).
  DateTime? _failedAt;
  static const _retryAfter = Duration(minutes: 2);

  String get _storeKey => 'seerr_session:$accountKey';

  /// Sessão pronta (memória → armazenamento seguro → entrada pelo Quick Connect).
  Future<_Session> _ensureSession() async {
    final current = _session;
    if (current != null) return current;
    final failedAt = _failedAt;
    if (failedAt != null && DateTime.now().difference(failedAt) < _retryAfter) {
      throw const CgflixRequestsUnavailable('falhou há pouco; tenta de novo daqui a pouco');
    }
    return _signingIn ??= _loadOrSignIn().whenComplete(() => _signingIn = null);
  }

  Future<_Session> _loadOrSignIn() async {
    final stored = _Session.decode(await _store.read(_storeKey));
    if (stored != null) {
      LogRedactionManager.registerCustomValue(stored.cookie);
      return _session = stored;
    }
    return _signIn();
  }

  /// Esquece o cookie (401/403) e entra de novo.
  Future<_Session> _renew(_Session stale) async {
    if (!identical(_session, stale) && _session != null) return _session!;
    _session = null;
    await _store.delete(_storeKey);
    return _signingIn ??= _signIn(preferredUrl: stale.baseUrl).whenComplete(() => _signingIn = null);
  }

  Future<_Session> _signIn({String? preferredUrl}) async {
    try {
      final session = await _signInOnce(preferredUrl);
      _failedAt = null;
      return session;
    } on CgflixRequestsUnavailable {
      _failedAt = DateTime.now();
      rethrow;
    }
  }

  Future<_Session> _signInOnce(String? preferredUrl) async {
    final baseUrl = await _discover(preferredUrl);
    try {
      final initiation = await _auth.initiateQuickConnect(baseUrl);
      await authorizeQuickConnect(initiation.code);
      final session = await _auth.signInWithQuickConnect(
        baseUrl: baseUrl,
        secret: initiation.secret,
        timeout: quickConnectTimeout,
      );
      if (session == null) throw const CgflixRequestsUnavailable('Quick Connect não foi aprovado a tempo');
      LogRedactionManager.registerCustomValue(session.cookie);
      final fresh = _Session(baseUrl: session.baseUrl, cookie: session.cookie, userId: session.userId);
      await _store.write(_storeKey, fresh.encode());
      appLogger.i('CGFLIX: entrou nos Pedidos pelo Quick Connect');
      return _session = fresh;
    } on CgflixRequestsUnavailable {
      rethrow;
    } catch (e) {
      // Sem detalhes do código/secret no log (o upstream já registra o secret para redação).
      throw CgflixRequestsUnavailable('entrada automática falhou: ${e.runtimeType}');
    }
  }

  /// Primeiro endereço (na ordem de preferência) que responde como um Seerr pronto. Testa todos
  /// juntos (cada um tem prazo de 8 s) para a busca não esperar um por um.
  Future<String> _discover(String? preferred) async {
    final candidates = [?preferred, ...cgflixSeerrCandidates(jellyfinBaseUrl).where((c) => c != preferred)];
    final answered = await Future.wait([
      for (final candidate in candidates) _auth.probe(candidate).then((_) => true, onError: (Object _) => false),
    ]);
    for (final (index, ok) in answered.indexed) {
      if (ok) return candidates[index];
    }
    throw const CgflixRequestsUnavailable('Seerr não encontrado ao lado do servidor');
  }

  /// Chamada autenticada; em 401/403 renova a sessão e tenta mais uma vez.
  Future<SeerrResponse> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Map<String, Object?>? body,
  }) async {
    var session = await _ensureSession();
    for (var attempt = 0; ; attempt++) {
      final client = SeerrHttpClient(
        baseUrl: session.baseUrl,
        httpClient: httpClientFactory?.call(),
        cookie: session.cookie,
      );
      final SeerrResponse res;
      try {
        res = await client.send(method, path, query: query, body: body);
      } catch (e) {
        throw CgflixRequestsUnavailable('Seerr fora do ar: ${e.runtimeType}');
      } finally {
        client.dispose();
      }
      if ((res.statusCode == 401 || res.statusCode == 403) && attempt == 0) {
        appLogger.i('CGFLIX: sessão dos Pedidos expirou (${res.statusCode}), entrando de novo');
        session = await _renew(session);
        continue;
      }
      return res;
    }
  }

  Future<Object?> _getJson(String path, {Map<String, Object?>? query}) async {
    final res = await _send('GET', path, query: query);
    if (res.statusCode >= 400) throw CgflixRequestsUnavailable('Seerr respondeu ${res.statusCode} em $path');
    return res.data;
  }

  @override
  Future<List<CgflixRequestable>> search(String query) async {
    final data = await _getJson('/search', query: {'query': query, 'page': 1, 'language': 'pt-BR'});
    final results = data is Map ? data['results'] : null;
    if (results is! List) return const [];
    return [
      for (final raw in results.whereType<Map>())
        if ((raw['mediaType'] == 'movie' || raw['mediaType'] == 'tv') && raw['id'] is int)
          if (cgflixRequestStateFor(_mediaStatus(raw['mediaInfo'])) case final state?)
            CgflixRequestable(
              tmdbId: raw['id'] as int,
              isMovie: raw['mediaType'] == 'movie',
              title: '${raw['title'] ?? raw['name'] ?? raw['originalTitle'] ?? raw['originalName'] ?? ''}',
              year: _yearOf(raw['releaseDate'] ?? raw['firstAirDate']),
              posterUrl: cgflixTmdbPoster(raw['posterPath']),
              overview: raw['overview'] is String ? raw['overview'] as String : null,
              state: state,
            ),
    ];
  }

  static int? _mediaStatus(Object? mediaInfo) =>
      mediaInfo is Map && mediaInfo['status'] is int ? mediaInfo['status'] as int : null;

  @override
  Future<List<CgflixSeasonChoice>> seasons(int tmdbId) async {
    final data = await _getJson('/tv/$tmdbId', query: {'language': 'pt-BR'});
    if (data is! Map) return const [];
    final statusBySeason = <int, int>{};
    final mediaSeasons = data['mediaInfo'] is Map ? (data['mediaInfo'] as Map)['seasons'] : null;
    if (mediaSeasons is List) {
      for (final s in mediaSeasons.whereType<Map>()) {
        if (s['seasonNumber'] is int && s['status'] is int) {
          statusBySeason[s['seasonNumber'] as int] = s['status'] as int;
        }
      }
    }
    final seasons = data['seasons'];
    if (seasons is! List) return const [];
    return [
      for (final s in seasons.whereType<Map>())
        if (s['seasonNumber'] is int && (s['seasonNumber'] as int) > 0)
          CgflixSeasonChoice(
            number: s['seasonNumber'] as int,
            name: s['name'] is String && (s['name'] as String).isNotEmpty
                ? s['name'] as String
                : 'Temporada ${s['seasonNumber']}',
            episodes: s['episodeCount'] is int ? s['episodeCount'] as int : null,
            lockedLabel: switch (statusBySeason[s['seasonNumber']]) {
              2 => 'Pedido',
              3 => 'Baixando',
              5 => 'Já temos',
              _ => null,
            },
          ),
    ];
  }

  @override
  Future<void> request(CgflixRequestable item, {List<int>? seasons}) async {
    final payload = SeerrRequestPayload(
      mediaType: item.isMovie ? 'movie' : 'tv',
      mediaId: item.tmdbId,
      seasons: item.isMovie ? null : seasons,
    );
    final res = await _send('POST', '/request', body: payload.toJson());
    if (res.statusCode < 400) return;
    final data = res.data;
    final message = data is Map && data['message'] is String ? data['message'] as String : null;
    appLogger.w('CGFLIX: pedido recusado (${res.statusCode}): $message');
    throw CgflixRequestRejected(switch (res.statusCode) {
      403 => 'Sua conta não tem permissão para pedir. Fale com o Caio.',
      409 => 'Esse título já foi pedido.',
      _ when (message ?? '').toLowerCase().contains('quota') => 'Você chegou ao limite de pedidos por agora.',
      _ => 'Não deu para fazer o pedido agora. Tente de novo mais tarde.',
    });
  }

  @override
  Future<List<CgflixMyRequest>> myRequests() async {
    final session = await _ensureSession();
    final data = await _getJson('/user/${session.userId}/requests', query: {'take': 50, 'skip': 0});
    final results = data is Map ? data['results'] : null;
    if (results is! List) return const [];
    final requests = <CgflixMyRequest>[];
    for (final raw in results.whereType<Map>()) {
      final media = raw['media'];
      if (media is! Map || media['tmdbId'] is! int || raw['id'] is! int) continue;
      final seasons = raw['seasons'];
      requests.add(
        CgflixMyRequest(
          id: raw['id'] as int,
          tmdbId: media['tmdbId'] as int,
          isMovie: media['mediaType'] == 'movie' || raw['type'] == 'movie',
          status: cgflixMyRequestStatusFor(
            requestStatus: raw['status'] is int ? raw['status'] as int : null,
            mediaStatus: media['status'] is int ? media['status'] as int : null,
          ),
          createdAt: raw['createdAt'] is String ? DateTime.tryParse(raw['createdAt'] as String) : null,
          seasons: [
            if (seasons is List)
              for (final s in seasons.whereType<Map>())
                if (s['seasonNumber'] is int) s['seasonNumber'] as int,
          ],
        ),
      );
    }
    requests.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return requests;
  }

  @override
  Future<CgflixTitleInfo> titleInfo(int tmdbId, {required bool isMovie}) async {
    final data = await _getJson(isMovie ? '/movie/$tmdbId' : '/tv/$tmdbId', query: {'language': 'pt-BR'});
    if (data is! Map) return (title: '', year: null, posterUrl: null);
    return (
      title: '${data['title'] ?? data['name'] ?? ''}',
      year: _yearOf(data['releaseDate'] ?? data['firstAirDate']),
      posterUrl: cgflixTmdbPoster(data['posterPath']),
    );
  }
}
