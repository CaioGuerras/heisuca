import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../media/ids.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/multi_server_provider.dart';
import '../screens/profile/profile_switch_screen.dart';
import '../screens/settings/add_connection_screen.dart';
import 'kids/heisuca_kids_flow.dart';

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
    // Logo depois de adicionar um servidor o perfil ainda está em rebind: antes a escolha era
    // descartada em silêncio (parecia "não funcionou"). Agora espera o binding assentar.
    if (_profiles.isBinding) await _profiles.awaitBindingSettle();
    if (!mounted || !_servers.expectedServerIds.contains(id) || _profiles.isBinding) return;
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
    // Modo infantil: a folha leva a "Gerenciar perfis" (troca sem PIN); some por inteiro.
    if (servers == null || heisucaKidsActive(context)) return const SizedBox.shrink();
    final id = source?.selected;
    final client = id == null ? null : servers.getClientForServer(ServerId(id));
    return ListTile(leading: const Icon(Icons.dns_outlined), title: const Text('Fonte atual'),
      subtitle: Text(client == null ? 'Selecionar servidor' : '${heisucaBackendLabel(client.backend.name)} · ${client.serverName ?? "Servidor"}'),
      trailing: const Icon(Icons.expand_more), onTap: source == null ? null : () => heisucaChooseSource(context));
  }
}


/// Rótulo de backend legível ("Jellyfin", "Plex", "Emby") em vez do nome do enum.
String heisucaBackendLabel(String name) => switch (name) {
  'plex' => 'Plex', 'jellyfin' => 'Jellyfin', 'emby' => 'Emby', _ => name,
};

/// Porta única para adicionar fonte (menu Você, Fonte atual e Configurações).
/// Usa o fluxo real do upstream (AddConnectionScreen: Plex, Jellyfin, Emby). Quando dá certo,
/// espera o rebind do perfil e o servidor novo aparecer, e então PASSA a mostrá-lo; se uma
/// conta Plex trouxe vários servidores, pergunta qual. Nada de sucesso sem servidor de verdade.
Future<void> heisucaAddSource(BuildContext context) async {
  final servers = context.read<MultiServerProvider>();
  final profiles = context.read<ActiveProfileProvider>();
  final selection = context.getInheritedWidgetOfExactType<_SourceSelection>();
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final before = {...servers.expectedServerIds};
  final added = await navigator.push<bool>(
    MaterialPageRoute(builder: (_) => AddConnectionScreen(targetProfile: profiles.active)));
  if (added != true) return;
  if (profiles.isBinding) await profiles.awaitBindingSettle();
  // A conta Plex descobre os servidores depois do login; dá um tempo curto para chegarem.
  List<String> fresh() => servers.expectedServerIds.where((id) => !before.contains(id)).toList();
  final deadline = DateTime.now().add(const Duration(seconds: 12));
  while (fresh().isEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  final news = fresh();
  String name(String id) => servers.getClientForServer(ServerId(id))?.serverName ??
      servers.serverManager.serverDisplayName(ServerId(id));
  if (news.isEmpty) {
    messenger?.showSnackBar(const SnackBar(content: Text(
      'Conexão salva, mas nenhum servidor novo respondeu ainda. Ele aparece em Fonte atual quando conectar.')));
    return;
  }
  var chosen = news.length == 1 ? news.single : null;
  if (chosen == null && navigator.mounted) {
    chosen = await showModalBottomSheet<String>(context: navigator.context, showDragHandle: true,
      builder: (sheet) => SafeArea(child: ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('Qual servidor você quer ver agora?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        for (final id in news) ListTile(leading: const Icon(Icons.dns_rounded), title: Text(name(id)),
          subtitle: Text(heisucaBackendLabel(servers.getClientForServer(ServerId(id))?.backend.name ?? 'Fonte')),
          onTap: () => Navigator.pop(sheet, id)),
      ])));
  }
  if (chosen == null) return;
  await selection?.select(chosen);
  messenger?.showSnackBar(SnackBar(content: Text('Agora você está vendo: ${name(chosen)}')));
}

Future<void> heisucaChooseSource(BuildContext context) async {
  if (heisucaKidsActive(context, listen: false)) return;
  final source = context.getInheritedWidgetOfExactType<_SourceSelection>();
  final servers = context.read<MultiServerProvider?>();
  if (source == null || servers == null) return;
  await showModalBottomSheet<void>(
        context: context, showDragHandle: true, builder: (sheetContext) => SafeArea(child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Escolha uma fonte'), subtitle: Text('As bibliotecas ficam separadas por servidor.')),
          for (final serverId in servers.expectedServerIds) Builder(builder: (_) {
            final other = servers.getClientForServer(ServerId(serverId));
            final online = servers.isServerOnline(ServerId(serverId));
            return ListTile(leading: Icon(online ? Icons.dns : Icons.cloud_off),
              title: Text(other?.serverName ?? servers.serverManager.serverDisplayName(ServerId(serverId))),
              subtitle: Text('${heisucaBackendLabel(other?.backend.name ?? "Fonte")} · ${online ? "Conectado" : "Offline"}'),
              trailing: serverId == source.selected ? const Icon(Icons.check) : null,
              onTap: () { Navigator.pop(sheetContext); source.select(serverId); });
          }),
          ListTile(leading: const Icon(Icons.add_circle_outline_rounded), title: const Text('Adicionar fonte'),
            subtitle: const Text('Outro servidor Jellyfin, Emby ou conta Plex'),
            onTap: () { Navigator.pop(sheetContext); heisucaAddSource(context); }),
          ListTile(leading: const Icon(Icons.manage_accounts), title: const Text('Gerenciar perfis e conexões'),
            onTap: () { Navigator.pop(sheetContext); Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileSwitchScreen())); }),
        ])));
}
