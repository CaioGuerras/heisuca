import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../media/ids.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/multi_server_provider.dart';
import '../screens/profile/profile_switch_screen.dart';

/// A fonte não altera login, perfil nem a resolução de clientes para downloads.
/// Remontar os consumidores descarta resultados pendentes da navegação anterior.
class HeisucaSourceScope extends StatefulWidget {
  const HeisucaSourceScope({super.key, required this.profileId, required this.child});
  /// Trocar fonte não é abrir uma nova sessão de usuário.
  static bool skipInitialPromptOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SourceSelection>()?.changedByUser ?? false;
  final String? profileId;
  final Widget child;
  @override
  State<HeisucaSourceScope> createState() => _HeisucaSourceScopeState();
}

class _HeisucaSourceScopeState extends State<HeisucaSourceScope> {
  late final MultiServerProvider _servers = context.read<MultiServerProvider>();
  late final ActiveProfileProvider _profiles = context.read<ActiveProfileProvider>();
  SharedPreferences? _prefs;
  String? _selected;
  bool _loaded = false, _changedByUser = false;
  String get _key => 'heisuca.navigation.source.${widget.profileId ?? "local"}';
  @override
  void initState() {
    super.initState();
    _servers.addListener(_changed);
    _profiles.addListener(_changed);
    _restore();
  }
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _prefs = prefs;
    _selected = prefs.getString(_key);
    _loaded = true;
    _changed();
  }
  void _changed() {
    if (!mounted || !_loaded) return;
    // O conjunto esperado inclui servidores offline: uma queda não troca a fonte.
    final ids = _servers.expectedServerIds;
    if (!_profiles.isBinding) {
      if (_selected == null || !ids.contains(_selected)) {
        _selected = ids.firstOrNull;
        if (_selected != null) unawaited(_prefs!.setString(_key, _selected!));
        else unawaited(_prefs!.remove(_key));
      }
    }
    // Durante binding, a identidade salva continua restritiva, nunca libera todos.
    _servers.serverManager.setNavigationSource(this, _selected ?? '__heisuca_no_source__');
    setState(() {});
  }
  Future<void> _select(String id) async {
    if (!_servers.expectedServerIds.contains(id) || _profiles.isBinding) return;
    final saved = await _prefs!.setString(_key, id);
    if (!mounted || !saved) return;
    _selected = id;
    _changedByUser = true;
    _changed();
  }
  @override
  void dispose() {
    _servers.serverManager.clearNavigationSource(this);
    _servers.removeListener(_changed);
    _profiles.removeListener(_changed);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const ColoredBox(color: Color(0xff0e0b14));
    return _SourceSelection(selected: _selected, select: _select, changedByUser: _changedByUser,
      child: KeyedSubtree(key: ValueKey('navigation:$_selected'), child: widget.child));
  }
}

class _SourceSelection extends InheritedWidget {
  const _SourceSelection({required this.selected, required this.select, required this.changedByUser, required super.child});
  final String? selected;
  final bool changedByUser;
  final Future<void> Function(String) select;
  @override
  bool updateShouldNotify(_SourceSelection oldWidget) => selected != oldWidget.selected || changedByUser != oldWidget.changedByUser;
}

class HeisucaSourceTile extends StatelessWidget {
  const HeisucaSourceTile({super.key});
  @override
  Widget build(BuildContext context) {
    final source = context.dependOnInheritedWidgetOfExactType<_SourceSelection>();
    final servers = context.watch<MultiServerProvider?>();
    if (servers == null) return const SizedBox.shrink();
    final id = source?.selected;
    final client = id == null ? null : servers.getClientForServer(ServerId(id));
    return ListTile(leading: const Icon(Icons.dns_outlined), title: const Text('Fonte atual'),
      subtitle: Text(client == null ? 'Selecionar servidor' : '${client.backend.name} · ${client.serverName ?? "Servidor"}'),
      trailing: const Icon(Icons.expand_more), onTap: source == null ? null : () => showModalBottomSheet<void>(
        context: context, showDragHandle: true, builder: (sheetContext) => SafeArea(child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Escolha uma fonte'), subtitle: Text('As bibliotecas ficam separadas por servidor.')),
          for (final serverId in servers.expectedServerIds) Builder(builder: (_) {
            final other = servers.getClientForServer(ServerId(serverId));
            final online = servers.isServerOnline(ServerId(serverId));
            return ListTile(leading: Icon(online ? Icons.dns : Icons.cloud_off),
              title: Text(other?.serverName ?? servers.serverManager.serverDisplayName(ServerId(serverId))),
              subtitle: Text('${other?.backend.name ?? "Fonte"} · ${online ? "Conectado" : "Offline"}'),
              trailing: serverId == source.selected ? const Icon(Icons.check) : null,
              onTap: () { Navigator.pop(sheetContext); source.select(serverId); });
          }),
          ListTile(leading: const Icon(Icons.manage_accounts), title: const Text('Gerenciar perfis e conexões'),
            onTap: () { Navigator.pop(sheetContext); Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileSwitchScreen())); }),
        ]))));
  }
}
