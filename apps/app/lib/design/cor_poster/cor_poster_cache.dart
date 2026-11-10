import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'paleta_poster.dart';
import 'semente.dart';

/// Guarda a cor de cada pôster e faz a conta fora da thread da tela.
///
/// A parte cara (ler o BlurHash e escolher a cor) não depende do tema e fica
/// guardada por hash. A paleta do tema sai dela na hora, sem custo que apareça.
/// Chame [aquecer] com os itens visíveis: no toque, a cor já está pronta.
class CorPosterCache extends ChangeNotifier {
  CorPosterCache({this.capacidade = 512});

  /// Uma instância para o app todo.
  static final CorPosterCache global = CorPosterCache();

  final int capacidade;
  final LinkedHashMap<String, int> _sementes = LinkedHashMap<String, int>();
  final Map<String, Future<void>> _emCalculo = <String, Future<void>>{};
  final Set<String> _invalidos = <String>{};

  /// A paleta já pronta, ou `null` se a cor desse pôster ainda não foi calculada.
  PaletaPoster? ler(String? hash, PapelDoTema tema) {
    if (hash == null) return null;
    final semente = _sementes.remove(hash);
    if (semente == null) return null;
    _sementes[hash] = semente; // volta para o fim: usado por último
    return PaletaPoster.de(semente: semente, tema: tema);
  }

  /// Calcula, em lote e fora da thread da tela, o que ainda falta de [hashes].
  /// Avisa os ouvintes quando alguma cor nova chega.
  Future<void> aquecer(Iterable<String?> hashes) {
    final pedidos = hashes.whereType<String>().toSet();
    final esperas = <Future<void>>[
      for (final hash in pedidos)
        if (_emCalculo[hash] case final Future<void> emCurso) emCurso,
    ];
    final faltam = <String>[
      for (final hash in pedidos)
        if (!_sementes.containsKey(hash) && !_emCalculo.containsKey(hash) && !_invalidos.contains(hash)) hash,
    ];
    if (faltam.isNotEmpty) {
      final lote = _calcular(faltam);
      for (final hash in faltam) {
        _emCalculo[hash] = lote;
      }
      esperas.add(lote);
    }
    return esperas.isEmpty ? Future<void>.value() : Future.wait(esperas);
  }

  Future<void> _calcular(List<String> faltam) async {
    try {
      final novas = await compute(sementesEmLote, faltam);
      for (final hash in faltam) {
        final semente = novas[hash];
        if (semente == null) {
          _invalidos.add(hash);
        } else {
          _sementes[hash] = semente;
        }
      }
      while (_sementes.length > capacidade) {
        _sementes.remove(_sementes.keys.first);
      }
      if (novas.isNotEmpty) notifyListeners();
    } finally {
      final feitos = faltam.toSet();
      _emCalculo.removeWhere((hash, _) => feitos.contains(hash));
    }
  }

  /// A paleta de [hash], calculando se preciso. `null` para hash inválido.
  Future<PaletaPoster?> paleta(String? hash, PapelDoTema tema) async {
    if (hash == null) return null;
    final pronta = ler(hash, tema);
    if (pronta != null) return pronta;
    await aquecer([hash]);
    return ler(hash, tema);
  }

  @visibleForTesting
  int get guardadas => _sementes.length;
}
