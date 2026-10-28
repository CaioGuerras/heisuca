import 'dart:async';
import 'dart:io';
import '../../utils/app_logger.dart';

/// Callback para ler bytes remotos de um stream (WebDAV ou SMB) sob demanda.
typedef RemoteChunkReader = Future<List<int>> Function(int startByte, int length);

/// Metadata de um arquivo remoto exposto via proxy.
class RemoteMediaDescriptor {
  final String id;
  final String uri;
  final int totalBytes;
  final String contentType;
  final RemoteChunkReader reader;

  const RemoteMediaDescriptor({
    required this.id,
    required this.uri,
    required this.totalBytes,
    this.contentType = 'video/mp4',
    required this.reader,
  });
}

/// Servidor Proxy HTTP Loopback Local (127.0.0.1)
/// Permite que o motor libmpv / media_kit reproduza mídias de WebDAV e SMB
/// com suporte completo a Range Requests (HTTP 206 Partial Content) e seek instantâneo.
class LocalStreamProxy {
  static LocalStreamProxy? _instance;
  static LocalStreamProxy get instance => _instance ??= LocalStreamProxy._();

  LocalStreamProxy._();

  HttpServer? _server;
  int _port = 0;
  final Map<String, RemoteMediaDescriptor> _registeredMedia = {};

  int get port => _port;
  bool get isRunning => _server != null;

  /// Inicia o servidor HTTP em loopback (127.0.0.1)
  Future<int> start() async {
    if (_server != null) return _port;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      appLogger.i('Heisuca LocalStreamProxy ativo em 127.0.0.1:$_port');

      _server!.listen(_handleRequest, onError: (e) {
        appLogger.e('Erro no servidor LocalStreamProxy: $e');
      });

      return _port;
    } catch (e) {
      appLogger.e('Falha ao iniciar LocalStreamProxy: $e');
      rethrow;
    }
  }

  /// Registra uma mídia remota e retorna a URL local para o player
  String registerMedia(RemoteMediaDescriptor descriptor) {
    _registeredMedia[descriptor.id] = descriptor;
    return 'http://127.0.0.1:$_port/stream?id=${Uri.encodeComponent(descriptor.id)}';
  }

  /// Remove registro de mídia quando o player encerra
  void unregisterMedia(String id) {
    _registeredMedia.remove(id);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.set(HttpHeaders.accessControlAllowOriginHeader, '*');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    if (request.uri.path != '/stream') {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    final id = request.uri.queryParameters['id'];
    if (id == null || !_registeredMedia.containsKey(id)) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    final descriptor = _registeredMedia[id]!;
    final totalBytes = descriptor.totalBytes;
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    response.headers.set(HttpHeaders.contentTypeHeader, descriptor.contentType);

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final range = rangeHeader.substring(6).split('-');
      final start = int.tryParse(range[0]) ?? 0;
      final end = (range.length > 1 && range[1].isNotEmpty)
          ? int.tryParse(range[1]) ?? (totalBytes - 1)
          : (totalBytes - 1);

      final clampedEnd = end.clamp(start, totalBytes - 1);
      final contentLength = clampedEnd - start + 1;

      response.statusCode = HttpStatus.partialContent;
      response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$clampedEnd/$totalBytes',
      );
      response.headers.set(HttpHeaders.contentLengthHeader, contentLength.toString());

      try {
        final chunk = await descriptor.reader(start, contentLength);
        response.add(chunk);
      } catch (e) {
        appLogger.w('Erro ao ler bytes da mídia remota ($start-$clampedEnd): $e');
      }
    } else {
      // Sem cabeçalho Range: envia cabeçalho com tamanho total
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.contentLengthHeader, totalBytes.toString());

      try {
        // Envia primeiros 2MB se requisitado completo
        final initialChunkSize = 2 * 1024 * 1024;
        final length = totalBytes > initialChunkSize ? initialChunkSize : totalBytes;
        final chunk = await descriptor.reader(0, length);
        response.add(chunk);
      } catch (e) {
        appLogger.w('Erro ao enviar stream inicial: $e');
      }
    }

    await response.close();
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _registeredMedia.clear();
  }
}
