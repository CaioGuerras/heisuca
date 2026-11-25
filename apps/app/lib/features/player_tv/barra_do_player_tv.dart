import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';

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

/// Barra de baixo do player da TV, no jeito do Apple TV: transporte à esquerda, faixas à direita.
///
/// Um caminho só de foco: ← e → passam por todos os botões, das duas metades, pulando os apagados;
/// OK aciona; ↑ chama [aoSubir] (a linha do tempo). Sobre o vídeo vale sempre o tema escuro.
/// Com letra grande, as metades descem uma para baixo da outra em vez de cortar.
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
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: Forma.espaco3,
          children: [
            Wrap(
              spacing: Forma.espaco3,
              runSpacing: Forma.espaco3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [for (final item in transporte) _BotaoDaBarra(item: item)],
            ),
            Wrap(
              spacing: Forma.espaco3,
              runSpacing: Forma.espaco3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [for (final item in faixas) _BotaoDaBarra(item: item)],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoDaBarra extends StatelessWidget {
  const _BotaoDaBarra({required this.item});

  final ItemDaBarraTv item;

  /// Escala do botão com foco: cresce um pouco, como no Apple TV.
  static const double escalaComFoco = 1.08;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final redondo = item.icone != null;
    final forma = redondo ? const CircleBorder() : Forma.pilula();
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
            : ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: Forma.toqueMinimo,
                  maxWidth: BarraDoPlayerTv.larguraMaximaDaPilula,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco2),
                  child: Text(
                    item.texto ?? item.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipo.texto(tema).copyWith(color: tinta, fontWeight: FontWeight.w600),
                  ),
                ),
              );
        return AnimatedScale(
          // Com "remover animações", o foco aparece só pela cor.
          scale: comFoco && !Movimento.reduzido(context) ? escalaComFoco : 1,
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
        );
      },
    );
  }

  /// O botão solto deixa o vídeo aparecer por trás.
  static const double _opacidadeSolto = 0.72;
}
