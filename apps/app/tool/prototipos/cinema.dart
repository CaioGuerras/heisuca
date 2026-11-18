// Protótipo Flutter para aprovação visual. Dados de demonstração;
// não faz parte do entrypoint, do pacote distribuído ou das conexões reais.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/desktop/desktop_theme.dart';
import 'package:heisuca/heisuca/heisuca_logo.dart';

class FilmeDemo {
  const FilmeDemo(this.nome, this.arquivo, this.ano);
  final String nome, arquivo, ano;
}
const filmes = [
  FilmeDemo('Duna: Parte Dois', 'dune.jpg', '2024'),
  FilmeDemo('Interestelar', 'interstellar.jpg', '2014'),
  FilmeDemo('Blade Runner 2049', 'blade-runner.jpg', '2017'),
  FilmeDemo('A Chegada', 'arrival.jpg', '2016'),
  FilmeDemo('Oppenheimer', 'oppenheimer.jpg', '2023'),
  FilmeDemo('Whiplash', 'whiplash.jpg', '2014'),
  FilmeDemo('1917', '1917.jpg', '2019'),
  FilmeDemo('Batman', 'batman.jpg', '2022'),
];

class CinemaPrototype extends StatefulWidget {
  const CinemaPrototype({super.key, required this.assets, required this.images, this.lateral = false, this.ficha = false});
  final String assets;
  final Map<String, ui.Image> images;
  final bool lateral, ficha;
  @override
  State<CinemaPrototype> createState() => _CinemaPrototypeState();
}
class _CinemaPrototypeState extends State<CinemaPrototype> {
  bool ficha = false;
  bool lista = false;
  String aba = 'Início';
  String busca = '';
  TemaHeisuca get p => Theme.of(context).extension<TemaHeisuca>()!;
  @override
  void initState() { super.initState(); ficha = widget.ficha; }
  Text label(String text, {double size = 14, bool bold = false, Color? color, double? spacing, int? lines}) => Text(text,
    maxLines: lines, overflow: lines == null ? null : TextOverflow.ellipsis,
    style: TextStyle(fontFamily: 'Inter', fontSize: size, fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: color ?? p.texto, letterSpacing: spacing, height: 1.35));
  Widget picture(String file, {BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center}) => RawImage(
    image: widget.images[file], fit: fit, alignment: alignment);
  void details() => setState(() => ficha = true);
  void note(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Widget tap({required Widget child, required VoidCallback onTap, String? name, double radius = 12}) => Toque(
    forma: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)), aoTocar: onTap, rotulo: name, child: child);
  Widget icon(IconData glyph, String name, VoidCallback action) => tap(name: name, onTap: action,
    child: SizedBox(width: 40, height: 40, child: Icon(glyph, color: p.texto, size: 21)));
  Widget button(String text, IconData glyph, VoidCallback action, {bool primary = false}) => tap(onTap: action,
    child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 19),
      decoration: BoxDecoration(color: primary ? p.botaoFundo : p.fundo.withValues(alpha: .40),
        borderRadius: BorderRadius.circular(11), border: primary ? null : Border.all(color: p.texto.withValues(alpha: .24))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(glyph, size: 20, color: primary ? p.botaoTexto : p.texto),
        const SizedBox(width: 9), label(text, bold: true, color: primary ? p.botaoTexto : p.texto)])));
  Widget nav(String text, IconData glyph, {bool side = false}) {
    final selected = aba == text;
    return tap(onTap: () => setState(() {aba = text; ficha = false;}), child: Container(
      height: side ? 46 : 44, padding: EdgeInsets.symmetric(horizontal: side ? 15 : 13),
      decoration: BoxDecoration(color: side && selected ? p.superficie2 : null,
        borderRadius: BorderRadius.circular(11)),
      child: Row(mainAxisSize: side ? MainAxisSize.max : MainAxisSize.min, children: [
        if (side) ...[Icon(glyph, size: 20, color: selected ? p.texto : p.texto2), const SizedBox(width: 13)],
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [label(text, size: side ? 12 : 14, bold: selected, color: selected ? p.texto : p.texto2),
          if (!side) ...[const SizedBox(height: 7), Container(width: 15, height: 2,
            decoration: BoxDecoration(color: selected ? p.acento : Colors.transparent, borderRadius: BorderRadius.circular(2)))]]),
      ])));
  }
  Widget source({bool side = false}) => tap(onTap: () => note('Prévia: aqui você troca entre suas bibliotecas.'),
    child: Container(padding: EdgeInsets.symmetric(horizontal: side ? 12 : 15, vertical: 10),
      decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.borda)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.dns_outlined, size: 17, color: p.texto2),
        const SizedBox(width: 10), label('Sua biblioteca', size: 12, bold: true), const SizedBox(width: 14),
        Icon(Icons.expand_more, size: 17, color: p.texto2)])));
  Widget search() => SizedBox(width: widget.lateral ? 285 : 238, height: 38, child: TextField(
    onChanged: (value) => setState(() => busca = value),
    style: TextStyle(fontSize: 12, color: p.texto),
    decoration: InputDecoration(hintText: 'Buscar na sua biblioteca', hintStyle: TextStyle(fontSize: 12, color: p.texto2),
      contentPadding: const EdgeInsets.symmetric(vertical: 8), prefixIcon: Icon(Icons.search, size: 18, color: p.texto2),
      suffixIcon: Padding(padding: const EdgeInsets.only(top: 10, right: 10), child: label('⌘ K', size: 10, color: p.texto2)),
      fillColor: p.superficie, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: p.borda)))));
  Widget topbar() => Container(height: 76, padding: EdgeInsets.symmetric(horizontal: widget.lateral ? 36 : 44),
    child: Row(children: [
      if (!widget.lateral) ...[const HeisucaLogo(width: 156, height: 34, siteHeader: true), const SizedBox(width: 38),
        nav('Início', Icons.home_outlined), nav('Filmes', Icons.movie_outlined), nav('Séries', Icons.live_tv_outlined), nav('Minha lista', Icons.bookmark_border)],
      if (widget.lateral) ...[if(ficha) icon(Icons.arrow_back, 'Voltar', () => setState(() => ficha = false)),
        label(ficha ? 'Filmes' : 'Bom filme, Caio.', size: 20, bold: true), const SizedBox(width: 14),
        label('Biblioteca de demonstração', size: 11, color: p.texto2)],
      const Spacer(), search(), const SizedBox(width: 16),
      icon(Icons.add, 'Abrir arquivo ou URL', () => note('Prévia: abrir arquivo ou URL sem sair da biblioteca.')),
      const SizedBox(width: 12), tap(onTap: () => note('Prévia: perfil e ajustes.'), child: CircleAvatar(radius: 17,
        backgroundColor: p.superficie2, child: label('C', bold: true, size: 12))),
    ]));
  Widget sidebar() => Container(width: 216, decoration: BoxDecoration(color: p.superficie.withValues(alpha: .42),
    border: Border(right: BorderSide(color: p.borda.withValues(alpha: .45)))), padding: const EdgeInsets.fromLTRB(22, 28, 20, 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const HeisucaLogo(width: 155, height: 34, siteHeader: true), const SizedBox(height: 35), source(side: true),
      const SizedBox(height: 32), nav('Início', Icons.home_outlined, side: true), const SizedBox(height: 5),
      nav('Filmes', Icons.movie_outlined, side: true), const SizedBox(height: 5), nav('Séries', Icons.live_tv_outlined, side: true),
      const SizedBox(height: 5), nav('Minha lista', Icons.bookmark_border, side: true), const SizedBox(height: 34),
      Padding(padding: const EdgeInsets.only(left: 15), child: label('NO SEU COMPUTADOR', size: 9, spacing: 1.1, color: p.texto2)),
      const SizedBox(height: 10), nav('Arquivos recentes', Icons.folder_open_outlined, side: true),
      const Spacer(), tap(onTap: () => note('Prévia: ajustes de aparência e reprodução.'), child: Row(children: [
        Icon(Icons.tune, size: 18, color: p.texto2), const SizedBox(width: 13), label('Ajustes', size: 13, color: p.texto2)])),
      const SizedBox(height: 22), label('Prévia visual · dados de demonstração', size: 9, color: p.texto2),
    ]));
  Widget hero() => SizedBox(height: widget.lateral ? 306 : 354, child: LayoutBuilder(builder: (context, bounds) => Stack(children: [
    Positioned(right: 0, top: -45, bottom: -35, width: bounds.maxWidth * .84,
      child: picture('dune-hero.jpg', alignment: const Alignment(.4, .45))),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [p.fundo, p.fundo.withValues(alpha: .92),
      p.fundo.withValues(alpha: .28), p.fundo.withValues(alpha: .04)], stops: const [0, .24, .55, 1])))),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [p.fundo.withValues(alpha: .18), Colors.transparent, p.fundo], stops: const [0, .55, 1])))),
    Positioned(left: widget.lateral ? 36 : 48, top: widget.lateral ? 23 : 30, width: 465,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if(!widget.lateral) ...[source(), const SizedBox(height: 23)] else ...[label('O CINEMA MERECE A TELA TODA', size: 10, spacing: 2.2, color: p.texto2), const SizedBox(height: 13)],
        label('DUNA', size: widget.lateral ? 56 : 64, spacing: 10, bold: true),
        Padding(padding: const EdgeInsets.only(left: 3), child: label('P A R T E  D O I S', size: 14, spacing: 3.2)),
        const SizedBox(height: 15), Row(children: [label('2024   ·   2h 47min   ·   Ficção científica', size: 12, color: p.texto2),
          const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(border: Border.all(color: p.texto2.withValues(alpha: .45)), borderRadius: BorderRadius.circular(3)), child: label('4K', size: 9))]),
        const SizedBox(height: 13), label('Uma jornada além do destino. Paul e Chani enfrentam\num império nas areias de Arrakis.', size: 13, color: p.texto2),
        const SizedBox(height: 22), Row(children: [button('Assistir', Icons.play_arrow_rounded, () => note('Prévia visual: não inicia reprodução real.'), primary: true),
          const SizedBox(width: 10), button('Ver detalhes', Icons.info_outline, details), const SizedBox(width: 8),
          icon(lista ? Icons.bookmark : Icons.bookmark_border, 'Minha lista', () => setState(() => lista = !lista))]),
      ])),
    Positioned(right: 48, bottom: 30, child: Row(children: List.generate(3, (i) => Container(margin: const EdgeInsets.only(left: 6),
      width: i == 0 ? 24 : 5, height: 4, decoration: BoxDecoration(color: p.texto.withValues(alpha: i == 0 ? .9 : .3), borderRadius: BorderRadius.circular(3)))))),
  ])));
  Widget heading(String title, String sub, {String? action}) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    label(title, size: 19, bold: true), const SizedBox(width: 13), label(sub, size: 11, color: p.texto2), const Spacer(),
    if(action != null) tap(onTap: () => setState(() => aba = 'Filmes'), child: Row(children: [label(action, size: 11, color: p.texto2),
      const SizedBox(width: 5), Icon(Icons.chevron_right, size: 16, color: p.texto2)]))]);
  Widget resume() => Column(children: [heading('Continue de onde parou', 'Seu tempo, sua história.', action: 'Ver todos'), const SizedBox(height: 17),
    LayoutBuilder(builder: (_, bounds) => Row(children: List.generate(4, (i) {
      final f = filmes[[1,2,4,5][i]];
      return Expanded(child: Padding(padding: EdgeInsets.only(right: i == 3 ? 0 : 18), child: _HoverCard(
        onTap: details, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: widget.lateral ? 89 : 101, width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [picture(f.arquivo, alignment: const Alignment(0, -.1)),
              ColoredBox(color: p.fundo.withValues(alpha: .15)),
              Align(alignment: Alignment.center, child: Container(width: 31, height: 31,
                decoration: BoxDecoration(color: p.fundo.withValues(alpha: .48), shape: BoxShape.circle,
                  border: Border.all(color: p.texto.withValues(alpha: .65))), child: Icon(Icons.play_arrow_rounded, size: 19, color: p.texto))),
              Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: [.32,.57,.21,.73][i], minHeight: 3,
                color: p.acento, backgroundColor: p.fundo.withValues(alpha: .5))),
              Positioned(right: 8, bottom: 9, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: p.fundo.withValues(alpha: .7), borderRadius: BorderRadius.circular(4)),
                child: label(['Restam 1h 54','Restam 1h 10','Restam 2h 22','Restam 29min'][i], size: 9))),
            ]))), const SizedBox(height: 8), label(f.nome, size: 12, bold: true, lines: 1),
        ]))));
    }))),
  ]);
  Widget posters() {
    final visible = filmes.where((f) => f.nome.toLowerCase().contains(busca.toLowerCase())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading(busca.isEmpty ? 'Uma boa noite começa aqui' : 'Resultados da busca',
      busca.isEmpty ? 'Da sua biblioteca' : '${visible.length} títulos', action: 'Explorar filmes'), const SizedBox(height: 17),
      LayoutBuilder(builder: (_, bounds) {
        final width = (bounds.maxWidth - (widget.lateral ? 6 : 7) * 17) / (widget.lateral ? 7 : 8);
        return SizedBox(height: width * 1.5 + 45, child: ListView.separated(scrollDirection: Axis.horizontal,
          itemCount: visible.length, separatorBuilder: (_, _) => const SizedBox(width: 17), itemBuilder: (_, i) {
            final f = visible[i];
            return SizedBox(width: width, child: _HoverCard(onTap: details, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: width, height: width * 1.5, child: picture(f.arquivo))),
              const SizedBox(height: 8), label(f.nome, size: 11, bold: true, lines: 1), const SizedBox(height: 2), label(f.ano, size: 10, color: p.texto2),
            ])));
          }));
      }),
    ]);
  }
  Widget home() => ListView(children: [hero(), Padding(padding: EdgeInsets.symmetric(horizontal: widget.lateral ? 36 : 48),
    child: Column(children: [const SizedBox(height: 6), resume(), const SizedBox(height: 29), posters(), const SizedBox(height: 35),
      if(!widget.lateral) label('Prévia visual · biblioteca de demonstração', size: 10, color: p.texto2), const SizedBox(height: 20)]))]);
  Widget detail() => ListView(children: [SizedBox(height: 438, child: Stack(children: [
    Positioned(left: 280, right: 0, top: -30, bottom: 0, child: picture('dune-hero.jpg', alignment: const Alignment(0, .4))),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [p.fundo, p.fundo.withValues(alpha: .9),
      p.fundo.withValues(alpha: .1)], stops: const [0,.25,1])))),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.transparent, p.fundo], stops: const [.35,1])))),
    Positioned(left: 48, top: 20, child: icon(Icons.arrow_back, 'Voltar ao início', () => setState(() => ficha = false))),
    Positioned(left: 48, top: 84, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 176, height: 264, child: picture('dune.jpg')))),
    Positioned(left: 258, top: 92, width: 560, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('DA SUA BIBLIOTECA', size: 10, color: p.texto2, spacing: 2), const SizedBox(height: 15),
      label('Duna: Parte Dois', size: 38, bold: true), const SizedBox(height: 12), label('2024   ·   2h 47min   ·   Ficção científica, aventura', size: 13, color: p.texto2),
      const SizedBox(height: 20), label('Paul Atreides se une a Chani e aos Fremen enquanto busca\nvingança contra os conspiradores que destruíram sua família.\nUma escolha entre o amor e o destino do universo.', size: 14, color: p.texto2),
      const SizedBox(height: 25), Row(children: [button('Assistir', Icons.play_arrow_rounded, () => note('Prévia visual: não inicia reprodução real.'), primary: true),
        const SizedBox(width: 10), button(lista ? 'Na minha lista' : 'Minha lista', lista ? Icons.bookmark : Icons.bookmark_border, () => setState(() => lista = !lista))]),
    ])),
  ])), Padding(padding: const EdgeInsets.symmetric(horizontal: 48), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [label('A história por trás da imagem', size: 19, bold: true), const SizedBox(height: 13),
        label('Direção de Denis Villeneuve. Com Timothée Chalamet,\nZendaya, Rebecca Ferguson e Javier Bardem.', size: 13, color: p.texto2)])),
      Container(width: 330, padding: const EdgeInsets.fromLTRB(20,16,20,16), decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [label('Sua versão', size: 12, bold: true), const SizedBox(height: 9),
          label('4K  ·  HDR  ·  Áudio e legendas', size: 12, color: p.texto2), const SizedBox(height: 10),
          tap(onTap: () => note('Prévia: escolher outra versão.'), child: Row(children: [label('Escolher versão', size: 11), const Spacer(), Icon(Icons.chevron_right, size: 16, color: p.texto2)]))])),
    ]), const SizedBox(height: 33), posters(), const SizedBox(height: 28),
  ]))]);
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: p.fundo, body: Row(children: [if(widget.lateral) sidebar(),
    Expanded(child: Column(children: [topbar(), Expanded(child: AnimatedSwitcher(duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      child: ficha ? KeyedSubtree(key: const ValueKey('ficha'), child: detail()) : KeyedSubtree(key: ValueKey(aba), child: home())))]))]));
}

class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_HoverCard> createState() => _HoverCardState();
}
class _HoverCardState extends State<_HoverCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(onEnter: (_) => setState(() => hover = true), onExit: (_) => setState(() => hover = false),
    cursor: SystemMouseCursors.click, child: AnimatedScale(scale: hover && !MediaQuery.disableAnimationsOf(context) ? 1.025 : 1,
      duration: const Duration(milliseconds: 180), curve: Curves.easeOutCubic,
      child: Toque(forma: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), aoTocar: widget.onTap, child: widget.child)));
}

Widget prototypeApp(String assets, Map<String, ui.Image> images, {bool lateral = false, bool ficha = false}) => MaterialApp(debugShowCheckedModeBanner: false,
  theme: desktopTheme('shikkoku', Brightness.dark), home: CinemaPrototype(assets: assets, images: images, lateral: lateral, ficha: ficha));
