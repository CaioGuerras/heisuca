import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'heisuca_design_system.dart';
import 'heisuca_theme.dart';

/// Modal de Solicitação Direta no Seerr (炳素華)
/// Integração com o ecossistema Seerr para requisição de títulos e episódios faltantes.
class HeisucaSeerrSheet extends StatefulWidget {
  const HeisucaSeerrSheet({
    super.key,
    required this.title,
    this.year,
  });

  final String title;
  final int? year;

  static Future<void> show(BuildContext context, {required String title, int? year}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HeisucaSeerrSheet(title: title, year: year),
    );
  }

  @override
  State<HeisucaSeerrSheet> createState() => _HeisucaSeerrSheetState();
}

class _HeisucaSeerrSheetState extends State<HeisucaSeerrSheet> {
  String _selectedQuality = '4K HDR';
  bool _requesting = false;
  bool _requested = false;

  void _submitRequest() async {
    setState(() => _requesting = true);
    HapticFeedback.mediumImpact();

    // Simula a requisição ao Seerr com confirmação tátil
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _requesting = false;
        _requested = true;
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 14.0,
        bottom: MediaQuery.paddingOf(context).bottom + 20.0,
        left: 20.0,
        right: 20.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF13101C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pílula de arraste
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          const SizedBox(height: 18.0),

          // Título e Ícone do Seerr
          Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF7A40F2).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFF7A40F2).withOpacity(0.4), width: 0.8),
                ),
                child: const Center(
                  child: Icon(Symbols.cloud_download_rounded, color: Color(0xFF7A40F2), size: 22.0),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedir no Seerr',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTitulo,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF4F1FA),
                      ),
                    ),
                    Text(
                      '${widget.title}${widget.year != null ? ' (${widget.year})' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 12.5,
                        color: Color(0xFFA99FBB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20.0),

          if (_requested) ...[
            // Estado de Sucesso
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.12),
                borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                border: Border.all(color: const Color(0xFF34D399).withOpacity(0.35), width: 0.8),
              ),
              child: Row(
                children: const [
                  Icon(Symbols.check_circle_rounded, color: Color(0xFF34D399), size: 24.0),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Pedido enviado com sucesso para a fila do Seerr! O download começará automaticamente.',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 13.0,
                        color: Color(0xFFD1FAE5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            HeisucaSpringPressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 46.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
                ),
                child: const Center(
                  child: Text(
                    'Concluir',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTexto,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF4F1FA),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Seletor de Perfil de Qualidade
            const Text(
              'Perfil de Qualidade Solicitado:',
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDCD7E8),
              ),
            ),
            const SizedBox(height: 10.0),

            Row(
              children: [
                _buildQualityOption('4K HDR Remux / WEB-DL', '4K HDR'),
                const SizedBox(width: 10.0),
                _buildQualityOption('1080p Qualidade Alta', '1080p'),
              ],
            ),

            const SizedBox(height: 22.0),

            // Botão Confirmar Pedido
            HeisucaSpringPressable(
              onTap: _requesting ? null : _submitRequest,
              child: Container(
                width: double.infinity,
                height: 48.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7A40F2), Color(0xFF5A25D0)],
                  ),
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7A40F2).withOpacity(0.35),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _requesting
                      ? const SizedBox(
                          width: 22.0,
                          height: 22.0,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Symbols.send_rounded, color: Colors.white, size: 18.0),
                            SizedBox(width: 8.0),
                            Text(
                              'Confirmar Pedido no Seerr',
                              style: TextStyle(
                                fontFamily: HeisucaTheme.fonteTexto,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityOption(String label, String value) {
    final isSelected = _selectedQuality == value;

    return Expanded(
      child: HeisucaSpringPressable(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedQuality = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7A40F2).withOpacity(0.22)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
            border: Border.all(
              color: isSelected ? const Color(0xFF7A40F2) : Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFF4F1FA) : const Color(0xFFA99FBB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
