import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_registry.dart';
import 'heisuca_kids.dart';

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

class HeisucaKidsIdentityScreen extends StatefulWidget {
  const HeisucaKidsIdentityScreen({super.key, required this.record});
  final HeisucaKidsRecord record;
  @override State<HeisucaKidsIdentityScreen> createState() => _HeisucaKidsIdentityScreenState();
}
class _HeisucaKidsIdentityScreenState extends State<HeisucaKidsIdentityScreen> {
  late final _name = TextEditingController(text: widget.record.name);
  String? _photo;
  bool _saving = false;
  @override void dispose() { _name.dispose(); super.dispose(); }
  Future<void> _pick() async { try { final p = await heisucaPickProfilePhoto(); if (mounted && p != null) setState(() => _photo = p); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir a foto. Use uma imagem de até 8 MB.'))); } }
  Future<void> _save() async {
    final profiles = context.read<ActiveProfileProvider>();
    final r = widget.record;
    if (profiles.activeId != r.parentProfileId) return;
    final profile = profiles.profiles.where((p) => p.id == r.kidsProfileId).firstOrNull;
    if (profile == null || _name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await context.read<ProfileRegistry>().upsert(profile.copyWith(displayName: _name.text.trim(), avatarThumbUrl: _photo ?? profile.avatarThumbUrl));
      await HeisucaKids.instance.save(HeisucaKidsRecord(parentProfileId: r.parentProfileId, kidsProfileId: r.kidsProfileId,
        variant: r.variant, ceiling: r.ceiling, pinHash: r.pinHash, name: _name.text.trim()));
      if (mounted) Navigator.pop(context);
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o perfil.'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Perfil infantil')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      TextField(controller: _name, maxLength: 24, textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome da criança', helperText: 'Também aparece na animação de boas-vindas')),
      if (_photo != null) Center(child: ClipOval(child: Image.file(File.fromUri(Uri.parse(_photo!)), width: 96, height: 96, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 96)))),
      OutlinedButton.icon(onPressed: _saving ? null : _pick, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Escolher foto')),
      const SizedBox(height: 16), FilledButton(onPressed: _saving ? null : _save, child: const Text('Salvar')),
    ]));
}
