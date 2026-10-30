import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../profiles/active_profile_provider.dart';
import '../../screens/profile/profile_switch_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../services/settings_service.dart';
import '../heisuca_theme.dart';

/// Ajustes oficiais do Heisuca na TV — Enxuto.
/// Apenas 7 itens focáveis por D-pad:
/// 1. Perfil
/// 2. Áudio padrão
/// 3. Legenda padrão
/// 4. Tamanho da legenda
/// 5. "Ainda está aí?" (ligado/desligado)
/// 6. Sobre
/// 7. Sair
class HeisucaTvSettingsScreen extends StatefulWidget {
  const HeisucaTvSettingsScreen({super.key});

  @override
  State<HeisucaTvSettingsScreen> createState() => _HeisucaTvSettingsScreenState();
}

class _HeisucaTvSettingsScreenState extends State<HeisucaTvSettingsScreen> {
  bool _preferPortuguese = true;
  String _subtitleLang = 'Português';
  int _subtitleSize = 38;
  bool _stillWatching = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = SettingsService.instanceOrNull;
    if (settings != null) {
      _preferPortuguese = settings.read(SettingsService.heisucaPreferPortugueseAudio);
      _subtitleSize = settings.read(SettingsService.subtitleFontSize);
      final count = settings.read(SettingsService.stillWatchingEpisodes);
      _stillWatching = count > 0;
      final lang = settings.read(SettingsService.subtitleSearchLanguage);
      _subtitleLang = (lang == 'por' || lang == 'pt') ? 'Português' : 'Desligada';
    }
  }

  Future<void> _toggleAudio() async {
    final next = !_preferPortuguese;
    setState(() => _preferPortuguese = next);
    final settings = SettingsService.instanceOrNull;
    await settings?.write(SettingsService.heisucaPreferPortugueseAudio, next);
  }

  Future<void> _toggleSubtitle() async {
    final next = _subtitleLang == 'Português' ? 'Desligada' : 'Português';
    setState(() => _subtitleLang = next);
    final settings = SettingsService.instanceOrNull;
    await settings?.write(
      SettingsService.subtitleSearchLanguage,
      next == 'Português' ? 'por' : null,
    );
  }

  Future<void> _cycleSubtitleSize() async {
    final nextSize = switch (_subtitleSize) {
      28 => 38,
      38 => 48,
      _ => 28,
    };
    setState(() => _subtitleSize = nextSize);
    final settings = SettingsService.instanceOrNull;
    await settings?.write(SettingsService.subtitleFontSize, nextSize);
  }

  Future<void> _toggleStillWatching() async {
    final next = !_stillWatching;
    setState(() => _stillWatching = next);
    final settings = SettingsService.instanceOrNull;
    await settings?.write(SettingsService.stillWatchingEpisodes, next ? 3 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ActiveProfileProvider?>();
    final activeProfile = profiles?.active;
    final profileName = activeProfile?.displayName ?? 'Família';

    final sizeLabel = switch (_subtitleSize) {
      28 => 'Pequeno (28)',
      48 => 'Grande (48)',
      _ => 'Normal (38)',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF17151C),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ajustes',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2EFF5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Lista Enxuta de Ajustes para TV
            Expanded(
              child: ListView(
                children: [
                  _TvSettingsRow(
                    autofocus: true,
                    title: 'Perfil',
                    value: profileName,
                    actionLabel: 'Trocar perfil',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSwitchScreen(requireSelection: false),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _TvSettingsRow(
                    title: 'Áudio padrão',
                    value: _preferPortuguese ? 'Português (dublado)' : 'Idioma original',
                    onTap: _toggleAudio,
                  ),
                  const SizedBox(height: 16),
                  _TvSettingsRow(
                    title: 'Legenda padrão',
                    value: _subtitleLang,
                    onTap: _toggleSubtitle,
                  ),
                  const SizedBox(height: 16),
                  _TvSettingsRow(
                    title: 'Tamanho da legenda',
                    value: sizeLabel,
                    onTap: _cycleSubtitleSize,
                  ),
                  const SizedBox(height: 16),
                  _TvSettingsRow(
                    title: 'Ainda está aí?',
                    value: _stillWatching ? 'Ligado (após 3 episódios)' : 'Desligado',
                    onTap: _toggleStillWatching,
                  ),
                  const SizedBox(height: 16),
                  _TvSettingsRow(
                    title: 'Sobre',
                    value: 'Heisuca 2.0 (炳素華) · Créditos Wholphin',
                    actionLabel: 'Ver',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _TvSettingsRow(
                    title: 'Sair',
                    value: 'Trocar de servidor ou desconectar',
                    isDestructive: true,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF292531),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Sair do Heisuca?', style: TextStyle(color: Colors.white, fontSize: 26)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontSize: 20)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sair', style: TextStyle(fontSize: 20)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        unawaited(SystemNavigator.pop());
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvSettingsRow extends StatefulWidget {
  const _TvSettingsRow({
    required this.title,
    required this.value,
    this.actionLabel,
    required this.onTap,
    this.autofocus = false,
    this.isDestructive = false,
  });

  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback onTap;
  final bool autofocus;
  final bool isDestructive;

  @override
  State<_TvSettingsRow> createState() => _TvSettingsRowState();
}

class _TvSettingsRowState extends State<_TvSettingsRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: active ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : const Color(0xFF292531), // SUP
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.08),
                width: active ? 3.5 : 1.0,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTitulo,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? (widget.isDestructive ? const Color(0xFFC82B3D) : const Color(0xFF17151C))
                              : (widget.isDestructive ? const Color(0xFFEF4444) : const Color(0xFFF2EFF5)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 22,
                          color: active ? const Color(0xFF45404F) : const Color(0xFFB9B1C4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.actionLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF17151C) : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.actionLabel!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : const Color(0xFFF2EFF5),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 30,
                    color: active ? const Color(0xFF17151C) : Colors.white54,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
