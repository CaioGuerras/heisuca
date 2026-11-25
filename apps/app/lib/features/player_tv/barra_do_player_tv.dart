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
  const ItemDaBarraTv({required this.foco, required this.rotulo, this.icone, this.texto, this.aoTocar});

  final FocusNode foco;

  /// Como o leitor de tela anuncia o botão.
  final String rotulo;
  final IconData? icone;
  final String? texto;

  /// `null` deixa o botão apagado e fora do caminho do foco.
  final VoidCallback? aoTocar;
}

/// Barra de baixo do player da TV: transporte seguido das faixas, com o mesmo respiro entre todos.
///
/// Um caminho só de foco: ← e → passam por todos os botões, das duas metades, pulando os apagados;
/// OK aciona; ↑ chama [aoSubir] (a linha do tempo). Sobre o vídeo vale sempre o tema escuro.
/// Com letra grande, os controles continuam na linha seguinte em vez de cortar.
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

  /// Largura máxima de uma pílula: o nome da faixa longo termina em reticências.
  static const double larguraMaximaDaPilula = 360;

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
        child: Wrap(
          spacing: Forma.espaco3,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: Forma.espaco3,
          children: [
            for (final item in [...transporte, ...faixas]) _BotaoDaBarra(item: item),
          ],
        ),
      ),
    );
  }
}

class _BotaoDaBarra extends StatelessWidget {
  const _BotaoDaBarra({required this.item});

  final ItemDaBarraTv item;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final redondo = item.icone != null;
    final forma = redondo ? const CircleBorder() : Forma.pilula();
    final estilo = Tipo.texto(tema).copyWith(fontWeight: FontWeight.w600);
    final texto = item.texto ?? item.rotulo;
    final tamanho = redondo ? const Size.square(BarraDoPlayerTv.diametro) : _medirPilula(context, texto, estilo);
    // O anel é pintado para fora pelo Toque; reservar também a escala impede que ele invada os vizinhos.
    // O envelope independe do foco atual, portanto ←/→ nunca movem os controles da fileira.
    const escalaMaxima = HeisucaBase.focoEscalaTv;
    const anel = Forma.anelDeFoco * escalaMaxima;
    final reserva = EdgeInsets.symmetric(
      horizontal: tamanho.width * (escalaMaxima - 1) / 2 + anel,
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
                    child: Text(
                      texto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estilo.copyWith(color: tinta),
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

  Size _medirPilula(BuildContext context, String texto, TextStyle estilo) {
    final pintor = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: BarraDoPlayerTv.larguraMaximaDaPilula - Forma.espaco4 * 2);
    final tamanho = Size(pintor.width + Forma.espaco4 * 2, max(Forma.toqueMinimo, pintor.height + Forma.espaco2 * 2));
    pintor.dispose();
    return tamanho;
  }

  /// O botão solto deixa o vídeo aparecer por trás.
  static const double _opacidadeSolto = 0.72;
}
