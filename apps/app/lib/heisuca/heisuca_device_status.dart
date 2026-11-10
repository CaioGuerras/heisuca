import 'package:flutter/material.dart';

import '../cgflix/cgflix_palette.dart';
import '../services/device_performance.dart';
import 'heisuca_motion.dart';
import 'heisuca_theme.dart';
import 'services/heisuca_device_service.dart';
import 'services/heisuca_frame_measurement.dart';

/// Apresenta os níveis que a política já usa; não cria outra classificação por RAM.
class HeisucaDeviceStatusDialog extends StatefulWidget {
  const HeisucaDeviceStatusDialog({
    super.key,
    required this.profile,
    required this.effectsPreference,
    required this.exoPlayer,
    required this.hardwareDecoding,
    this.frameMeasurement,
  });
  final HeisucaDeviceProfile profile;
  final String effectsPreference;
  final bool exoPlayer;
  final bool hardwareDecoding;
  final HeisucaFrameMeasurement? frameMeasurement;

  @override
  State<HeisucaDeviceStatusDialog> createState() => _HeisucaDeviceStatusDialogState();
}

class _HeisucaDeviceStatusDialogState extends State<HeisucaDeviceStatusDialog> {
  bool _details = false;
  HeisucaFrameMeasurement get _measurement => widget.frameMeasurement ?? HeisucaFrameMeasurement.instance;

  Widget _detailsTransition(BuildContext context, Widget child) {
    if (HeisucaMotion.reduced(context)) return child;
    return AnimatedSize(
      duration: HeisucaMotion.duration,
      curve: HeisucaMotion.curve,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cgflix;
    final p = widget.profile;
    final memory = DevicePerformance.totalMemBytes;
    final reduced = DevicePerformance.isReduced;
    // Sem dados, não apresentar o fallback generoso do cache como hardware de topo.
    final int? tier = reduced
        ? 0
        : memory == null
        ? null
        : DevicePerformance.isFlagshipHardware
        ? 2
        : 1;
    const labels = ['Reduzido', 'Padrão', 'Topo de linha'];
    final ram = memory == null ? null : '${(memory / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
    final reason = reduced
        ? DevicePerformance.isLowEndHardware
              ? 'A memória ou o sistema pedem uma interface mais leve.'
              : 'Você escolheu os efeitos reduzidos.'
        : ram == null
        ? 'O sistema não informou a memória. Os efeitos seguem a sua preferência.'
        : 'O app escolheu este nível com base na memória: $ram.';
    final body = TextStyle(fontFamily: HeisucaTheme.fonteTexto, color: palette.onGlass, fontSize: 15, height: 1.5);
    Widget fact(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text));
    return Dialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: palette.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DefaultTextStyle(
            style: body,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Funções e desempenho',
                    style: TextStyle(
                      fontFamily: HeisucaTheme.fonteTitulo,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: palette.onGlass,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: tier == null ? 'Nível ainda não informado' : 'Nível atual: ${labels[tier]}',
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var index = 0; index < labels.length; index++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: tier == index ? palette.accent : palette.onGlass.withValues(alpha: .12),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      labels[index],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: tier == index ? FontWeight.w700 : FontWeight.w400,
                                        color: palette.onGlass,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(reason),
                  const SizedBox(height: 10),
                  Text(
                    reduced
                        ? 'Menos movimento e imagens mais leves.'
                        : MediaQuery.disableAnimationsOf(context)
                        ? 'Movimento reduzido pelo sistema.'
                        : 'Animações e efeitos completos.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'O nível ajusta a interface e as imagens guardadas na memória. '
                    'O suporte a cada vídeo depende do aparelho e do arquivo.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                  if (p.lowMemory == true) ...[
                    const SizedBox(height: 10),
                    const Text('O Android avisou que há pouca memória disponível agora.'),
                  ],
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _measurement,
                    builder: (context, _) {
                      final hz = View.of(context).display.refreshRate;
                      final result = _measurement.result;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextButton(
                            onPressed: _measurement.measuring || !hz.isFinite || hz <= 0
                                ? null
                                : () => _measurement.start(refreshRate: View.of(context).display.refreshRate),
                            child: Text(_measurement.measuring ? 'Medindo fluidez…' : 'Medir fluidez'),
                          ),
                          Text(
                            _measurement.measuring
                                ? 'Use o app por 20 segundos. Depois volte aqui para ver o resultado.'
                                : result?.summary ??
                                      'Mede a interface enquanto você usa o app. Os dados ficam só neste aparelho.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                          if (_details && result != null && result.frames.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tela: ${result.refreshRate.toStringAsFixed(1)} Hz · limite: ${result.budgetMs.toStringAsFixed(1)} ms',
                            ),
                            Text(
                              'Quadros medidos: ${result.frames.length} · acima do limite: ${result.latePercent.toStringAsFixed(1)}%',
                            ),
                            for (final stage in [
                              (name: 'Construção', value: (HeisucaFrameSample f) => f.build),
                              (name: 'Rasterização', value: (HeisucaFrameSample f) => f.raster),
                              (name: 'Total (inclui fila)', value: (HeisucaFrameSample f) => f.total),
                            ])
                              Text(
                                '${stage.name}: p50 ${result.percentile(.50, stage.value).toStringAsFixed(1)} · '
                                'p90 ${result.percentile(.90, stage.value).toStringAsFixed(1)} · '
                                'p99 ${result.percentile(.99, stage.value).toStringAsFixed(1)} ms',
                              ),
                            const Text(
                              'Acima do limite: construção ou rasterização excedeu o intervalo da tela. '
                              'Até 10%: boa; até 30%: pode melhorar; acima: baixa. Este resultado não mede o vídeo '
                              'e não muda os efeitos automaticamente.',
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    expanded: _details,
                    child: TextButton(
                      onPressed: () => setState(() => _details = !_details),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Detalhes técnicos')),
                          Icon(_details ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  _detailsTransition(
                    context,
                    _details
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              fact('Memória: ${ram ?? "não informada"}'),
                              fact(
                                'Processo: ${DevicePerformance.processIs64Bit == null
                                    ? "não informado"
                                    : DevicePerformance.processIs64Bit!
                                    ? "64 bits"
                                    : "32 bits"}',
                              ),
                              fact('Interface: ${p.renderer ?? "não informada pelo Android"}'),
                              fact(
                                'Tela agora: ${p.currentRefreshRateHz?.round().toString() ?? "não informada"} Hz · máximo: ${p.maxRefreshRateHz?.round().toString() ?? "não informado"} Hz',
                              ),
                              fact('Preferência de efeitos: ${widget.effectsPreference}'),
                              fact(
                                'Reduzir movimento do sistema: ${MediaQuery.disableAnimationsOf(context) ? "ativo" : "desativado"}',
                              ),
                              fact(
                                'Cache de imagens: ${(PaintingBinding.instance.imageCache.maximumSizeBytes / (1024 * 1024)).round()} MiB',
                              ),
                              fact('Motor escolhido: ${widget.exoPlayer ? "ExoPlayer" : "mpv"}'),
                              fact(
                                'Decodificação por hardware: ${widget.hardwareDecoding ? "solicitada" : "desativada"}',
                              ),
                              const Text(
                                'HDR, Dolby Vision e decodificador em uso: confira as informações durante a reprodução.',
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
