import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/cabecalho_de_fileira.dart';
import '../../design/componentes/cartao.dart';
import '../../design/componentes/pilula_de_escolha.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../inicio/fileira.dart' show MedidaDaFileira;
import 'modelo.dart';

/// A seção de episódios da página do título: a temporada no cabeçalho, os episódios em fileira e, quando são
/// muitos, as faixas ("1-10", "11-20") para pular direto.
///
/// Guarda só a temporada escolhida. Os episódios de cada temporada chegam prontos (ou `null` enquanto carregam).
class Episodios extends StatefulWidget {
  const Episodios({super.key, required this.temporadas, this.inicial = 0, this.aoMudarTemporada, this.aoVerTudo});

  final List<TemporadaDoTitulo> temporadas;

  /// A temporada aberta ao montar: a do episódio que o botão "Assistir" vai tocar.
  final int inicial;

  /// Avisa qual temporada foi aberta (para buscar os episódios dela).
  final ValueChanged<int>? aoMudarTemporada;

  /// Abre a lista completa da temporada escolhida; sem isto, o "Ver tudo" não aparece.
  final ValueChanged<int>? aoVerTudo;

  /// Quantos episódios cabem em cada faixa. Com até uma faixa, as faixas não aparecem.
  static const int tamanhoDaFaixa = 10;

  /// Altura do desenho da faixa; a área de toque continua em [Forma.toqueMinimo].
  static const double alturaDaFaixa = PilulaDeEscolha.altura;

  /// Quantos cartões vazios guardam o lugar enquanto os episódios carregam.
  static const int cartoesCarregando = 3;

  @override
  State<Episodios> createState() => _EpisodiosState();
}

class _EpisodiosState extends State<Episodios> {
  final _rolagem = ScrollController();
  late int _temporada = _dentro(widget.inicial);
  int _faixa = 0;

  /// A fileira ainda precisa ir até o episódio atual (ao abrir e a cada troca de temporada).
  bool _levarAoAtual = true;
  String? _chaveLevada;

  int _dentro(int indice) => widget.temporadas.isEmpty ? 0 : indice.clamp(0, widget.temporadas.length - 1);

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(_acompanharFaixa);
  }

  @override
  void didUpdateWidget(Episodios antiga) {
    super.didUpdateWidget(antiga);
    _temporada = _dentro(_temporada);
  }

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  double _passo = 1;

  void _acompanharFaixa() {
    if (!_rolagem.hasClients) return;
    final episodios = widget.temporadas.isEmpty ? null : widget.temporadas[_temporada].episodios;
    if (episodios == null || episodios.isEmpty) return;
    final posicao = _rolagem.position;
    final ultima = (episodios.length - 1) ~/ Episodios.tamanhoDaFaixa;
    // No fim da fileira o último cartão nunca chega à borda: a última faixa vale assim mesmo.
    final faixa = posicao.pixels >= posicao.maxScrollExtent - 1 && posicao.maxScrollExtent > 0
        ? ultima
        : ((posicao.pixels + _passo / 2) / _passo).floor().clamp(0, episodios.length - 1) ~/ Episodios.tamanhoDaFaixa;
    if (faixa != _faixa) setState(() => _faixa = faixa);
  }

  void _irPara(int indice, {required bool animar}) {
    if (!_rolagem.hasClients) return;
    final posicao = _rolagem.position;
    final alvo = (indice * _passo).clamp(0.0, posicao.maxScrollExtent);
    final tempo = Movimento.tempo(context, Movimento.tela);
    if (animar && !Movimento.reduzido(context)) {
      _rolagem.animateTo(alvo, duration: tempo, curve: Movimento.padrao);
    } else {
      _rolagem.jumpTo(alvo);
    }
  }

  void _trocar(int indice) {
    if (indice == _temporada) return;
    setState(() {
      _temporada = indice;
      _faixa = 0;
      _levarAoAtual = true;
    });
    if (_rolagem.hasClients) _rolagem.jumpTo(0);
    widget.aoMudarTemporada?.call(indice);
  }

  Future<void> _escolherTemporada() async {
    final tema = TemaHeisuca.de(context);
    final escolhida = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: tema.superficie,
      sheetAnimationStyle: Movimento.reduzido(context) ? AnimationStyle.noAnimation : null,
      builder: (folha) => _Temporadas(tema: tema, temporadas: widget.temporadas, atual: _temporada),
    );
    if (escolhida != null && mounted) _trocar(escolhida);
  }

  @override
  Widget build(BuildContext context) {
    final temporadas = widget.temporadas;
    if (temporadas.isEmpty) return const SizedBox.shrink();
    final temporada = temporadas[_temporada];
    final episodios = temporada.episodios;
    final variasTemporadas = temporadas.length > 1;

    final medida = MedidaDaFileira.de(
      context,
      FormatoDoCartao.paisagem,
      comSubtitulo: episodios?.any((episodio) => episodio.duracao != null) ?? false,
    );
    _passo = medida.largura + Forma.espaco3;

    if (episodios != null && episodios.isNotEmpty && (_levarAoAtual || _chaveLevada != temporada.chave)) {
      _levarAoAtual = false;
      _chaveLevada = temporada.chave;
      final atual = episodios.indexWhere((episodio) => episodio.atual);
      if (atual > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _irPara(atual, animar: false);
        });
      }
    }

    final faixas = episodios == null ? 0 : (episodios.length / Episodios.tamanhoDaFaixa).ceil();

    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoDeFileira(
            titulo: temporada.nome,
            aoTocarTitulo: variasTemporadas ? _escolherTemporada : null,
            iconeDoTitulo: Symbols.expand_more_rounded,
            rotuloDoTitulo: '${temporada.nome}, trocar de temporada',
            aoVerTudo: widget.aoVerTudo == null || episodios == null || episodios.isEmpty
                ? null
                : () => widget.aoVerTudo!(_temporada),
            iconeDeVerTudo: Symbols.chevron_right_rounded,
          ),
          if (episodios == null)
            _Carregando(medida: medida)
          else if (episodios.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco3),
              child: Text('Esta temporada ainda não tem episódios.', style: Tipo.pequeno(TemaHeisuca.de(context))),
            )
          else
            SizedBox(
              height: medida.altura,
              child: ListView.separated(
                key: ValueKey('episodios-${temporada.chave}'),
                controller: _rolagem,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
                itemCount: episodios.length,
                separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco3),
                itemBuilder: (context, i) {
                  final episodio = episodios[i];
                  return Cartao(
                    key: ValueKey(episodio.chave),
                    titulo: episodio.rotulo,
                    subtitulo: episodio.duracao,
                    largura: medida.largura,
                    formato: FormatoDoCartao.paisagem,
                    arte: episodio.arte?.call(context, Size(medida.largura, medida.alturaDoQuadro)),
                    progresso: episodio.progresso,
                    emDestaque: episodio.atual,
                    aoTocar: episodio.aoTocar,
                    aoSegurar: episodio.aoSegurar,
                  );
                },
              ),
            ),
          if (faixas > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
              child: Row(
                children: [
                  for (var faixa = 0; faixa < faixas; faixa++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Forma.espaco2),
                      child: _Faixa(
                        primeiro: episodios![faixa * Episodios.tamanhoDaFaixa].numero,
                        ultimo: episodios[((faixa + 1) * Episodios.tamanhoDaFaixa - 1).clamp(0, episodios.length - 1)]
                            .numero,
                        escolhida: faixa == _faixa,
                        aoTocar: () {
                          setState(() => _faixa = faixa);
                          _irPara(faixa * Episodios.tamanhoDaFaixa, animar: true);
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A faixa de dez episódios ("1-10") que rola a fileira até eles.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.primeiro, required this.ultimo, required this.escolhida, required this.aoTocar});

  final int primeiro;
  final int ultimo;
  final bool escolhida;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => PilulaDeEscolha(
    texto: primeiro == ultimo ? '$primeiro' : '$primeiro-$ultimo',
    rotulo: primeiro == ultimo ? 'Episódio $primeiro' : 'Episódios $primeiro a $ultimo',
    selecionado: escolhida,
    algarismos: true,
    aoTocar: aoTocar,
  );
}

/// O lugar dos episódios enquanto não chegam: cartões vazios, das mesmas medidas.
class _Carregando extends StatelessWidget {
  const _Carregando({required this.medida});

  final MedidaDaFileira medida;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: medida.altura,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
        itemCount: Episodios.cartoesCarregando,
        separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco3),
        itemBuilder: (_, _) => Cartao(titulo: '', largura: medida.largura, formato: FormatoDoCartao.paisagem),
      ),
    ),
  );
}

/// A folha de escolha da temporada.
class _Temporadas extends StatelessWidget {
  const _Temporadas({required this.tema, required this.temporadas, required this.atual});

  /// O tema de quem abriu (já tingido pelo pôster): a folha nasce fora da tela e não o herdaria.
  final TemaHeisuca tema;
  final List<TemporadaDoTitulo> temporadas;
  final int atual;

  @override
  Widget build(BuildContext context) => ListView.builder(
    shrinkWrap: true,
    padding: const EdgeInsets.symmetric(vertical: Forma.espaco3),
    itemCount: temporadas.length,
    itemBuilder: (context, i) => Toque(
      forma: Forma.superelipse(Forma.raioPequeno),
      rotulo: temporadas[i].nome,
      selecionado: i == atual,
      excluirSemantica: true,
      escala: 1,
      aoTocar: () => Navigator.of(context).pop(i),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Forma.toqueMinimo),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4, vertical: Forma.espaco2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  temporadas[i].nome,
                  style: Tipo.texto(tema).copyWith(fontWeight: i == atual ? FontWeight.w600 : null),
                ),
              ),
              if (i == atual) Icon(Symbols.check_rounded, size: 24, color: tema.texto),
            ],
          ),
        ),
      ),
    ),
  );
}
