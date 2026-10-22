import 'package:flutter/material.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../services/watch_actions.dart';
import '../utils/snackbar_helper.dart';

/// Gerenciador de estado reativo e instantâneo para Favoritos e Vistos no Heisuca.
/// Garante que o estado nunca fique defasado na interface e que os textos/ícones
/// (coração cheio/vazado, visto/não visto) alternem na hora com feedback tátil.
class HeisucaStateStore extends ChangeNotifier {
  HeisucaStateStore._();
  static final HeisucaStateStore instance = HeisucaStateStore._();

  final Map<String, bool> _favorites = {};
  final Map<String, bool> _watched = {};

  bool isFavorite(MediaItem item) {
    final key = item.globalKey.isNotEmpty ? item.globalKey : item.id;
    if (_favorites.containsKey(key)) {
      return _favorites[key]!;
    }
    return item.isFavorite ?? false;
  }

  bool isWatched(MediaItem item) {
    final key = item.globalKey.isNotEmpty ? item.globalKey : item.id;
    if (_watched.containsKey(key)) {
      return _watched[key]!;
    }
    return item.isWatched;
  }

  Future<bool> toggleFavorite(BuildContext context, MediaItem item) async {
    final key = item.globalKey.isNotEmpty ? item.globalKey : item.id;
    final current = isFavorite(item);
    final next = !current;
    
    // Atualização otimista imediata na UI
    _favorites[key] = next;
    notifyListeners();

    try {
      final client = cgflixClientFor(context, item);
      if (client != null) {
        await client.setFavorite(item, next);
      }
      if (context.mounted) {
        showSuccessSnackBar(
          context,
          next ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
        );
      }
      return next;
    } catch (_) {
      // Reverter em caso de falha de rede
      _favorites[key] = current;
      notifyListeners();
      if (context.mounted) {
        showErrorSnackBar(context, 'Não foi possível atualizar os favoritos');
      }
      return current;
    }
  }

  Future<bool> toggleWatched(BuildContext context, MediaItem item) async {
    final key = item.globalKey.isNotEmpty ? item.globalKey : item.id;
    final current = isWatched(item);
    final next = !current;

    // Atualização otimista imediata na UI
    _watched[key] = next;
    notifyListeners();

    try {
      await WatchActions.setWatched(context, item, watched: next);
      if (context.mounted) {
        showSuccessSnackBar(
          context,
          next ? 'Marcado como visto' : 'Marcado como não visto',
        );
      }
      return next;
    } catch (_) {
      _watched[key] = current;
      notifyListeners();
      if (context.mounted) {
        showErrorSnackBar(context, 'Não foi possível atualizar o status de visto');
      }
      return current;
    }
  }
}
