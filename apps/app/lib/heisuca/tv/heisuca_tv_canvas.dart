import 'package:flutter/widgets.dart';

/// Tela de referência da TV (Heisuca TV-1): as telas do modelo A foram desenhadas em 1920×1080.
/// Um Android TV 1080p trabalha em 960×540 dp (densidade 2) e uma TV box 720p em ~1280×720 dp; sem
/// escala, o destaque de 1080 de altura passa da tela e os botões [Assistir]/[Detalhes] somem.
/// O conteúdo é montado na largura de referência e reduzido para a largura real; a altura segue a
/// proporção do aparelho. O MediaQuery de dentro já descreve a tela de referência.
class HeisucaTvCanvas extends StatelessWidget {
  const HeisucaTvCanvas({super.key, required this.child});

  static const double larguraReferencia = 1920;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.hasBoundedWidth || !box.hasBoundedHeight || box.maxWidth <= 0) return child;
        final escala = box.maxWidth / larguraReferencia;
        final tamanho = Size(larguraReferencia, box.maxHeight / escala);
        final mq = MediaQuery.of(context);
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: tamanho,
            child: MediaQuery(
              data: mq.copyWith(
                size: tamanho,
                devicePixelRatio: mq.devicePixelRatio * escala,
                padding: mq.padding / escala,
                viewPadding: mq.viewPadding / escala,
                viewInsets: mq.viewInsets / escala,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
