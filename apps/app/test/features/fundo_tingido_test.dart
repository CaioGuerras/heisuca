import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/cor_poster/cor_poster_cache.dart';
import 'package:heisuca/design/cor_poster/paleta_poster.dart';
import 'package:heisuca/design/cor_poster/temas_cor_poster.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/fundo_tingido.dart';

import '../design/componentes/apoio.dart';

const _sonda = Key('sonda');

class _Sonda extends StatelessWidget {
  const _Sonda();
  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    return ColoredBox(
      key: _sonda,
      color: tema.superficie,
      child: Text('texto', style: TextStyle(color: tema.texto)),
    );
  }
}

Color _superficie(WidgetTester tester) => tester.widget<ColoredBox>(find.byKey(_sonda)).color;

Future<void> _esperarCor(WidgetTester tester, CorPosterCache cores, String hash, PapelDoTema papel) async {
  // A conta roda em outra thread: o relógio de verdade anda um pouco e a tela recebe o aviso no quadro seguinte.
  for (var volta = 0; volta < 200 && cores.ler(hash, papel) == null; volta++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  final hashes = [
    for (final item in (jsonDecode(File('test/fixtures/cor_poster/blurhash_200.json').readAsStringSync()) as List))
      (item as Map<String, dynamic>)['primary'] as String,
  ];

  for (final tema in TemaHeisuca.todos) {
    testWidgets('${tema.nome}: sem pôster vale a superfície neutra; com pôster, a cor dele, e o texto não muda', (
      tester,
    ) async {
      final cores = CorPosterCache();
      final papel = TemasCorPoster.de(tema.nome);
      final neutra = Color(PaletaPoster.neutra(papel).superficie);

      await tester.pumpWidget(
        naTela(
          tema: tema,
          FundoTingido(hash: null, cores: cores, child: const _Sonda()),
        ),
      );
      await tester.pumpAndSettle();
      expect(_superficie(tester), neutra);

      await tester.pumpWidget(
        naTela(
          tema: tema,
          FundoTingido(hash: hashes[0], cores: cores, child: const _Sonda()),
        ),
      );
      await _esperarCor(tester, cores, hashes[0], papel);
      final paleta = cores.ler(hashes[0], papel);
      expect(paleta, isNotNull);
      expect(_superficie(tester), Color(paleta!.superficie));
      expect(_superficie(tester), isNot(neutra));
      expect(tester.widget<Text>(find.text('texto')).style!.color, tema.texto);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('trocar de pôster troca a cor; a cor preparada antes já está pronta na troca', (tester) async {
    final cores = CorPosterCache();
    final papel = TemasCorPoster.shikkoku;
    await tester.pumpWidget(
      naTela(FundoTingido(hash: hashes[0], preparar: [hashes[1]], cores: cores, child: const _Sonda())),
    );
    await _esperarCor(tester, cores, hashes[0], papel);
    await _esperarCor(tester, cores, hashes[1], papel);
    final primeira = _superficie(tester);

    await tester.pumpWidget(naTela(FundoTingido(hash: hashes[1], cores: cores, child: const _Sonda())));
    await tester.pumpAndSettle();
    expect(_superficie(tester), Color(cores.ler(hashes[1], papel)!.superficie));
    expect(_superficie(tester), isNot(primeira));
  });

  testWidgets('"remover animações": a cor troca sem animação pendente', (tester) async {
    final cores = CorPosterCache();
    await tester.pumpWidget(
      naTela(semAnimacao: true, FundoTingido(hash: hashes[0], cores: cores, child: const _Sonda())),
    );
    await _esperarCor(tester, cores, hashes[0], TemasCorPoster.shikkoku);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
