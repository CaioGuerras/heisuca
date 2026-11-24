// Retrospectiva do ano (Caio, 24/11): o servidor (cgf-retrospectiva --publicar) grava o resumo de cada
// pessoa nas DisplayPreferences "retrospectiva" (client "heisuca") dela, uma chave por ano com o JSON.
// O app lê com a sessão da própria conta; é o mesmo conteúdo de heisuca.docaio.com.br/retrospectiva/.
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/multi_server_provider.dart';
import '../../services/jellyfin_client.dart';

/// Um título do top 5. [detalhe] = episódios (série) ou vezes (filme).
class CgflixRetroTitulo {
  const CgflixRetroTitulo({required this.titulo, required this.horas, required this.detalhe, this.id});
  final String titulo;
  final num horas;
  final num detalhe;

  /// Item do pôster (a série, no caso de episódio). Nulo = saiu do acervo.
  final String? id;

  static List<CgflixRetroTitulo> _lista(Object? raw, String campo) => [
    if (raw is List)
      for (final x in raw.whereType<Map>())
        CgflixRetroTitulo(
          titulo: '${x['titulo'] ?? '?'}',
          horas: _num(x['horas']),
          detalhe: _num(x[campo]),
          id: x['id'] is String && (x['id'] as String).isNotEmpty ? x['id'] as String : null,
        ),
  ];
}

num _num(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;

class CgflixRetrospectiva {
  const CgflixRetrospectiva({
    required this.ano,
    required this.ate,
    required this.horas,
    required this.diasComTela,
    required this.titulos,
    required this.episodios,
    required this.filmes,
    this.topSeries = const [],
    this.topFilmes = const [],
    this.generos = const [],
    this.mesForte,
    this.diaDaSemana,
    this.maratonaDia,
    this.maratonaHoras,
  });

  final int ano;

  /// Dia (AAAA-MM-DD) até onde a conta vai.
  final String ate;
  final num horas;
  final num diasComTela;
  final num titulos;
  final num episodios;
  final num filmes;
  final List<CgflixRetroTitulo> topSeries;
  final List<CgflixRetroTitulo> topFilmes;
  final List<String> generos;

  /// Abreviação do servidor (jan…dez).
  final String? mesForte;
  final String? diaDaSemana;
  final String? maratonaDia;
  final num? maratonaHoras;

  factory CgflixRetrospectiva.fromJson(Map<String, Object?> j) {
    final maratona = j['maratona'];
    return CgflixRetrospectiva(
      ano: _num(j['ano']).toInt(),
      ate: '${j['ate'] ?? ''}',
      horas: _num(j['horas']),
      diasComTela: _num(j['dias_com_tela']),
      titulos: _num(j['titulos']),
      episodios: _num(j['episodios']),
      filmes: _num(j['filmes']),
      topSeries: CgflixRetroTitulo._lista(j['top_series'], 'episodios'),
      topFilmes: CgflixRetroTitulo._lista(j['top_filmes'], 'vezes'),
      generos: [if (j['generos'] case final List g) ...g.map((x) => '$x')],
      mesForte: j['mes_forte'] as String?,
      diaDaSemana: j['dia_da_semana'] as String?,
      maratonaDia: maratona is Map ? maratona['dia'] as String? : null,
      maratonaHoras: maratona is Map ? _num(maratona['horas']) : null,
    );
  }

  /// O ano mais recente das preferências (ou [ano], se existir). Nulo = ainda não saiu.
  /// Valor que não decodifica fica de fora (não derruba a tela).
  static CgflixRetrospectiva? escolher(Map<String, Object?> prefs, {String? ano}) {
    final anos = prefs.keys.where((k) => RegExp(r'^\d{4}$').hasMatch(k)).toList()..sort();
    final ordem = [if (ano != null && prefs.containsKey(ano)) ano, ...anos.reversed];
    for (final k in ordem) {
      final raw = prefs[k];
      try {
        final j = raw is String ? jsonDecode(raw) : raw;
        if (j is Map) return CgflixRetrospectiva.fromJson(j.cast<String, Object?>());
      } on FormatException {
        continue;
      }
    }
    return null;
  }
}

/// Textos iguais aos da página web (pt-BR: vírgula decimal, ponto no milhar, no máximo 1 casa).
abstract final class CgflixRetroTexto {
  static const meses = {
    'jan': 'janeiro',
    'fev': 'fevereiro',
    'mar': 'março',
    'abr': 'abril',
    'mai': 'maio',
    'jun': 'junho',
    'jul': 'julho',
    'ago': 'agosto',
    'set': 'setembro',
    'out': 'outubro',
    'nov': 'novembro',
    'dez': 'dezembro',
  };

  static String numero(num n) {
    final arred = (n * 10).round() / 10;
    final inteiro = arred.truncate().abs();
    final digitos = '$inteiro';
    final milhar = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) milhar.write('.');
      milhar.write(digitos[i]);
    }
    final decimal = ((arred.abs() - inteiro) * 10).round();
    return '${arred < 0 ? '-' : ''}$milhar${decimal == 0 ? '' : ',$decimal'}';
  }

  static String plural(num n, String um, String varios) => '${numero(n)} ${n == 1 ? um : varios}';

  /// AAAA-MM-DD -> DD/MM.
  static String data(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : iso;
  }
}

/// De onde a tela tira os dados (os testes usam uma falsa).
abstract interface class CgflixRetrospectivaFonte {
  /// Primeiro nome da conta, para o título.
  String get nome;
  Future<Map<String, Object?>> preferencias();
  String posterUrl(String itemId);

  /// Jellyfin conectado agora, ou nulo (Plex, sem conexão): aí o menu não oferece a tela.
  static CgflixRetrospectivaFonte? of(BuildContext context) {
    if (debugOverride case final fake?) return fake;
    final MultiServerProvider? servers;
    try {
      servers = Provider.of<MultiServerProvider?>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
    final client = servers?.serverManager.navigationOnlineClients.values.whereType<JellyfinClient>().firstOrNull;
    return client == null ? null : _JellyfinRetrospectiva(client);
  }

  static CgflixRetrospectivaFonte? debugOverride;
}

class _JellyfinRetrospectiva implements CgflixRetrospectivaFonte {
  _JellyfinRetrospectiva(this.client);
  final JellyfinClient client;

  @override
  String get nome => client.connection.userName;

  @override
  Future<Map<String, Object?>> preferencias() => client.cgflixFetchRetrospectiva();

  @override
  String posterUrl(String itemId) =>
      client.thumbnailUrl('/Items/${Uri.encodeComponent(itemId)}/Images/Primary', height: 480);
}
