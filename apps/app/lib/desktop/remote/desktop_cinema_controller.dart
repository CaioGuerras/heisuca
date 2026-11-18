import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../media/media_hub.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import 'desktop_servers_controller.dart';

/// Catálogo da Início, restrito à fonte e à sessão autenticada que o carregou.
class DesktopCinemaController extends ChangeNotifier {
  DesktopCinemaController(this.servers) {
    servers.addListener(synchronize);
    synchronize();
  }
  final DesktopServersController servers;
  DesktopServerConnection? _source;
  Object? _authentication;
  List<MediaHub> _rows = const [];
  int _epoch = 0;
  bool _disposed = false, _loading = false;
  String? _error;
  DesktopServerConnection? get source => _source;
  List<MediaHub> get rows => identical(_source?.client.authenticationSessionId, _authentication) ? _rows : const [];
  bool get loading => _loading || servers.restoring;
  String? get error => _error;
  MediaItem? get featured {
    final items = rows.where((r) => !r.isContinueWatchingHub).expand((r) => r.items)
      .where((i) => i.kind == MediaKind.movie || i.kind == MediaKind.show).toList();
    for (final item in items) {
      if (item.heroArtCandidates(containerAspectRatio: 2.6).isNotEmpty) return item;
    }
    return items.isEmpty ? null : items.first;
  }
  void _notify() { if (!_disposed) notifyListeners(); }
  void synchronize() {
    if (_disposed) return;
    final available = servers.connections;
    DesktopServerConnection? target;
    for (final connection in available) {
      if (connection.id == _source?.id) { target = connection; break; }
    }
    target ??= available.isEmpty ? null : available.first;
    if (target?.id == _source?.id && identical(target?.client, _source?.client) &&
        identical(target?.client.authenticationSessionId, _authentication)) {
      _notify();
      return;
    }
    _source = target;
    _authentication = target?.client.authenticationSessionId;
    _rows = const []; _error = null; _loading = false; _epoch++;
    _notify();
    if (target != null) unawaited(refresh());
  }
  void selectServer(String id) {
    if (_disposed || id == _source?.id) return;
    for (final connection in servers.connections) {
      if (connection.id != id) continue;
      _source = connection; _authentication = connection.client.authenticationSessionId;
      _rows = const []; _error = null; _epoch++;
      unawaited(refresh());
      return;
    }
  }
  Future<void> refresh() async {
    if (_disposed) return;
    final source = _source;
    if (source == null) return;
    final epoch = ++_epoch;
    final session = source.client.authenticationSessionId;
    _authentication = session; _loading = true; _error = null; _notify();
    bool current() => !_disposed && epoch == _epoch && identical(_source?.client, source.client) &&
      identical(source.client.authenticationSessionId, session);
    try {
      final diagnostics = HubFetchDiagnostics();
      final rows = await source.client.fetchGlobalHubs(limit: 16, diagnostics: diagnostics)
        .timeout(const Duration(seconds: 25));
      if (!current()) return;
      _rows = List.unmodifiable(rows.where((r) => r.items.isNotEmpty));
      if (diagnostics.failed) {
        _error = _rows.isEmpty ? 'Não foi possível carregar sua biblioteca.' : 'Parte da biblioteca não pôde ser atualizada.';
      }
    } on Object {
      if (!current()) return;
      _error = 'Não foi possível carregar sua biblioteca. Tente novamente.';
    } finally {
      if (current()) { _loading = false; _notify(); }
      else if (!_disposed && epoch == _epoch && !identical(source.client.authenticationSessionId, session)) { synchronize(); }
    }
  }
  @override
  void dispose() {
    _disposed = true; _epoch++;
    servers.removeListener(synchronize);
    super.dispose();
  }
}
