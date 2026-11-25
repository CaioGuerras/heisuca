import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/design/forma.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/features/player_tv/barra_do_player_tv.dart';

import 'apoio.dart';

/// Monta a barra com quatro botões de transporte e três pílulas; devolve os nós de foco na ordem.
class _Barra {
  _Barra({bool semProximo = false}) {
    transporte = [
      ItemDaBarraTv(
        foco: voltar,
        rotulo: 'Voltar 10 segundos',
        icone: Icons.replay_10,
        aoTocar: () => tocados.add('v'),
      ),
      ItemDaBarraTv(foco: tocar, rotulo: 'Pausar', icone: Icons.pause, aoTocar: () => tocados.add('t')),
      ItemDaBarraTv(
        foco: avancar,
        rotulo: 'Avançar 10 segundos',
        icone: Icons.forward_10,
        aoTocar: () => tocados.add('a'),
      ),
      ItemDaBarraTv(
        foco: proximo,
        rotulo: 'Próximo episódio',
        icone: Icons.skip_next,
        aoTocar: semProximo ? null : () => tocados.add('p'),
      ),
    ];
    faixas = [
      ItemDaBarraTv(
        foco: audio,
        rotulo: 'Áudio',
        texto: 'Áudio · Português (AAC 2.0)',
        aoTocar: () => tocados.add('au'),
      ),
      ItemDaBarraTv(foco: legenda, rotulo: 'Legenda', texto: 'Legenda · Desligada', aoTocar: () => tocados.add('le')),
      ItemDaBarraTv(foco: episodios, rotulo: 'Episódios', texto: 'Episódios', aoTocar: () => tocados.add('ep')),
    ];
  }

  final voltar = FocusNode(debugLabel: 'voltar');
  final tocar = FocusNode(debugLabel: 'tocar');
  final avancar = FocusNode(debugLabel: 'avancar');
  final proximo = FocusNode(debugLabel: 'proximo');
  final audio = FocusNode(debugLabel: 'audio');
  final legenda = FocusNode(debugLabel: 'legenda');
  final episodios = FocusNode(debugLabel: 'episodios');
  final tocados = <String>[];
  var subidas = 0;
  var mexidas = 0;
  late final List<ItemDaBarraTv> transporte;
  late final List<ItemDaBarraTv> faixas;

  Widget widget({double largura = 1280}) => SizedBox(
    width: largura,
    child: BarraDoPlayerTv(transporte: transporte, faixas: faixas, aoSubir: () => subidas++, aoMexer: () => mexidas++),
  );

  void descartar() {
    for (final n in [voltar, tocar, avancar, proximo, audio, legenda, episodios]) {
      n.dispose();
    }
  }
}

Future<void> _tecla(WidgetTester tester, LogicalKeyboardKey tecla) async {
  await tester.sendKeyEvent(tecla);
  await tester.pumpAndSettle();
}

void main() {
  for (final letra in [1.0, 2.0]) {
    testWidgets('960×540, letra $letra: D-pad reserva anel e crescimento com o mesmo vão entre controles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final barra = _Barra();
      addTearDown(barra.descartar);
      final transporte = barra.transporte.take(3).toList();
      final faixas = [
        ItemDaBarraTv(
          foco: barra.audio,
          rotulo: 'Áudio',
          iconeDaPilula: Icons.volume_up,
          texto: 'Português',
          textoCompacto: 'PT',
          aoTocar: () {},
        ),
        ItemDaBarraTv(
          foco: barra.legenda,
          rotulo: 'Legenda',
          iconeDaPilula: Icons.subtitles,
          texto: 'Português · forçada',
          textoCompacto: 'PT · forç.',
          aoTocar: () {},
        ),
        ItemDaBarraTv(
          foco: barra.episodios,
          rotulo: 'Episódios',
          iconeDaPilula: Icons.list,
          texto: 'Capítulos',
          textoCompacto: 'Cap.',
          aoTocar: () {},
        ),
      ];
      await tester.pumpWidget(
        naTela(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
              child: Padding(
                padding: Forma.margemSeguraTv,
                child: BarraDoPlayerTv(transporte: transporte, faixas: faixas),
              ),
            ),
          ),
        ),
      );
      for (final texto in tester.widgetList<Text>(find.byType(Text))) {
        expect(texto.overflow, isNot(TextOverflow.ellipsis));
      }
      final caminho = [...transporte, ...faixas];
      barra.voltar.requestFocus();
      await tester.pumpAndSettle();
      final envelopes = <Rect>[];
      for (final item in caminho) {
        expect(item.foco.hasFocus, isTrue, reason: 'D-pad alcança ${item.rotulo}');
        final toque = find.ancestor(of: find.bySemanticsLabel(item.rotulo), matching: find.byType(AnimatedScale)).first;
        final escala = tester.widget<AnimatedScale>(toque).scale;
        envelopes.add(tester.getRect(find.bySemanticsLabel(item.rotulo)).inflate(Forma.anelDeFoco * escala));
        await _tecla(tester, LogicalKeyboardKey.arrowRight);
      }
      for (var i = 0; i < envelopes.length; i++) {
        final atual = envelopes[i];
        expect(atual.left, greaterThanOrEqualTo(Forma.margemSeguraTv.left - 0.01));
        expect(atual.right, lessThanOrEqualTo(960 - Forma.margemSeguraTv.right + 0.01));
        if (i == 0) continue;
        final anterior = envelopes[i - 1];
        expect(atual.center.dy, closeTo(anterior.center.dy, 0.01), reason: 'uma única linha');
        if ((atual.center.dy - anterior.center.dy).abs() < 1) {
          expect(
            atual.left - anterior.right,
            closeTo(Forma.espaco3, 0.01),
            reason: '${caminho[i - 1].rotulo} → ${caminho[i].rotulo}: anéis com o mesmo respiro',
          );
        } else {
          expect(atual.top - anterior.bottom, greaterThanOrEqualTo(Forma.espaco3 - 0.01));
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('960×540, letra $letra: texto da pílula centralizado no botão', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final barra = _Barra();
      addTearDown(barra.descartar);
      await tester.pumpWidget(
        naTela(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
              child: barra.widget(largura: 864),
            ),
          ),
        ),
      );
      final texto = find.text('Episódios');
      final paragrafo = tester.renderObject<RenderParagraph>(texto);
      final caixas = paragrafo.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 9));
      final tinta = caixas.map((caixa) => caixa.toRect()).reduce((a, b) => a.expandToInclude(b));
      final centroDaTinta = paragrafo.localToGlobal(tinta.center).dy;
      final toque = find.ancestor(of: texto, matching: find.byType(Toque)).first;
      expect(centroDaTinta, closeTo(tester.getCenter(toque).dy, 1));
      expect(tester.takeException(), isNull);
    });
  }

  for (final tema in [...TemaHeisuca.todos, ...TemaHeisuca.doKids]) {
    testWidgets('${tema.nome}: sobre o vídeo vale sempre o tema escuro', (tester) async {
      final barra = _Barra();
      addTearDown(barra.descartar);
      await tester.pumpWidget(naTela(tema: tema, barra.widget()));
      barra.audio.requestFocus();
      await tester.pumpAndSettle();
      const escuro = TemaHeisuca.shikkoku;
      final texto = tester.widget<Text>(find.text('Áudio · Português (AAC 2.0)'));
      expect(texto.style!.color, escuro.botaoTexto, reason: 'com foco, o conteúdo usa a tinta do botão');
      final solto = tester.widget<Text>(find.text('Episódios'));
      expect(solto.style!.color, escuro.texto);
    });
  }

  testWidgets('todo botão tem pelo menos 48 de toque e o toque aciona', (tester) async {
    final barra = _Barra();
    addTearDown(barra.descartar);
    await tester.pumpWidget(naTela(barra.widget()));
    for (final rotulo in ['Voltar 10 segundos', 'Pausar', 'Próximo episódio', 'Áudio', 'Episódios']) {
      final achado = find.bySemanticsLabel(rotulo);
      final tamanho = tester.getSize(achado);
      expect(tamanho.width, greaterThanOrEqualTo(48), reason: rotulo);
      expect(tamanho.height, greaterThanOrEqualTo(48), reason: rotulo);
    }
    await tester.tap(find.bySemanticsLabel('Pausar'));
    await tester.pumpAndSettle();
    expect(barra.tocados, ['t']);
  });

  testWidgets('← e → passam pelas duas metades num caminho só; nas pontas a tecla não vaza', (tester) async {
    final barra = _Barra();
    addTearDown(barra.descartar);
    var vazou = 0;
    await tester.pumpWidget(
      naTela(
        Focus(
          onKeyEvent: (_, _) {
            vazou++;
            return KeyEventResult.ignored;
          },
          child: barra.widget(),
        ),
      ),
    );
    barra.tocar.requestFocus();
    await tester.pumpAndSettle();

    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    expect(barra.avancar.hasFocus, isTrue);
    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    expect(barra.audio.hasFocus, isTrue, reason: 'do transporte para as faixas sem parar');
    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    expect(barra.episodios.hasFocus, isTrue);
    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    expect(barra.episodios.hasFocus, isTrue, reason: 'na ponta direita o foco fica');

    for (var i = 0; i < 6; i++) {
      await _tecla(tester, LogicalKeyboardKey.arrowLeft);
    }
    expect(barra.voltar.hasFocus, isTrue);
    await _tecla(tester, LogicalKeyboardKey.arrowLeft);
    expect(barra.voltar.hasFocus, isTrue, reason: 'na ponta esquerda o foco fica');
    expect(vazou, 0, reason: '← e → nunca chegam ao player (que avançaria o vídeo)');
    expect(barra.mexidas, greaterThan(0));
  });

  testWidgets('botão sem ação fica fora do caminho', (tester) async {
    final barra = _Barra(semProximo: true);
    addTearDown(barra.descartar);
    await tester.pumpWidget(naTela(barra.widget()));
    barra.avancar.requestFocus();
    await tester.pumpAndSettle();
    await _tecla(tester, LogicalKeyboardKey.arrowRight);
    expect(barra.proximo.hasFocus, isFalse);
    expect(barra.audio.hasFocus, isTrue);
  });

  testWidgets('OK e Enter acionam o botão com foco; ↑ sobe para a linha do tempo', (tester) async {
    final barra = _Barra();
    addTearDown(barra.descartar);
    await tester.pumpWidget(naTela(barra.widget()));
    barra.legenda.requestFocus();
    await tester.pumpAndSettle();
    await _tecla(tester, LogicalKeyboardKey.select);
    await _tecla(tester, LogicalKeyboardKey.enter);
    expect(barra.tocados, ['le', 'le']);
    await _tecla(tester, LogicalKeyboardKey.arrowUp);
    expect(barra.subidas, 1);
  });

  testWidgets('o leitor de tela lê o nome de cada botão como botão', (tester) async {
    final alca = tester.ensureSemantics();
    final barra = _Barra();
    addTearDown(barra.descartar);
    await tester.pumpWidget(naTela(barra.widget()));
    for (final rotulo in ['Voltar 10 segundos', 'Pausar', 'Avançar 10 segundos', 'Áudio', 'Legenda', 'Episódios']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(rotulo)),
        containsSemantics(label: rotulo, isButton: true, hasTapAction: true, isEnabled: true),
        reason: rotulo,
      );
    }
    alca.dispose();
  });

  testWidgets('letra 200 % numa tela estreita: barra continua em uma linha', (tester) async {
    final barra = _Barra();
    addTearDown(barra.descartar);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: naTela(barra.widget(largura: 600)),
      ),
    );
    expect(tester.takeException(), isNull);
    final topoTransporte = tester.getTopLeft(find.bySemanticsLabel('Pausar')).dy;
    final topoFaixas = tester.getTopLeft(find.bySemanticsLabel('Episódios')).dy;
    expect(topoFaixas, closeTo(topoTransporte, 20), reason: 'sem quebra de linha');
  });

  testWidgets('o botão com foco cresce; com "remover animações" não cresce, só muda de cor', (tester) async {
    for (final semAnimacao in [false, true]) {
      final barra = _Barra();
      await tester.pumpWidget(naTela(semAnimacao: semAnimacao, barra.widget()));
      barra.tocar.requestFocus();
      await tester.pumpAndSettle();
      final escala = tester.widget<AnimatedScale>(
        find.ancestor(of: find.bySemanticsLabel('Pausar'), matching: find.byType(AnimatedScale)).first,
      );
      expect(escala.scale, semAnimacao ? 1 : greaterThan(1), reason: 'semAnimacao=$semAnimacao');
      await tester.pumpWidget(const SizedBox());
      barra.descartar();
    }
  });
}
