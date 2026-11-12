import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/cor_poster/paleta_poster.dart';
import '../../design/cor_poster/temas_cor_poster.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import 'destaque.dart';
import 'modelo.dart';

/// A tela Início da V2: destaque no topo, fileiras embaixo e o fundo tingido pelo destaque.
///
/// Não conhece servidor nem player: recebe os títulos prontos e as fileiras já montadas.
class TelaInicio extends StatefulWidget {
  const TelaInicio({
    super.key,
    required this.destaques,
    required this.fileiras,
    this.destaqueCarregando = false,
    this.noLugarDoDestaque,
    this.aoBuscar,
    this.perfil,
    this.aoAtualizar,
    this.controle,
    this.chaveDeRolagem,
    this.cores,
    this.folgaInferior = 96,
  });

  final List<TituloEmDestaque> destaques;

  /// As fileiras, de cima para baixo. Ficam todas montadas: fileira que some e volta ao rolar
  /// muda de altura e faz a lista pular. A lista de cartões de cada uma é que monta sob demanda.
  final List<Widget> fileiras;

  /// Os destaques ainda não chegaram: guarda o lugar deles em vez de subir as fileiras.
  final bool destaqueCarregando;

  /// O que ocupa o topo quando não há destaque para mostrar (um aviso de falha, por exemplo).
  final Widget? noLugarDoDestaque;

  final VoidCallback? aoBuscar;

  /// O que fica no canto de cima, do lado oposto à busca: a pílula de quem está usando o app.
  final Widget? perfil;

  /// Puxar para atualizar; sem isto o gesto não existe.
  final Future<void> Function()? aoAtualizar;

  final ScrollController? controle;
  final Key? chaveDeRolagem;

  /// De onde sai a cor do pôster; por padrão, o cache do app.
  final CorPosterCache? cores;

  /// Espaço no fim da lista para a barra flutuante não cobrir a última fileira.
  final double folgaInferior;

  /// Fração da altura da tela que o destaque ocupa, e os limites em telas muito baixas ou altas.
  static const double fracaoDoDestaque = 0.74;
  static const double destaqueMinimo = 480;
  static const double destaqueMaximo = 780;

  /// Altura do topo quando não há destaque: só o lugar do botão de busca.
  static const double topoSemDestaque = 72;

  /// Véu no tom do papel atrás da barra de status, para as horas e os ícones se lerem sobre a arte.
  static const double opacidadeDoVeu = 0.55;

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _atual = 0;

  CorPosterCache get _cores => widget.cores ?? CorPosterCache.global;

  @override
  void initState() {
    super.initState();
    _cores.addListener(_mudou);
    _aquecer();
  }

  @override
  void didUpdateWidget(TelaInicio antiga) {
    super.didUpdateWidget(antiga);
    final antes = antiga.cores ?? CorPosterCache.global;
    if (antes != _cores) {
      antes.removeListener(_mudou);
      _cores.addListener(_mudou);
    }
    if (_atual >= widget.destaques.length) _atual = 0;
    if (!identical(antiga.destaques, widget.destaques)) _aquecer();
  }

  @override
  void dispose() {
    _cores.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  void _aquecer() {
    final hashes = [for (final titulo in widget.destaques) ?titulo.hash];
    if (hashes.isNotEmpty) _cores.aquecer(hashes);
  }

  @override
  Widget build(BuildContext context) {
    final base = TemaHeisuca.de(context);
    final papel = TemasCorPoster.de(base.nome);
    final destaques = widget.destaques;
    final hash = destaques.isEmpty ? null : destaques[_atual.clamp(0, destaques.length - 1)].hash;
    final paleta = _cores.ler(hash, papel) ?? PaletaPoster.neutra(papel);

    // O pôster tinge fundo e superfícies; texto e acento continuam os do tema.
    final tingido = base.copyWith(superficie: Color(paleta.superficie), superficie2: Color(paleta.superficie2));
    final material = Theme.of(context);
    final tempo = Movimento.tempo(context, Movimento.tema);

    final media = MediaQuery.of(context);
    final alturaDoDestaque = (media.size.height * TelaInicio.fracaoDoDestaque).clamp(
      TelaInicio.destaqueMinimo,
      TelaInicio.destaqueMaximo,
    );
    final temDestaque = destaques.isNotEmpty || widget.destaqueCarregando;

    Widget lista = CustomScrollView(
      key: widget.chaveDeRolagem,
      controller: widget.controle,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: temDestaque
              ? Destaque(
                  titulos: destaques,
                  altura: alturaDoDestaque,
                  aoMudar: (indice) => setState(() => _atual = indice),
                )
              : Padding(
                  padding: EdgeInsets.only(top: media.padding.top + TelaInicio.topoSemDestaque),
                  child: widget.noLugarDoDestaque,
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Forma.espaco2)),
        SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.fileiras),
        ),
        SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + widget.folgaInferior)),
      ],
    );
    if (widget.aoAtualizar != null) {
      lista = RefreshIndicator(
        color: base.texto,
        backgroundColor: Color(paleta.superficie2),
        edgeOffset: media.padding.top + Forma.espaco2,
        onRefresh: widget.aoAtualizar!,
        child: lista,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: base.brilho == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: base.brilho,
      ),
      child: AnimatedTheme(
        duration: tempo,
        curve: Movimento.padrao,
        data: material.copyWith(
          extensions: [
            for (final extensao in material.extensions.values)
              if (extensao is! TemaHeisuca) extensao,
            tingido,
          ],
        ),
        child: ColoredBox(
          color: base.fundo,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // O fundo não rola: é a parede da tela, e muda de cor com o destaque.
              ExcludeSemantics(
                child: AnimatedContainer(
                  duration: tempo,
                  curve: Movimento.padrao,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [for (final cor in paleta.degrade()) Color(cor)],
                    ),
                  ),
                  foregroundDecoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      // O raio do degradê é fração do lado menor; o alcance do halo é fração da altura.
                      radius: paleta.alcanceHalo * media.size.height / media.size.shortestSide,
                      colors: [Color(paleta.halo), Color(paleta.halo).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              lista,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: media.padding.top + Forma.espaco6,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          base.fundo.withValues(alpha: TelaInicio.opacidadeDoVeu),
                          base.fundo.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.perfil != null)
                PositionedDirectional(
                  top: media.padding.top + Forma.espaco2,
                  start: Forma.espaco4,
                  // A busca fica do outro lado: a pílula não passa por baixo dela.
                  end: Forma.espaco4 + Forma.toqueMinimo + Forma.espaco2,
                  child: Align(alignment: AlignmentDirectional.centerStart, child: widget.perfil),
                ),
              if (widget.aoBuscar != null)
                PositionedDirectional(
                  top: media.padding.top + Forma.espaco2,
                  end: Forma.espaco4,
                  child: BotaoDeIcone(
                    icone: Symbols.search_rounded,
                    rotulo: 'Buscar',
                    sobreArte: true,
                    aoTocar: widget.aoBuscar,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
