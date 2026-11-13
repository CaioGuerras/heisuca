import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/log_redaction_manager.dart';

class ConfiguracaoAtualizacao {
  ConfiguracaoAtualizacao({this.feed = '', this.hostsApk = '', this.distribuicao = 'direct'});
  factory ConfiguracaoAtualizacao.doBuild() => ConfiguracaoAtualizacao(
    feed: const String.fromEnvironment('HEISUCA_UPDATE_FEED_URL'),
    hostsApk: const String.fromEnvironment('HEISUCA_UPDATE_APK_HOSTS'),
    distribuicao: const String.fromEnvironment('FLUTTER_APP_FLAVOR') == 'play'
        ? 'play'
        : const String.fromEnvironment('HEISUCA_DISTRIBUTION', defaultValue: 'direct'),
  );
  final String feed, hostsApk, distribuicao;
  Uri? get origem {
    final uri = Uri.tryParse(feed);
    if (distribuicao != 'direct' || uri == null || !_https(uri) || uri.hasQuery || uri.hasFragment) return null;
    if (hostsApk
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .any((s) => !RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(s.trim()))) {
      return null;
    }
    return uri.replace(path: uri.path.endsWith('/') ? uri.path : '${uri.path}/');
  }

  bool get ligado => origem != null;
  static bool _https(Uri uri) =>
      uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty && !uri.hasFragment;
  bool permite(Uri uri, {bool somenteFeed = false}) {
    final base = origem;
    if (base == null || !_https(uri)) return false;
    if (uri.host == base.host && uri.port == base.port) return true;
    return !somenteFeed && uri.port == 443 && hostsApk.split(',').map((s) => s.trim().toLowerCase()).contains(uri.host);
  }
}

class ApkAtualizacao {
  const ApkAtualizacao(this.abi, this.url, this.bytes, this.sha256);
  final String abi, sha256;
  final Uri url;
  final int bytes;
}

class OfertaAtualizacao {
  const OfertaAtualizacao(this.canal, this.versao, this.build, this.notas, this.assinatura, this.apks);
  final String canal, versao, notas, assinatura;
  final int build;
  final List<ApkAtualizacao> apks;
}

/// Código de um canal fechado (teste ou beta de um grupo): vira um trecho do endereço do feed, por isso só letras,
/// números, `_` e `-`. De 6 a 256 caracteres: curto o bastante para ser ditado a um grupo de testadores.
bool codigoDeCanalValido(String codigo) => RegExp(r'^[A-Za-z0-9_-]{6,256}$').hasMatch(codigo);

/// O pedido foi recusado de vez: endereço fora do permitido, redirecionamento inválido ou resposta definitiva do
/// servidor. Diferente de uma queda de rede, tentar de novo não muda o resultado. Sem detalhes, como as demais falhas.
class RecusaDeAtualizacao extends FormatException {
  const RecusaDeAtualizacao() : super('Não foi possível obter a atualização.');
}

class UpdateFeedClient {
  UpdateFeedClient(this.config, {this.cliente});
  final ConfiguracaoAtualizacao config;
  final http.Client? cliente;
  http.Client? _cliente;
  static const limiteJson = 64 * 1024;
  static const abis = {'arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64', 'universal'};
  static final _hash = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Não usa o cliente de mídia: sem autenticação, identificadores ou registro de URLs.
  /// Redirecionamento é manual, antes de enviar qualquer requisição ao novo destino.
  ///
  /// [aPartirDe]: pede só o resto do arquivo (`Range`), para retomar um download interrompido. O servidor pode
  /// responder 206 (o resto) ou 200 (o arquivo inteiro, se ignorar o pedido); quem chama confere qual veio.
  Future<http.StreamedResponse> abrir(
    Uri uri, {
    bool somenteFeed = false,
    Future<void>? cancelar,
    int? aPartirDe,
  }) async {
    try {
      for (var saltos = 0; saltos <= 3; saltos++) {
        if (!config.permite(uri, somenteFeed: somenteFeed)) throw const RecusaDeAtualizacao();
        final aborto = Completer<void>();
        void abortar() {
          if (!aborto.isCompleted) aborto.complete();
        }

        if (cancelar != null) unawaited(cancelar.then((_) => abortar()));
        final prazo = Timer(const Duration(seconds: 20), abortar);
        final pedido = http.AbortableRequest('GET', uri, abortTrigger: aborto.future)..followRedirects = false;
        if (aPartirDe != null && aPartirDe > 0) pedido.headers['range'] = 'bytes=$aPartirDe-';
        late http.StreamedResponse resposta;
        try {
          resposta = await (cliente ?? (_cliente ??= http.Client())).send(pedido).timeout(const Duration(seconds: 21));
        } finally {
          prazo.cancel();
        }
        if (aborto.isCompleted) {
          await resposta.stream.listen((_) {}).cancel();
          throw const FormatException();
        }
        if ([301, 302, 303, 307, 308].contains(resposta.statusCode)) {
          await resposta.stream.listen((_) {}).cancel();
          final destino = resposta.headers['location'];
          if (destino == null || saltos == 3) throw const RecusaDeAtualizacao();
          uri = uri.resolve(destino);
          continue;
        }
        final aceito = resposta.statusCode == 200 || (resposta.statusCode == 206 && (aPartirDe ?? 0) > 0);
        if (!aceito) {
          await resposta.stream.listen((_) {}).cancel();
          // 5xx pode ser passageiro (vale tentar de novo); o resto é resposta definitiva do servidor.
          if (resposta.statusCode >= 500) throw const FormatException();
          throw const RecusaDeAtualizacao();
        }
        return resposta;
      }
    } on RecusaDeAtualizacao {
      rethrow;
    } catch (_) {
      // Nunca propagar uma ClientException com o caminho secreto do canal de teste.
      throw const FormatException('Não foi possível obter a atualização.');
    }
    throw const FormatException('Redirecionamento inválido.');
  }

  Future<OfertaAtualizacao?> consultar(String canal, {String? codigo}) async {
    if (!config.ligado) return null;
    if (!{'estavel', 'beta', 'teste'}.contains(canal)) throw const FormatException('Canal inválido.');
    if (canal == 'teste' && (codigo == null || !codigoDeCanalValido(codigo))) {
      throw const FormatException('Código inválido.');
    }
    LogRedactionManager.registerToken(codigo);
    final caminho = canal == 'teste' ? 'teste/$codigo/latest.json' : '$canal/latest.json';
    final resposta = await abrir(config.origem!.resolve(caminho), somenteFeed: true);
    final acumulado = <int>[];
    try {
      if ((resposta.contentLength ?? 0) > limiteJson) {
        await resposta.stream.listen((_) {}).cancel();
        throw const FormatException();
      }
      await for (final parte in resposta.stream.timeout(const Duration(seconds: 15))) {
        if (acumulado.length + parte.length > limiteJson) throw const FormatException();
        acumulado.addAll(parte);
      }
      final dados = jsonDecode(utf8.decode(acumulado));
      if (dados is! Map<String, dynamic>) throw const FormatException();
      final versao = dados['versao'];
      final build = dados['build'];
      final notas = dados['notas'];
      final assinatura = dados['assinatura_sha256'];
      final entradas = dados['apks'];
      if (dados['canal'] != canal ||
          versao is! String ||
          versao.length > 64 ||
          !RegExp(r'^\d+\.\d+\.\d+(?:[-.A-Za-z0-9]*)?$').hasMatch(versao) ||
          build is! int ||
          build <= 0 ||
          build > 2100000000 ||
          notas is! String ||
          notas.length > 8000 ||
          assinatura is! String ||
          !_hash.hasMatch(assinatura) ||
          entradas is! List ||
          entradas.isEmpty ||
          entradas.length > abis.length) {
        throw const FormatException();
      }
      final apks = <ApkAtualizacao>[];
      final vistos = <String>{};
      for (final entrada in entradas) {
        if (entrada is! Map<String, dynamic>) throw const FormatException();
        final abi = entrada['abi'];
        final endereco = entrada['url'];
        final bytes = entrada['bytes'];
        final sha = entrada['sha256'];
        final uri = endereco is String && endereco.length <= 2048 ? Uri.tryParse(endereco) : null;
        if (abi is! String ||
            !abis.contains(abi) ||
            !vistos.add(abi) ||
            uri == null ||
            !config.permite(uri) ||
            bytes is! int ||
            bytes <= 0 ||
            bytes > 1024 * 1024 * 1024 ||
            sha is! String ||
            !_hash.hasMatch(sha)) {
          throw const FormatException();
        }
        apks.add(ApkAtualizacao(abi, uri, bytes, sha.toLowerCase()));
      }
      return OfertaAtualizacao(canal, versao, build, notas, assinatura.toLowerCase(), List.unmodifiable(apks));
    } catch (_) {
      throw const FormatException('Feed de atualização inválido.');
    }
  }

  void fechar() => (cliente ?? _cliente)?.close();
}
