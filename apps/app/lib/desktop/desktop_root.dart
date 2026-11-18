import 'dart:async';

import 'package:flutter/material.dart';

import 'desktop_app.dart';
import 'desktop_playback_controller.dart';
import 'platform/desktop_connection_vault.dart';
import 'remote/desktop_remote_playback.dart';
import 'remote/desktop_servers_controller.dart';
import 'ui/desktop_library_screen.dart';

/// Owns the desktop session graph; local playback never requires an account.
class DesktopRoot extends StatefulWidget {
  const DesktopRoot({super.key, this.initialSource});
  final String? initialSource;

  @override
  State<DesktopRoot> createState() => _DesktopRootState();
}

class _DesktopRootState extends State<DesktopRoot> {
  late final DesktopPlaybackController _playback;
  late final DesktopServersController _servers;
  late final DesktopRemotePlaybackCoordinator _remote;

  @override
  void initState() {
    super.initState();
    _playback = DesktopPlaybackController();
    _servers = DesktopServersController(vault: createDesktopConnectionVault());
    _remote = DesktopRemotePlaybackCoordinator(playback: _playback);
    unawaited(_servers.restore());
  }

  Future<void> _beforeClose() async {
    await _remote.stop();
    await _playback.close();
  }

  @override
  void dispose() {
    _remote.dispose();
    _servers.dispose();
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DesktopApp(
    controller: _playback,
    initialSource: widget.initialSource,
    onBeforeClose: _beforeClose,
    libraryBuilder: (context) => DesktopLibraryScreen(
      servers: _servers,
      onPlay: (server, item, index) async {
        await _remote.play(server, item, selectedMediaIndex: index);
        if (_remote.error != null) throw StateError(_remote.error!);
      },
    ),
  );
}
