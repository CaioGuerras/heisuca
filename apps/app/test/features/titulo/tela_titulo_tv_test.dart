import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/features/titulo/modelo.dart';
import 'package:heisuca/features/titulo/tela_titulo_tv.dart';

import '../../design/componentes/apoio.dart';

void main() {
  for (final letra in [1.0, 2.0]) {
    testWidgets('TV 960×540, letra $letra: sinopse ocupa quatro linhas e termina em palavra inteira', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final texto = List.filled(
        30,
        'Dois amigos encontram uma aventura extraordinária quando visitam a cidade.',
      ).join(' ');
      var assistiu = false;
      await tester.pumpWidget(
        naTela(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(letra)),
              child: TelaTituloTv(
                pagina: PaginaDoTitulo(
                  chave: 'filme',
                  titulo: 'Uma aventura',
                  nota: '7,1',
                  anos: '2011',
                  generos: 'Comédia, Ficção científica',
                  detalhes: const ['1h 44min', '1080p'],
                  classificacao: '12',
                  sinopse: texto,
                  aoAssistir: () => assistiu = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final textos = tester.widgetList<Text>(find.byType(Text));
      final sinopse = textos.singleWhere((t) => t.data?.startsWith('Dois amigos') ?? false);
      expect(sinopse.maxLines, 4);
      final visivel = sinopse.data!;
      expect(visivel.endsWith('…'), isTrue);
      final inteiro = visivel.substring(0, visivel.length - 1);
      expect(texto.startsWith(inteiro), isTrue);
      expect(texto[inteiro.length], ' ', reason: 'o corte vem antes do espaço, nunca no meio de uma palavra');
      final elemento = tester.element(find.byWidget(sinopse));
      final pintor = TextPainter(
        text: TextSpan(text: visivel, style: sinopse.style),
        textDirection: Directionality.of(elemento),
        textScaler: MediaQuery.textScalerOf(elemento),
        maxLines: 4,
      )..layout(maxWidth: tester.renderObject<RenderParagraph>(find.byWidget(sinopse)).constraints.maxWidth);
      expect(pintor.didExceedMaxLines, isFalse);
      expect(pintor.computeLineMetrics(), hasLength(4));
      pintor.dispose();
      expect(find.bySemanticsLabel(texto), findsOneWidget, reason: 'a acessibilidade conserva a sinopse completa');
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(assistiu, isTrue, reason: 'Assistir permanece acessível pelo D-pad com a sinopse maior');
      final botao = tester.getRect(find.byKey(const Key('heisuca-tv-title-play')));
      expect(botao.top, greaterThanOrEqualTo(0));
      expect(botao.bottom, lessThanOrEqualTo(540));
      expect(tester.takeException(), isNull);
    });
  }
}
