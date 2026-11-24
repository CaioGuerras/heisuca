// Retrospectiva no app (24/11): escolha do ano, textos em pt-BR e os três estados da tela.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/you/cgflix_retrospectiva.dart';
import 'package:heisuca/cgflix/you/cgflix_retrospectiva_screen.dart';

const _tela = Size(420, 900);

/// Mesmo formato que o cgf-retrospectiva --publicar grava.
final _dados2026 = {
  'usuario': 'maria',
  'ano': 2026,
  'ate': '2026-11-24',
  'horas': 1234.56,
  'dias_com_tela': 200,
  'titulos': 42,
  'episodios': 310,
  'filmes': 12,
  'top_series': [
    {'titulo': 'Naruto', 'horas': 80.5, 'episodios': 150, 'id': 'abc'},
    {'titulo': 'Boruto', 'horas': 20, 'episodios': 40, 'id': null},
  ],
  'top_filmes': [
    {'titulo': 'Divertida Mente 2', 'horas': 3.2, 'vezes': 2, 'id': 'f1'},
  ],
  'generos': ['Animação', 'Aventura'],
  'mes_forte': 'jul',
  'dia_da_semana': 'sábado',
  'maratona': {'dia': '2026-07-12', 'horas': 9.4},
};

class _FonteFalsa implements CgflixRetrospectivaFonte {
  _FonteFalsa(this._prefs, {this.falha = false});
  final Map<String, Object?> _prefs;
  bool falha;
  int chamadas = 0;

  @override
  String get nome => 'Maria';

  @override
  Future<Map<String, Object?>> preferencias() async {
    chamadas++;
    if (falha) throw Exception('sem rede');
    return _prefs;
  }

  // Vazio = caixa sem imagem (sem rede no teste).
  @override
  String posterUrl(String itemId) => '';
}

Future<void> _montar(WidgetTester tester, CgflixThemeVariant variante, CgflixRetrospectivaFonte fonte) async {
  tester.view.physicalSize = _tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: cgflixAppTheme(variante),
      home: CgflixRetrospectivaScreen(fonte: fonte),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('escolher: ano mais recente, pula JSON quebrado e chave que não é ano', () {
    final prefs = <String, Object?>{
      '2025': jsonEncode({..._dados2026, 'ano': 2025}),
      '2026': jsonEncode(_dados2026),
      '2027': '{quebrado',
      'tema': 'escuro',
    };
    final d = CgflixRetrospectiva.escolher(prefs)!;
    expect(d.ano, 2026);
    expect(d.topSeries.first.titulo, 'Naruto');
    expect(d.topSeries.first.detalhe, 150);
    expect(d.topSeries[1].id, isNull);
    expect(d.topFilmes.single.detalhe, 2);
    expect(d.maratonaHoras, 9.4);
    expect(CgflixRetrospectiva.escolher(prefs, ano: '2025')!.ano, 2025);
    expect(CgflixRetrospectiva.escolher(const {}), isNull);
    expect(CgflixRetrospectiva.escolher(const {'2026': '{quebrado'}), isNull);
  });

  test('números em pt-BR: ponto no milhar, vírgula com 1 casa', () {
    expect(CgflixRetroTexto.numero(1234), '1.234');
    expect(CgflixRetroTexto.numero(1234567.89), '1.234.567,9');
    expect(CgflixRetroTexto.numero(12.34), '12,3');
    expect(CgflixRetroTexto.numero(5), '5');
    expect(CgflixRetroTexto.numero(0.04), '0');
    expect(CgflixRetroTexto.plural(1, 'dia', 'dias'), '1 dia');
    expect(CgflixRetroTexto.plural(3, 'dia', 'dias'), '3 dias');
    expect(CgflixRetroTexto.data('2026-07-12'), '12/07');
  });

  for (final variante in CgflixThemeVariant.values) {
    final nome = variante.name;

    testWidgets('$nome: retrospectiva com dados', (tester) async {
      await _montar(tester, variante, _FonteFalsa({'2026': jsonEncode(_dados2026)}));
      expect(tester.takeException(), isNull);
      expect(find.text('Maria, seu 2026 no Heisuca'), findsOneWidget);
      expect(find.text('1.234,6'), findsOneWidget);
      expect(find.textContaining('Naruto'), findsWidgets);

      // Controle remoto: a seta para baixo rola a tela.
      final lista = tester.state<ScrollableState>(find.byType(Scrollable).first);
      final antes = lista.position.pixels;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(lista.position.pixels, greaterThan(antes));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nome: retrospectiva ainda não saiu', (tester) async {
      await _montar(tester, variante, _FonteFalsa(const {}));
      expect(tester.takeException(), isNull);
      expect(find.text('Sua retrospectiva ainda não saiu'), findsOneWidget);
    });

    testWidgets('$nome: ano sem horas', (tester) async {
      await _montar(
        tester,
        variante,
        _FonteFalsa({
          '2026': jsonEncode({..._dados2026, 'horas': 0}),
        }),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Ainda não há nada aqui'), findsOneWidget);
    });

    testWidgets('$nome: erro e tentar de novo', (tester) async {
      final fonte = _FonteFalsa({'2026': jsonEncode(_dados2026)}, falha: true);
      await _montar(tester, variante, fonte);
      expect(tester.takeException(), isNull);
      expect(find.text('Não deu para carregar agora'), findsOneWidget);
      fonte.falha = false;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(fonte.chamadas, 2);
      expect(find.text('Maria, seu 2026 no Heisuca'), findsOneWidget);
    });
  }
}
