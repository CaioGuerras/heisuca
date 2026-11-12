import 'package:flutter/material.dart';

import '../forma.dart';
import '../movimento.dart';
import '../tema.dart';
import '../tipo.dart';
import 'toque.dart';

/// As duas proporções de um cartão de título.
enum FormatoDoCartao {
  /// Pôster em pé (2:3): fileiras de biblioteca.
  poster(2 / 3),

  /// Quadro deitado (16:9): "Continuar" e episódios.
  paisagem(16 / 9);

  const FormatoDoCartao(this.proporcao);
  final double proporcao;
}

/// Cartão de título: arte, nome e, quando existe, progresso, tempo e nota.
///
/// Enquanto a [arte] não chega, o cartão aparece na [corDoPoster] (sem esqueleto cinza).
/// O que fica sobre a arte usa os neutros do Sumi, como o player: lê-se sobre qualquer imagem.
class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.titulo,
    required this.largura,
    this.subtitulo,
    this.arte,
    this.corDoPoster,
    this.formato = FormatoDoCartao.poster,
    this.progresso,
    this.tempo,
    this.nota,
    this.emDestaque = false,
    this.aoTocar,
    this.aoSegurar,
  });

  final String titulo;
  final String? subtitulo;
  final double largura;

  /// A imagem, já recortada para cobrir o quadro. `null` enquanto carrega.
  final Widget? arte;

  /// Cor tirada do pôster; sem ela, a superfície do tema.
  final Color? corDoPoster;
  final FormatoDoCartao formato;

  /// Quanto já foi visto, de 0 a 1. `null` ou 0 esconde a barra.
  final double? progresso;

  /// Texto de tempo sobre a arte ("26:44 / 40:39").
  final String? tempo;

  /// Nota sobre a arte ("8,6").
  final String? nota;

  /// O cartão do que está em uso agora (o episódio atual): ganha contorno na cor de acento.
  final bool emDestaque;
  final VoidCallback? aoTocar;

  /// Toque longo: abre o menu do cartão.
  final VoidCallback? aoSegurar;

  static const double _alturaDaBarra = 3;
  static const double _veu = 0.72;

  /// Espessura do contorno de [emDestaque].
  static const double contornoDoDestaque = 2;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final sobreArte = TemaHeisuca.sumi;
    final forma = Forma.superelipse(Forma.raioMedio);
    final visto = (progresso ?? 0).clamp(0.0, 1.0);
    final temRodape = visto > 0 || tempo != null || nota != null;
    final rotulo = [titulo, ?subtitulo, ?tempo, ?nota, if (visto > 0) '${(visto * 100).round()}%'].join(', ');

    final quadro = AspectRatio(
      aspectRatio: formato.proporcao,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: forma),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: corDoPoster ?? tema.superficie2),
            AnimatedSwitcher(
              duration: Movimento.tempo(context, Movimento.cartao),
              switchInCurve: Movimento.entra,
              // O padrão do AnimatedSwitcher deixa o filho no tamanho que ele quiser: a arte não cobriria o quadro.
              layoutBuilder: (atual, anteriores) => Stack(fit: StackFit.expand, children: [...anteriores, ?atual]),
              child: arte ?? const SizedBox.expand(),
            ),
            if (temRodape)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      sobreArte.fundo.withValues(alpha: 0),
                      sobreArte.fundo.withValues(alpha: _veu),
                    ],
                  ),
                ),
              ),
            if (emDestaque)
              DecoratedBox(
                decoration: ShapeDecoration(
                  shape: Forma.superelipse(
                    Forma.raioMedio,
                    lado: BorderSide(color: tema.acento, width: contornoDoDestaque),
                  ),
                ),
              ),
            if (temRodape)
              Padding(
                padding: const EdgeInsets.all(Forma.espaco2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tempo != null || nota != null)
                      Text(
                        tempo ?? nota!,
                        style: Tipo.tempo(tema).copyWith(color: sobreArte.texto, fontWeight: FontWeight.w600),
                        maxLines: 1,
                      ),
                    if (visto > 0) ...[
                      const SizedBox(height: Forma.espaco1),
                      ClipPath(
                        clipper: ShapeBorderClipper(shape: Forma.pilula()),
                        child: SizedBox(
                          height: _alturaDaBarra,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(color: sobreArte.texto.withValues(alpha: 0.32)),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: visto,
                                child: ColoredBox(color: sobreArte.texto),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: largura,
      child: Toque(
        forma: forma,
        rotulo: rotulo,
        excluirSemantica: true,
        selecionado: emDestaque ? true : null,
        aoTocar: aoTocar,
        aoSegurar: aoSegurar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            quadro,
            const SizedBox(height: Forma.espaco2),
            Text(
              titulo,
              style: Tipo.pequeno(tema).copyWith(color: tema.texto, fontWeight: FontWeight.w600, height: 1.25),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitulo != null)
              Text(subtitulo!, style: Tipo.legenda(tema), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
