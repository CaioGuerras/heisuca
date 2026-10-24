import 'package:flutter/material.dart';

import '../services/device_performance.dart';
import 'services/heisuca_device_service.dart';

/// Regra inicial do Caio (24/10): pouca memória atual OU 32 bits com até 2 GiB.
/// A preferência de efeitos não pode esconder uma limitação física do aparelho.
int heisucaDeviceTier({
  required bool reduced,
  bool? is64Bit,
  int? memory,
  bool? lowMemory,
}) {
  if (lowMemory == true ||
      (is64Bit == false && memory != null && memory <= 2 * 1024 * 1024 * 1024)) {
    return 2;
  }
  return reduced ? 1 : 0;
}

class HeisucaDeviceScreen extends StatefulWidget {
  const HeisucaDeviceScreen({super.key});

  @override
  State<HeisucaDeviceScreen> createState() => _HeisucaDeviceScreenState();
}

class _HeisucaDeviceScreenState extends State<HeisucaDeviceScreen>
    with WidgetsBindingObserver {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  Future<void> _refresh() async {
    // O singleton já foi iniciado pelo bootstrap; não altera a preferência salva.
    await DevicePerformance.getInstance();
    await HeisucaDeviceService.instance.initialize();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = HeisucaDeviceService.instance.profile;
    final memory = DevicePerformance.totalMemBytes ?? profile.totalMemBytes;
    final bits = DevicePerformance.processIs64Bit;
    final reduced = DevicePerformance.isReduced;
    final tier = heisucaDeviceTier(
      reduced: reduced,
      is64Bit: bits,
      memory: memory,
      lowMemory: profile.lowMemory,
    );
    const labels = ['No máximo', 'Com ajustes', 'No limite'];
    const colors = [Colors.green, Colors.amber, Colors.red];
    return Scaffold(
      appBar: AppBar(title: const Text('Este aparelho')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Semantics(
                  label: 'Desempenho: ${labels[tier]}',
                  child: Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: Container(
                          height: index == tier ? 24 : 12,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors[index].withValues(
                              alpha: index == tier ? 1 : 0.25,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  labels[tier],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (tier == 2)
                  const Text(
                    'Este aparelho roda melhor o Heisuca Lite (em breve).',
                  ),
                if (tier == 0)
                  const Text(
                    'Tudo ligado no orçamento de efeitos visuais. Isso não garante suporte a todos os vídeos.',
                  ),
                if (profile.lowMemory == true)
                  const Text(
                    'O Android sinalizou pouca memória disponível agora.',
                  ),
                if (reduced) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Ajustes ativos para poupar memória e trabalho da interface:',
                  ),
                  const Text(
                    '• Animações que usam o portão de desempenho ficam sem duração.',
                  ),
                  const Text('• Rotação automática de fundos desligada.'),
                  const Text(
                    '• Imagens menores, cache limitado a 64 MiB e até 3 requisições de arte simultâneas.',
                  ),
                  Text(
                    DevicePerformance.isLowEndHardware
                        ? 'Motivo: processo de 32 bits, sinal de pouca RAM ou RAM até aproximadamente 2,2 GiB.'
                        : 'Motivo: preferência de efeitos reduzidos.',
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'RAM: ${memory == null ? "não informada" : "${(memory / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB"}',
                ),
                Text(
                  'Processo: ${bits == null
                      ? "não informado"
                      : bits
                      ? "64 bits"
                      : "32 bits"}',
                ),
                Text(
                  'Pouca RAM (Android): ${DevicePerformance.systemLowRam == null
                      ? "não informado"
                      : DevicePerformance.systemLowRam!
                      ? "sim"
                      : "não"}',
                ),
                const Text(
                  'Decodificação por hardware: não informada nesta tela. Confira o decodificador efetivo nas estatísticas durante a reprodução.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Diagnóstico pelos sinais disponíveis. Não é um teste de reprodução; memória e decodificador dependem do uso e do vídeo.',
                ),
                TextButton(
                  onPressed: _refresh,
                  child: const Text('Atualizar diagnóstico'),
                ),
              ],
            ),
    );
  }
}
