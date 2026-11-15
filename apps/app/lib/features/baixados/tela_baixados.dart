import 'package:flutter/material.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/cartao.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../fundo_tingido.dart';
import 'modelo.dart';

/// Só desenha os dados recebidos; todas as operações pertencem à ligação.
class TelaBaixados extends StatelessWidget {
  const TelaBaixados({
    super.key,
    required this.grupos,
    required this.totalBytes,
    required this.aoExplorar,
    this.perfil,
    this.carregando = false,
    this.aviso,
    this.cores,
    this.folgaInferior = 96,
  });
  final List<GrupoBaixado> grupos;
  final Widget? perfil;
  final int totalBytes;
  final VoidCallback aoExplorar;
  final bool carregando;
  final String? aviso;
  final CorPosterCache? cores;
  final double folgaInferior;

  @override
  Widget build(BuildContext context) => FundoTingido(
    hash: grupos.firstOrNull?.hash,
    preparar: [for (final grupo in grupos) ?grupo.hash],
    cores: cores,
    child: Builder(
      builder: (context) {
        final tema = TemaHeisuca.de(context);
        return ListView(
          padding: EdgeInsets.fromLTRB(
            Forma.espaco4,
            MediaQuery.paddingOf(context).top + Forma.espaco6,
            Forma.espaco4,
            MediaQuery.paddingOf(context).bottom + folgaInferior,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text('Baixados', style: Tipo.titulo(tema))),
                ),
                ?perfil,
              ],
            ),
            Text('${espacoEmTexto(totalBytes)} em baixados no app', style: Tipo.pequeno(tema)),
            if (aviso != null) Text(aviso!, style: Tipo.texto(tema)),
            if (carregando)
              Text('Carregando seus baixados…', style: Tipo.texto(tema))
            else if (grupos.isEmpty) ...[
              const SizedBox(height: Forma.espaco6),
              Text('Nada baixado ainda', style: Tipo.subtitulo(tema)),
              Text('Guarde um filme ou uma série para assistir sem conexão.', style: Tipo.texto(tema)),
              const SizedBox(height: Forma.espaco4),
              Botao(rotulo: 'Explorar', aoTocar: aoExplorar),
            ],
            for (final grupo in grupos) _Grupo(dados: grupo),
          ],
        );
      },
    ),
  );
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.dados});
  final GrupoBaixado dados;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    const largura = Forma.toqueMinimo * 2;
    return Padding(
      key: ValueKey(dados.chave),
      padding: const EdgeInsets.only(top: Forma.espaco6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Cartao(
                  titulo: '',
                  largura: largura,
                  arte: dados.arte?.call(context, const Size(largura, largura * 1.5)),
                ),
              ),
              const SizedBox(width: Forma.espaco3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(dados.titulo, style: Tipo.subtitulo(tema))),
                    if (dados.serie)
                      Text(
                        '${dados.itens.length} ${dados.itens.length == 1 ? 'episódio' : 'episódios'}',
                        style: Tipo.pequeno(tema),
                      ),
                    Text(espacoEmTexto(dados.bytes), style: Tipo.pequeno(tema)),
                  ],
                ),
              ),
            ],
          ),
          for (final item in dados.itens) ...[
            if (dados.serie) Text(item.titulo, style: Tipo.texto(tema)),
            if (item.estado == EstadoDaBaixa.baixando || item.estado == EstadoDaBaixa.esperando) ...[
              Text(
                item.estado == EstadoDaBaixa.esperando ? 'Aguardando' : '${item.progresso} %',
                style: Tipo.tempo(tema),
              ),
              LinearProgressIndicator(
                value: item.progresso.clamp(0, 100) / 100,
                color: tema.texto,
                backgroundColor: tema.superficie2,
                semanticsLabel: 'Progresso de ${item.titulo}',
                semanticsValue: '${item.progresso} %',
              ),
              Botao(rotulo: 'Pausar', tipo: TipoDeBotao.secundario, aoTocar: item.aoPausar),
            ] else if (item.estado == EstadoDaBaixa.pausado || item.estado == EstadoDaBaixa.interrompido) ...[
              Text(item.estado == EstadoDaBaixa.pausado ? 'Pausado' : 'Interrompido', style: Tipo.pequeno(tema)),
              Botao(rotulo: 'Retomar', tipo: TipoDeBotao.secundario, aoTocar: item.aoRetomar),
            ] else
              Botao(rotulo: 'Assistir', tipo: TipoDeBotao.secundario, aoTocar: item.aoAssistir),
            const SizedBox(height: Forma.espaco2),
          ],
          if (dados.serie) ...[
            Botao(rotulo: 'Apagar vistos', tipo: TipoDeBotao.discreto, aoTocar: dados.aoApagarVistos),
            Text('Manter os próximos episódios', style: Tipo.pequeno(tema)),
            Wrap(
              spacing: Forma.espaco2,
              runSpacing: Forma.espaco2,
              children: [
                for (final n in [1, 3, 5])
                  Semantics(
                    selected: dados.manter == n,
                    child: Botao(
                      rotulo: 'Manter $n',
                      tipo: dados.manter == n ? TipoDeBotao.principal : TipoDeBotao.secundario,
                      aoTocar: dados.aoManter == null ? null : () => dados.aoManter!(n),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
