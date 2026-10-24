import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_registry.dart';
import 'heisuca_kids.dart';
import 'heisuca_kids_flow.dart';
import '../../profiles/profile.dart';
import '../../services/jellyfin_client.dart';
import '../../screens/profile/pin_entry_dialog.dart';
import '../../providers/multi_server_provider.dart';
import '../../cgflix/cgflix_palette.dart';

/// Copia para o armazenamento privado: a foto continua válida depois de reiniciar.
Future<String?> heisucaPickProfilePhoto() async {
  final picked = await FilePicker.pickFiles(type: FileType.image, withData: true);
  if (picked == null) return null;
  final bytes = picked.files.single.bytes;
  if (bytes == null || bytes.length > 8 * 1024 * 1024) throw StateError('Escolha uma foto de até 8 MB.');
  final directory = Directory('${(await getApplicationSupportDirectory()).path}/profile-photos');
  await directory.create(recursive: true);
  final file = File('${directory.path}/${const Uuid().v4()}.image');
  await file.writeAsBytes(bytes, flush: true);
  return file.uri.toString();
}

/// Perfil infantil (menu do responsável): nome, foto, tema, classificação e PIN, com retorno visível.
/// A classificação é aplicada no SERVIDOR (cgflix-kids), com a sessão do responsável.
class HeisucaKidsIdentityScreen extends StatefulWidget {
  const HeisucaKidsIdentityScreen({super.key, required this.record});
  final HeisucaKidsRecord record;
  @override State<HeisucaKidsIdentityScreen> createState() => _HeisucaKidsIdentityScreenState();
}

class _HeisucaKidsIdentityScreenState extends State<HeisucaKidsIdentityScreen> {
  late final _name = TextEditingController(text: widget.record.name);
  late CgflixThemeVariant _variant = widget.record.variant;
  late String _ceiling = widget.record.ceiling;
  late String _pinHash = widget.record.pinHash;
  String? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profiles = context.read<ActiveProfileProvider>();
    _photo = profiles.profiles.where((p) => p.id == widget.record.kidsProfileId).firstOrNull?.avatarThumbUrl;
  }

  @override void dispose() { _name.dispose(); super.dispose(); }

  void _say(String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pick() async {
    try { final p = await heisucaPickProfilePhoto(); if (mounted && p != null) setState(() => _photo = p); }
    catch (_) { if (mounted) _say('Não foi possível abrir a foto. Use uma imagem de até 8 MB.'); }
  }

  Future<void> _changePin() async {
    final current = await showPinEntryDialog(context, 'PIN atual do responsável');
    if (current == null || !mounted) return;
    if (!verifyPin(current, _pinHash)) { _say('PIN incorreto.'); return; }
    final pin = await captureAndConfirmPin(context, setLabel: 'Novo PIN', confirmLabel: 'Repita o novo PIN',
      onMismatch: (ctx) => ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(const SnackBar(content: Text('Os PINs não conferem.'))));
    if (pin == null || !mounted) return;
    setState(() => _pinHash = computePinHash(pin));
    _say('Novo PIN pronto. Toque em Salvar.');
  }

  Future<void> _save() async {
    final profiles = context.read<ActiveProfileProvider>();
    final registry = context.read<ProfileRegistry>();
    final servers = context.read<MultiServerProvider>();
    final r = widget.record;
    final name = _name.text.trim();
    if (name.isEmpty) { _say('Informe o nome da criança.'); return; }
    if (profiles.activeId != r.parentProfileId) { _say('Abra esta tela pelo perfil do responsável.'); return; }
    final profile = profiles.profiles.where((p) => p.id == r.kidsProfileId).firstOrNull;
    if (profile == null) { _say('O perfil infantil não está mais neste aparelho.'); return; }
    setState(() => _saving = true);
    try {
      if (_ceiling != r.ceiling) {
        // O teto é do servidor: reativa com a sessão do responsável (o cgflix-kids só atualiza a política).
        final client = heisucaKidsJellyfinSource(servers);
        if (client == null) throw const CgflixKidsException(0);
        await client.cgflixActivateKids(_ceiling);
      }
      await registry.upsert(profile.copyWith(displayName: name, avatarThumbUrl: _photo ?? profile.avatarThumbUrl));
      await HeisucaKids.instance.save(HeisucaKidsRecord(parentProfileId: r.parentProfileId, kidsProfileId: r.kidsProfileId,
        variant: _variant, ceiling: _ceiling, pinHash: _pinHash, name: name));
      if (!mounted) return;
      _say('Perfil infantil salvo.');
      Navigator.pop(context);
    } on CgflixKidsException catch (e) {
      if (mounted) _say(e.status == 0 ? 'Conecte ao servidor Jellyfin para mudar a classificação.' : e.message);
    } catch (_) {
      if (mounted) _say('Não foi possível salvar o perfil.');
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget option(String title, String subtitle, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: .12) : scheme.onSurface.withValues(alpha: .05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: 1.5)),
        child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle),
          trailing: selected ? Icon(Icons.check_circle_rounded, color: scheme.primary) : null, onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))));
    final photo = _photo;
    return Scaffold(appBar: AppBar(title: const Text('Perfil infantil')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: GestureDetector(onTap: _saving ? null : _pick, child: CircleAvatar(radius: 48,
        backgroundColor: scheme.onSurface.withValues(alpha: .08),
        foregroundImage: photo == null ? null : (photo.startsWith('file:') ? FileImage(File.fromUri(Uri.parse(photo))) : NetworkImage(photo)) as ImageProvider,
        child: const Icon(Icons.add_a_photo_outlined, size: 32)))),
      Center(child: TextButton(onPressed: _saving ? null : _pick, child: Text(photo == null ? 'Escolher foto' : 'Trocar foto'))),
      const SizedBox(height: 8),
      TextField(controller: _name, maxLength: 24, textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome da criança', helperText: 'Aparece no "Oi, …!" da abertura')),
      const SizedBox(height: 16),
      const Text('Tema do app', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      option('Menina · Ichigo', 'Morangos, melancias e corações', _variant == CgflixThemeVariant.ichigo,
        () => setState(() => _variant = CgflixThemeVariant.ichigo)),
      option('Menino · Sorairo', 'Nuvens, estrelas e aviõezinhos', _variant == CgflixThemeVariant.sorairo,
        () => setState(() => _variant = CgflixThemeVariant.sorairo)),
      const SizedBox(height: 16),
      const Text('Até qual classificação?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      option('Livre', 'Recomendado para os pequenos', _ceiling == 'livre', () => setState(() => _ceiling = 'livre')),
      option('Até 10 anos', 'Inclui títulos com classificação 10', _ceiling == '10', () => setState(() => _ceiling = '10')),
      const SizedBox(height: 8),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.pin_outlined), title: const Text('Trocar o PIN do responsável'),
        onTap: _saving ? null : _changePin),
      const SizedBox(height: 16),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Salvando…' : 'Salvar')),
    ]));
  }
}
