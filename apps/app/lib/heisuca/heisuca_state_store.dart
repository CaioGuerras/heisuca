import 'dart:async';

import 'package:flutter/material.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../services/watch_actions.dart';
import '../utils/snackbar_helper.dart';

/// Gerenciador de estado reativo e instantâneo para Favoritos e Vistos no Heisuca.
/// Garante que o estado nunca fique defasado na interface e que os textos/ícones
/// (coração cheio/vazado, visto/não visto) alternem na hora com feedback tátil.
///
/// A tela muda na hora; as gravações do mesmo título saem para o servidor uma de cada vez, na ordem dos
/// toques. Assim a última escolha é sempre a que fica no servidor.
class HeisucaStateStore extends ChangeNotifier {
  HeisucaStateStore._();
  static final HeisucaStateStore instance = HeisucaStateStore._();

  final Map<String, bool> _favorites = {};
  final Map<String, bool> _watched = {};

  /// O último valor que o servidor confirmou (ou o que o título trazia antes do primeiro toque).
  final Map<String, bool> _favoritoNoServidor = {};
  final Map<String, bool> _vistoNoServidor = {};

  /// A última gravação pendente de cada título, por tipo: a seguinte espera esta terminar.
  final Map<String, Future<void>> _fila = {};

  String _chave(MediaItem item) => item.globalKey.isNotEmpty ? item.globalKey : item.id;

  bool isFavorite(MediaItem item) => _favorites[_chave(item)] ?? item.isFavorite ?? false;

  bool isWatched(MediaItem item) => _watched[_chave(item)] ?? item.isWatched;

  /// Roda [acao] depois de a gravação anterior da mesma [chave] terminar, com ou sem falha.
  Future<T> _emOrdem<T>(String chave, Future<T> Function() acao) async {
    final anterior = _fila[chave];
    final fim = Completer<void>();
    _fila[chave] = fim.future;
    try {
      if (anterior != null) await anterior;
      return await acao();
    } finally {
      fim.complete();
      if (identical(_fila[chave], fim.future)) _fila.remove(chave);
    }
  }

  Future<bool> toggleFavorite(BuildContext context, MediaItem item) async {
    final key = _chave(item);
    final next = !isFavorite(item);
    _favoritoNoServidor.putIfAbsent(key, () => !next);

    // Atualização otimista imediata na UI
    _favorites[key] = next;
    notifyListeners();

    // O cliente é lido já: depois da espera a tela de origem pode ter saído.
    final client = cgflixClientFor(context, item);
    return _emOrdem('f:$key', () async {
      try {
        if (client == null) throw StateError('Fonte indisponível');
        await client.setFavorite(item, next);
        _favoritoNoServidor[key] = next;
        if (context.mounted) {
          showSuccessSnackBar(context, next ? 'Adicionado aos favoritos' : 'Removido dos favoritos');
        }
        return next;
      } catch (_) {
        // Falhou: a tela volta ao que o servidor tem, a não ser que já exista uma escolha mais nova.
        final noServidor = _favoritoNoServidor[key] ?? !next;
        if (_favorites[key] == next) {
          _favorites[key] = noServidor;
          notifyListeners();
        }
        if (context.mounted) {
          showErrorSnackBar(context, 'Não foi possível atualizar os favoritos');
        }
        return noServidor;
      }
    });
  }

  Future<bool> toggleWatched(BuildContext context, MediaItem item) async {
    final key = _chave(item);
    final next = !isWatched(item);
    _vistoNoServidor.putIfAbsent(key, () => !next);

    // Atualização otimista imediata na UI
    _watched[key] = next;
    notifyListeners();

    return _emOrdem('v:$key', () async {
      try {
        if (!context.mounted) throw StateError('Tela fechada antes da gravação');
        await WatchActions.setWatched(context, item, watched: next);
        _vistoNoServidor[key] = next;
        if (context.mounted) {
          showSuccessSnackBar(context, next ? 'Marcado como visto' : 'Marcado como não visto');
        }
        return next;
      } catch (_) {
        final noServidor = _vistoNoServidor[key] ?? !next;
        if (_watched[key] == next) {
          _watched[key] = noServidor;
          notifyListeners();
        }
        if (context.mounted) {
          showErrorSnackBar(context, 'Não foi possível atualizar o status de visto');
        }
        return noServidor;
      }
    });
  }
}
