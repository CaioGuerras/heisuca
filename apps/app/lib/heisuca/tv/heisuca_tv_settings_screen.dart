import '../theme/heisuca_base.dart';
import '../../services/settings_service.dart' as settings;
import '../../cgflix/cgflix_theme_picker.dart';
import '../../providers/theme_provider.dart';
import '../../cgflix/cgflix_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../profiles/active_profile_provider.dart';
import '../../screens/profile/profile_switch_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../services/settings_service.dart';
import '../heisuca_theme.dart';
import 'heisuca_tv_canvas.dart';
import '../../services/updates/update_controller.dart';
import '../../screens/updates/update_settings_screen.dart';

/// Ajustes oficiais do Heisuca na TV — Enxuto.
/// Itens focáveis por D-pad; Atualizações aparece apenas na distribuição direta do Android.
/// 1. Perfil
/// 2. Áudio padrão
/// 3. Legenda padrão
/// 4. Tamanho da legenda
/// 5. "Ainda está aí?" (ligado/desligado)
/// 6. Desempenho na tela
/// 7. Atualizações (direta)
/// 8. Sobre
/// 9. Sair
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
  bool _performanceOverlay = false;

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
      _performanceOverlay = settings.read(SettingsService.showPerformanceOverlay);
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
    await settings?.write(SettingsService.subtitleSearchLanguage, next == 'Português' ? 'por' : null);
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

  Future<void> _togglePerformanceOverlay() async {
    final next = !_performanceOverlay;
    setState(() => _performanceOverlay = next);
    await SettingsService.instanceOrNull?.write(SettingsService.showPerformanceOverlay, next);
  }

  @override
  Widget build(BuildContext context) {
    final atualizacoes = context.watch<UpdateController?>();
    final profiles = context.watch<ActiveProfileProvider?>();
    final activeProfile = profiles?.active;
    final profileName = activeProfile?.displayName ?? 'Família';

    final sizeLabel = switch (_subtitleSize) {
      28 => 'Pequeno (28)',
      48 => 'Grande (48)',
      _ => 'Normal (38)',
    };

    return HeisucaTvCanvas(
      child: Scaffold(
        backgroundColor: context.cgflix.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: context.cgflix.text, size: 32),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ajustes',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: context.cgflix.text,
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
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: false)));
                      },
                    ),
                    const SizedBox(height: 16),
                    _TvSettingsRow(
                      title: 'Tema',
                      value: cgflixThemeName(
                        context.watch<ThemeProvider?>()?.themeMode ??
                            SettingsService.instanceOrNull?.read(SettingsService.themeMode) ??
                            settings.ThemeMode.oled,
                      ),
                      actionLabel: 'Trocar',
                      onTap: () async {
                        final provider = context.read<ThemeProvider>();
                        await provider.setThemeMode(
                          provider.themeMode == settings.ThemeMode.sumi
                              ? settings.ThemeMode.oled
                              : settings.ThemeMode.sumi,
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
                    _TvSettingsRow(title: 'Legenda padrão', value: _subtitleLang, onTap: _toggleSubtitle),
                    const SizedBox(height: 16),
                    _TvSettingsRow(title: 'Tamanho da legenda', value: sizeLabel, onTap: _cycleSubtitleSize),
                    const SizedBox(height: 16),
                    _TvSettingsRow(
                      title: 'Ainda está aí?',
                      value: _stillWatching ? 'Ligado (após 3 episódios)' : 'Desligado',
                      onTap: _toggleStillWatching,
                    ),
                    const SizedBox(height: 16),
                    _TvSettingsRow(
                      title: 'Desempenho na tela',
                      value: _performanceOverlay ? 'Ligado' : 'Desligado',
                      onTap: _togglePerformanceOverlay,
                    ),
                    const SizedBox(height: 16),
                    if (atualizacoes?.permiteAjustes == true) ...[
                      _TvSettingsRow(
                        title: 'Atualizações',
                        value: 'Versões do app e canais de atualização',
                        actionLabel: 'Ver',
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdateSettingsScreen())),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _TvSettingsRow(
                      title: 'Sobre',
                      value: 'Heisuca 2.0 (炳素華) · Créditos Wholphin',
                      actionLabel: 'Ver',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
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
                            backgroundColor: context.cgflix.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Sair do Heisuca?', style: TextStyle(color: context.cgflix.text, fontSize: 26)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: context.cgflix.text.withValues(alpha: 70 / 100),
                                    fontSize: 20,
                                  ),
                                ),
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
          scale: active ? HeisucaBase.focoEscalaTv : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: active ? context.cgflix.text : context.cgflix.surface, // SUP
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? context.cgflix.focusRing : context.cgflix.text.withValues(alpha: 0.08),
                width: active ? HeisucaBase.focoBorda : 1.0,
              ),
              boxShadow: active
                  ? [BoxShadow(color: context.cgflix.text.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: 2)]
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
                              ? (widget.isDestructive ? context.cgflix.danger : context.cgflix.background)
                              : (widget.isDestructive ? context.cgflix.danger : context.cgflix.text),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 22,
                          color: active ? context.cgflix.surfaceHigh : context.cgflix.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.actionLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? context.cgflix.background : context.cgflix.text.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.actionLabel!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: active ? context.cgflix.text : context.cgflix.text,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 30,
                    color: active ? context.cgflix.background : context.cgflix.text.withValues(alpha: 54 / 100),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
