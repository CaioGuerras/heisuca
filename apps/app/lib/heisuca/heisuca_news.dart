import 'package:flutter/material.dart';
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

/// Aviso único por versão, na sessão Jellyfin, sem alterar o desenho da Início.
class HeisucaNewsNotice extends StatefulWidget {
  const HeisucaNewsNotice({super.key, required this.child});
  final Widget child;
  @override
  State<HeisucaNewsNotice> createState() => _HeisucaNewsNoticeState();
}

class _HeisucaNewsNoticeState extends State<HeisucaNewsNotice> {
  bool _scheduled = false;
  @override
  Widget build(BuildContext context) {
    if (!_scheduled && heisucaNewsAvailable(context)) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
    return widget.child;
  }

  Future<void> _show() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'heisuca.news.notified';
    if (!mounted || prefs.getString(key) == heisucaNewsVersion) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null || ModalRoute.of(context)?.isCurrent == false) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Veja o que mudou no Heisuca.'),
        action: SnackBarAction(
          label: 'Novidades',
          onPressed: () {
            if (mounted) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HeisucaNewsScreen()));
          },
        ),
      ),
    );
    await prefs.setString(key, heisucaNewsVersion);
  }
}
