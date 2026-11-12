import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/design/componentes/pilula_de_perfil.dart';
import 'package:heisuca/features/casca/pilula_do_perfil_ativo.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:provider/provider.dart';

import '../../design/componentes/apoio.dart';

void main() {
  test('primeiroNome fica com a primeira palavra do nome do perfil', () {
    expect(primeiroNome('Isis Guerras'), 'Isis');
    expect(primeiroNome('heitor.silva'), 'heitor');
    expect(primeiroNome('ana_clara-2'), 'ana');
    expect(primeiroNome('  Rosiel  '), 'Rosiel');
    expect(primeiroNome('.oculto'), 'oculto');
    expect(primeiroNome(''), '');
    expect(primeiroNome(null), '');
  });

  testWidgets('sem perfil carregado, mostra o ícone de pessoa, anuncia "Você" e ainda responde ao toque', (
    tester,
  ) async {
    final alca = tester.ensureSemantics();
    var toques = 0;
    await tester.pumpWidget(
      Provider<ActiveProfileProvider?>.value(value: null, child: naTela(PilulaDoPerfilAtivo(aoAbrir: () => toques++))),
    );
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Você'), findsOneWidget);
    await tester.tap(find.byType(PilulaDePerfil));
    expect(toques, 1);
    alca.dispose();
  });

  testWidgets('repassa "sobre a arte" e "só o avatar" à pílula', (tester) async {
    await tester.pumpWidget(
      Provider<ActiveProfileProvider?>.value(
        value: null,
        child: naTela(PilulaDoPerfilAtivo(sobreArte: true, soAvatar: true, aoAbrir: () {})),
      ),
    );
    final pilula = tester.widget<PilulaDePerfil>(find.byType(PilulaDePerfil));
    expect(pilula.sobreArte, isTrue);
    expect(pilula.soAvatar, isTrue);
  });
}
