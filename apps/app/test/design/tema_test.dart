import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/design/tipo.dart';

void main() {
  for (final tema in TemaHeisuca.todos) {
    group(tema.nome, () {
      final material = tema.paraMaterial();

      test('texto, texto secundário e botão principal são legíveis', () {
        for (final base in [tema.fundo, tema.superficie, tema.superficie2]) {
          expect(TemaHeisuca.contraste(tema.texto, base), greaterThanOrEqualTo(4.5));
        }
        expect(TemaHeisuca.contraste(tema.texto2, tema.fundo), greaterThanOrEqualTo(4.5));
        expect(TemaHeisuca.contraste(tema.botaoTexto, tema.botaoFundo), greaterThanOrEqualTo(4.5));
      });

      test('a tinta escolhida sobre acento e erro é a de maior contraste, e passa de 4,5', () {
        for (final base in [tema.acento, tema.erro]) {
          final tinta = tema.sobre(base);
          final outra = tinta == tema.texto ? tema.fundo : tema.texto;
          expect(TemaHeisuca.contraste(tinta, base), greaterThanOrEqualTo(TemaHeisuca.contraste(outra, base)));
          expect(TemaHeisuca.contraste(tinta, base), greaterThanOrEqualTo(4.5));
        }
      });

      test('o Material recebe o tema: brilho, fundo, tinta e extensão', () {
        expect(material.brightness, tema.brilho);
        expect(material.scaffoldBackgroundColor, tema.fundo);
        expect(material.colorScheme.onSurface, tema.texto);
        expect(material.colorScheme.surfaceTint.a, 0, reason: 'superfície não ganha tinta de elevação');
        expect(material.extension<TemaHeisuca>(), same(tema));
        expect(material.textTheme.bodyLarge!.color, tema.texto);
      });

      test('o botão principal é neutro, não da cor do acento', () {
        final estilo = material.filledButtonTheme.style!;
        expect(estilo.backgroundColor!.resolve(<WidgetState>{}), tema.botaoFundo);
        expect(estilo.foregroundColor!.resolve(<WidgetState>{}), tema.botaoTexto);
        expect(tema.botaoFundo, isNot(tema.acento));
      });

      test('tempo e progresso usam algarismos de largura fixa', () {
        expect(Tipo.tempo(tema).fontFeatures, contains(const FontFeature.tabularFigures()));
      });
    });
  }

  test('contraste: preto no branco dá 21 e cor igual dá 1', () {
    const preto = Color.fromARGB(255, 0, 0, 0), branco = Color.fromARGB(255, 255, 255, 255);
    expect(TemaHeisuca.contraste(preto, branco), closeTo(21, 0.001));
    expect(TemaHeisuca.contraste(branco, preto), closeTo(21, 0.001));
    expect(TemaHeisuca.contraste(branco, branco), 1);
  });

  test('a troca de tema começa num tema e termina no outro', () {
    const de = TemaHeisuca.shikkoku, para = TemaHeisuca.hisui;
    expect(de.lerp(para, 0).fundo, de.fundo);
    expect(de.lerp(para, 1).fundo, para.fundo);
    expect(de.lerp(para, 1).brilho, Brightness.light);
    expect(de.lerp(para, 0.49).brilho, Brightness.dark);
    final meio = de.lerp(para, 0.5).fundo;
    expect(meio, isNot(de.fundo));
    expect(meio, isNot(para.fundo));
  });

  testWidgets('a tela lê o tema do contexto; sem tema da V2, vale o Shikkoku', (tester) async {
    late TemaHeisuca lido;
    final leitor = Builder(
      builder: (context) {
        lido = TemaHeisuca.de(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(MaterialApp(theme: TemaHeisuca.hisui.paraMaterial(), home: leitor));
    expect(lido.nome, 'hisui');
    await tester.pumpWidget(MaterialApp(theme: ThemeData(), home: leitor));
    await tester.pumpAndSettle();
    expect(lido.nome, 'shikkoku');
  });
}
