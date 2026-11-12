import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/tema_da_v2.dart';

void main() {
  group('temaDaPaleta', () {
    test('cada tema do app tem o seu par na V2', () {
      expect(temaDaPaleta(CgflixPalette.isis), TemaHeisuca.shikkoku);
      expect(temaDaPaleta(CgflixPalette.heitor), TemaHeisuca.hisui);
      expect(temaDaPaleta(CgflixPalette.sumi), TemaHeisuca.sumi);
    });

    test('o kids segue o brilho da paleta', () {
      for (final paleta in [
        CgflixPalette.ichigo,
        CgflixPalette.sorairo,
        CgflixPalette.ichigoNoite,
        CgflixPalette.sorairoNoite,
      ]) {
        expect(temaDaPaleta(paleta), paleta.isLight ? TemaHeisuca.hisui : TemaHeisuca.shikkoku);
      }
    });
  });

  test('temaDaV2 guarda as extensões que as telas atuais leem e troca só o tema da V2', () {
    final atual = ThemeData(extensions: const [CgflixPalette.isis, TemaHeisuca.shikkoku]);
    final novo = temaDaV2(atual, TemaHeisuca.hisui);
    expect(novo.extension<CgflixPalette>(), CgflixPalette.isis);
    expect(novo.extension<TemaHeisuca>(), TemaHeisuca.hisui);
    expect(novo.brightness, Brightness.light);
  });

  testWidgets('SobOTemaDaV2 entrega o tema da V2 do tema escolhido no app', (tester) async {
    late TemaHeisuca visto;
    late CgflixPalette paleta;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [CgflixPalette.heitor]),
        home: SobOTemaDaV2(
          child: Builder(
            builder: (context) {
              visto = TemaHeisuca.de(context);
              paleta = context.cgflix;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(visto, TemaHeisuca.hisui);
    expect(paleta, CgflixPalette.heitor);
  });
}
