import 'dart:async';
import 'update_feed_client.dart';

class UpdateChecker {
  UpdateChecker({
    required this.feed,
    required this.buildInstalado,
    required this.emReproducao,
    required this.lerUltima,
    required this.gravarUltima,
    bool Function()? beta,
    String? Function()? codigo,
    DateTime Function()? agora,
  }) : beta = beta ?? (() => false),
       codigo = codigo ?? (() => null),
       agora = agora ?? DateTime.now;
  final UpdateFeedClient feed;
  final int buildInstalado;
  final bool Function() emReproducao, beta;
  final String? Function() codigo;
  final DateTime? Function() lerUltima;
  final Future<void> Function(DateTime) gravarUltima;
  final DateTime Function() agora;
  bool falhou = false;
  bool limitadoHoje = false;
  OfertaAtualizacao? disponivel;
  Future<OfertaAtualizacao?>? _pendente;

  Future<OfertaAtualizacao?> verificar() => _pendente ??= _verificar().whenComplete(() => _pendente = null);

  Future<OfertaAtualizacao?> _verificar() async {
    falhou = false;
    limitadoHoje = false;
    if (!feed.config.ligado || emReproducao()) return null;
    final instante = agora();
    final ultima = lerUltima();
    if (ultima != null && instante.difference(ultima) < const Duration(hours: 24)) {
      limitadoHoje = true;
      return disponivel;
    }
    final codigoInicial = codigo();
    final betaInicial = beta();
    final canais = codigoInicial?.isNotEmpty == true ? ['teste'] : ['estavel', if (betaInicial) 'beta'];
    try {
      // Reserva persistida antes da rede; falha/reinício não dispara outra consulta no mesmo dia.
      await gravarUltima(instante);
      if (emReproducao()) return null;
      OfertaAtualizacao? melhor;
      var sucessos = 0;
      for (final canal in canais) {
        if (emReproducao()) return null;
        try {
          final oferta = await feed.consultar(canal, codigo: codigoInicial);
          if (oferta != null) sucessos++;
          if (oferta != null && oferta.build > buildInstalado && (melhor == null || oferta.build > melhor.build)) {
            melhor = oferta;
          }
        } catch (_) {
          /* Consulta automática falha em silêncio, sem registrar endereço/código. */
        }
      }
      if (emReproducao() || codigo() != codigoInicial || beta() != betaInicial) return null;
      falhou = sucessos == 0;
      return disponivel = melhor;
    } catch (_) {
      falhou = true;
      return null;
    }
  }
}
