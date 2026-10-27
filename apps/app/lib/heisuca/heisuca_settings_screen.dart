import 'heisuca_dpad_focus.dart';
import '../services/device_performance.dart';
import 'heisuca_device_status.dart';
import 'heisuca_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../cgflix/cgflix_palette.dart';
import '../providers/theme_provider.dart';
import '../models/transcode_quality_preset.dart';
import '../utils/quality_preset_labels.dart';
import '../services/settings_service.dart' as settings;
import 'heisuca_design_system.dart';
import '../screens/settings/playback_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'heisuca_source_scope.dart';
import 'heisuca_theme.dart';
import 'heisuca_logo.dart';
import '../cgflix/cgflix_theme.dart' show cgflixAppTheme;
import 'services/heisuca_device_service.dart';

/// Tela de Configurações Flagship do Heisuca (炳素華)
/// Filosofia: "Simples para quem assiste, preciso para quem calibra."
/// Reconhecimento de Hardware automático, configurações básicas visíveis e aba técnica Avançada isolada.
/// Totalmente adaptada para os temas Shikkoku (Escuro) e Hisui (Claro).
class HeisucaSettingsScreen extends StatefulWidget {
  const HeisucaSettingsScreen({super.key});

  @override
  State<HeisucaSettingsScreen> createState() => _HeisucaSettingsScreenState();
}

class _HeisucaSettingsScreenState extends State<HeisucaSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HeisucaDeviceService _deviceService = HeisucaDeviceService.instance;

  settings.SettingsService? _settings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _deviceService.addListener(_deviceChanged);
    _deviceService.initialize();
    _loadSettings();
  }

  void _deviceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    try {
      final service = await settings.SettingsService.getInstance();
      if (mounted) setState(() => _settings = service);
    } catch (_) {
      _showSaveError();
    }
  }

  void _showSaveError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível acessar as configurações. Tente novamente.')),
    );
  }

  Future<void> _save<T>(settings.Pref<T> pref, T value) async {
    final service = _settings;
    if (service == null || _saving) return;
    setState(() => _saving = true);
    try {
      await service.write(pref, value);
    } catch (_) {
      _showSaveError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restore() async {
    final service = _settings;
    if (service == null || _saving) return;
    setState(() => _saving = true);
    try {
      // Restaura somente as preferências desta tela, preservando conta e tema.
      await service.reset(settings.SettingsService.defaultQualityPreset);
      await service.reset(settings.SettingsService.skipIntroMode);
      await service.reset(settings.SettingsService.heisucaPreferPortugueseAudio);
      await service.reset(settings.SettingsService.enableHardwareDecoding);
      await service.reset(settings.SettingsService.matchContentFrameRate);
      await service.reset(settings.SettingsService.playbackBufferTier);
    } catch (_) {
      _showSaveError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _deviceService.removeListener(_deviceChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deviceStatus() async {
    await _deviceService.initialize();
    if (!mounted) return;
    final p = _deviceService.profile;
    final settingsNow = _settings;
    final effectsLabel = switch (settingsNow?.read(settings.SettingsService.visualEffects).name) {
      'full' => 'completos', 'reduced' => 'reduzidos', _ => 'automática',
    };
    await DevicePerformance.getInstance();
    if (!mounted) return;
    await showDialog<void>(context: context,
      animationStyle: AnimationStyle(duration: HeisucaMotion.durationFor(context), curve: HeisucaMotion.curve),
      builder: (_) => HeisucaDeviceStatusDialog(
      profile: p, effectsPreference: effectsLabel,
      exoPlayer: settingsNow?.read(settings.SettingsService.useExoPlayer) == true,
      hardwareDecoding: settingsNow?.read(settings.SettingsService.enableHardwareDecoding) != false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = _deviceService.profile;
    final palette = context.cgflix;
    final isLight = palette.isLight;

    final bg = context.cgflix.background;
    final cardBg = context.cgflix.surface;
    final borderColor = context.cgflix.divider;
    final titleColor = context.cgflix.text;
    final subtitleColor = context.cgflix.textOn(context.cgflix.surface);
    final accentColor = context.cgflix.accent;
    final tabBg = context.cgflix.surfaceHigh;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 14.0, left: 20.0, right: 20.0, bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.arrow_back_rounded, color: titleColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10.0),
                        Flexible(
                          child: Text(
                            'Configurações',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTitulo,
                              fontSize: 22.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: context.cgflix.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: context.cgflix.success.withValues(alpha: 0.35), width: 0.6),
                    ),
                    child: const HeisucaLogo(height: 14, siteHeader: true),
                  ),
                ],
              ),
            ),

            // Card "Aparelho Reconhecido" (Termo natural aprovado pelo Caio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: isLight
                      ? [
                          BoxShadow(
                            color: context.cgflix.cardShadow.first.color,
                            blurRadius: 10.0,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Center(
                        child: Icon(Symbols.smartphone_rounded, color: accentColor, size: 24.0),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.deviceName == null ? 'Aparelho' : 'Aparelho Reconhecido',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                          Text(
                            profile.deviceName ?? 'Identificação indisponível',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTitulo,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            profile.hardwareSummary,
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 10.5,
                              color: context.cgflix.textOn(context.cgflix.surface),
                            ),
                          ),
                          TextButton(onPressed: _deviceStatus, child: const Text('Ver funções ativas')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Seletor de Abas (Geral vs Avançado)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              height: 48.0,
              decoration: BoxDecoration(
                color: tabBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: HeisucaDpadFocus(borderRadius: 8, child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: context.cgflix.onAction,
                unselectedLabelColor: subtitleColor,
                tabs: const [
                  Tab(text: 'Geral'),
                  Tab(text: 'Avançado'),
                ],
              )),
            ),

            // Conteúdo das Abas
            Expanded(
              child: AbsorbPointer(
                absorbing: _settings == null || _saving,
                child: TabBarView(
                controller: _tabController,
                physics: const HeisucaSpringPhysics(),
                children: [
                  // Aba 1: Geral (Configurações simples e seguras)
                  _buildGeneralTab(isLight),

                  // Aba 2: Avançado (Área técnica isolada)
                  _buildAdvancedTab(isLight),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(bool isLight) {
    return ListView(
      physics: const HeisucaSpringPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 120.0),
      children: [
        _buildSectionHeader('Aparência e Tema', isLight),
        const SizedBox(height: 8.0),
        LayoutBuilder(builder: (context, constraints) {
          final selected = context.watch<ThemeProvider>().themeMode;
          final choices = [
            ('Shikkoku', 'Escuro', settings.ThemeMode.oled, CgflixPalette.isis),
            ('Hisui', 'Claro', settings.ThemeMode.light, CgflixPalette.heitor),
            ('Hisui escuro', 'Escuro', settings.ThemeMode.dark, CgflixPalette.hisuiDark),
          ];
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final choice in choices)
              SizedBox(
                width: constraints.maxWidth < 380 ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
                child: _buildThemeOptionCard(
                  title: choice.$1,
                  subtitle: choice.$2,
                  preview: choice.$4,
                  isSelected: selected == choice.$3 ||
                      (selected == settings.ThemeMode.system && choice.$3 ==
                          (isLight ? settings.ThemeMode.light : settings.ThemeMode.oled)),
                  onTap: () async {
                    await context.read<ThemeProvider>().setThemeMode(choice.$3);
                  },
                ),
              ),
          ]);
        }),

        const SizedBox(height: 18.0),

        _buildSectionHeader('Reprodução e Vídeo', isLight),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Qualidade de reprodução'),
          subtitle: const Text('Original prioriza reprodução direta. Reduzir exige transcodificação no servidor.'),
        ),
        HeisucaDpadFocus(borderRadius: 8, child: DropdownButton<TranscodeQualityPreset>(
          key: const ValueKey('heisuca-quality'),
          isExpanded: true,
          value: _settings?.read(settings.SettingsService.defaultQualityPreset) ?? TranscodeQualityPreset.original,
          items: TranscodeQualityPreset.displayOrder.map((quality) => DropdownMenuItem(
            value: quality,
            child: Text(qualityPresetLabel(quality)),
          )).toList(),
          onChanged: (value) {
            if (value != null) _save(settings.SettingsService.defaultQualityPreset, value);
          },
        )),
        _buildSwitchTile(
          title: 'Pular Abertura Automático',
          subtitle: 'Usa os marcadores disponíveis no vídeo; sem eles, não avança.',
          value: _settings?.read(settings.SettingsService.skipIntroMode) == settings.SkipMarkerMode.auto,
          isLight: isLight,
          onChanged: (value) => _save(settings.SettingsService.skipIntroMode,
              value ? settings.SkipMarkerMode.auto : settings.SkipMarkerMode.button),
        ),

        const SizedBox(height: 18.0),

        _buildSectionHeader('Áudio e Legendas', isLight),
        _buildSwitchTile(
          title: 'Preferir Áudio em Português',
          subtitle: 'Prefere uma faixa em português disponível; preserva a seleção manual.',
          value: _settings?.read(settings.SettingsService.heisucaPreferPortugueseAudio) ?? false,
          isLight: isLight,
          onChanged: (v) => _save(settings.SettingsService.heisucaPreferPortugueseAudio, v),
        ),
      ],
    );
  }

  Widget _settingsLink(IconData icon, String title, String subtitle, Widget page) => ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
      if (mounted) setState(() {});
    });

  Widget _buildAdvancedTab(bool isLight) {
    final usesExoPlayer = _settings?.read(settings.SettingsService.useExoPlayer) ?? false;
    final accentColor = context.cgflix.accent;
    final cardBg = context.cgflix.surface;
    final borderColor = context.cgflix.divider;
    final titleColor = context.cgflix.text;

    return ListView(
      physics: const HeisucaSpringPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 120.0),
      children: [
        _settingsLink(Icons.play_circle_outline, 'Ao assistir',
          'Gestos, PiP, retomada, abertura e próximo episódio', const PlaybackSettingsScreen()),
        _settingsLink(Icons.tune, 'Vídeo e áudio avançados',
          'Motor, HDR, taxa de quadros, canais e normalização', const PlaybackSettingsScreen(cgflixTechnical: true)),
        _settingsLink(Icons.subtitles_outlined, 'Áudio e legendas',
          'Idiomas, estilo, posição e legendas ASS', const SettingsScreen(heisucaSection: HeisucaSettingsSection.subtitles)),
        _settingsLink(Icons.download_outlined, 'Downloads',
          'Pasta, Wi-Fi e remoção de episódios assistidos', const SettingsScreen(heisucaSection: HeisucaSettingsSection.downloads)),
        const HeisucaSourceTile(),
        _settingsLink(Icons.dns_outlined, 'Gerenciar conexões',
          'Adicionar e administrar serviços do perfil', const SettingsScreen(heisucaSection: HeisucaSettingsSection.sources)),
        _settingsLink(Icons.monitor_heart_outlined, 'Diagnóstico e backup',
          'Logs, desempenho, cache e exportação de ajustes', const SettingsScreen(heisucaSection: HeisucaSettingsSection.diagnostics)),
        const SizedBox(height: 24),
        // Alerta educativo sobre opções avançadas
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: context.cgflix.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: context.cgflix.accent.withValues(alpha: 0.3), width: 0.6),
          ),
          child: Row(
            children: [
              Icon(Symbols.warning_rounded, color: context.cgflix.accent, size: 20.0),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'As alterações serão usadas nas próximas reproduções. O suporte depende do aparelho e do vídeo.',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 11.5,
                    color: context.cgflix.text,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        _buildSectionHeader('Decodificação de vídeo', isLight),
        if (!usesExoPlayer) _buildSwitchTile(
          title: 'Decodificação por Hardware',
          subtitle: 'Permite usar o decodificador do aparelho quando compatível.',
          value: _settings?.read(settings.SettingsService.enableHardwareDecoding) ?? true,
          isLight: isLight,
          onChanged: (v) => _save(settings.SettingsService.enableHardwareDecoding, v),
        ),
        _buildSwitchTile(
          title: 'Ajustar Frequência ao Vídeo',
          subtitle: 'Solicita uma frequência compatível com o vídeo, quando disponível.',
          value: _settings?.read(settings.SettingsService.matchContentFrameRate) ?? false,
          isLight: isLight,
          onChanged: (v) => _save(settings.SettingsService.matchContentFrameRate, v),
        ),

        const SizedBox(height: 16.0),

        _buildSectionHeader('Buffer de Memória RAM', isLight),
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: borderColor, width: 0.6),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: context.cgflix.cardShadow.first.color,
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tamanho do Buffer de Vídeo',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Perfil do motor',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                usesExoPlayer
                    ? 'Perfis de buffer do ExoPlayer.'
                    : 'Buffer mpv limitado à memória do aparelho. Aplicado na próxima reprodução; pode reduzir sob pressão de RAM.',
                style: TextStyle(color: titleColor, fontSize: 12),
              ),
              HeisucaDpadFocus(borderRadius: 8, child: DropdownButton<settings.PlaybackBufferTier>(
                key: const ValueKey('heisuca-buffer'),
                isExpanded: true,
                value: _settings?.read(settings.SettingsService.playbackBufferTier) ?? settings.PlaybackBufferTier.auto,
                items: const [
                  DropdownMenuItem(value: settings.PlaybackBufferTier.auto, child: Text('Automático')),
                  DropdownMenuItem(value: settings.PlaybackBufferTier.large, child: Text('Grande')),
                  DropdownMenuItem(value: settings.PlaybackBufferTier.extraLarge, child: Text('Muito grande')),
                ],
                onChanged: (value) {
                  if (value != null) _save(settings.SettingsService.playbackBufferTier, value);
                },
              )),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Botão Restaurar Configuração Recomendada
        HeisucaSpringPressable(
          onTap: _restore,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cgflix.divider,
              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
              border: Border.all(
                color: context.cgflix.divider,
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                'Restaurar configuração recomendada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.cgflix.text,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: HeisucaTheme.fonteTitulo,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: context.cgflix.textMuted,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool isLight,
    required ValueChanged<bool> onChanged,
  }) {
    final cardBg = context.cgflix.surface;
    final borderColor = context.cgflix.divider;
    final titleColor = context.cgflix.text;
    final subtitleColor = context.cgflix.textOn(context.cgflix.surface);
    final activeColor = context.cgflix.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
          border: Border.all(color: borderColor, width: 0.6),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: context.cgflix.cardShadow.first.color,
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
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
                    title,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 11.5,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            HeisucaDpadFocus(borderRadius: 24, child: Switch(
              value: value,
              onChanged: _settings == null || _saving ? null : (v) {
                HapticFeedback.lightImpact();
                onChanged(v);
              },
              activeThumbColor: activeColor,
              activeTrackColor: activeColor.withValues(alpha: 0.35),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required CgflixPalette preview,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.cgflix;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $subtitle',
      child: HeisucaSpringPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: isSelected ? palette.focusRing : palette.divider,
                width: isSelected ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(color: preview.background, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Theme(
                data: cgflixAppTheme(preview.variant).copyWith(extensions: [preview]),
                child: const HeisucaLogo(height: 24, siteHeader: true),
              )),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 14, fontWeight: FontWeight.w600, color: palette.text)),
            Text(subtitle, style: TextStyle(fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 12, color: palette.textOn(palette.surface))),
          ]),
        ),
      ),
    );
  }
}
