import 'package:flutter/material.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cgflix/cgflix_palette.dart';
import '../media/ids.dart';
import '../providers/multi_server_provider.dart';
import 'heisuca_logo.dart';
import 'heisuca_theme.dart';

const heisucaNewsVersion = '2.0.33';
const heisucaNewsAsset = 'assets/heisuca/CHANGELOG_USUARIO.md';

bool heisucaNewsAvailable(BuildContext context) {
  final servers = context.watch<MultiServerProvider?>();
  final id = servers?.serverManager.navigationServerId;
  return id != null && servers!.serverManager.backendForServer(ServerId(id))?.name == 'jellyfin';
}

/// Texto editorial único: o mesmo arquivo acompanha o APK de teste.
class HeisucaNewsScreen extends StatefulWidget {
  const HeisucaNewsScreen({super.key});
  @override
  State<HeisucaNewsScreen> createState() => _HeisucaNewsScreenState();
}

class _HeisucaNewsScreenState extends State<HeisucaNewsScreen> {
  final _text = rootBundle.loadString(heisucaNewsAsset);
  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    // Só marca após o texto poder ser carregado, ao abrir a tela.
    try {
      await _text;
    } catch (_) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('heisuca.news.read', heisucaNewsVersion);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text('Novidades', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 22)),
                  ),
                  const HeisucaLogo(height: 32, apenasSelo: true),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: _text,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Não foi possível abrir as novidades.'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
                    children: [
                      for (final line in snapshot.data!.split('\n').where((line) => line.trim().isNotEmpty))
                        Padding(
                          padding: EdgeInsets.only(top: line.startsWith('#') ? 22 : 12),
                          child: Text(
                            line.replaceFirst(RegExp(r'^#{1,3} '), '').replaceFirst(RegExp(r'^- '), '• '),
                            style: TextStyle(
                              fontFamily: line.startsWith('#') ? HeisucaTheme.fonteTitulo : HeisucaTheme.fonteTexto,
                              fontSize: line.startsWith('## ')
                                  ? 22
                                  : line.startsWith('### ')
                                  ? 17
                                  : 15,
                              height: 1.6,
                              color: line.startsWith('### ') ? palette.accent : palette.onGlass,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sinal local ao item do Sobre; nunca ocupa a superfície da navegação.
class HeisucaNewsEntry extends StatefulWidget {
  const HeisucaNewsEntry({super.key});
  @override
  State<HeisucaNewsEntry> createState() => _HeisucaNewsEntryState();
}

class _HeisucaNewsEntryState extends State<HeisucaNewsEntry> {
  final _prefs = SharedPreferences.getInstance();
  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
    future: _prefs,
    builder: (context, snapshot) {
      final unread = snapshot.hasData && snapshot.data!.getString('heisuca.news.read') != heisucaNewsVersion;
      return FocusableListTile(
        leading: const AppIcon(Symbols.auto_awesome_rounded, fill: 0),
        subtitle: const Text('O que mudou no Heisuca.'),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HeisucaNewsScreen()));
          if (mounted) setState(() {});
        },
        title: Row(
          children: [
            const Text('Novidades'),
            if (unread) ...[
              const SizedBox(width: 8),
              Semantics(
                label: 'Novidades ainda não lidas',
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: context.cgflix.accent, shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
