import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'desktop_preferences.dart';

import 'package:flutter/material.dart';

import 'desktop_app.dart';
import 'desktop_playback_controller.dart';
import 'platform/desktop_connection_vault.dart';
import 'remote/desktop_remote_playback.dart';
import 'remote/desktop_servers_controller.dart';
import 'ui/desktop_library_screen.dart';
import 'ui/desktop_cinema_home.dart';
import 'remote/desktop_cinema_controller.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';

/// Owns the desktop session graph; local playback never requires an account.
class DesktopRoot extends StatefulWidget {
  const DesktopRoot({super.key, this.initialSource, this.vault, this.preferences});
  final DesktopConnectionVault? vault;
  final DesktopPreferences? preferences;
  final String? initialSource;

  @override
  State<DesktopRoot> createState() => _DesktopRootState();
}

class _DesktopRootState extends State<DesktopRoot> {
  late final DesktopPlaybackController _playback;
  late final DesktopPreferences _preferences;
  late final DesktopServersController _servers;
  late final DesktopRemotePlaybackCoordinator _remote;
  late final DesktopCinemaController _cinema;
  String? _browseSource;
  MediaItem? _browseItem;
  MediaKind? _browseKind;
  String? _browseSearch;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? DesktopPreferences(file: () async {
      final support = await getApplicationSupportDirectory();
      return File(path.join(support.path, 'heisuca-desktop-preferences.json'));
    });
    unawaited(_preferences.load());
    _playback = DesktopPlaybackController();
    _playback.addListener(_recordLocalProgress);
    _servers = DesktopServersController(vault: widget.vault ?? createDesktopConnectionVault());
    _cinema = DesktopCinemaController(_servers);
    _remote = DesktopRemotePlaybackCoordinator(playback: _playback);
    unawaited(_servers.restore());
  }

  void _recordLocalProgress({bool force = false}) {
    final uri = _playback.localFileUri;
    if (uri == null || !_playback.hasMedia || !_playback.state.hasRenderedFrame) return;
    _preferences.recordLocal(uri: uri, title: _playback.title ?? 'Vídeo',
      positionMs: _playback.state.position.inMilliseconds,
      durationMs: _playback.state.duration.inMilliseconds, force: force);
  }

  Future<void> _beforeClose() async {
    _recordLocalProgress(force: true);
    _servers.cancelAuthentication();
    await Future.wait([_remote.stop(), _servers.flushPersistence(), _preferences.flush()]);
    await _playback.close();
  }

  @override
  void dispose() {
    _playback.removeListener(_recordLocalProgress);
    _remote.dispose();
    if (widget.preferences == null) _preferences.dispose();
    _cinema.dispose();
    _servers.dispose();
    _playback.dispose();
    super.dispose();
  }

  Future<void> _playRemote(DesktopServerConnection server, MediaItem item, int? index) async {
    await _remote.play(server, item, selectedMediaIndex: index);
    if (_remote.error != null) throw StateError(_remote.error!);
  }

  @override
  Widget build(BuildContext context) => DesktopApp(
    controller: _playback,
    preferences: _preferences,
    initialSource: widget.initialSource,
    onBeforeClose: _beforeClose,
    homeBuilder: (context, actions) => DesktopCinemaHome(catalog: _cinema, preferences: _preferences,
      actions: actions, onBrowse: (source, item, kind, search) {
        _browseSource = source?.id; _browseItem = item; _browseKind = kind; _browseSearch = search;
        actions.openLibrary();
      }, onPlay: (server, item) => _playRemote(server, item, null)),
    libraryBuilder: (context) {
      final screen = DesktopLibraryScreen(
        servers: _servers, initialServerId: _browseSource ?? _cinema.source?.id,
        initialItem: _browseItem, initialKind: _browseKind, initialSearch: _browseSearch,
        onServerSelected: _cinema.selectServer,
        onPlay: _playRemote,
      );
      _browseSource = null; _browseItem = null; _browseKind = null; _browseSearch = null;
      return screen;
    },
  );
}
