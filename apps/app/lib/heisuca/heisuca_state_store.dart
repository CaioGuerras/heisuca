import 'dart:async';

import 'package:flutter/material.dart';
import '../cgflix/home/cgflix_actions.dart';
import '../media/media_item.dart';
import '../services/watch_actions.dart';
import '../utils/snackbar_helper.dart';
import 'heisuca_lista_plex.dart';

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

  /// Quantas trocas cada fila já recebeu: só a troca mais nova pode desfazer o que a tela mostra.
  final Map<String, int> _trocas = {};

  int _novaTroca(String fila) => _trocas[fila] = (_trocas[fila] ?? 0) + 1;

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
    // Título de servidor Plex: a lista é a Watchlist da conta (o Plex não tem favorito por servidor).
    final listaDoPlex = ListaDoPlex.de(context, item, client);
    final troca = _novaTroca('f:$key');
    return _emOrdem('f:$key', () async {
      try {
        if (listaDoPlex != null) {
          await listaDoPlex.gravar(next);
        } else {
          if (client == null) throw StateError('Fonte indisponível');
          await client.setFavorite(item, next);
        }
        _favoritoNoServidor[key] = next;
        if (context.mounted) {
          showSuccessSnackBar(
            context,
            listaDoPlex != null
                ? (next ? 'Adicionado à sua lista do Plex' : 'Removido da sua lista do Plex')
                : (next ? 'Adicionado aos favoritos' : 'Removido dos favoritos'),
          );
        }
        return next;
      } catch (_) {
        // Falhou: a tela volta ao que o servidor tem, a não ser que já exista uma escolha mais nova.
        final noServidor = _favoritoNoServidor[key] ?? !next;
        if (_trocas['f:$key'] == troca) {
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

  /// Título de servidor Plex: pergunta à conta se ele está na lista e acerta a tela.
  ///
  /// O título não traz essa resposta (no Plex a lista é da conta, não do servidor). Não desfaz escolha feita na
  /// tela enquanto a pergunta estava a caminho. Fora do Plex não faz nada.
  Future<void> conferirLista(BuildContext context, MediaItem item) async {
    final lista = ListaDoPlex.de(context, item, cgflixClientFor(context, item));
    if (lista == null) return;
    final key = _chave(item);
    final troca = _trocas['f:$key'];
    final bool? naLista;
    try {
      naLista = await lista.estaNaLista();
    } catch (_) {
      return;
    }
    if (naLista == null || _trocas['f:$key'] != troca) return;
    final mudou = isFavorite(item) != naLista;
    _favoritoNoServidor[key] = naLista;
    _favorites[key] = naLista;
    if (mudou) notifyListeners();
  }

  Future<bool> toggleWatched(BuildContext context, MediaItem item) async {
    final key = _chave(item);
    final next = !isWatched(item);
    _vistoNoServidor.putIfAbsent(key, () => !next);

    // Atualização otimista imediata na UI
    _watched[key] = next;
    notifyListeners();

    // O que a gravação precisa é lido já: depois da espera a tela de origem pode ter saído.
    Future<WatchMarkOutcome> Function({required bool watched})? gravar;
    try {
      gravar = WatchActions.prepare(context, item);
    } catch (_) {
      // Sem ter como gravar, a troca falha na vez dela, como qualquer outra.
    }
    final troca = _novaTroca('v:$key');
    return _emOrdem('v:$key', () async {
      try {
        if (gravar == null) throw StateError('Fonte indisponível');
        // Sem fonte para gravar, nada foi marcado: é falha, não sucesso.
        if (await gravar(watched: next) == WatchMarkOutcome.skipped) throw StateError('Fonte indisponível');
        _vistoNoServidor[key] = next;
        if (context.mounted) {
          showSuccessSnackBar(context, next ? 'Marcado como visto' : 'Marcado como não visto');
        }
        return next;
      } catch (_) {
        final noServidor = _vistoNoServidor[key] ?? !next;
        if (_trocas['v:$key'] == troca) {
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
