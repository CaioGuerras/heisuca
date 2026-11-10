import 'package:flutter/material.dart';
import '../../heisuca/heisuca_theme.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/dialog_action_button.dart';

/// A mesma composição no Android de mão e na TV, com os tokens próprios de cada tema.
class UpdateLayout extends StatelessWidget {
  const UpdateLayout({super.key, required this.titulo, required this.children});
  final String titulo;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final tv = PlatformDetector.isTV();
    final atual = Theme.of(context);
    final tema = atual.copyWith(
      colorScheme: atual.colorScheme,
      textTheme: atual.textTheme.apply(fontFamily: HeisucaTheme.fonteTexto, bodyColor: atual.colorScheme.onSurface),
    );
    final tela = Theme(
      data: tema,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: tema.scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(tv ? 48 : 24, tv ? 36 : 24, tv ? 48 : 24, 24),
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontFamily: HeisucaTheme.fonteTitulo,
                            fontWeight: FontWeight.w600,
                            fontSize: tv ? 36 : 28,
                            color: tema.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(tv ? 48 : 24, 0, tv ? 48 : 24, tv ? 36 : 24),
                          children: children,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Layout responsivo em dp: a fonte 22 da TV não é reduzida pela escala do canvas de pôsteres.
    return tela;
  }
}

class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: DefaultTextStyle(
      style: TextStyle(
        fontFamily: HeisucaTheme.fonteTexto,
        fontSize: PlatformDetector.isTV() ? 22 : 17,
        height: 1.4,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    ),
  );
}

class UpdateButton extends StatelessWidget {
  const UpdateButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.foco,
    this.autofocus = false,
    this.primario = false,
    this.acima,
    this.abaixo,
  });
  final String texto;
  final VoidCallback? onPressed, acima, abaixo;
  final FocusNode? foco;
  final bool autofocus, primario;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      child: DialogActionButton(
        label: texto,
        onPressed: onPressed,
        focusNode: foco,
        autofocus: autofocus,
        isPrimary: primario,
        onNavigateUp: acima,
        onNavigateDown: abaixo,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 64),
          textStyle: TextStyle(
            fontFamily: HeisucaTheme.fonteTexto,
            fontSize: PlatformDetector.isTV() ? 22 : 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
  );
}
