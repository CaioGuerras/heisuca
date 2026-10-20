// Controles M3 das Configurações (refino 2b, versão 1.6.1):
//   - números viram um controle deslizante (Slider) direto na lista, com o valor no resumo;
//   - cores viram uma escolha de círculos (com check no escolhido e o nome para o leitor de tela),
//     no lugar do quadrado solto que abria um campo de código de cor;
//   - prévia ao vivo da legenda no topo de "Estilo das legendas".
// Ganchos de uma linha em `SettingNumberTile` e `SettingColorTile` (lib/widgets/setting_tile.dart):
// só valem dentro das Configurações ([CgflixSettingsLook]).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../screens/settings/settings_utils.dart';
import '../services/settings_mutation_service.dart';
import '../services/settings_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/settings_builder.dart';
import 'cgflix_config_itens.dart';

Future<void> _write<T>(BuildContext context, Pref<T> pref, T value, FutureOr<void> Function(T)? after) async {
  final failure = await const SettingsMutationService().write(context, pref, value);
  if (failure != null && context.mounted) showErrorSnackBar(context, failure.display);
  if (after != null) await after(value);
}

/// Número como controle deslizante: título, valor atual no resumo e o Slider embaixo. Grava ao
/// soltar (o valor do resumo acompanha o dedo).
class CgflixSliderSetting extends StatefulWidget {
  const CgflixSliderSetting({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.subtitleBuilder,
    required this.min,
    required this.max,
    this.onAfterWrite,
  });

  final Pref<int> pref;
  final IconData icon;
  final String title;
  final String Function(int) subtitleBuilder;
  final int min;
  final int max;
  final FutureOr<void> Function(int)? onAfterWrite;

  @override
  State<CgflixSliderSetting> createState() => _CgflixSliderSettingState();
}

class _CgflixSliderSettingState extends State<CgflixSliderSetting> {
  int? _dragging;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SettingsService.instance.listenable(widget.pref),
      builder: (context, stored, _) {
        final value = (_dragging ?? stored).clamp(widget.min, widget.max);
        final label = widget.subtitleBuilder(value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: ListTile(
                leading: AppIcon(widget.icon),
                title: Text(widget.title),
                subtitle: Text(label),
                minTileHeight: 56,
              ),
            ),
            Padding(
              // Alinhado com o texto (16 de margem + 24 do ícone + 16 de espaço).
              padding: const EdgeInsetsDirectional.only(start: 40, end: 4),
              child: Slider(
                value: value.toDouble(),
                min: widget.min.toDouble(),
                max: widget.max.toDouble(),
                divisions: widget.max - widget.min,
                label: label,
                semanticFormatterCallback: (v) => '${widget.title}: ${widget.subtitleBuilder(v.round())}',
                onChanged: (v) => setState(() => _dragging = v.round()),
                onChangeEnd: (v) async {
                  final picked = v.round();
                  await _write(context, widget.pref, picked, widget.onAfterWrite);
                  if (mounted) setState(() => _dragging = null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cor como escolha M3: círculos de 40 dp (toque de 48 dp) com check no escolhido; "Outra cor"
/// abre o seletor completo do upstream.
class CgflixColorChoice extends StatelessWidget {
  const CgflixColorChoice({super.key, required this.pref, required this.icon, required this.title, this.onAfterWrite});

  final Pref<String> pref;
  final IconData icon;
  final String title;
  final FutureOr<void> Function(String hex)? onAfterWrite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (context, hex, _) {
        final current = hex.toUpperCase();
        final custom = !cgflixSubtitleColors.containsKey(current);
        Widget circle({
          required Color color,
          required String name,
          required bool selected,
          required VoidCallback onTap,
          Widget? child,
        }) {
          final dark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
          return Semantics(
            label: name,
            selected: selected,
            inMutuallyExclusiveGroup: true,
            button: true,
            child: Tooltip(
              message: name,
              child: InkResponse(
                onTap: onTap,
                radius: 24,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? scheme.primary : scheme.outline, width: selected ? 3 : 1),
                      ),
                      child: ExcludeSemantics(
                        child:
                            child ??
                            (selected
                                ? Icon(Symbols.check_rounded, size: 22, color: dark ? Colors.white : Colors.black)
                                : null),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: AppIcon(icon),
              title: Text(title),
              subtitle: Text(cgflixSubtitleColorName(current)),
              minTileHeight: 56,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 44, end: 8, bottom: 8),
              child: Wrap(
                children: [
                  for (final MapEntry(key: value, value: name) in cgflixSubtitleColors.entries)
                    circle(
                      color: hexToColor(value),
                      name: name,
                      selected: value == current,
                      onTap: () => _write(context, pref, value, onAfterWrite),
                    ),
                  circle(
                    color: custom ? hexToColor(current) : scheme.surfaceContainerHighest,
                    name: 'Outra cor',
                    selected: custom,
                    onTap: () => showColorInputDialog(
                      context: context,
                      title: title,
                      currentHex: hex,
                      onSave: (v) => _write(context, pref, v, onAfterWrite),
                    ),
                    child: custom ? null : Icon(Symbols.palette_rounded, size: 20, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Prévia ao vivo da legenda: uma cena escura (o player é sempre escuro) com uma frase de exemplo
/// no tamanho, cor, contorno e fundo escolhidos.
class CgflixSubtitlePreview extends StatelessWidget {
  const CgflixSubtitlePreview({super.key});

  static const _prefs = <Pref<Object?>>[
    SettingsService.subtitleFontSize,
    SettingsService.subtitleTextColor,
    SettingsService.subtitleBorderSize,
    SettingsService.subtitleBorderColor,
    SettingsService.subtitleBackgroundColor,
    SettingsService.subtitleBackgroundOpacity,
    SettingsService.subtitleBold,
    SettingsService.subtitleItalic,
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsBuilder(
      prefs: _prefs,
      builder: (context) {
        final svc = SettingsService.instance;
        // 38 (o padrão) aparece com 18 de letra; a prévia não segue a fonte grande do sistema
        // porque mostra o tamanho da legenda no vídeo, que também não segue.
        final size = (svc.read(SettingsService.subtitleFontSize) * 18 / 38).clamp(8.0, 40.0);
        final border = svc.read(SettingsService.subtitleBorderSize).toDouble();
        final style = TextStyle(
          fontSize: size,
          height: 1.25,
          fontWeight: svc.read(SettingsService.subtitleBold) ? FontWeight.w700 : FontWeight.w500,
          fontStyle: svc.read(SettingsService.subtitleItalic) ? FontStyle.italic : FontStyle.normal,
        );
        final opacity = svc.read(SettingsService.subtitleBackgroundOpacity) / 100;
        const sample = 'Assim fica a legenda no vídeo.';
        return Semantics(
          label: 'Prévia da legenda',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    // Cena neutra (noite azulada), igual nos dois temas.
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A5068), Color(0xFF1B2A3A), Color(0xFF0B1118)],
                    ),
                  ),
                  child: Align(
                    alignment: const Alignment(0, 0.8),
                    child: MediaQuery.withNoTextScaling(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: hexToColor(svc.read(SettingsService.subtitleBackgroundColor)).withValues(alpha: opacity),
                        child: Stack(
                          children: [
                            if (border > 0)
                              Text(
                                sample,
                                textAlign: TextAlign.center,
                                style: style.copyWith(
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = border * 1.2
                                    ..strokeJoin = StrokeJoin.round
                                    ..color = hexToColor(svc.read(SettingsService.subtitleBorderColor)),
                                ),
                              ),
                            Text(
                              sample,
                              textAlign: TextAlign.center,
                              style: style.copyWith(color: hexToColor(svc.read(SettingsService.subtitleTextColor))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
