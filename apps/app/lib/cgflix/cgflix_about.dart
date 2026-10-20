// Peças que são só do CGFLIX: dedicatória e créditos ao Plezy. Etapa 1E: a dedicatória fica
// somente no Sobre (saiu da abertura, do menu do usuário e da Início, e o interruptor do Avançado).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../widgets/app_icon.dart';
import 'cgflix_palette.dart';

const cgflixDedicationText = 'Feito com amor, para Isis e Heitor';

/// Coração roxo (Isis) e verde (Heitor), os dois em qualquer tema.
class CgflixDedicationHearts extends StatelessWidget {
  const CgflixDedicationHearts({super.key, this.size = 22, this.spacing = 8});
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(Symbols.favorite_rounded, fill: 1, color: CgflixPalette.isis.accent, size: size),
        SizedBox(width: spacing),
        AppIcon(Symbols.favorite_rounded, fill: 1, color: context.cgflix.dedication, size: size),
      ],
    ),
  );
}

/// Dedicatória, centralizada abaixo da versão: coração roxo e coração verde.
class CgflixDedication extends StatelessWidget {
  const CgflixDedication({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(cgflixDedicationText, style: style, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        const CgflixDedicationHearts(),
      ],
    );
  }
}

/// Créditos ao projeto original (GPL-3.0). Só aparecem no Sobre e no README.
class CgflixCredits extends StatelessWidget {
  const CgflixCredits({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'O CGFLIX é baseado no Plezy (github.com/edde746/plezy), software livre sob a licença GPL-3.0.',
    style: Theme.of(context).textTheme.bodySmall,
    textAlign: TextAlign.center,
  );
}
