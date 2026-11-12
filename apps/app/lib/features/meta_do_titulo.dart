import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../design/forma.dart';
import '../design/tema.dart';
import '../design/tipo.dart';

/// "★ nota · anos · gêneros · classificação". O que falta não aparece, nem o ponto dele.
class MetaDoTitulo extends StatelessWidget {
  const MetaDoTitulo({super.key, this.nota, this.anos, this.generos, this.classificacao});

  /// Nota já formatada ("8,6").
  final String? nota;

  /// Ano ou intervalo ("2000 - 2010").
  final String? anos;
  final String? generos;

  /// Classificação indicativa ("12").
  final String? classificacao;

  static const double _estrela = 16;

  /// O que o leitor de tela diz no lugar da linha.
  static List<String> rotulos({String? nota, String? anos, String? generos, String? classificacao}) => [
    if (nota != null) 'nota $nota',
    ?anos,
    ?generos,
    if (classificacao != null) 'classificação $classificacao',
  ];

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final estilo = Tipo.tempo(tema);
    final partes = <Widget>[
      if (nota != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.star_rounded, size: _estrela, fill: 1, color: tema.acento),
            const SizedBox(width: Forma.espaco1),
            Text(
              nota!,
              style: estilo.copyWith(color: tema.texto, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      if (anos != null) Text(anos!, style: estilo),
      if (generos != null) Text(generos!, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo),
      if (classificacao != null)
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: Forma.superelipse(Forma.raioPequeno, lado: BorderSide(color: tema.borda)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Forma.espaco2, vertical: Forma.espaco1 / 2),
            child: Text(classificacao!, style: Tipo.legenda(tema).copyWith(color: tema.texto)),
          ),
        ),
    ];
    if (partes.isEmpty) return const SizedBox.shrink();
    // Numa linha só quando cabe; com letra grande, o que não cabe desce para a linha de baixo.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: Forma.espaco1,
      children: [
        for (var i = 0; i < partes.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // O selo da classificação já tem contorno: basta o espaço. Sem o ponto, a linha que ele abre ao
              // descer não começa com um ponto solto.
              if (i > 0 && partes[i] is DecoratedBox)
                const SizedBox(width: Forma.espaco2)
              else if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Forma.espaco2),
                  child: Text('·', style: estilo),
                ),
              Flexible(child: partes[i]),
            ],
          ),
      ],
    );
  }
}
