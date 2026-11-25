import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/componentes/botao.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../features/inicio/modelo.dart' show FazArte;
import '../../features/tema_da_v2.dart';
import '../theme/heisuca_base.dart';
import 'heisuca_tv_segurar.dart';

/// Peças da TV usadas pelo Início e pela ficha do título: o mesmo botão, o mesmo cartão e a mesma escala de texto.
///
/// Tudo sai dos tokens da V2 (`lib/design/`): foco = anel + escala, sem onda nem cor escrita à mão. O tema é o
/// escuro da TV, que quem monta a tela aplica (`TrilhoDaTv.escuroDaTv`).

/// Texto da TV: a escala do celular vista a 3 m. Nada abaixo de 24 na tela de referência de 1920.
TextStyle tvTexto(TextStyle estilo) => estilo.copyWith(fontSize: max(24, (estilo.fontSize ?? 16) * 1.5));

/// Altura de uma linha de [estilo] como o [Text] a desenha (escala da letra e comportamento de altura do
/// [DefaultTextStyle]). A conta `fontSize × height` não vê o arredondamento da linha.
double medirLinhaTv(BuildContext context, TextStyle estilo) {
  final pintor = TextPainter(
    text: TextSpan(text: 'Ág', style: estilo),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
    maxLines: 1,
  )..layout();
  final altura = pintor.height;
  pintor.dispose();
  return altura;
}

/// Botão em pílula da TV: neutro, o principal em destaque; foco = anel + escala.
///
/// [selecionado] marca um estado ligado ("Já vi", "Minha lista", a temporada aberta) com o ícone cheio no acento.
/// [compacto] serve para fileiras de escolha (temporadas): mais baixo e sem largura mínima.
class BotaoTv extends StatefulWidget {
  const BotaoTv({
    super.key,
    required this.rotulo,
    this.aoTocar,
    this.icone,
    this.focusNode,
    this.aoFocar,
    this.principal = false,
    this.selecionado = false,
    this.compacto = false,
    this.autofocus = false,
  });

  final String rotulo;
  final IconData? icone;

  /// Nulo = o botão aparece apagado (ainda sem o que fazer, como o [Assistir] da série que carrega), mas segue
  /// focável para o foco não se perder.
  final VoidCallback? aoTocar;
  final FocusNode? focusNode;

  /// Chamado quando o botão ganha o foco.
  final VoidCallback? aoFocar;
  final bool principal;
  final bool selecionado;
  final bool compacto;
  final bool autofocus;

  /// Altura do botão [compacto] (sem ícone maior que a letra), para quem monta uma fileira de pílulas que rola:
  /// o mínimo de toque ou a linha do texto com a letra do aparelho, o que for maior.
  static double alturaCompacta(BuildContext context, TemaHeisuca tema) => max(
    _alturaMinimaCompacta,
    medirLinhaTv(context, tvTexto(Tipo.texto(tema)).copyWith(fontWeight: FontWeight.w600)),
  );

  static const double _alturaMinimaCompacta = Forma.toqueMinimo + Forma.espaco2;

  @override
  State<BotaoTv> createState() => _BotaoTvState();
}

class _BotaoTvState extends State<BotaoTv> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final tinta = widget.principal ? tema.botaoTexto : tema.texto;
    final icone = widget.icone;
    final estilo = widget.compacto ? tvTexto(Tipo.texto(tema)) : tvTexto(Tipo.subtitulo(tema));
    final ativo = widget.aoTocar != null;
    return Semantics(
      button: true,
      enabled: ativo,
      selected: widget.selecionado,
      label: widget.rotulo,
      container: true,
      onTap: ativo ? widget.aoTocar : null,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: (focado) {
          if (focado) widget.aoFocar?.call();
        },
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.aoTocar?.call();
              return null;
            },
          ),
        },
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: widget.aoTocar,
            child: AnimatedScale(
              scale: _foco ? HeisucaBase.focoEscalaTv : 1,
              duration: Movimento.tempo(context, Movimento.toque),
              curve: Movimento.entra,
              child: AnimatedContainer(
                duration: Movimento.tempo(context, Movimento.toque),
                curve: Movimento.entra,
                constraints: widget.compacto
                    ? const BoxConstraints(minHeight: BotaoTv._alturaMinimaCompacta)
                    : const BoxConstraints(minHeight: 72, minWidth: 200),
                padding: EdgeInsets.symmetric(horizontal: widget.compacto ? Forma.espaco6 : HeisucaBase.espaco8),
                decoration: ShapeDecoration(
                  shape: Forma.pilula(
                    lado: _foco ? BorderSide(color: tema.foco, width: Forma.anelDeFoco) : BorderSide.none,
                  ),
                  color: widget.principal ? tema.botaoFundo : tema.superficie2,
                ),
                child: AnimatedOpacity(
                  opacity: ativo ? 1 : 0.5,
                  duration: Movimento.tempo(context, Movimento.troca),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icone != null) ...[
                        Icon(
                          icone,
                          size: widget.compacto ? 28 : 36,
                          fill: widget.selecionado ? 1 : 0,
                          color: widget.selecionado && !widget.principal ? tema.acento : tinta,
                        ),
                        const SizedBox(width: Forma.espaco3),
                      ],
                      Text(
                        widget.rotulo,
                        style: estilo.copyWith(
                          color: tinta,
                          fontWeight: widget.selecionado || !widget.compacto ? FontWeight.w600 : FontWeight.w500,
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
  }
}

/// Cartão da TV: a arte com anel de foco e escala, barra de progresso opcional e, abaixo, título e legenda.
///
/// Serve para episódio (16:9), pôster (2:3) e pessoa (quadrado). [destaque] contorna a arte no acento quando o
/// cartão não está em foco (o episódio que o [Assistir] toca). Sem [aoTocar], o cartão ainda recebe o foco, para a
/// tela rolar até ele, mas o OK não faz nada.
class CartaoTv extends StatefulWidget {
  const CartaoTv({
    super.key,
    required this.largura,
    required this.alturaDaArte,
    required this.titulo,
    this.arte,
    this.legenda,
    this.progresso,
    this.destaque = false,
    this.redondo = false,
    this.aoTocar,
    this.aoSegurar,
    this.aoFocar,
    this.autofocus = false,
    this.focusNode,
  });

  final double largura;
  final double alturaDaArte;
  final String titulo;
  final FazArte? arte;
  final String? legenda;

  /// De 0 a 1; nulo = sem barra.
  final double? progresso;
  final bool destaque;

  /// Arte em círculo (foto de pessoa).
  final bool redondo;
  final VoidCallback? aoTocar;
  final VoidCallback? aoSegurar;
  final ValueChanged<bool>? aoFocar;
  final bool autofocus;

  /// Nó de foco de quem precisa mandar o foco para este cartão (o 1º resultado da busca).
  final FocusNode? focusNode;

  /// Altura das linhas de texto abaixo da arte, para quem monta a fileira reservar o espaço certo.
  ///
  /// Mede cada linha com o mesmo motor de texto que o [Text] usa (estilo, escala da letra e comportamento de altura
  /// do [DefaultTextStyle]): a conta `fontSize × height` não vê o arredondamento da linha e deixava a fileira curta.
  static double alturaDoTexto(BuildContext context, TemaHeisuca tema, {bool comLegenda = true}) =>
      Forma.espaco3 +
      medirLinhaTv(context, _estiloDoTitulo(tema)) +
      (comLegenda ? medirLinhaTv(context, _estiloDaLegenda(tema)) : 0);

  static TextStyle _estiloDoTitulo(TemaHeisuca tema) =>
      tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto, fontWeight: FontWeight.w600);
  static TextStyle _estiloDaLegenda(TemaHeisuca tema) => tvTexto(Tipo.pequeno(tema));

  @override
  State<CartaoTv> createState() => _CartaoTvState();
}

class _CartaoTvState extends State<CartaoTv> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final tamanho = Size(widget.largura, widget.alturaDaArte);
    final lado = _foco
        ? BorderSide(color: tema.foco, width: Forma.anelDeFoco)
        : widget.destaque
        ? BorderSide(color: tema.acento, width: Forma.anelDeFoco)
        : BorderSide.none;
    final progresso = widget.progresso;
    final legenda = widget.legenda;
    return SizedBox(
      width: widget.largura,
      child: Semantics(
        button: widget.aoTocar != null,
        label: [widget.titulo, ?legenda].join(', '),
        container: true,
        onTap: widget.aoTocar,
        onLongPress: widget.aoSegurar,
        child: SegurarOkTv(
          aoTocar: widget.aoTocar,
          aoSegurar: widget.aoSegurar,
          child: FocusableActionDetector(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onFocusChange: (focado) => widget.aoFocar?.call(focado),
            onShowFocusHighlight: (v) => setState(() => _foco = v),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.aoTocar?.call();
                  return null;
                },
              ),
            },
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: widget.aoTocar,
                onLongPress: widget.aoSegurar,
                child: Column(
                  crossAxisAlignment: widget.redondo ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    AnimatedScale(
                      scale: _foco ? HeisucaBase.focoEscalaTv : 1,
                      duration: Movimento.tempo(context, Movimento.toque),
                      curve: Movimento.entra,
                      child: Container(
                        width: tamanho.width,
                        height: tamanho.height,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: tema.superficie,
                          shape: widget.redondo
                              ? CircleBorder(side: lado)
                              : Forma.superelipse(Forma.raioMedio, lado: lado),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.arte != null)
                              widget.arte!(context, tamanho)
                            else
                              Center(
                                child: Text(
                                  widget.titulo,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: tvTexto(Tipo.pequeno(tema)),
                                ),
                              ),
                            if (progresso != null)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  height: Forma.espaco2,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColoredBox(color: tema.superficie2),
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progresso.clamp(0.0, 1.0),
                                        child: ColoredBox(color: tema.acento),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Forma.espaco3),
                    Text(
                      widget.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: widget.redondo ? TextAlign.center : TextAlign.start,
                      style: CartaoTv._estiloDoTitulo(tema),
                    ),
                    if (legenda != null)
                      Text(
                        legenda,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: widget.redondo ? TextAlign.center : TextAlign.start,
                        style: CartaoTv._estiloDaLegenda(tema),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de tela inteira da TV (nada achado, servidor fora do ar): ícone, título, texto e as ações em [BotaoTv].
class AvisoTv extends StatelessWidget {
  const AvisoTv({super.key, required this.icone, required this.titulo, this.texto, this.acoes = const []});

  final IconData icone;
  final String titulo;
  final String? texto;
  final List<Widget> acoes;

  /// Largura máxima do texto na tela de referência de 1920.
  static const double larguraMaxima = 960;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final texto = this.texto;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: larguraMaxima),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 72, color: tema.texto2),
            const SizedBox(height: Forma.espaco4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tvTexto(Tipo.subtitulo(tema)).copyWith(color: tema.texto),
            ),
            if (texto != null) ...[
              const SizedBox(height: Forma.espaco2),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: tvTexto(Tipo.texto(tema)).copyWith(color: tema.texto2),
              ),
            ],
            if (acoes.isNotEmpty) ...[
              const SizedBox(height: Forma.espaco6),
              Wrap(spacing: Forma.espaco4, runSpacing: Forma.espaco4, alignment: WrapAlignment.center, children: acoes),
            ],
          ],
        ),
      ),
    );
  }
}

/// ← na borda esquerda abre o trilho: se não há nada à esquerda do foco, chama [aoAbrirMenu] (como no Início e no
/// app de Windows). O campo de texto só deixa o ← passar com o cursor no começo.
class BordaDoMenuTv extends StatelessWidget {
  const BordaDoMenuTv({super.key, required this.aoAbrirMenu, required this.child});

  final VoidCallback? aoAbrirMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, evento) {
      final abrir = aoAbrirMenu;
      if (abrir == null || evento is! KeyDownEvent || evento.logicalKey != LogicalKeyboardKey.arrowLeft) {
        return KeyEventResult.ignored;
      }
      final foco = FocusManager.instance.primaryFocus;
      if (foco == null) return KeyEventResult.ignored;
      if (!foco.focusInDirection(TraversalDirection.left)) abrir();
      return KeyEventResult.handled;
    },
    child: child,
  );
}

/// Confirmação de sair do app na TV (Ajustes → Sair e o Voltar da Fire TV), nos componentes da V2. O foco começa em Cancelar: o OK sem querer não fecha o app.
class ConfirmarSaidaTv extends StatelessWidget {
  const ConfirmarSaidaTv({super.key});

  /// Largura máxima do diálogo em dp (fora da tela de referência: os botões da V2 têm o tamanho certo em dp).
  static const double largura = 550;

  /// Mostra a confirmação; `true` só quando a pessoa escolhe Sair.
  static Future<bool> mostrar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => const SobOTemaDaV2(child: ConfirmarSaidaTv()),
    );
    return confirmado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Dialog(
      backgroundColor: tema.superficie,
      shape: Forma.superelipse(Forma.raioGrande, lado: BorderSide(color: tema.borda)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: largura),
        child: Padding(
          padding: const EdgeInsets.all(Forma.espaco6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Sair do Heisuca?', style: Tipo.subtitulo(tema))),
              const SizedBox(height: Forma.espaco2),
              Text('O app fecha. Sua conta continua conectada.', style: Tipo.texto(tema).copyWith(color: tema.texto2)),
              const SizedBox(height: Forma.espaco6),
              FocusTraversalGroup(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: Forma.espaco3,
                  runSpacing: Forma.espaco3,
                  children: [
                    Botao(
                      rotulo: 'Cancelar',
                      tipo: TipoDeBotao.secundario,
                      focoInicial: true,
                      aoTocar: () => Navigator.of(context).pop(false),
                    ),
                    Botao(rotulo: 'Sair', aoTocar: () => Navigator.of(context).pop(true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
