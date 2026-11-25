import 'package:flutter/widgets.dart';

import '../../design/tema.dart';

/// Margem segura da TV: 5 % da tela de cada lado, onde o overscan de muitas TVs come a imagem.
///
/// Vale em qualquer medida, porque sai do tamanho que o [MediaQuery] descreve: numa TV 1080p (960×540 dp)
/// dá 48 dp nas laterais e 27 dp em cima e embaixo; dentro do `HeisucaTvCanvas` (tela de referência de
/// 1920 de largura), 96 × 54. Nada que a pessoa precise ver fica fora dela.
class HeisucaTvAreaSegura extends StatelessWidget {
  const HeisucaTvAreaSegura({super.key, required this.child});

  /// Fração da tela reservada em cada borda.
  static const double fracao = 0.05;

  final Widget child;

  /// A margem para uma tela de [tamanho].
  static EdgeInsets margem(Size tamanho) =>
      EdgeInsets.symmetric(horizontal: tamanho.width * fracao, vertical: tamanho.height * fracao);

  @override
  Widget build(BuildContext context) => Padding(padding: margem(MediaQuery.sizeOf(context)), child: child);
}

/// Lista da TV que some aos poucos nas bordas de cima e de baixo, em vez de cortar seco: o item que sai
/// da tela parece continuar (dá para rolar), não parece cortado.
///
/// [altura] deve ser igual ao respiro vertical da lista: parada no topo ou no fim, nada fica esmaecido.
class HeisucaTvBordasSuaves extends StatelessWidget {
  const HeisucaTvBordasSuaves({super.key, required this.altura, required this.child});

  final double altura;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Só o alfa conta (dstIn); a cor é a do fundo para não haver cor escrita à mão.
    final cheio = TemaHeisuca.de(context).fundo;
    final vazio = cheio.withValues(alpha: 0);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (caixa) {
        final borda = caixa.height <= 0 ? 0.0 : (altura / caixa.height).clamp(0.0, 0.5);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [vazio, cheio, cheio, vazio],
          stops: [0, borda, 1 - borda, 1],
        ).createShader(caixa);
      },
      child: child,
    );
  }
}
