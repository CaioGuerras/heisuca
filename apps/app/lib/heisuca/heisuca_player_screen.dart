import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'heisuca_design_system.dart';
import 'heisuca_theme.dart';

/// Player Cinematográfico Nativo 20:9 Flagship Heisuca (炳素華)
/// Filosofia: "Nada entre você e o filme."
/// Calibrado para o Motorola Edge 60 Pro (144Hz pOLED, 20:9, Snapdragon 7 Gen 3)
/// Suporta gestos de brilho/volume, botões clicáveis 20:9 e 1.0x, Pular Abertura (▶▶) e gaveta lateral.
class HeisucaPlayerScreen extends StatefulWidget {
  const HeisucaPlayerScreen({
    super.key,
    required this.title,
    this.episodeCode,
    this.initialPosition = Duration.zero,
    this.duration = const Duration(minutes: 166),
  });

  final String title;
  final String? episodeCode;
  final Duration initialPosition;
  final Duration duration;

  @override
  State<HeisucaPlayerScreen> createState() => _HeisucaPlayerScreenState();
}

class _HeisucaPlayerScreenState extends State<HeisucaPlayerScreen> {
  bool _isPlaying = true;
  bool _controlsVisible = true;
  double _volume = 0.85;
  double _brightness = 0.70;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  String _aspectRatio = '20:9';
  double _playbackSpeed = 1.0;
  bool _showSkipOpening = true;
  bool _isDrawerOpen = false;

  late Duration _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    // Forçar orientação landscape e imersão total
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
  }

  void _skipOpening() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentPosition += const Duration(seconds: 85);
      _showSkipOpening = false;
    });
  }

  void _openAspectRatioPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13101C),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formato de Tela (Aspect Ratio)',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF4F1FA),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildOptionRow('20:9 Tela Cheia (Motorola Edge)', _aspectRatio == '20:9', () {
              setState(() => _aspectRatio = '20:9');
              Navigator.pop(ctx);
            }),
            _buildOptionRow('16:9 Original sem cortes', _aspectRatio == '16:9', () {
              setState(() => _aspectRatio = '16:9');
              Navigator.pop(ctx);
            }),
            _buildOptionRow('2.39:1 Cinema Anamórfico', _aspectRatio == '2.39:1', () {
              setState(() => _aspectRatio = '2.39:1');
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  void _openSpeedPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13101C),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Velocidade de Reprodução',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTitulo,
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF4F1FA),
              ),
            ),
            const SizedBox(height: 12.0),
            for (final s in [0.75, 1.0, 1.25, 1.5, 2.0])
              _buildOptionRow('${s}x', _playbackSpeed == s, () {
                setState(() => _playbackSpeed = s);
                Navigator.pop(ctx);
              }),
          ],
        ),
      ),
    );
  }

  void _openAudioSubtitlesSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 320.0,
        decoration: BoxDecoration(
          color: const Color(0xFF13101C),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            // Áudio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Áudio', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 16.0, fontWeight: FontWeight.w700, color: Color(0xFFF4F1FA))),
                  const SizedBox(height: 10.0),
                  _buildOptionRow('Português 5.1 (Dublado)', true, () {}),
                  _buildOptionRow('Inglês Atmos (Original)', false, () {}),
                ],
              ),
            ),
            VerticalDivider(color: Colors.white.withOpacity(0.08), width: 32.0),
            // Legendas (.ASS)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('Legendas', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 16.0, fontWeight: FontWeight.w700, color: Color(0xFFF4F1FA))),
                      SizedBox(width: 6.0),
                      Text('.ASS Estilizada', style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF7A40F2))),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  _buildOptionRow('Desativada', false, () {}),
                  _buildOptionRow('Português (Brasil)', true, () {}),
                  _buildOptionRow('Português (Forçada)', false, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? const Color(0xFF7A40F2) : const Color(0xFFF4F1FA),
              ),
            ),
            if (isSelected)
              const Icon(Symbols.check_rounded, color: Color(0xFF7A40F2), size: 18.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _controlsVisible = !_controlsVisible);
        },
        // Gestos verticais: Brilho (Esquerda) e Volume (Direita)
        onVerticalDragUpdate: (details) {
          final isLeft = details.globalPosition.dx < size.width / 2;
          final delta = -details.primaryDelta! / 200.0;
          setState(() {
            if (isLeft) {
              _brightness = (_brightness + delta).clamp(0.0, 1.0);
              _showBrightnessIndicator = true;
            } else {
              _volume = (_volume + delta).clamp(0.0, 1.0);
              _showVolumeIndicator = true;
            }
          });
        },
        onVerticalDragEnd: (_) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              setState(() {
                _showBrightnessIndicator = false;
                _showVolumeIndicator = false;
              });
            }
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Superfície de Vídeo (libmpv Vulkan Zero-Copy)
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Symbols.movie_rounded, color: Colors.white12, size: 80.0),
              ),
            ),

            // 2. HUD de Brilho (Lado Esquerdo)
            if (_showBrightnessIndicator)
              Positioned(
                left: 36.0,
                top: size.height / 2 - 60.0,
                child: _buildVerticalHud(Symbols.brightness_5_rounded, _brightness),
              ),

            // 3. HUD de Volume (Lado Direito)
            if (_showVolumeIndicator)
              Positioned(
                right: 36.0,
                top: size.height / 2 - 60.0,
                child: _buildVerticalHud(Symbols.volume_up_rounded, _volume),
              ),

            // 4. Controles Sobrepostos (Overlay)
            if (_controlsVisible) ...[
              // Barra Superior (Top Chrome)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // Botão Central de Play / Pause
              Center(
                child: HeisucaSpringPressable(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.0),
                    ),
                    child: Center(
                      child: Icon(
                        _isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                        color: Colors.white,
                        size: 36.0,
                      ),
                    ),
                  ),
                ),
              ),

              // Botão Pular Abertura (▶▶ com setas apontando para a direita!)
              if (_showSkipOpening)
                Positioned(
                  right: 32.0,
                  bottom: 78.0,
                  child: HeisucaSpringPressable(
                    onTap: _skipOpening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E172A).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFF7A40F2).withOpacity(0.6), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7A40F2).withOpacity(0.35),
                            blurRadius: 12.0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '▶▶  Pular Abertura',
                            style: TextStyle(
                              fontFamily: HeisucaTheme.fonteTexto,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF4F1FA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Barra Inferior com Timeline
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomTimelineBar(),
              ),
            ],

            // 5. Gaveta Lateral de Episódios
            if (_isDrawerOpen)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 320.0,
                child: _buildLateralDrawer(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Botão Voltar
          HeisucaSpringPressable(
            onTap: () => Navigator.pop(context),
            child: const Icon(Symbols.arrow_back_rounded, color: Colors.white, size: 24.0),
          ),
          const SizedBox(width: 14.0),

          // Título da Obra
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF4F1FA),
                  ),
                ),
                if (widget.episodeCode != null)
                  Text(
                    widget.episodeCode!,
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),

          // Badge 4K HDR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Text(
              '4K HDR',
              style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFDCD7E8)),
            ),
          ),
          const SizedBox(width: 10.0),

          // Botão Clicável de Aspect Ratio (20:9 ▼)
          HeisucaSpringPressable(
            onTap: _openAspectRatioPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.6),
              ),
              child: Text(
                '$_aspectRatio ▼',
                style: const TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFF4F1FA)),
              ),
            ),
          ),
          const SizedBox(width: 8.0),

          // Botão Clicável de Velocidade (1.0x ▼)
          HeisucaSpringPressable(
            onTap: _openSpeedPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.6),
              ),
              child: Text(
                '${_playbackSpeed}x ▼',
                style: const TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFF4F1FA)),
              ),
            ),
          ),
          const SizedBox(width: 8.0),

          // Botão Áudio & Legendas (.ASS)
          HeisucaSpringPressable(
            onTap: _openAudioSubtitlesSheet,
            child: const Icon(Symbols.subtitles_rounded, color: Colors.white, size: 22.0),
          ),
          const SizedBox(width: 12.0),

          // Botão Gaveta Lateral
          HeisucaSpringPressable(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isDrawerOpen = !_isDrawerOpen);
            },
            child: const Icon(Symbols.video_library_rounded, color: Colors.white, size: 22.0),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTimelineBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra da Timeline
          ClipRRect(
            borderRadius: BorderRadius.circular(3.0),
            child: LinearProgressIndicator(
              value: 0.38,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: const Color(0xFF7A40F2),
              minHeight: 5.0,
            ),
          ),
          const SizedBox(height: 6.0),
          // Timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('42:15', style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFDCD7E8), fontFeatures: [ui.FontFeature.tabularFigures()])),
              Text('-1:23:45', style: TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFDCD7E8), fontFeatures: [ui.FontFeature.tabularFigures()])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalHud(IconData icon, double value) {
    return Container(
      width: 44.0,
      height: 120.0,
      decoration: BoxDecoration(
        color: const Color(0xFF13101C).withOpacity(0.88),
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18.0),
          const SizedBox(height: 8.0),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: RotatedBox(
                quarterTurns: 3,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  color: const Color(0xFF7A40F2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLateralDrawer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF110E1A).withOpacity(0.96),
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.10), width: 0.8)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Episódios', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo, fontSize: 16.0, fontWeight: FontWeight.w700, color: Color(0xFFF4F1FA))),
              GestureDetector(
                onTap: () => setState(() => _isDrawerOpen = false),
                child: const Icon(Symbols.close_rounded, color: Colors.white, size: 20.0),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 10.0),
              itemBuilder: (ctx, idx) {
                final isCurrent = idx == 2;
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF7A40F2).withOpacity(0.18) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: isCurrent ? const Color(0xFF7A40F2) : Colors.transparent, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54.0,
                        height: 32.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF251C33),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Center(
                          child: Text('E${idx + 1}', style: const TextStyle(fontFamily: HeisucaTheme.fonteTexto, fontSize: 11.0, fontWeight: FontWeight.w700, color: Color(0xFFA99FBB))),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'Episódio ${idx + 1}',
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTexto,
                            fontSize: 12.5,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? Colors.white : const Color(0xFFDCD7E8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
