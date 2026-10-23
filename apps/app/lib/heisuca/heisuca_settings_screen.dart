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

  @override
  Widget build(BuildContext context) {
    final profile = _deviceService.profile;
    final palette = context.cgflix;
    final isLight = palette.isLight;

    final bg = isLight ? const Color(0xFFF7F3EC) : const Color(0xFF0E0B16);
    final cardBg = isLight ? Colors.white : Colors.white.withOpacity(0.04);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.08);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFFA99FBB);
    final accentColor = isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2);
    final tabBg = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.04);

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
                      color: const Color(0xFF34D399).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: const Color(0xFF34D399).withOpacity(0.35), width: 0.6),
                    ),
                    child: const Text(
                      'HEISUCA',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                        letterSpacing: 0.6,
                      ),
                    ),
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
                            color: Colors.black.withOpacity(0.04),
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
                        color: accentColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: accentColor.withOpacity(0.4), width: 0.8),
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
                              color: isLight ? const Color(0xFF64748B) : const Color(0xFF8E859E),
                            ),
                          ),
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
              height: 40.0,
              decoration: BoxDecoration(
                color: tabBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TabBar(
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
                labelColor: Colors.white,
                unselectedLabelColor: subtitleColor,
                tabs: const [
                  Tab(text: 'Geral'),
                  Tab(text: 'Avançado'),
                ],
              ),
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
        Row(
          children: [
            // Shikkoku (Escuro OLED)
            Expanded(
              child: _buildThemeOptionCard(
                title: 'Shikkoku',
                subtitle: 'Escuro OLED',
                previewBg: const Color(0xFF0B0910),
                sealColor: const Color(0xFF7444E0),
                sealText: '炳',
                isSelected: !isLight,
                isLight: isLight,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await context.read<ThemeProvider>().setThemeMode(settings.ThemeMode.oled);
                },
              ),
            ),
            const SizedBox(width: 12.0),
            // Hisui (Claro Esmeralda)
            Expanded(
              child: _buildThemeOptionCard(
                title: 'Hisui',
                subtitle: 'Claro Esmeralda',
                previewBg: const Color(0xFFF7F3EC),
                sealColor: const Color(0xFF047857),
                sealText: '炳',
                isSelected: isLight,
                isLight: isLight,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await context.read<ThemeProvider>().setThemeMode(settings.ThemeMode.light);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 18.0),

        _buildSectionHeader('Reprodução e Vídeo', isLight),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Qualidade de reprodução'),
          subtitle: const Text('Original prioriza reprodução direta. Reduzir exige transcodificação no servidor.'),
        ),
        DropdownButton<TranscodeQualityPreset>(
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
        ),
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
    final accentColor = isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2);
    final cardBg = isLight ? Colors.white : Colors.white.withOpacity(0.03);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);

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
            color: const Color(0xFFF59E0B).withOpacity(0.10),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 0.6),
          ),
          child: Row(
            children: [
              const Icon(Symbols.warning_rounded, color: Color(0xFFFBBF24), size: 20.0),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'As alterações serão usadas nas próximas reproduções. O suporte depende do aparelho e do vídeo.',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 11.5,
                    color: isLight ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
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
                      color: Colors.black.withOpacity(0.03),
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
                    : 'O libmpv gerencia o buffer automaticamente conforme a memória do aparelho.',
                style: TextStyle(color: titleColor, fontSize: 12),
              ),
              DropdownButton<settings.PlaybackBufferTier>(
                key: const ValueKey('heisuca-buffer'),
                isExpanded: true,
                value: usesExoPlayer
                    ? (_settings?.read(settings.SettingsService.playbackBufferTier) ?? settings.PlaybackBufferTier.auto)
                    : settings.PlaybackBufferTier.auto,
                items: const [
                  DropdownMenuItem(value: settings.PlaybackBufferTier.auto, child: Text('Automático')),
                  DropdownMenuItem(value: settings.PlaybackBufferTier.large, child: Text('Grande')),
                  DropdownMenuItem(value: settings.PlaybackBufferTier.extraLarge, child: Text('Muito grande')),
                ],
                onChanged: !usesExoPlayer ? null : (value) {
                  if (value != null) _save(settings.SettingsService.playbackBufferTier, value);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Botão Restaurar Configuração Recomendada
        HeisucaSpringPressable(
          onTap: _restore,
          child: Container(
            height: 44.0,
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
              border: Border.all(
                color: isLight ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.10),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                'Restaurar Configuração Recomendada',
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA),
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
          color: isLight ? const Color(0xFF047857) : const Color(0xFFA99FBB),
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
    final cardBg = isLight ? Colors.white : Colors.white.withOpacity(0.03);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final subtitleColor = isLight ? const Color(0xFF64748B) : Colors.white.withOpacity(0.45);
    final activeColor = isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2);

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
                    color: Colors.black.withOpacity(0.03),
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
            Switch(
              value: value,
              onChanged: _settings == null || _saving ? null : (v) {
                HapticFeedback.lightImpact();
                onChanged(v);
              },
              activeColor: activeColor,
              activeTrackColor: activeColor.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required Color previewBg,
    required Color sealColor,
    required String sealText,
    required bool isSelected,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    final cardBg = isLight ? Colors.white : Colors.white.withOpacity(0.04);
    final borderColor = isSelected
        ? (isLight ? const Color(0xFF047857) : const Color(0xFF9D74FF))
        : (isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.08));
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);
    final subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFFA99FBB);

    return HeisucaSpringPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 0.8,
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                    blurRadius: 10.0,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview mini box
            Container(
              height: 48.0,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isLight ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.12),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22.0,
                      height: 22.0,
                      decoration: BoxDecoration(
                        color: sealColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Center(
                        child: Text(
                          sealText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'HEISUCA',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTitulo,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isSelected && !isLight
                            ? const Color(0xFFF4F1FA)
                            : (isLight ? const Color(0xFF134E4A) : Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTitulo,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: HeisucaTheme.fonteTexto,
                          fontSize: 10.5,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: isLight ? const Color(0xFF047857) : const Color(0xFF9D74FF),
                    size: 18.0,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

