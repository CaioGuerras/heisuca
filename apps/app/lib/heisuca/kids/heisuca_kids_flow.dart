// Entrar e sair do modo infantil. Entrar: na 1ª vez, configuração em 3 passos (o que muda;
// tema e classificação; PIN do responsável), ativação no servidor (cgflix-kids) e um perfil local
// ligado ao usuário-sombra. Sair: só com o PIN. A troca usa o caminho oficial de perfis
// (switchProfileFromUi), sob a abertura kids, que esconde a recarga.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../cgflix/cgflix_palette.dart';
import '../../connection/connection.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_activation.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_registry.dart';
import '../../providers/multi_server_provider.dart';
import '../../screens/profile/pin_entry_dialog.dart';
import '../../screens/settings/connection_persistence.dart';
import '../../services/jellyfin_client.dart';
import 'heisuca_kids.dart';
import 'heisuca_kids_identity.dart';
import '../heisuca_security.dart';
import 'heisuca_kids_opening.dart';

/// Modo infantil ativo agora? (o menu, a fonte e os pedidos se escondem por isto).
bool heisucaKidsActive(BuildContext context, {bool listen = true}) {
  final profiles = listen ? context.watch<ActiveProfileProvider?>() : context.read<ActiveProfileProvider?>();
  if (listen) context.watch<HeisucaKids?>();
  return HeisucaKids.instance.isKids(profiles?.activeId);
}

void _say(BuildContext context, String text) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

/// Cliente Jellyfin da fonte em uso (o modo infantil é do servidor, não do aparelho).
JellyfinClient? heisucaKidsJellyfinSource(MultiServerProvider servers) {
  final manager = servers.serverManager;
  final selected = manager.navigationServerId;
  final online = manager.navigationOnlineClients.values.whereType<JellyfinClient>();
  return online.where((c) => c.serverId.value == selected).firstOrNull ?? online.firstOrNull ??
      manager.visibleOnlineClients.values.whereType<JellyfinClient>().firstOrNull;
}

Future<void> heisucaEnterKids(BuildContext context) async {
  final profiles = context.read<ActiveProfileProvider>();
  final registry = context.read<ProfileRegistry>();
  final servers = context.read<MultiServerProvider>();
  final kids = HeisucaKids.instance;
  final parent = profiles.active;
  if (parent == null || kids.isKids(parent.id)) return;

  final existing = kids.forParent(parent.id);
  final existingProfile = existing == null ? null : profiles.profiles.where((p) => p.id == existing.kidsProfileId).firstOrNull;
  if (existing != null && existingProfile != null) {
    await heisucaRunUnderKidsOpening(context, variant: existing.variant, name: existing.name,
      work: () => switchProfileFromUi(context, existingProfile));
    return;
  }

  final client = heisucaKidsJellyfinSource(servers);
  if (client == null) {
    _say(context, 'O modo infantil precisa de um servidor Jellyfin conectado.');
    return;
  }
  final setup = await Navigator.of(context, rootNavigator: true).push<HeisucaKidsSetup>(
    MaterialPageRoute(builder: (_) => const HeisucaKidsSetupScreen()));
  if (setup == null || !context.mounted) return;

  final ({String token, String userId, String name}) session;
  try {
    session = await client.cgflixActivateKids(setup.ceiling);
  } on CgflixKidsException catch (e) {
    if (context.mounted) _say(context, e.message);
    return;
  } catch (_) {
    if (context.mounted) _say(context, 'Sem resposta do servidor. Confira a internet e tente de novo.');
    return;
  }
  if (!context.mounted) return;

  final base = client.connection;
  final now = DateTime.now();
  final connection = JellyfinConnection(
    id: '${base.serverMachineId}/${session.userId}',
    baseUrl: base.baseUrl, baseUrls: base.baseUrls, serverName: base.serverName,
    serverMachineId: base.serverMachineId, userId: session.userId, userName: session.name,
    accessToken: session.token, deviceId: base.deviceId, dialect: base.dialect,
    createdAt: now, lastAuthenticatedAt: now,
  );
  final kidsProfile = Profile.local(id: 'kids-${const Uuid().v4()}', displayName: setup.name, avatarThumbUrl: setup.photo,
    sortOrder: now.millisecondsSinceEpoch, createdAt: now);
  await registry.upsert(kidsProfile);
  if (!context.mounted) return;
  await persistAndBindConnection(context: context, connection: connection, bindToProfile: ProfileConnection(
    profileId: kidsProfile.id, connectionId: connection.id, userToken: session.token,
    userIdentifier: session.userId, tokenAcquiredAt: now));
  await kids.save(HeisucaKidsRecord(parentProfileId: parent.id, kidsProfileId: kidsProfile.id, variant: setup.variant,
    ceiling: setup.ceiling, pinHash: computePinHash(setup.pin), name: setup.name));
  if (!context.mounted) return;
  await heisucaRunUnderKidsOpening(context, variant: setup.variant, name: setup.name,
    work: () => switchProfileFromUi(context, kidsProfile));
}

/// Sai do modo infantil com o PIN do responsável e volta ao perfil dele.
Future<bool> heisucaExitKids(BuildContext context) async {
  final profiles = context.read<ActiveProfileProvider>();
  final record = HeisucaKids.instance.forKids(profiles.activeId);
  if (record == null) return false;
  final parent = profiles.profiles.where((p) => p.id == record.parentProfileId).firstOrNull;
  if (parent == null) {
    _say(context, 'O perfil do responsável não está mais neste aparelho.');
    return false;
  }
  final security = HeisucaSecurity.instance;
  if (security.kidsEnabled(record.parentProfileId) && await security.authenticate('Sair do modo infantil')) {
    if (!context.mounted) return false;
    return switchProfileFromUi(context, parent);
  }
  if (!context.mounted) return false;
  String? error;
  for (var attempt = 0; attempt < 3; attempt++) {
    final pin = await showPinEntryDialog(context, 'PIN do responsável', errorMessage: error);
    if (pin == null || !context.mounted) return false;
    if (verifyPin(pin, record.pinHash)) {
      return switchProfileFromUi(context, parent);
    }
    error = 'PIN incorreto.';
  }
  if (context.mounted) _say(context, 'PIN incorreto. O modo infantil continua.');
  return false;
}

// -------------------------------------------------------------------------------------------
// Primeira vez: 3 passos.

@immutable
class HeisucaKidsSetup {
  const HeisucaKidsSetup({required this.variant, required this.ceiling, required this.name, required this.pin, this.photo});
  final CgflixThemeVariant variant;
  final String ceiling, name, pin;
  final String? photo;
}

class HeisucaKidsSetupScreen extends StatefulWidget {
  const HeisucaKidsSetupScreen({super.key});
  @override
  State<HeisucaKidsSetupScreen> createState() => _HeisucaKidsSetupScreenState();
}

class _HeisucaKidsSetupScreenState extends State<HeisucaKidsSetupScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  String? _photo;
  bool _finishing = false;
  int _step = 0;
  // Sem tema pré-marcado (Caio, 24/10: "pegou o tema de menina automaticamente"): escolha obrigatória.
  CgflixThemeVariant? _variant;
  var _ceiling = 'livre';

  @override
  void dispose() { _pages.dispose(); _name.dispose(); super.dispose(); }

  void _go(int step) {
    setState(() => _step = step);
    _pages.animateToPage(step, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final pin = await captureAndConfirmPin(context, setLabel: 'Crie o PIN do responsável', confirmLabel: 'Repita o PIN',
      onMismatch: (ctx) => ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(const SnackBar(content: Text('Os PINs não conferem.'))));
    if (!mounted) return;
    setState(() => _finishing = false);
    if (pin == null) return;
    final name = _name.text.trim().isEmpty ? 'Criança' : _name.text.trim();
    Navigator.pop(context, HeisucaKidsSetup(variant: _variant!, ceiling: _ceiling, name: name, pin: pin, photo: _photo));
  }

  @override
  Widget build(BuildContext context) {
    final palette = CgflixPalette.forVariant(_variant ?? CgflixThemeVariant.heitor);
    final scheme = Theme.of(context).colorScheme;
    Widget page({required String title, required String body, List<Widget> children = const []}) => ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
        Text(title, style: TextStyle(fontFamily: 'Fredoka', fontVariations: const [FontVariation('wght', 600)],
          fontSize: 28, height: 1.15, color: palette.onGlass)),
        const SizedBox(height: 12),
        Text(body, style: TextStyle(fontSize: 15, height: 1.5, color: palette.textMuted)),
        const SizedBox(height: 24),
        ...children,
      ]);
    Widget choice({required bool selected, required String title, required String subtitle, required VoidCallback onTap, String? asset}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(
        color: selected ? palette.chipSelected : palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? palette.accent : palette.divider, width: selected ? 2 : 1)),
        child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(
          padding: const EdgeInsets.all(16), child: Row(children: [
            if (asset != null) ...[_Figure(asset), const SizedBox(width: 14)],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.onGlass)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: palette.textMuted)),
            ])),
            if (selected) Icon(Icons.check_circle_rounded, color: palette.accent),
          ])))));
    return Theme(data: Theme.of(context).copyWith(colorScheme: scheme.copyWith(primary: palette.accent)), child: Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: palette.onGlass, elevation: 0,
        title: Text('Modo infantil · ${_step + 1} de 3', style: TextStyle(color: palette.onGlass, fontSize: 15))),
      body: SafeArea(child: Column(children: [
        Expanded(child: PageView(controller: _pages, physics: const NeverScrollableScrollPhysics(), children: [
          page(title: 'O Heisuca vira um app para crianças',
            body: 'O servidor passa a mostrar só desenhos e filmes de família, até a classificação que você escolher. '
                'Pedidos, downloads, configurações e troca de perfil ficam escondidos.\n\n'
                'Para sair do modo infantil, o app pede o PIN do responsável.'),
          page(title: 'Para quem é?', body: 'Escolha o nome, a foto e o tema do perfil infantil.', children: [
            TextField(controller: _name, maxLength: 24, textCapitalization: TextCapitalization.words,
              style: TextStyle(color: palette.onGlass),
              decoration: const InputDecoration(labelText: 'Nome da criança', hintText: 'Como aparece no “Oi, …!”')),
            OutlinedButton.icon(icon: const Icon(Icons.add_a_photo_outlined), label: Text(_photo == null ? 'Escolher foto' : 'Foto escolhida · trocar'),
              onPressed: () async {
                try { final photo = await heisucaPickProfilePhoto(); if (mounted && photo != null) setState(() => _photo = photo); }
                catch (_) { if (context.mounted) _say(context, 'Escolha uma imagem de até 8 MB.'); }
              }),
            const SizedBox(height: 14),
            Text('Tema do app', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.onGlass)),
            const SizedBox(height: 10),
            choice(selected: _variant == CgflixThemeVariant.ichigo, title: 'Menina · Ichigo', subtitle: 'Morangos, melancias e corações',
              asset: 'morango', onTap: () => setState(() => _variant = CgflixThemeVariant.ichigo)),
            choice(selected: _variant == CgflixThemeVariant.sorairo, title: 'Menino · Sorairo', subtitle: 'Nuvens, estrelas e aviõezinhos',
              asset: 'aviao', onTap: () => setState(() => _variant = CgflixThemeVariant.sorairo)),
            const SizedBox(height: 14),
            Text('Até qual classificação?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.onGlass)),
            const SizedBox(height: 10),
            choice(selected: _ceiling == 'livre', title: 'Livre', subtitle: 'Recomendado para os pequenos',
              onTap: () => setState(() => _ceiling = 'livre')),
            choice(selected: _ceiling == '10', title: 'Até 10 anos', subtitle: 'Inclui títulos com classificação 10',
              onTap: () => setState(() => _ceiling = '10')),
            const SizedBox(height: 14),

          ]),
          page(title: 'Último passo: o PIN', body: 'Crie um PIN de 4 números. Só com ele o app sai do modo infantil. '
              'Guarde bem: sem o PIN, a saída exige entrar de novo no aparelho.'),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), child: Row(children: [
          if (_step > 0) TextButton(onPressed: () => _go(_step - 1), child: Text('Voltar', style: TextStyle(color: palette.onGlass))),
          const Spacer(),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: palette.action, foregroundColor: palette.onAction,
              minimumSize: const Size(140, 48)),
            onPressed: _finishing ? null : _step < 2 ? () {
              if (_step == 1 && _name.text.trim().isEmpty) { _say(context, 'Informe o nome da criança.'); return; }
              if (_step == 1 && _variant == null) { _say(context, 'Escolha o tema: Menina (Ichigo) ou Menino (Sorairo).'); return; }
              FocusScope.of(context).unfocus(); _go(_step + 1);
            } : _finish,
            child: Text(_step < 2 ? 'Continuar' : 'Criar PIN e ativar')),
        ])),
      ])),
    ));
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: 44, child: SvgPicture.asset('assets/heisuca/kids/$name.svg'));
}
