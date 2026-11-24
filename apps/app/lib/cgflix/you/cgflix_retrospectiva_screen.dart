// Tela "Minha retrospectiva" (Caio, 24/11): mesmo conteúdo e mesmos textos da página
// heisuca.docaio.com.br/retrospectiva/, lido com a sessão da própria conta (funciona na TV e sem login no site).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../screens/libraries/state_messages.dart';
import '../../utils/app_logger.dart';
import '../cgflix_palette.dart';
import 'cgflix_retrospectiva.dart';

Future<void> cgflixOpenRetrospectiva(BuildContext context, CgflixRetrospectivaFonte fonte) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'cgflix/retrospectiva'),
        builder: (_) => CgflixRetrospectivaScreen(fonte: fonte),
      ),
    );

class CgflixRetrospectivaScreen extends StatefulWidget {
  const CgflixRetrospectivaScreen({super.key, required this.fonte});
  final CgflixRetrospectivaFonte fonte;

  @override
  State<CgflixRetrospectivaScreen> createState() => _CgflixRetrospectivaScreenState();
}

class _CgflixRetrospectivaScreenState extends State<CgflixRetrospectivaScreen> {
  late Future<CgflixRetrospectiva?> _future = _carregar();
  final _scroll = ScrollController();

  Future<CgflixRetrospectiva?> _carregar() async {
    try {
      return CgflixRetrospectiva.escolher(await widget.fonte.preferencias());
    } catch (e) {
      appLogger.w('CGFLIX: retrospectiva não carregou', error: e);
      rethrow;
    }
  }

  void _tentarDeNovo() {
    final novo = _carregar();
    setState(() {
      _future = novo;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Controle remoto da TV: setas para cima e para baixo rolam a tela (não há nada focável no meio).
  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent || !_scroll.hasClients) return KeyEventResult.ignored;
    final passo = switch (e.logicalKey) {
      LogicalKeyboardKey.arrowDown => 240.0,
      LogicalKeyboardKey.arrowUp => -240.0,
      _ => null,
    };
    if (passo == null) return KeyEventResult.ignored;
    final p = _scroll.position;
    _scroll.animateTo(
      (p.pixels + passo).clamp(p.minScrollExtent, p.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retrospectiva')),
      body: FutureBuilder<CgflixRetrospectiva?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorStateWidget(
              message: 'Não deu para carregar agora',
              icon: Symbols.cloud_off_rounded,
              onRetry: _tentarDeNovo,
              retryLabel: 'Tentar de novo',
            );
          }
          final d = snap.data;
          if (d == null) {
            return const EmptyStateWidget(
              icon: Symbols.auto_awesome_rounded,
              message: 'Sua retrospectiva ainda não saiu',
              subtitle: 'Ela aparece aqui quando houver o que contar. Volte daqui a alguns dias.',
            );
          }
          if (d.horas == 0) {
            return EmptyStateWidget(
              icon: Symbols.auto_awesome_rounded,
              message: 'Ainda não há nada aqui',
              subtitle: 'Não achamos reproduções suas em ${d.ano}. Bom filme!',
            );
          }
          return Focus(
            autofocus: true,
            onKeyEvent: _tecla,
            child: _Conteudo(dados: d, fonte: widget.fonte, scroll: _scroll),
          );
        },
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.dados, required this.fonte, required this.scroll});
  final CgflixRetrospectiva dados;
  final CgflixRetrospectivaFonte fonte;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final d = dados;
    final palette = CgflixPalette.of(context);
    final texto = Theme.of(context).textTheme;
    final nome = fonte.nome.trim().split(RegExp(r'\s+')).first;
    final numeros = <(String, String)>[
      (CgflixRetroTexto.numero(d.horas), 'horas de tela'),
      (CgflixRetroTexto.numero(d.diasComTela), d.diasComTela == 1 ? 'dia assistindo' : 'dias assistindo'),
      (CgflixRetroTexto.numero(d.titulos), d.titulos == 1 ? 'título' : 'títulos'),
      (CgflixRetroTexto.numero(d.episodios), d.episodios == 1 ? 'episódio' : 'episódios'),
      (CgflixRetroTexto.numero(d.filmes), d.filmes == 1 ? 'filme' : 'filmes'),
    ];
    String detSerie(CgflixRetroTitulo x) => CgflixRetroTexto.plural(x.detalhe, 'episódio', 'episódios');
    String detFilme(CgflixRetroTitulo x) => CgflixRetroTexto.plural(x.detalhe, 'vez', 'vezes');
    final destaque = d.topSeries.isNotEmpty
        ? ('Série do ano', d.topSeries.first, detSerie(d.topSeries.first))
        : d.topFilmes.isNotEmpty
        ? ('Filme do ano', d.topFilmes.first, detFilme(d.topFilmes.first))
        : null;
    final fatos = <(String, String)>[
      if (d.mesForte case final m?) ('Mês em que você mais assistiu', CgflixRetroTexto.meses[m] ?? m),
      if (d.diaDaSemana case final s?) ('Seu dia favorito da semana', s),
      if (d.maratonaDia case final dia? when d.maratonaHoras != null)
        (
          'Maior maratona',
          '${CgflixRetroTexto.plural(d.maratonaHoras!, 'hora', 'horas')} em ${CgflixRetroTexto.data(dia)}',
        ),
    ];

    Widget caixa(Widget filho) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16)),
      child: filho,
    );

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Retrospectiva ${d.ano}', style: texto.labelLarge?.copyWith(color: palette.accent)),
        const SizedBox(height: 4),
        Text(
          '${nome.isEmpty ? 'Seu' : '$nome, seu'} ${d.ano} no Heisuca',
          style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Tudo o que você assistiu neste ano, até ${CgflixRetroTexto.data(d.ate)}.',
          style: texto.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (n, rot) in numeros)
              SizedBox(
                width: 104,
                child: caixa(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n, style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(rot, style: texto.bodySmall?.copyWith(color: palette.textMuted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (destaque case (final rot, final x, final det)) ...[
          const SizedBox(height: 20),
          caixa(
            Row(
              children: [
                _Poster(url: x.id == null ? null : fonte.posterUrl(x.id!), largura: 96),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rot, style: texto.labelMedium?.copyWith(color: palette.accent)),
                      const SizedBox(height: 4),
                      Text(x.titulo, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${CgflixRetroTexto.plural(x.horas, 'hora', 'horas')} · $det',
                        style: texto.bodySmall?.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (d.topSeries.isNotEmpty) _Top(titulo: 'Suas séries', itens: d.topSeries, fonte: fonte, detalhe: detSerie),
        if (d.topFilmes.isNotEmpty) _Top(titulo: 'Seus filmes', itens: d.topFilmes, fonte: fonte, detalhe: detFilme),
        if (fatos.isNotEmpty || d.generos.isNotEmpty) const SizedBox(height: 20),
        for (final (rot, valor) in fatos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: caixa(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rot, style: texto.bodySmall?.copyWith(color: palette.textMuted)),
                  const SizedBox(height: 2),
                  Text(valor, style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        if (d.generos.isNotEmpty)
          caixa(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seus gêneros', style: texto.bodySmall?.copyWith(color: palette.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in d.generos)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: palette.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                        child: Text(g, style: texto.bodySmall),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Só você vê esta tela. Conta o tempo de tela real; o que durou menos de 2 minutos ficou de fora. '
          'Atualizada todo dia.',
          style: texto.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _Top extends StatelessWidget {
  const _Top({required this.titulo, required this.itens, required this.fonte, required this.detalhe});
  final String titulo;
  final List<CgflixRetroTitulo> itens;
  final CgflixRetrospectivaFonte fonte;
  final String Function(CgflixRetroTitulo) detalhe;

  @override
  Widget build(BuildContext context) {
    final palette = CgflixPalette.of(context);
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(titulo, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final (i, x) in itens.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}',
                    style: texto.titleMedium?.copyWith(color: palette.accent, fontWeight: FontWeight.w700),
                  ),
                ),
                _Poster(url: x.id == null ? null : fonte.posterUrl(x.id!), largura: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(x.titulo, style: texto.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(
                        '${CgflixRetroTexto.plural(x.horas, 'hora', 'horas')} · ${detalhe(x)}',
                        style: texto.bodySmall?.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pôster 2:3; sem imagem (saiu do acervo ou falhou) fica a moldura vazia.
class _Poster extends StatelessWidget {
  const _Poster({required this.url, required this.largura});
  final String? url;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final vazio = ColoredBox(color: CgflixPalette.of(context).surfaceHigh);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: largura,
        height: largura * 1.5,
        child: url == null || url!.isEmpty
            ? vazio
            : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => vazio),
      ),
    );
  }
}
