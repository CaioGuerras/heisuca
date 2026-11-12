import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    this.visto = false,
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

  /// Já foi visto até o fim: ganha o ✓ no canto de cima da arte.
  final bool visto;

  /// O cartão do que está em uso agora (o episódio atual): ganha contorno na cor de acento.
  final bool emDestaque;
  final VoidCallback? aoTocar;

  /// Toque longo: abre o menu do cartão.
  final VoidCallback? aoSegurar;

  static const double _alturaDaBarra = 3;
  static const double _veu = 0.72;

  /// Espessura do contorno de [emDestaque].
  static const double contornoDoDestaque = 2;

  /// Lado do círculo do ✓ de [visto] e do desenho dentro dele.
  static const double seloDeVisto = 24;
  static const double _iconeDoVisto = 16;

  // As mesmas medidas do texto embaixo da arte (Tipo.pequeno e Tipo.legenda).
  static const double _letraDoTitulo = 14;
  static const double _alturaDoTitulo = 1.25;
  static const double _letraDoSubtitulo = 12;
  static const double _alturaDoSubtitulo = 1.45;

  /// Altura do cartão inteiro (arte, nome e subtítulo) na letra do aparelho.
  ///
  /// Quem monta fileira ou grade reserva este espaço antes de o cartão existir.
  static double alturaPara(
    BuildContext context, {
    required double largura,
    FormatoDoCartao formato = FormatoDoCartao.poster,
    bool comSubtitulo = false,
  }) {
    final letra = MediaQuery.textScalerOf(context);
    final titulo = letra.scale(_letraDoTitulo) * _alturaDoTitulo;
    final subtitulo = comSubtitulo ? letra.scale(_letraDoSubtitulo) * _alturaDoSubtitulo : 0.0;
    return (largura / formato.proporcao + Forma.espaco2 + titulo + subtitulo).ceilToDouble() + 2;
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final sobreArte = TemaHeisuca.sumi;
    final forma = Forma.superelipse(Forma.raioMedio);
    final fracao = (progresso ?? 0).clamp(0.0, 1.0);
    final temRodape = fracao > 0 || tempo != null || nota != null;
    final rotulo = [
      titulo,
      ?subtitulo,
      ?tempo,
      ?nota,
      if (fracao > 0) '${(fracao * 100).round()}%',
      if (visto) 'visto',
    ].join(', ');

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
            if (visto)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(Forma.espaco2),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: sobreArte.fundo.withValues(alpha: _veu),
                      shape: Forma.pilula(),
                    ),
                    child: SizedBox.square(
                      dimension: seloDeVisto,
                      child: Icon(Symbols.check_rounded, size: _iconeDoVisto, weight: 700, color: sobreArte.texto),
                    ),
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
                    if (fracao > 0) ...[
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
                                widthFactor: fracao,
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
