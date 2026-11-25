import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../cgflix/requests/cgflix_seerr.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../heisuca/tv/heisuca_tv_area_segura.dart';
import '../../heisuca/tv/heisuca_tv_canvas.dart';
import '../../heisuca/tv/heisuca_tv_pecas.dart';
import '../navegacao_tv/trilho_da_tv.dart';
import '../tema_da_v2.dart';

/// Apresentação de TV dos pedidos. A sessão, a busca e a gravação continuam no serviço compartilhado.
class PedidosDaTv extends StatelessWidget {
  const PedidosDaTv({
    super.key,
    required this.titulo,
    required this.itens,
    required this.ocupados,
    required this.aoPedir,
    this.carregando = false,
    this.indisponivel = false,
  });

  final String titulo;
  final List<CgflixRequestable> itens;
  final Set<int> ocupados;
  final ValueChanged<CgflixRequestable> aoPedir;
  final bool carregando;
  final bool indisponivel;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    if (carregando || indisponivel) {
      return Text(
        carregando ? 'Consultando pedidos…' : 'Pedidos indisponíveis agora',
        style: tvTexto(Tipo.texto(tema)),
      );
    }
    if (itens.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(titulo, style: tvTexto(Tipo.subtitulo(tema)))),
        const SizedBox(height: Forma.espaco4),
        Text('Ainda não temos. Peça e avisamos quando chegar.', style: tvTexto(Tipo.texto(tema))),
        for (final item in itens) ...[
          const SizedBox(height: Forma.espaco6),
          Column(
            key: ValueKey('cgflix-pedir-${item.isMovie ? 'filme' : 'serie'}-${item.tmdbId}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: tvTexto(Tipo.texto(tema)).copyWith(fontWeight: FontWeight.w600)),
              Text(
                [if (item.year != null) '${item.year}', item.isMovie ? 'Filme' : 'Série'].join(' · '),
                style: tvTexto(Tipo.pequeno(tema)),
              ),
              const SizedBox(height: Forma.espaco4),
              if (item.state == CgflixRequestState.requestable)
                Semantics(
                  label: 'Pedir ${item.title}',
                  child: BotaoTv(
                    rotulo: ocupados.contains(item.tmdbId) ? 'Pedindo…' : 'Pedir',
                    compacto: true,
                    icone: Symbols.add_rounded,
                    aoTocar: ocupados.contains(item.tmdbId) ? null : () => aoPedir(item),
                  ),
                )
              else
                Text(
                  item.state == CgflixRequestState.requested ? 'Pedido' : 'Baixando',
                  style: tvTexto(Tipo.texto(tema)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Escolha de temporadas com os mesmos botões da TV, sem controles Material de toque.
class TemporadasDoPedidoTv extends StatefulWidget {
  const TemporadasDoPedidoTv({super.key, required this.backend, required this.item});
  final CgflixRequestsBackend backend;
  final CgflixRequestable item;

  static Future<List<int>?> mostrar(
    BuildContext context, {
    required CgflixRequestsBackend backend,
    required CgflixRequestable item,
  }) => showDialog<List<int>>(
    context: context,
    builder: (_) => TemporadasDoPedidoTv(backend: backend, item: item),
  );

  @override
  State<TemporadasDoPedidoTv> createState() => _TemporadasDoPedidoTvState();
}

class _TemporadasDoPedidoTvState extends State<TemporadasDoPedidoTv> {
  List<CgflixSeasonChoice>? _temporadas;
  final Set<int> _escolhidas = {};
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final temporadas = await widget.backend.seasons(widget.item.tmdbId);
      if (!mounted) return;
      setState(() {
        _temporadas = temporadas;
        _escolhidas.addAll(temporadas.where((s) => s.lockedLabel == null).map((s) => s.number));
      });
    } catch (_) {
      if (mounted) setState(() => _falhou = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = TrilhoDaTv.escuroDaTv(TemaHeisuca.de(context));
    final temporadas = _temporadas;
    final abertas = temporadas?.where((s) => s.lockedLabel == null).toList() ?? const <CgflixSeasonChoice>[];
    final todas = abertas.isNotEmpty && abertas.every((s) => _escolhidas.contains(s.number));
    final quantidade = _escolhidas.length;
    return Theme(
      data: temaDaV2(Theme.of(context), tema),
      child: Material(
        color: tema.fundo,
        child: HeisucaTvCanvas(
          child: HeisucaTvAreaSegura(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Forma.espaco6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedir ${widget.item.title}', style: tvTexto(Tipo.titulo(tema))),
                  const SizedBox(height: Forma.espaco6),
                  if (_falhou)
                    Text('Pedidos indisponíveis agora', style: tvTexto(Tipo.texto(tema)))
                  else if (temporadas == null)
                    Text('Carregando temporadas…', style: tvTexto(Tipo.texto(tema)))
                  else ...[
                    Wrap(
                      spacing: Forma.espaco6,
                      runSpacing: Forma.espaco6,
                      children: [
                        if (abertas.length > 1)
                          BotaoTv(
                            rotulo: 'Todas',
                            selecionado: todas,
                            aoTocar: () => setState(() {
                              _escolhidas.clear();
                              if (!todas) _escolhidas.addAll(abertas.map((s) => s.number));
                            }),
                          ),
                        for (final temporada in temporadas)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BotaoTv(
                                rotulo: temporada.name,
                                selecionado: temporada.lockedLabel != null || _escolhidas.contains(temporada.number),
                                aoTocar: temporada.lockedLabel != null
                                    ? null
                                    : () => setState(() {
                                        if (!_escolhidas.remove(temporada.number)) _escolhidas.add(temporada.number);
                                      }),
                              ),
                              if (temporada.lockedLabel != null)
                                Text(temporada.lockedLabel!, style: tvTexto(Tipo.pequeno(tema))),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: Forma.espaco6),
                    BotaoTv(
                      rotulo: quantidade == 0
                          ? 'Escolha uma temporada'
                          : todas
                          ? 'Pedir todas'
                          : 'Pedir $quantidade ${quantidade == 1 ? 'temporada' : 'temporadas'}',
                      principal: true,
                      aoTocar: quantidade == 0
                          ? null
                          : () => Navigator.of(context).pop(todas ? const <int>[] : (_escolhidas.toList()..sort())),
                    ),
                    const SizedBox(height: Forma.espaco6),
                  ],
                  BotaoTv(rotulo: 'Cancelar', autofocus: true, aoTocar: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
