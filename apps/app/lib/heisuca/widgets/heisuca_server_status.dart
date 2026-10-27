import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/jellyfin_endpoint_discovery.dart';
import '../../utils/media_server_http_client.dart';
import '../heisuca_theme.dart';

/// Sonda pública cancelável: digitar um endereço não prova conexão.
class HeisucaServerStatus extends StatefulWidget {
  const HeisucaServerStatus({super.key, required this.controller, this.discovery});
  final TextEditingController controller;
  final JellyfinEndpointDiscovery? discovery;

  @override
  State<HeisucaServerStatus> createState() => _HeisucaServerStatusState();
}

class _HeisucaServerStatusState extends State<HeisucaServerStatus> {
  Timer? _debounce;
  AbortController? _abort;
  int _revision = 0;
  String? _lastInput;
  String? _message;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(HeisucaServerStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller || oldWidget.discovery != widget.discovery) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _lastInput = null;
      _changed();
    }
  }

  void _changed() {
    final raw = widget.controller.text.trim();
    if (_lastInput == raw) return;
    _lastInput = raw;
    _debounce?.cancel();
    _abort?.abort();
    final revision = ++_revision;
    _found = false;
    if (raw.isEmpty) {
      setState(() => _message = null);
      return;
    }
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (raw.length < 2 ||
        uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      setState(() => _message = 'Digite o endereço completo do servidor.');
      return;
    }
    setState(() => _message = 'Procurando servidor…');
    final abort = _abort = AbortController();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final info = await (widget.discovery ?? JellyfinEndpointDiscovery()).probe(uri.toString(), abort: abort);
        if (!mounted || abort.isAborted || revision != _revision) return;
        setState(() {
          _found = true;
          final product = info.dialect?.productName ?? 'Servidor';
          _message = '$product${info.version.isEmpty ? "" : " ${info.version}"} · ${info.serverName}';
        });
      } catch (_) {
        if (!mounted || abort.isAborted || revision != _revision) return;
        setState(() => _message = 'Nenhum servidor respondeu. Confira o endereço e a conexão.');
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _revision++;
    _debounce?.cancel();
    _abort?.abort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _found ? const Color(0xFF22C55E) : muted, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 11.5, height: 1.4, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
