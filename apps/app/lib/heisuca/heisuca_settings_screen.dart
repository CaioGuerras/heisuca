import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../cgflix/cgflix_palette.dart';
import 'heisuca_design_system.dart';
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

  // Preferências Básicas
  bool _preferOriginalQuality = true;
  bool _autoSkipOpening = true;
  bool _preferPortuguese = true;

  // Preferências Avançadas
  bool _useZeroCopyVulkan = true;
  int _ramBufferSizeMb = 256;
  bool _force144Hz = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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
                      'OTIMIZADO',
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
                            'Aparelho Reconhecido',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                          Text(
                            profile.deviceName,
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTitulo,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${profile.chipset} • ${profile.totalRamGb}GB RAM • ${profile.maxRefreshRateHz}Hz pOLED',
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
        _buildSectionHeader('Reprodução e Vídeo', isLight),
        _buildSwitchTile(
          title: 'Qualidade Original Direta',
          subtitle: 'Priorizar Direct Play sem transcodificação',
          value: _preferOriginalQuality,
          isLight: isLight,
          onChanged: (v) => setState(() => _preferOriginalQuality = v),
        ),
        _buildSwitchTile(
          title: 'Pular Abertura Automático',
          subtitle: 'Avança os créditos iniciais automaticamente',
          value: _autoSkipOpening,
          isLight: isLight,
          onChanged: (v) => setState(() => _autoSkipOpening = v),
        ),

        const SizedBox(height: 18.0),

        _buildSectionHeader('Áudio e Legendas', isLight),
        _buildSwitchTile(
          title: 'Preferir Áudio em Português',
          subtitle: 'Selecionar dublagem brasileira automaticamente',
          value: _preferPortuguese,
          isLight: isLight,
          onChanged: (v) => setState(() => _preferPortuguese = v),
        ),
      ],
    );
  }

  Widget _buildAdvancedTab(bool isLight) {
    final accentColor = isLight ? const Color(0xFF047857) : const Color(0xFF7A40F2);
    final cardBg = isLight ? Colors.white : Colors.white.withOpacity(0.03);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.06);
    final titleColor = isLight ? const Color(0xFF134E4A) : const Color(0xFFF4F1FA);

    return ListView(
      physics: const HeisucaSpringPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 120.0),
      children: [
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
                  'As opções abaixo afetam diretamente o motor libmpv e a GPU. Altere apenas se necessário.',
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

        _buildSectionHeader('Motor de Renderização GPU', isLight),
        _buildSwitchTile(
          title: 'Decodificação Zero-Copy Vulkan',
          subtitle: 'HardwareBuffer direto para a GPU sem cópias de memória',
          value: _useZeroCopyVulkan,
          isLight: isLight,
          onChanged: (v) => setState(() => _useZeroCopyVulkan = v),
        ),
        _buildSwitchTile(
          title: 'Taxa de Atualização Máxima (144Hz)',
          subtitle: 'Sincronização vertical contra stuttering em 24fps/60fps',
          value: _force144Hz,
          isLight: isLight,
          onChanged: (v) => setState(() => _force144Hz = v),
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
                    '$_ramBufferSizeMb MB',
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
              Slider(
                value: _ramBufferSizeMb.toDouble(),
                min: 64,
                max: 512,
                divisions: 7,
                activeColor: accentColor,
                inactiveColor: isLight ? const Color(0xFFCBD5E1) : Colors.white.withOpacity(0.1),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _ramBufferSizeMb = v.toInt());
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Botão Restaurar Configuração Recomendada
        HeisucaSpringPressable(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _preferOriginalQuality = true;
              _autoSkipOpening = true;
              _preferPortuguese = true;
              _useZeroCopyVulkan = true;
              _ramBufferSizeMb = 256;
              _force144Hz = true;
            });
          },
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
              onChanged: (v) {
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
}
