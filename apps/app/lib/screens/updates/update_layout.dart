import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../features/tema_da_v2.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../services/updates/update_controller.dart';
import '../../utils/platform_detector.dart';

/// A moldura das telas de atualização: título fixo no topo e o conteúdo numa lista, no desenho da V2.
///
/// No celular quem volta é a seta do topo; na TV, o botão "Voltar" que cada tela põe no fim da lista.
/// Na TV tudo fica dentro da margem segura de 5 % ([HeisucaTvAreaSegura]), numa coluna central: a lista
/// termina antes da borda de baixo, que muitas TVs cortam, e a margem interna só abriga o anel de foco.
class UpdateLayout extends StatelessWidget {
  const UpdateLayout({super.key, required this.titulo, required this.children});
  final String titulo;
  final List<Widget> children;

  /// Largura máxima do conteúdo no celular e no tablet; na TV, [larguraNaTv]: uma coluna central que deixa
  /// folga dos dois lados numa TV 1080p (960 dp) e cabe com sobra na margem segura.
  static const double largura = 640;
  static const double larguraNaTv = 720;

  /// Quanto a letra cresce na TV, vista de longe.
  static const double letraNaTv = 1.3;

  @override
  Widget build(BuildContext context) {
    final tv = PlatformDetector.isTV();
    final media = MediaQuery.of(context);
    // Na TV a margem segura já afasta da borda: lá, como no celular, a margem da lista só abriga o anel de foco.
    const margem = Forma.espaco4;
    return SobOTemaDaV2(
      child: MediaQuery(
        data: tv ? media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(1) * letraNaTv)) : media,
        child: Builder(
          builder: (context) {
            final tema = TemaHeisuca.de(context);
            return Scaffold(
              backgroundColor: tema.fundo,
              body: SafeArea(
                minimum: tv ? HeisucaTvAreaSegura.margem(media.size) : EdgeInsets.zero,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tv ? larguraNaTv : largura),
                    child: DefaultTextStyle.merge(
                      style: Tipo.texto(tema),
                      child: FocusTraversalGroup(
                        policy: WidgetOrderTraversalPolicy(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!tv)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(Forma.espaco2, Forma.espaco2, Forma.espaco2, 0),
                                child: BotaoDeIcone(
                                  icone: Symbols.arrow_back_rounded,
                                  rotulo: 'Voltar',
                                  aoTocar: () => unawaited(Navigator.of(context).maybePop()),
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                margem,
                                tv ? 0 : Forma.espaco2,
                                margem,
                                tv ? 0 : Forma.espaco4,
                              ),
                              child: Semantics(header: true, child: Text(titulo, style: Tipo.titulo(tema))),
                            ),
                            Expanded(
                              child: _ListaDaTela(tv: tv, children: children),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A lista da tela. Na TV ganha respiro em cima (o título fica fixo) e some aos poucos nas bordas de cima e de
/// baixo, em vez de cortar seco o que ainda vai entrar.
class _ListaDaTela extends StatelessWidget {
  const _ListaDaTela({required this.tv, required this.children});
  final bool tv;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final lista = ListView(
      padding: EdgeInsets.fromLTRB(Forma.espaco4, tv ? Forma.espaco6 : 0, Forma.espaco4, Forma.espaco6),
      children: children,
    );
    return tv ? HeisucaTvBordasSuaves(altura: Forma.espaco6, child: lista) : lista;
  }
}

/// Um painel da tela: superfície do tema, cantos em superelipse e borda fina.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.children, this.titulo});

  /// Nome do bloco, em letra pequena, acima do conteúdo.
  final String? titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: tema.superficie,
          shape: Forma.superelipse(Forma.raioGrande, lado: BorderSide(color: tema.borda)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Forma.espaco4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (titulo != null) ...[
                Semantics(header: true, child: Text(titulo!, style: Tipo.legenda(tema))),
                const SizedBox(height: Forma.espaco3),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// O estado da atualização e a única ação principal: verificar, baixar, cancelar ou instalar.
///
/// Aparece igual nas duas telas. Não afirma que o app está em dia: o controlador não guarda essa resposta;
/// o que a última consulta disse vem na mensagem dele.
class UpdateStatusCard extends StatelessWidget {
  const UpdateStatusCard({super.key, required this.controlador, required this.foco});
  final UpdateController controlador;

  /// O foco do botão principal.
  final FocusNode foco;

  void _executar() {
    final c = controlador;
    if (c.baixando) {
      c.cancelar();
    } else if (c.pronto) {
      unawaited(c.instalar());
    } else if (c.oferta != null) {
      unawaited(c.baixar());
    } else {
      unawaited(c.verificar(manual: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controlador;
    final tema = TemaHeisuca.de(context);
    final oferta = c.oferta;
    final nova = oferta == null ? null : '${oferta.versao} (${oferta.build})';
    final parte = c.total > 0 ? c.recebidos / c.total : 0.0;
    // O título diz onde a pessoa está; a linha de baixo, o que fazer ou o que aconteceu.
    final estado = !c.habilitado
        ? 'Atualizações indisponíveis'
        : c.instalando
        ? 'Abrindo o instalador'
        : c.baixando
        ? 'Baixando ${(parte * 100).floor()}%'
        : c.pronto
        ? 'Pronta para instalar'
        : c.verificando
        ? 'Procurando versão nova…'
        : oferta != null
        ? 'Versão nova disponível'
        : 'Heisuca ${c.estado.versao}';
    final rotulo = c.baixando
        ? 'Cancelar'
        : c.instalando
        ? 'Preparando instalação…'
        : c.verificando
        ? 'Verificando…'
        : c.pronto
        ? 'Instalar'
        : oferta != null
        ? 'Baixar'
        : 'Verificar agora';
    final mostraOferta = oferta != null && c.habilitado;
    return UpdateCard(
      children: [
        Text(estado, style: Tipo.subtitulo(tema)),
        const SizedBox(height: Forma.espaco1),
        Text(
          mostraOferta
              ? 'Você tem a ${c.estado.versao} (${c.estado.build}); a nova é a $nova.'
              : 'Versão instalada: ${c.estado.versao} (${c.estado.build})',
          style: Tipo.pequeno(tema),
        ),
        if (c.baixando) ...[
          const SizedBox(height: Forma.espaco4),
          ClipPath(
            clipper: ShapeBorderClipper(shape: Forma.pilula()),
            child: LinearProgressIndicator(
              value: parte,
              minHeight: Forma.espaco2,
              color: tema.texto,
              backgroundColor: tema.superficie2,
            ),
          ),
        ],
        if (mostraOferta && oferta.notas.trim().isNotEmpty) ...[
          const SizedBox(height: Forma.espaco4),
          Text('O que mudou', style: Tipo.legenda(tema)),
          const SizedBox(height: Forma.espaco1),
          Text(oferta.notas, style: Tipo.texto(tema)),
        ],
        if (c.mensagem != null) ...[
          const SizedBox(height: Forma.espaco3),
          Semantics(liveRegion: true, child: Text(c.mensagem!, style: Tipo.pequeno(tema))),
        ],
        if (c.habilitado) ...[
          const SizedBox(height: Forma.espaco4),
          Botao(
            key: const ValueKey('atualizador-acao'),
            rotulo: rotulo,
            foco: foco,
            focoInicial: true,
            expandido: true,
            // Verificando ou abrindo o instalador, o botão espera (o controlador já recusaria o toque).
            aoTocar: c.verificando || c.instalando ? null : _executar,
          ),
          if (mostraOferta) ...[
            const SizedBox(height: Forma.espaco3),
            Text('Depois de instalar, abra o app de novo.', style: Tipo.legenda(tema), textAlign: TextAlign.center),
          ],
        ],
      ],
    );
  }
}

/// Uma linha de escolha única: nome, uma frase do que ela faz e a marca de escolhida.
class UpdateChoice extends StatelessWidget {
  const UpdateChoice({
    super.key,
    required this.titulo,
    required this.texto,
    required this.escolhida,
    required this.aoTocar,
    this.foco,
  });
  final String titulo;
  final String texto;
  final bool escolhida;

  /// `null` deixa a linha inativa.
  final VoidCallback? aoTocar;
  final FocusNode? foco;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Toque(
      forma: Forma.superelipse(Forma.raioMedio),
      selecionado: escolhida,
      aoTocar: aoTocar,
      foco: foco,
      escala: 1,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: escolhida ? tema.superficie2 : Colors.transparent,
          shape: Forma.superelipse(Forma.raioMedio),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco3, vertical: Forma.espaco3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: Tipo.texto(tema).copyWith(fontWeight: FontWeight.w600)),
                      Text(texto, style: Tipo.pequeno(tema)),
                    ],
                  ),
                ),
                const SizedBox(width: Forma.espaco3),
                ExcludeSemantics(
                  child: Icon(
                    escolhida ? Symbols.check_circle_rounded : Symbols.radio_button_unchecked_rounded,
                    fill: escolhida ? 1 : 0,
                    color: escolhida ? tema.texto : tema.texto2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
