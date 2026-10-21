import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'heisuca_design_system.dart';
import 'heisuca_theme.dart';
import 'services/heisuca_device_service.dart';

/// Tela de Configurações Flagship do Heisuca (炳素華)
/// Filosofia: "Simples para quem assiste, preciso para quem calibra."
/// Reconhecimento de Hardware automático, configurações básicas visíveis e aba técnica Avançada isolada.
class HeisucaSettingsScreen extends StatefulWidget {
  const HeisucaSettingsScreen({super.key});

  @override
  State<HeisucaSettingsScreen> createState() => _HeisucaSettingsScreenState();
}

class _HeisucaSettingsScreenState extends State<HeisucaSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HeisucaDeviceService _deviceService = HeisucaDeviceService();

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
    final profile = _deviceService.currentProfile;

    return Scaffold(
      backgroundColor: HeisucaTheme.roxoFundo,
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
                  const Text(
                    'Configurações',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Color(0xFFF4F1FA),
                    ),
                  ),
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
                        color: Color(0xFF6EE7B7),
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
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A40F2).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: const Color(0xFF7A40F2).withOpacity(0.4), width: 0.8),
                      ),
                      child: const Center(
                        child: Icon(Symbols.smartphone_rounded, color: Color(0xFF7A40F2), size: 24.0),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aparelho Reconhecido',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFA99FBB),
                            ),
                          ),
                          Text(
                            profile.deviceModel,
                            style: const TextStyle(
                              fontFamily: HeisucaTheme.fonteTitulo,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF4F1FA),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${profile.chipset} • ${profile.ramGb}GB RAM • ${profile.maxRefreshRate}Hz pOLED',
                            style: const TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 10.5,
                              color: Color(0xFF8E859E),
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
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF7A40F2),
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
                unselectedLabelColor: const Color(0xFFA99FBB),
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
                  _buildGeneralTab(),

                  // Aba 2: Avançado (Área técnica isolada)
                  _buildAdvancedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return ListView(
      physics: const HeisucaSpringPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 120.0),
      children: [
        _buildSectionHeader('Reprodução e Vídeo'),
        _buildSwitchTile(
          title: 'Qualidade Original Direta',
          subtitle: 'Priorizar Direct Play sem transcodificação',
          value: _preferOriginalQuality,
          onChanged: (v) => setState(() => _preferOriginalQuality = v),
        ),
        _buildSwitchTile(
          title: 'Pular Abertura Automático',
          subtitle: 'Avança os créditos iniciais automaticamente',
          value: _autoSkipOpening,
          onChanged: (v) => setState(() => _autoSkipOpening = v),
        ),

        const SizedBox(height: 18.0),

        _buildSectionHeader('Áudio e Legendas'),
        _buildSwitchTile(
          title: 'Preferir Áudio em Português',
          subtitle: 'Selecionar dublagem brasileira automaticamente',
          value: _preferPortuguese,
          onChanged: (v) => setState(() => _preferPortuguese = v),
        ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
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
            children: const [
              Icon(Symbols.warning_rounded, color: Color(0xFFFBBF24), size: 20.0),
              SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'As opções abaixo afetam diretamente o motor libmpv e a GPU. Altere apenas se necessário.',
                  style: TextStyle(
                    fontFamily: HeisucaTheme.fonteTexto,
                    fontSize: 11.5,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        _buildSectionHeader('Motor de Renderização GPU'),
        _buildSwitchTile(
          title: 'Decodificação Zero-Copy Vulkan',
          subtitle: 'HardwareBuffer direto para a GPU sem cópias de memória',
          value: _useZeroCopyVulkan,
          onChanged: (v) => setState(() => _useZeroCopyVulkan = v),
        ),
        _buildSwitchTile(
          title: 'Taxa de Atualização Máxima (144Hz)',
          subtitle: 'Sincronização vertical contra stuttering em 24fps/60fps',
          value: _force144Hz,
          onChanged: (v) => setState(() => _force144Hz = v),
        ),

        const SizedBox(height: 16.0),

        _buildSectionHeader('Buffer de Memória RAM'),
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tamanho do Buffer de Vídeo',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF4F1FA),
                    ),
                  ),
                  Text(
                    '$_ramBufferSizeMb MB',
                    style: const TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A40F2),
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
                activeColor: const Color(0xFF7A40F2),
                inactiveColor: Colors.white.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
              border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.8),
            ),
            child: const Center(
              child: Text(
                'Restaurar Configuração Recomendada',
                style: TextStyle(
                  fontFamily: HeisucaTheme.fonteTexto,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF4F1FA),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: HeisucaTheme.fonteTitulo,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFA99FBB),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF4F1FA),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.45),
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
              activeColor: const Color(0xFF7A40F2),
              activeTrackColor: const Color(0xFF7A40F2).withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }
}
