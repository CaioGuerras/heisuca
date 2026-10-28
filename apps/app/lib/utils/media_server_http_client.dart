import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'app_logger.dart';
import 'future_extensions.dart';
import 'isolate_helper.dart';
import 'managed_http_client.dart';
import 'url_utils.dart';
import '../exceptions/media_server_exceptions.dart';

// Platform-specific imports are conditional
import 'platform_http_client_stub.dart' if (dart.library.io) 'platform_http_client_io.dart' as platform;

/// Response from [MediaServerHttpClient] requests.
class MediaServerResponse {
  final int statusCode;

  /// Parsed JSON body (`Map<String, dynamic>` or `List`), or raw `String`
  /// for non-JSON responses.
  final dynamic data;

  final Map<String, String> headers;
  final Uri? requestUri;

  /// Final response URI after redirects, or [requestUri] when the transport
  /// does not expose redirect metadata.
  final Uri? effectiveUri;

  MediaServerResponse({required this.statusCode, this.data, required this.headers, this.requestUri, Uri? effectiveUri})
    : effectiveUri = effectiveUri ?? requestUri;
}

/// Throw [MediaServerHttpException] for non-2xx responses so callers don't blindly
/// cast HTML/text error bodies to `Map<String, dynamic>`.
void throwIfHttpError(MediaServerResponse r) {
  if (r.statusCode >= 400) {
    throw MediaServerHttpException(
      type: MediaServerHttpErrorType.unknown,
      statusCode: r.statusCode,
      responseData: r.data,
      requestUri: r.requestUri,
      message: 'HTTP ${r.statusCode}',
    );
  }
}

/// Abort controller for cancelling in-flight HTTP requests.
///
/// Uses the `package:http` [AbortableRequest] mechanism so the underlying
/// transport (IOClient, WinHttpClient) actually cancels
/// the network operation.
class AbortController {
  final _completer = Completer<void>();

  Future<void> get trigger => _completer.future;

  bool get isAborted => _completer.isCompleted;

  void abort() {
    if (!_completer.isCompleted) _completer.complete();
  }

  /// Stop a paged operation before it starts or commits more work.
  ///
  /// The exception deliberately carries no request URI or response payload.
  void throwIfAborted() {
    if (isAborted) {
      throw MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'Operation cancelled');
    }
  }
}

/// HTTP client wrapper providing base URL, default headers, JSON parsing,
/// timeouts, logging, and optional endpoint failover.
class MediaServerHttpClient {
  final http.Client _client;

  /// Teto padrão do corpo lido para a memória ([_send] e [getBytes]). Um
  /// servidor hostil (ou um proxy com defeito) pode mandar gigabytes; 64 MiB
  /// cobre com folga a maior listagem JSON ou imagem legítima. Downloads para
  /// arquivo ([downloadFile]) não passam por aqui: vão direto ao disco.
  static const int defaultMaxResponseBytes = 64 * 1024 * 1024;

  /// Máximo de redirecionamentos seguidos por requisição (laços terminam aqui).
  static const int maxRedirects = 5;

  /// Cabeçalhos que carregam credencial: nunca seguem para outra origem.
  static const Set<String> _credentialHeaders = {
    'authorization',
    'proxy-authorization',
    'x-emby-token',
    'x-emby-authorization',
    'x-mediabrowser-token',
    'cookie',
  };

  /// Teto de corpo em memória desta instância (ver [defaultMaxResponseBytes]).
  final int maxResponseBytes;

  /// Requests owned by this client, aborted at the transport on shutdown so an
  /// in-flight body raises [http.RequestAbortedException] instead of truncating.
  final Set<AbortController> _activeAborts = <AbortController>{};

  /// Not delegated to [ManagedHttpClient]'s own closing guard: that reports
  /// shutdown as an [http.ClientException], which maps to
  /// [MediaServerHttpErrorType.connectionError] and so reads as transient.
  /// Failover, pagination and download retry all branch on
  /// [MediaServerHttpException.isCancellation].
  bool _closing = false;

  MediaServerHttpClient({
    http.Client? client,
    this.baseUrl = '',
    Map<String, String> defaultHeaders = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 120),
    this.maxResponseBytes = defaultMaxResponseBytes,
  }) : _client = client ?? platform.createPlatformClient(),
       defaultHeaders = Map.of(defaultHeaders);

  /// The underlying [http.Client] for direct streaming / multipart requests.
  http.Client get inner => _client;

  String baseUrl;
  Map<String, String> defaultHeaders;
  Duration connectTimeout;
  Duration receiveTimeout;

  Future<MediaServerResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) => _send('GET', path, queryParameters: queryParameters, headers: headers, timeout: timeout, abort: abort);

  Future<MediaServerResponse> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) => _send(
    'POST',
    path,
    queryParameters: queryParameters,
    headers: headers,
    body: body,
    timeout: timeout,
    abort: abort,
  );

  Future<MediaServerResponse> put(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) => _send(
    'PUT',
    path,
    queryParameters: queryParameters,
    headers: headers,
    body: body,
    timeout: timeout,
    abort: abort,
  );

  Future<MediaServerResponse> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) => _send('DELETE', path, queryParameters: queryParameters, headers: headers, timeout: timeout, abort: abort);

  /// Fetch raw bytes (e.g. images, BIF files, subtitles).
  Future<Uint8List> getBytes(String url, {Map<String, String>? headers, Duration? timeout, AbortController? abort}) {
    return _perform<Uint8List>(
      'GET',
      url,
      headers: headers,
      timeout: timeout,
      abort: abort,
      consume: (streamed, scope) async {
        final bytes = await scope.receive(_readCapped(streamed, scope.uri));
        scope.logResponse(streamed.statusCode);
        return bytes;
      },
    );
  }

  /// Stream-download a URL directly into a file.
  Future<void> downloadFile(
    String url,
    String filePath, {
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) {
    final tempFile = File('$filePath.download');
    return _perform<void>(
      'GET',
      url,
      label: 'download',
      headers: headers,
      timeout: timeout,
      abort: abort,
      // Also clears a temp file left by an earlier attempt when this one never
      // got past connect.
      onError: () async {
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      },
      consume: (streamed, scope) async {
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          await streamed.stream.drain<void>();
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.unknown,
            statusCode: streamed.statusCode,
            requestUri: scope.uri,
            message: 'HTTP ${streamed.statusCode}',
          );
        }

        final file = File(filePath);
        await file.parent.create(recursive: true);
        if (await tempFile.exists()) await tempFile.delete();
        final sink = tempFile.openWrite();
        try {
          await scope.receive(streamed.stream.pipe(sink));
        } finally {
          await sink.close();
        }
        if (await file.exists()) await file.delete();
        await tempFile.rename(filePath);
      },
    );
  }

  void close() {
    _closing = true;
    _abortActiveRequests();
    _client.close();
  }

  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) async {
    _closing = true;
    _abortActiveRequests();
    if (_client case final GracefulHttpClient graceful) {
      await graceful.closeGracefully(drainTimeout: drainTimeout);
    } else {
      _client.close();
    }
  }

  Future<MediaServerResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) {
    return _perform<MediaServerResponse>(
      method,
      path,
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      timeout: timeout,
      abort: abort,
      consume: (streamed, scope) async {
        final effectiveUri = switch (streamed) {
          http.BaseResponseWithUrl(:final url) => url,
          _ => scope.uri,
        };

        final bytes = await scope.receive(_readCapped(streamed, scope.uri));
        scope.logResponse(streamed.statusCode);

        dynamic data;
        try {
          data = await _decodeBody(bytes, streamed.headers);
        } catch (e) {
          final body = await _decodeTextBody(bytes);
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.unknown,
            statusCode: streamed.statusCode,
            responseData: body,
            requestUri: scope.uri,
            message: 'Failed to decode response body: $e',
          );
        }
        return MediaServerResponse(
          statusCode: streamed.statusCode,
          data: data,
          headers: streamed.headers,
          requestUri: scope.uri,
          effectiveUri: effectiveUri,
        );
      },
    );
  }

  /// Run one request: closing guard, abort registration, connect phase and
  /// failure wrapping. [consume] reads the body through its scope, which
  /// carries the same timeout and abort wiring into the receive phase;
  /// [onError] runs after the abort and before the failure is wrapped. Every
  /// exit path deregisters the request from [_activeAborts].
  Future<T> _perform<T>(
    String method,
    String url, {
    String? label,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
    Future<void> Function()? onError,
    required Future<T> Function(http.StreamedResponse streamed, _RequestScope scope) consume,
  }) async {
    if (_closing) {
      throw MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'HTTP client is closing');
    }

    final uri = _resolveUri(url, queryParameters);
    final operation = label ?? method;

    final requestAbort = AbortController();
    _activeAborts.add(requestAbort);
    final trigger = _abortTrigger(requestAbort, abort);
    final request = http.AbortableRequest(method, uri, abortTrigger: trigger);
    request.headers.addAll({...defaultHeaders, ...?headers});
    // URL absoluta de OUTRA origem que a do servidor (artes e legendas externas):
    // nenhum cabeçalho de credencial acompanha o pedido.
    final serverBase = Uri.tryParse(baseUrl);
    if (serverBase != null && serverBase.host.isNotEmpty && !_sameOrigin(serverBase, uri)) {
      request.headers.removeWhere((name, _) => _credentialHeaders.contains(name.toLowerCase()));
    }
    _setBody(request, body);

    final scope = _RequestScope(this, uri, operation, requestAbort, timeout ?? receiveTimeout);
    try {
      final streamed = await _sendFollowingRedirects(
        request,
        trigger,
        timeout ?? connectTimeout,
        operation: '$operation ${uri.path} connect',
        abort: requestAbort,
      );
      return await consume(streamed, scope);
    } catch (e) {
      // Once this request's abort has fired, any secondary teardown error that
      // surfaces first (a file sink failing after the stream died, a socket
      // reset) is still a cancellation to the caller. Timeouts abort the
      // request themselves before rethrowing and must keep their own type.
      final wasAborted = requestAbort.isAborted || (abort?.isAborted ?? false);
      requestAbort.abort();
      await onError?.call();
      if (wasAborted && e is! MediaServerHttpException && e is! TimeoutException) {
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.cancelled,
          requestUri: uri,
          message: 'Request aborted: $e',
        );
      }
      throw MediaServerHttpException.from(e, uri: uri);
    } finally {
      _activeAborts.remove(requestAbort);
    }
  }

  static bool _sameOrigin(Uri a, Uri b) =>
      a.scheme.toLowerCase() == b.scheme.toLowerCase() &&
      a.host.toLowerCase() == b.host.toLowerCase() &&
      a.port == b.port;

  static bool _isRedirectStatus(int status) =>
      status == 301 || status == 302 || status == 303 || status == 307 || status == 308;

  static bool _carriesCredentials(http.BaseRequest request) {
    if (request.headers.keys.any((k) => _credentialHeaders.contains(k.toLowerCase()))) return true;
    return request.url.queryParameters.keys.any((k) {
      final key = k.toLowerCase();
      return key == 'api_key' || key == 'apikey' || key == 'x-emby-token';
    });
  }

  /// Envia [first] seguindo redirecionamentos À MÃO (o transporte não segue
  /// sozinho), para a política ficar num lugar só e igual em todas as
  /// plataformas:
  ///
  /// - no máximo [maxRedirects] saltos; laço (302 para si, A→B→A) vira
  ///   [MediaServerHttpException] em tempo limitado (cada salto tem o prazo de
  ///   conexão);
  /// - só http/https;
  /// - requisição com credencial (token em cabeçalho ou `api_key`) só segue
  ///   para o MESMO host e sem rebaixar https para http; qualquer outro destino
  ///   é recusado, então o token nunca chega a outro host. Sem credencial (a
  ///   sondagem pública de endpoints) o salto cross-host segue, e quem chamou
  ///   decide pela URL final em [http.BaseResponseWithUrl].
  Future<http.StreamedResponse> _sendFollowingRedirects(
    http.AbortableRequest first,
    Future<void> trigger,
    Duration connectLimit, {
    required String operation,
    required AbortController abort,
  }) async {
    var request = first;
    for (var hop = 0; ; hop++) {
      request.followRedirects = false;
      final streamed = await _withAbortOnTimeout(
        _client.send(request),
        connectLimit,
        operation: operation,
        abort: abort,
      );
      final location = streamed.headers['location'];
      if (!_isRedirectStatus(streamed.statusCode) || location == null || location.isEmpty) return streamed;
      try {
        await streamed.stream.drain<void>();
      } catch (_) {}
      if (hop >= maxRedirects) {
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.unknown,
          requestUri: first.url,
          message: 'Too many redirects',
        );
      }
      final next = request.url.resolve(location);
      if (next.scheme != 'http' && next.scheme != 'https') {
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.unknown,
          requestUri: first.url,
          message: 'Redirect to unsupported scheme refused',
        );
      }
      final sameHost = next.host.toLowerCase() == request.url.host.toLowerCase();
      final downgrade = request.url.scheme == 'https' && next.scheme == 'http';
      if (_carriesCredentials(request) && (!sameHost || downgrade)) {
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.unknown,
          requestUri: first.url,
          message: 'Authenticated redirect to another host refused',
        );
      }
      final keepsMethod = streamed.statusCode == 307 || streamed.statusCode == 308;
      final asGet = !keepsMethod && request.method != 'GET' && request.method != 'HEAD';
      final method = asGet ? 'GET' : request.method;
      final nextRequest = http.AbortableRequest(method, next, abortTrigger: trigger);
      nextRequest.headers.addAll(request.headers);
      nextRequest.headers.removeWhere((k, _) => k.toLowerCase() == 'content-length');
      if (asGet) {
        nextRequest.headers.removeWhere((k, _) => k.toLowerCase() == 'content-type');
      } else if (request.bodyBytes.isNotEmpty) {
        nextRequest.bodyBytes = request.bodyBytes;
      }
      request = nextRequest;
    }
  }

  /// Lê o corpo inteiro para a memória respeitando [maxResponseBytes]: recusa
  /// já pelo Content-Length e, sem ele, corta ao passar do teto.
  Future<Uint8List> _readCapped(http.StreamedResponse streamed, Uri uri) async {
    final limit = maxResponseBytes;
    MediaServerHttpException tooBig() => MediaServerHttpException(
      type: MediaServerHttpErrorType.unknown,
      statusCode: streamed.statusCode,
      requestUri: uri,
      message: 'Response body exceeds $limit bytes',
    );
    final declared = streamed.contentLength;
    if (declared != null && declared > limit) throw tooBig();
    final builder = BytesBuilder(copy: false);
    await for (final chunk in streamed.stream) {
      builder.add(chunk);
      if (builder.length > limit) throw tooBig();
    }
    return builder.takeBytes();
  }

  void _abortActiveRequests() {
    for (final abort in _activeAborts.toList()) {
      abort.abort();
    }
  }

  Future<void> _abortTrigger(AbortController owned, AbortController? external) {
    final externalTrigger = external?.trigger;
    return externalTrigger == null ? owned.trigger : Future.any<void>([owned.trigger, externalTrigger]);
  }

  Future<T> _withAbortOnTimeout<T>(
    Future<T> future,
    Duration timeLimit, {
    required String operation,
    required AbortController abort,
  }) async {
    try {
      return await future.namedTimeout(timeLimit, operation: operation);
    } on TimeoutException {
      abort.abort();
      rethrow;
    }
  }

  /// Build a full URI from [baseUrl] + [path] + [queryParameters].
  /// Use this from callers that need to construct URLs with the client's
  /// current (possibly failover-switched) base, rather than reading
  /// `config.baseUrl` directly.
  Uri buildUri(String path, {Map<String, dynamic>? queryParameters}) => _buildUri(path, queryParameters);

  /// Build a full URI from [baseUrl] + [path] + [queryParameters].
  /// Uses [Uri.encodeComponent] which encodes spaces as `%20` (not `+`).
  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    // [path] may already carry a query string (e.g. Plex home hub keys like
    // `/hubs/home/recentlyAdded?type=2&sectionID=2`). Merge via [_appendQuery] —
    // the same path used for absolute URLs in [_send] — so extra params join with
    // `&` instead of producing a malformed double-`?` URL that corrupts the
    // existing params (e.g. sectionID).
    return _appendQuery(Uri.parse('$base$cleanPath'), queryParameters);
  }

  /// Resolve a request target: absolute URLs keep their own host and query,
  /// relative paths go through [baseUrl].
  Uri _resolveUri(String url, Map<String, dynamic>? queryParameters) =>
      _isAbsoluteUrl(url) ? _appendQuery(Uri.parse(url), queryParameters) : _buildUri(url, queryParameters);

  Uri _appendQuery(Uri uri, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    final query = encodeQueryParameters(queryParameters);
    if (query.isEmpty) return uri;
    final existing = uri.query;
    final combined = existing.isEmpty ? query : '$existing&$query';
    return uri.replace(query: combined);
  }

  static bool _isAbsoluteUrl(String url) => url.startsWith('http://') || url.startsWith('https://');

  /// Set the request body, choosing encoding based on the body type.
  void _setBody(http.Request request, Object? body) {
    if (body == null) return;

    if (body is List<int>) {
      request.bodyBytes = Uint8List.fromList(body);
      return;
    }

    if (body is String) {
      request.body = body;
      return;
    }

    // Structured bodies are always JSON-encoded, so default the content type
    // to match. `request.headers` is case-insensitive and already carries the
    // caller/default headers, so an explicit content type wins (Jellyfin pins
    // `application/json` in its defaults). Without this, `request.body` falls
    // back to text/plain, which Plex's cloud endpoints reject — the favorites
    // PUT to epg.provider.plex.tv answered 400 (#1878).
    request.headers.putIfAbsent('content-type', () => 'application/json');
    request.body = jsonEncode(body);
  }

  /// Decode the response body: lenient UTF-8, then JSON parse if applicable.
  /// Large payloads are decoded in a background isolate.
  Future<dynamic> _decodeBody(List<int> bytes, Map<String, String> headers) async {
    if (bytes.isEmpty) return null;

    final contentType = (_headerValue(headers, 'content-type') ?? '').toLowerCase();
    final isJson = contentType.contains('json');

    // For large JSON payloads, do both UTF-8 decode and JSON parse in a
    // single isolate roundtrip to avoid two context switches.
    if (isJson && bytes.length > 50 * 1024) {
      return await tryIsolateRun(() => jsonDecode(utf8.decode(bytes, allowMalformed: true)));
    }

    final body = await _decodeTextBody(bytes);

    return isJson ? jsonDecode(body) : body;
  }

  Future<String> _decodeTextBody(List<int> bytes) async {
    return bytes.length > 50 * 1024
        ? await tryIsolateRun(() => utf8.decode(bytes, allowMalformed: true))
        : utf8.decode(bytes, allowMalformed: true);
  }

  static String? _headerValue(Map<String, String> headers, String name) {
    final lowerName = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerName) return entry.value;
    }
    return null;
  }

  void _logResponse(String method, Uri uri, int statusCode, int ms) {
    // Dart builds this message before the level filter sees it, and it runs on
    // every buffered response. `MemoryAwareLogPrinter` already redacts each
    // emitted record, so the call site neither needs `redact()` nor should pay
    // for the interpolation in release, where the line is dropped.
    if (!debugLoggingEnabled) return;
    appLogger.d('$method $uri → $statusCode (${ms}ms)');
  }
}

/// The live request handed to a [MediaServerHttpClient._perform] body handler.
/// Its stopwatch starts with the connect phase, so [logResponse] reports the
/// full round trip regardless of how the body was read.
class _RequestScope {
  _RequestScope(this._owner, this.uri, this._operation, this._abort, this._receiveTimeout);

  final MediaServerHttpClient _owner;
  final Uri uri;
  final String _operation;
  final AbortController _abort;
  final Duration _receiveTimeout;
  final Stopwatch _sw = Stopwatch()..start();

  Future<T> receive<T>(Future<T> future) =>
      _owner._withAbortOnTimeout(future, _receiveTimeout, operation: '$_operation ${uri.path} receive', abort: _abort);

  void logResponse(int statusCode) {
    _sw.stop();
    _owner._logResponse(_operation, uri, statusCode, _sw.elapsedMilliseconds);
  }
}

/// Shared [MediaServerHttpClient] instance for ad-hoc requests (update checks,
/// log uploads, image fetches, etc). No base URL or default Plex headers.
final httpClient = MediaServerHttpClient();
