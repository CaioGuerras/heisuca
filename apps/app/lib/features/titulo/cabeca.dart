import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design/componentes/botao.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../design/vibracao.dart';
import '../meta_do_titulo.dart';
import 'modelo.dart';

/// A cabeça da página do título: a arte sobe até a barra de status e se desfaz no fundo;
/// por cima do fim dela vêm o logo, os dados, o botão de assistir, as ações e a sinopse.
///
/// A altura é a do conteúdo: com letra grande o bloco cresce para baixo, nada é cortado.
class CabecaDoTitulo extends StatelessWidget {
  const CabecaDoTitulo({
    super.key,
    required this.pagina,
    required this.alturaDaArte,
    this.chaveDoAssistir,
    this.rolagem,
  });

  final PaginaDoTitulo pagina;

  /// Altura da arte, do topo da tela até onde ela termina de se desfazer.
  final double alturaDaArte;

  /// Marca o botão de assistir, para a tela saber quando ele saiu de vista.
  final Key? chaveDoAssistir;

  /// Quanto a página já rolou. Com isto a arte sobe mais devagar que o texto e vai sumindo.
  final ValueListenable<double>? rolagem;

  /// Fração da rolagem que a arte deixa de acompanhar: ela fica para trás enquanto o texto sobe.
  static const double atrasoDaArte = 0.4;

  /// Onde a arte começa a se desfazer, em fração da própria altura.
  static const double inicioDoEsmaecer = 0.55;

  /// Quanto do bloco de texto fica por cima do fim da arte.
  static const double sobreposicao = 148;

  static const double _alturaDoLogo = 72;
  static const double _larguraDoLogo = 0.62;
  static const double _alturaDoProgresso = 3;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return LayoutBuilder(
      builder: (context, limites) {
        final largura = limites.maxWidth;
        final tamanhoDoLogo = Size(largura * _larguraDoLogo, _alturaDoLogo);
        final semLogo = Text(
          pagina.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Tipo.titulo(tema),
        );
        final temAcoes = pagina.aoAlternarLista != null || pagina.aoAlternarVisto != null;

        return Stack(
          children: [
            if (pagina.arte != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: alturaDaArte,
                child: ExcludeSemantics(
                  child: _ArteQueFica(
                    rolagem: rolagem,
                    altura: alturaDaArte,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      // Só o alfa conta: a arte se desfaz no fundo tingido da tela.
                      shaderCallback: (area) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, inicioDoEsmaecer, 1],
                        colors: [tema.fundo, tema.fundo, tema.fundo.withValues(alpha: 0)],
                      ).createShader(area),
                      child: pagina.arte!(context, Size(largura, alturaDaArte)),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Forma.espaco4,
                (alturaDaArte - sobreposicao).clamp(0, double.infinity),
                Forma.espaco4,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    label: pagina.titulo,
                    excludeSemantics: true,
                    child: Center(
                      child: pagina.logo == null
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: _alturaDoLogo),
                              child: Align(alignment: Alignment.bottomCenter, child: semLogo),
                            )
                          : SizedBox.fromSize(
                              size: tamanhoDoLogo,
                              child: pagina.logo!(context, tamanhoDoLogo, Center(child: semLogo)),
                            ),
                    ),
                  ),
                  const SizedBox(height: Forma.espaco3),
                  MetaDoTitulo(
                    nota: pagina.nota,
                    anos: pagina.anos,
                    generos: pagina.generos,
                    classificacao: pagina.classificacao,
                  ),
                  if (pagina.detalhes.isNotEmpty) ...[
                    const SizedBox(height: Forma.espaco1),
                    Text(pagina.detalhes.join(' · '), textAlign: TextAlign.center, style: Tipo.tempo(tema)),
                  ],
                  if (pagina.aoAssistir != null) ...[
                    const SizedBox(height: Forma.espaco4),
                    Botao(
                      key: chaveDoAssistir,
                      rotulo: pagina.rotuloDeAssistir,
                      icone: Symbols.play_arrow_rounded,
                      expandido: true,
                      vibracao: Vibracao.confirmar,
                      aoTocar: pagina.aoAssistir,
                    ),
                    if (pagina.progresso != null) ...[
                      const SizedBox(height: Forma.espaco2),
                      _Progresso(valor: pagina.progresso!, altura: _alturaDoProgresso),
                    ],
                  ],
                  if (temAcoes) ...[
                    const SizedBox(height: Forma.espaco2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (pagina.aoAlternarLista != null)
                          BotaoDeIcone(
                            icone: Symbols.favorite_rounded,
                            rotulo: 'Minha lista',
                            selecionado: pagina.naLista,
                            vibracao: Vibracao.confirmar,
                            aoTocar: pagina.aoAlternarLista,
                          ),
                        if (pagina.aoAlternarLista != null && pagina.aoAlternarVisto != null)
                          const SizedBox(width: Forma.espaco4),
                        if (pagina.aoAlternarVisto != null)
                          BotaoDeIcone(
                            icone: Symbols.check_circle_rounded,
                            rotulo: 'Já vi',
                            selecionado: pagina.visto,
                            vibracao: Vibracao.confirmar,
                            aoTocar: pagina.aoAlternarVisto,
                          ),
                      ],
                    ),
                  ],
                  if (pagina.sinopse != null) ...[
                    const SizedBox(height: Forma.espaco2),
                    _Sinopse(titulo: pagina.titulo, texto: pagina.sinopse!),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A arte acompanha a rolagem com atraso e some aos poucos; com "remover animações" ela rola junto, parada.
class _ArteQueFica extends StatelessWidget {
  const _ArteQueFica({required this.rolagem, required this.altura, required this.child});

  final ValueListenable<double>? rolagem;
  final double altura;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rolagem = this.rolagem;
    if (rolagem == null || Movimento.reduzido(context)) return child;
    return ValueListenableBuilder<double>(
      valueListenable: rolagem,
      child: child,
      builder: (context, rolado, child) {
        // Puxar a página para baixo (rolagem negativa) não mexe na arte.
        final andou = rolado.clamp(0.0, altura);
        return Transform.translate(
          offset: Offset(0, andou * CabecaDoTitulo.atrasoDaArte),
          child: Opacity(opacity: 1 - andou / altura, child: child),
        );
      },
    );
  }
}

/// Quanto já foi visto, numa linha fina centrada sob o botão.
class _Progresso extends StatelessWidget {
  const _Progresso({required this.valor, required this.altura});

  final double valor;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final visto = valor.clamp(0.0, 1.0);
    return Semantics(
      label: '${(visto * 100).round()}% assistido',
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: SizedBox(
          height: altura,
          child: DecoratedBox(
            decoration: ShapeDecoration(color: tema.borda, shape: Forma.pilula()),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: visto,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: tema.acento, shape: Forma.pilula()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sinopse, com o nome do título à frente. Curta por padrão; o toque mostra o texto inteiro.
class _Sinopse extends StatefulWidget {
  const _Sinopse({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  static const int linhasFechada = 3;

  @override
  State<_Sinopse> createState() => _SinopseState();
}

class _SinopseState extends State<_Sinopse> {
  bool _aberta = false;

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return Toque(
      forma: Forma.superelipse(Forma.raioPequeno),
      escala: 1,
      rotulo: '${widget.texto}. ${_aberta ? 'Mostrar menos' : 'Mostrar tudo'}',
      excluirSemantica: true,
      aoTocar: () => setState(() => _aberta = !_aberta),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Forma.espaco2),
        child: AnimatedSize(
          duration: Movimento.tempo(context, Movimento.cartao),
          curve: Movimento.padrao,
          alignment: Alignment.topCenter,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '「${widget.titulo}」 ',
                  style: TextStyle(color: tema.texto, fontWeight: FontWeight.w700),
                ),
                TextSpan(text: widget.texto),
              ],
            ),
            maxLines: _aberta ? null : _Sinopse.linhasFechada,
            overflow: _aberta ? TextOverflow.clip : TextOverflow.ellipsis,
            style: Tipo.pequeno(tema),
          ),
        ),
      ),
    );
  }
}
