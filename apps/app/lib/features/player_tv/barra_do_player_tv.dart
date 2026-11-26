import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/theme/heisuca_base.dart';

/// Um botão da barra do player da TV.
///
/// Com [icone], é um botão redondo de transporte (voltar, tocar, avançar, próximo); sem ele, uma pílula
/// com [texto] (Áudio, Legenda, Episódios). O [foco] é de quem monta a barra: o player precisa mandar o
/// foco para um botão certo quando o painel abre.
class ItemDaBarraTv {
  const ItemDaBarraTv({
    required this.foco,
    required this.rotulo,
    this.icone,
    this.iconeDaPilula,
    this.texto,
    this.textoCompacto,
    this.aoTocar,
  });

  final FocusNode foco;

  /// Como o leitor de tela anuncia o botão.
  final String rotulo;
  final IconData? icone;
  final String? texto;
  final String? textoCompacto;
  final IconData? iconeDaPilula;

  /// `null` deixa o botão apagado e fora do caminho do foco.
  final VoidCallback? aoTocar;
}

/// Barra de baixo do player da TV: transporte seguido das faixas, com o mesmo respiro entre todos.
///
/// Um caminho só de foco: ← e → passam por todos os botões, das duas metades, pulando os apagados;
/// OK aciona; ↑ chama [aoSubir] (a linha do tempo). Sobre o vídeo vale sempre o tema escuro.
/// Com letra grande, usa valores compactos e a escala pequena dos tokens, mantendo uma linha.
class BarraDoPlayerTv extends StatelessWidget {
  const BarraDoPlayerTv({super.key, required this.transporte, required this.faixas, this.aoSubir, this.aoMexer});

  final List<ItemDaBarraTv> transporte;
  final List<ItemDaBarraTv> faixas;

  /// ↑ em qualquer botão.
  final VoidCallback? aoSubir;

  /// Toda tecla tratada aqui: o player adia o sumiço dos controles.
  final VoidCallback? aoMexer;

  /// Diâmetro do botão redondo de transporte.
  static const double diametro = 64;

  List<ItemDaBarraTv> get _caminho => [...transporte, ...faixas].where((i) => i.aoTocar != null).toList();

  static final _teclasDaBarra = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
  };

  KeyEventResult _tecla(FocusNode _, KeyEvent evento) {
    final caminho = _caminho;
    final atual = caminho.indexWhere((i) => i.foco.hasFocus);
    final tecla = evento.logicalKey;
    if (atual < 0 || !_teclasDaBarra.contains(tecla)) return KeyEventResult.ignored;
    // A barra é dona dessas teclas enquanto tem o foco: nem o soltar chega ao player.
    if (evento is KeyUpEvent) return KeyEventResult.handled;

    if (tecla == LogicalKeyboardKey.arrowLeft || tecla == LogicalKeyboardKey.arrowRight) {
      final proximo = atual + (tecla == LogicalKeyboardKey.arrowRight ? 1 : -1);
      if (proximo >= 0 && proximo < caminho.length) caminho[proximo].foco.requestFocus();
      aoMexer?.call();
      // Na ponta, a tecla para aqui: não vaza para o player (que avançaria o vídeo).
      return KeyEventResult.handled;
    }
    if (tecla == LogicalKeyboardKey.arrowUp) {
      aoSubir?.call();
      aoMexer?.call();
      return KeyEventResult.handled;
    }
    if (tecla == LogicalKeyboardKey.arrowDown) {
      aoMexer?.call();
      return KeyEventResult.handled;
    }
    // O player trata OK como tocar/pausar antes dos atalhos do app: o OK do botão é tratado aqui.
    // Segurar o OK não repete a ação.
    if (evento is KeyDownEvent) {
      caminho[atual].aoTocar!();
      aoMexer?.call();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).copyWith(extensions: const [TemaHeisuca.shikkoku]);
    return Theme(
      data: escuro,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _tecla,
        child: LayoutBuilder(
          builder: (context, limites) {
            final itens = [...transporte, ...faixas];
            final tema = TemaHeisuca.de(context);
            var estilo = DefaultTextStyle.of(
              context,
            ).style.merge(Tipo.texto(tema)).copyWith(fontWeight: FontWeight.w600);
            var compacto = false;
            var soIcone = false;
            // Folga lateral única da fileira: a do botão mais largo. Com folga por botão, as pílulas largas
            // ficavam mais afastadas que os círculos (44 px contra 59 px na bancada de 25/11).
            double folga() => itens.fold<double>(0, (maior, item) {
              final tamanho = _tamanho(context, item, estilo, compacto, soIcone: soIcone);
              return max(maior, _folgaLateral(tamanho.width));
            });
            double largura() =>
                itens.fold<double>(0, (total, item) {
                  return total + _tamanho(context, item, estilo, compacto, soIcone: soIcone).width;
                }) +
                folga() * 2 * itens.length +
                Forma.espaco3 * (itens.length - 1);
            if (largura() > limites.maxWidth) {
              compacto = true;
            }
            if (largura() > limites.maxWidth) {
              estilo = DefaultTextStyle.of(
                context,
              ).style.merge(Tipo.legenda(tema)).copyWith(fontWeight: FontWeight.w600);
            }
            // Último degrau (tela pequena com letra grande): pílula só com ícone; o rótulo segue na semântica.
            if (largura() > limites.maxWidth) {
              soIcone = true;
            }
            final folgaLateral = folga();
            final linha = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) const SizedBox(width: Forma.espaco3),
                  _BotaoDaBarra(
                    item: itens[i],
                    estilo: estilo,
                    compacto: compacto,
                    soIcone: soIcone,
                    folgaLateral: folgaLateral,
                  ),
                ],
              ],
            );
            // Telas menores que a TV preservam a área de toque e rolam pelo foco.
            return Center(
              child: largura() <= limites.maxWidth
                  ? linha
                  : SingleChildScrollView(scrollDirection: Axis.horizontal, child: linha),
            );
          },
        ),
      ),
    );
  }
}

class _BotaoDaBarra extends StatelessWidget {
  const _BotaoDaBarra({
    required this.item,
    required this.estilo,
    required this.compacto,
    required this.folgaLateral,
    this.soIcone = false,
  });

  final TextStyle estilo;
  final double folgaLateral;
  final bool compacto;
  final bool soIcone;

  final ItemDaBarraTv item;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final redondo = item.icone != null;
    final forma = redondo ? const CircleBorder() : Forma.pilula();
    final texto = compacto ? item.textoCompacto ?? item.texto ?? item.rotulo : item.texto ?? item.rotulo;
    final tamanho = _tamanho(context, item, estilo, compacto, soIcone: soIcone);
    final mostrarTexto = !(soIcone && item.iconeDaPilula != null);
    // O anel é pintado para fora pelo Toque; reservar também a escala impede que ele invada os vizinhos.
    // O envelope independe do foco atual, portanto ←/→ nunca movem os controles da fileira.
    const escalaMaxima = HeisucaBase.focoEscalaTv;
    const anel = Forma.anelDeFoco * escalaMaxima;
    final reserva = EdgeInsets.symmetric(
      horizontal: max(folgaLateral, _folgaLateral(tamanho.width)),
      vertical: tamanho.height * (escalaMaxima - 1) / 2 + anel,
    );
    return ListenableBuilder(
      listenable: item.foco,
      builder: (context, _) {
        final comFoco = item.foco.hasFocus;
        final tinta = comFoco ? tema.botaoTexto : tema.texto;
        final Widget miolo = redondo
            ? SizedBox.square(
                dimension: BarraDoPlayerTv.diametro,
                child: Icon(item.icone, size: BarraDoPlayerTv.diametro / 2, color: tinta),
              )
            : SizedBox.fromSize(
                size: tamanho,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco2),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.iconeDaPilula != null) Icon(item.iconeDaPilula, size: Forma.espaco6, color: tinta),
                        if (item.iconeDaPilula != null && mostrarTexto) const SizedBox(width: Forma.espaco2),
                        if (mostrarTexto)
                          Text(texto, maxLines: 1, softWrap: false, style: estilo.copyWith(color: tinta)),
                      ],
                    ),
                  ),
                ),
              );
        return Padding(
          padding: reserva,
          child: AnimatedScale(
            // Com "remover animações", o foco aparece só pela cor.
            scale: comFoco && !Movimento.reduzido(context) ? escalaMaxima : 1,
            duration: Movimento.tempo(context, Movimento.toque),
            curve: Movimento.padrao,
            child: Toque(
              foco: item.foco,
              forma: forma,
              rotulo: item.rotulo,
              excluirSemantica: true,
              aoTocar: item.aoTocar,
              child: AnimatedContainer(
                duration: Movimento.tempo(context, Movimento.toque),
                curve: Movimento.padrao,
                decoration: ShapeDecoration(
                  color: comFoco ? tema.botaoFundo : tema.superficie2.withValues(alpha: _opacidadeSolto),
                  shape: forma,
                ),
                child: Center(widthFactor: 1, heightFactor: 1, child: miolo),
              ),
            ),
          ),
        );
      },
    );
  }

  /// O botão solto deixa o vídeo aparecer por trás.
  static const double _opacidadeSolto = 0.72;
}

/// Espaço que o botão precisa de cada lado para crescer no foco e pintar o anel sem invadir o vizinho.
double _folgaLateral(double largura) =>
    largura * (HeisucaBase.focoEscalaTv - 1) / 2 + Forma.anelDeFoco * HeisucaBase.focoEscalaTv;

Size _tamanho(BuildContext context, ItemDaBarraTv item, TextStyle estilo, bool compacto, {bool soIcone = false}) {
  if (item.icone != null) return const Size.square(BarraDoPlayerTv.diametro);
  if (soIcone && item.iconeDaPilula != null) {
    return Size(Forma.espaco6 + Forma.espaco4 * 2, max(Forma.toqueMinimo, Forma.espaco6 + Forma.espaco2 * 2));
  }
  final texto = compacto ? item.textoCompacto ?? item.texto ?? item.rotulo : item.texto ?? item.rotulo;
  final pintor = TextPainter(
    text: TextSpan(text: texto, style: estilo),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
    maxLines: 1,
  )..layout();
  final tamanho = Size(
    pintor.width.ceilToDouble() + Forma.espaco4 * 2 + (item.iconeDaPilula == null ? 0 : Forma.espaco6 + Forma.espaco2),
    max(
      Forma.toqueMinimo,
      max(item.iconeDaPilula == null ? 0.0 : Forma.espaco6, pintor.height.ceilToDouble()) + Forma.espaco2 * 2,
    ),
  );
  pintor.dispose();
  return tamanho;
}
