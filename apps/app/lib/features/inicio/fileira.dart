import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/cabecalho_de_fileira.dart';
import '../../design/componentes/cartao.dart';
import '../../design/cor_poster/cor_poster_cache.dart';
import '../../design/cor_poster/temas_cor_poster.dart';
import '../../design/forma.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import 'modelo.dart';

/// Medidas de uma fileira, iguais para a fileira pronta e para a que ainda carrega.
@immutable
class MedidaDaFileira {
  const MedidaDaFileira._({required this.largura, required this.alturaDoQuadro, required this.altura});

  /// O pôster deixa ver quatro cartões e o começo do quinto num celular; a paisagem, um e meio.
  factory MedidaDaFileira.de(BuildContext context, FormatoDoCartao formato, {required bool comSubtitulo}) {
    final tela = MediaQuery.sizeOf(context).width;
    final largura = switch (formato) {
      FormatoDoCartao.poster => ((tela - Forma.espaco4) / 4.3).clamp(88.0, 140.0),
      FormatoDoCartao.paisagem => ((tela - Forma.espaco4) / 1.55).clamp(200.0, 320.0),
    };
    return MedidaDaFileira._(
      largura: largura,
      alturaDoQuadro: largura / formato.proporcao,
      altura: Cartao.alturaPara(context, largura: largura, formato: formato, comSubtitulo: comSubtitulo),
    );
  }

  final double largura;
  final double alturaDoQuadro;
  final double altura;
}

/// Uma fileira do Início: cabeçalho e cartões que rolam de lado.
///
/// Fileira sem cartão não aparece (nem o título dela).
class Fileira extends StatefulWidget {
  const Fileira({super.key, required this.dados, this.cores});

  final FileiraDoInicio dados;

  /// De onde sai a cor do pôster de cada cartão; por padrão, o cache do app.
  final CorPosterCache? cores;

  /// Largura reservada ao número de uma fileira numerada.
  static const double larguraDoNumero = 40;

  /// Quantos cartões uma fileira numerada mostra.
  static const int limiteNumerada = 10;

  @override
  State<Fileira> createState() => _FileiraState();
}

class _FileiraState extends State<Fileira> {
  CorPosterCache get _cores => widget.cores ?? CorPosterCache.global;

  @override
  void initState() {
    super.initState();
    _cores.addListener(_mudou);
    _aquecer();
  }

  @override
  void didUpdateWidget(Fileira antiga) {
    super.didUpdateWidget(antiga);
    if ((antiga.cores ?? CorPosterCache.global) != _cores) {
      (antiga.cores ?? CorPosterCache.global).removeListener(_mudou);
      _cores.addListener(_mudou);
    }
    if (!identical(antiga.dados.itens, widget.dados.itens)) _aquecer();
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
    final hashes = [for (final item in widget.dados.itens) ?item.hash];
    if (hashes.isNotEmpty) _cores.aquecer(hashes);
  }

  @override
  Widget build(BuildContext context) {
    final dados = widget.dados;
    final itens = dados.numerada ? dados.itens.take(Fileira.limiteNumerada).toList() : dados.itens;
    if (itens.isEmpty) return const SizedBox.shrink();

    final tema = TemaHeisuca.de(context);
    final papel = TemasCorPoster.de(tema.nome);
    final medida = MedidaDaFileira.de(
      context,
      dados.formato,
      comSubtitulo: itens.any((item) => item.subtitulo != null),
    );

    Widget cartao(ItemDaFileira item) {
      final paleta = _cores.ler(item.hash, papel);
      return Cartao(
        key: ValueKey(item.chave),
        titulo: item.titulo,
        subtitulo: item.subtitulo,
        largura: medida.largura,
        formato: dados.formato,
        corDoPoster: paleta == null ? null : Color(paleta.superficie2),
        arte: item.arte?.call(context, Size(medida.largura, medida.alturaDoQuadro)),
        progresso: item.progresso,
        tempo: item.tempo,
        nota: item.nota,
        visto: item.visto,
        aoTocar: item.aoTocar,
        aoSegurar: item.aoSegurar,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Forma.espaco4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoDeFileira(
            titulo: dados.titulo,
            aoVerTudo: dados.aoVerTudo,
            iconeDeVerTudo: Symbols.chevron_right_rounded,
          ),
          SizedBox(
            height: medida.altura,
            child: ListView.separated(
              key: PageStorageKey('fileira-${dados.chave}'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Forma.espaco4),
              itemCount: itens.length,
              separatorBuilder: (_, _) => const SizedBox(width: Forma.espaco3),
              itemBuilder: (context, i) {
                if (!dados.numerada) return cartao(itens[i]);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: Fileira.larguraDoNumero,
                      height: medida.alturaDoQuadro,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${i + 1}',
                            semanticsLabel: '${i + 1}º lugar',
                            textScaler: TextScaler.noScaling,
                            style: Tipo.destaque(tema).copyWith(color: tema.texto2, fontFeatures: Tipo.algarismos),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Forma.espaco1),
                    cartao(itens[i]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// O lugar de uma fileira enquanto os dados não chegam: mesmas medidas, sem texto.
class FileiraCarregando extends StatelessWidget {
  const FileiraCarregando({super.key, this.formato = FormatoDoCartao.poster});

  final FormatoDoCartao formato;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final medida = MedidaDaFileira.de(context, formato, comSubtitulo: false);
    final quantos = (MediaQuery.sizeOf(context).width / (medida.largura + Forma.espaco3)).ceil();
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Forma.espaco4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Forma.toqueMinimo),
            SizedBox(
              height: medida.altura,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: Forma.espaco4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < quantos; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: Forma.espaco3),
                          child: SizedBox(
                            width: medida.largura,
                            height: medida.alturaDoQuadro,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                shape: Forma.superelipse(Forma.raioMedio),
                                color: tema.superficie2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
