// Refino 1 (1.5.0): telas novas nos dois temas (Isis e Heitor), sem exceção nem overflow.
// Apoie o CGFLIX (QR + botões), Minha conta (conta falsa: foto, senha, 403, falha), menu do
// usuário (ordem, sem conexão, coração rosa), Favoritos (falsos) e o slogan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/apoio/apoio.dart';
import 'package:plezy/cgflix/apoio/apoio_pix.dart';
import 'package:plezy/cgflix/apoio/apoio_pix_view.dart';
import 'package:plezy/cgflix/apoio/cgflix_apoio_screen.dart';
import 'package:plezy/cgflix/cgflix_slogan.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/cgflix_units.dart';
import 'package:plezy/cgflix/cgflix_user_menu.dart';
import 'package:plezy/cgflix/conta/cgflix_conta.dart';
import 'package:plezy/cgflix/conta/cgflix_minha_conta_screen.dart';
import 'package:plezy/cgflix/you/cgflix_favorites_screen.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _tela = Size(412, 914);

Future<void> _montar(WidgetTester tester, CgflixThemeVariant variante, Widget home, {Size tela = _tela}) async {
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(variante), home: home));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Conta falsa no lugar do Jellyfin.
class _ContaFalsa implements CgflixConta {
  _ContaFalsa({this.falhaPerfil = false});
  CgflixSenhaResultado senha = CgflixSenhaResultado.ok;
  bool falhaPerfil;
  String? foto;
  int fotosEnviadas = 0;
  (String, String)? ultimaSenha;

  @override
  Future<CgflixPerfil> perfil() async {
    if (falhaPerfil) throw Exception('sem rede');
    return CgflixPerfil(nome: 'Maria', fotoUrl: foto);
  }

  @override
  Future<void> trocarFoto(Uint8List jpeg) async {
    fotosEnviadas++;
    foto = 'http://127.0.0.1:1/foto.jpg';
  }

  @override
  Future<void> removerFoto() async => foto = null;

  @override
  Future<CgflixSenhaResultado> trocarSenha({required String atual, required String nova}) async {
    ultimaSenha = (atual, nova);
    return senha;
  }
}

Future<void> _preencherSenha(WidgetTester tester, String atual, String nova, String confirmar) async {
  await tester.enterText(find.byKey(const ValueKey('cgflix-conta-senha-atual')), atual);
  await tester.enterText(find.byKey(const ValueKey('cgflix-conta-senha-nova')), nova);
  await tester.enterText(find.byKey(const ValueKey('cgflix-conta-senha-confirmar')), confirmar);
  await tester.ensureVisible(find.byKey(const ValueKey('cgflix-conta-salvar-senha')));
  await tester.tap(find.byKey(const ValueKey('cgflix-conta-salvar-senha')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

final _filme = MediaItem.jellyfin(id: 'f1', kind: MediaKind.movie, title: 'Ainda Estou Aqui', year: 2024);
final _serie = MediaItem.jellyfin(id: 's1', kind: MediaKind.show, title: 'Cidade Invisível', year: 2021);

void main() {
  tearDown(() {
    cgflixUserMenuDebugOnline = null;
    CgflixConta.debugOverride = null;
    CgflixFavoritesSource.debugOverride = null;
    cgflixApoioDebugOverride = null;
    cgflixEscolherFoto = () async => null;
  });

  test('sincronia em segundos (sem "ms" na tela)', () {
    expect(cgflixFormatSyncOffsetSeconds(0), '0 s');
    expect(cgflixFormatSyncOffsetSeconds(150), '+0,15 s');
    expect(cgflixFormatSyncOffsetSeconds(-50), '-0,05 s');
    expect(cgflixFormatSyncOffsetSeconds(1000), '+1 s');
    expect(cgflixFormatSyncOffsetSeconds(-1250), '-1,25 s');
    expect(cgflixFormatSyncOffsetSeconds(15100), '+15,1 s');
  });

  test('nova senha: confere os campos antes do servidor', () {
    expect(cgflixValidarNovaSenha(atual: 'a', nova: '', confirmar: ''), 'Digite a nova senha.');
    expect(cgflixValidarNovaSenha(atual: 'a', nova: 'b', confirmar: 'c'), 'A confirmação não bate com a nova senha.');
    expect(cgflixValidarNovaSenha(atual: 'a', nova: 'a', confirmar: 'a'), 'A nova senha é igual à atual.');
    expect(cgflixValidarNovaSenha(atual: 'a', nova: 'b', confirmar: 'b'), isNull);
  });

  for (final variante in CgflixThemeVariant.values) {
    final nome = variante.name;

    testWidgets('$nome: Apoie o CGFLIX (QR com o BR Code, copiar)', (tester) async {
      final copiado = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copiado.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final semantics = tester.ensureSemantics();
      await _montar(tester, variante, const CgflixApoioScreen());
      expect(tester.takeException(), isNull);
      expect(find.text(cgflixApoioTitulo), findsOneWidget);
      expect(find.text(cgflixApoioTexto), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('QR Code do Pix')), findsOneWidget);
      semantics.dispose();
      // Coração rosa nos dois temas (o primeiro ícone do corpo).
      final coracao = find.descendant(of: find.byType(ListView), matching: find.byType(Icon)).first;
      expect(tester.widget<Icon>(coracao).color, cgflixApoioRosa);

      await tester.tap(find.byKey(const ValueKey('cgflix-apoio-copiaecola')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('cgflix-apoio-chave')));
      await tester.tap(find.byKey(const ValueKey('cgflix-apoio-chave')));
      await tester.pump(const Duration(seconds: 1));
      expect(copiado, [cgflixPixCopiaECola, ApoioPix.chave]);
    });

    testWidgets('$nome: Minha conta mostra a pessoa e troca a foto', (tester) async {
      final conta = _ContaFalsa();
      cgflixEscolherFoto = () async => Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      await _montar(tester, variante, CgflixMinhaContaScreen(conta: conta));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Remover foto'), findsNothing);
      expect(
        find.text(
          'A senha vale para o app, o site e a TV. Depois da troca, os outros aparelhos pedem para entrar de novo.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('cgflix-conta-trocar-foto')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(conta.fotosEnviadas, 1);
      expect(find.text('Foto atualizada.'), findsOneWidget);
      expect(find.text('Remover foto'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cgflix-conta-remover-foto')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(conta.foto, isNull);
      expect(find.text('Remover foto'), findsNothing);
    });

    testWidgets('$nome: Minha conta troca a senha e avisa a senha errada', (tester) async {
      final conta = _ContaFalsa();
      await _montar(tester, variante, CgflixMinhaContaScreen(conta: conta));
      await tester.pump();

      await _preencherSenha(tester, 'velha', 'nova', 'outra');
      expect(find.text('A confirmação não bate com a nova senha.'), findsOneWidget);
      expect(conta.ultimaSenha, isNull);

      conta.senha = CgflixSenhaResultado.senhaAtualErrada;
      await _preencherSenha(tester, 'velha', 'nova', 'nova');
      expect(conta.ultimaSenha, ('velha', 'nova'));
      expect(find.textContaining('Senha atual errada'), findsOneWidget);
      expect(find.textContaining('a conta é bloqueada'), findsOneWidget);

      conta.senha = CgflixSenhaResultado.ok;
      await _preencherSenha(tester, 'velha', 'nova', 'nova');
      expect(find.textContaining('Senha trocada'), findsOneWidget);
      expect(find.textContaining('Aqui você continua conectado'), findsOneWidget);
      expect(find.textContaining('Senha atual errada'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nome: Minha conta sem servidor mostra aviso e Tentar de novo', (tester) async {
      final conta = _ContaFalsa(falhaPerfil: true);
      await _montar(tester, variante, CgflixMinhaContaScreen(conta: conta));
      await tester.pump();
      expect(find.textContaining('Sem conexão com o servidor agora'), findsOneWidget);
      conta.falhaPerfil = false;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Maria'), findsOneWidget);
    });

    testWidgets('$nome: menu do usuário conectado ao Jellyfin', (tester) async {
      cgflixUserMenuDebugOnline = true;
      CgflixConta.debugOverride = _ContaFalsa();
      CgflixFavoritesSource.debugOverride = CgflixFavoritesSource(load: () async => [_filme]);
      await _montar(tester, variante, const Scaffold(body: CgflixUserMenuSheet()));
      expect(tester.takeException(), isNull);
      expect(find.text('Minha conta: foto e senha'), findsOneWidget);
      final ordem = [
        for (final e
            in find
                .byWidgetPredicate(
                  (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('cgflix-menu-'),
                )
                .evaluate())
          (e.widget.key! as ValueKey<String>).value,
      ];
      expect(ordem, [
        'cgflix-menu-account',
        'cgflix-menu-favorites',
        'cgflix-menu-downloads',
        'cgflix-menu-myRequests',
        'cgflix-menu-libraries',
        'cgflix-menu-settings',
        'cgflix-menu-about',
        'cgflix-menu-switchUser',
        'cgflix-menu-signOut',
        'cgflix-menu-support',
      ]);
      // Refino 2: três traços (depois de Bibliotecas, de Sobre e de Sair) e dois cabeçalhos curtos.
      expect(find.byType(Divider), findsNWidgets(3));
      expect(find.text('Ajustes e ajuda'), findsOneWidget);
      expect(find.text('Conta'), findsOneWidget);
      expect(find.text('Sobre e dicas'), findsOneWidget);
      final apoio = find.descendant(of: find.byKey(const ValueKey('cgflix-menu-support')), matching: find.byType(Icon));
      expect(tester.widget<Icon>(apoio).color, cgflixApoioRosa);
      final outro = find.descendant(
        of: find.byKey(const ValueKey('cgflix-menu-settings')),
        matching: find.byType(Icon),
      );
      expect(tester.widget<Icon>(outro).color, CgflixPalette.forVariant(variante).accentSoft);
    });

    testWidgets('$nome: menu do usuário sem conexão esconde o que depende do servidor', (tester) async {
      cgflixUserMenuDebugOnline = false;
      CgflixConta.debugOverride = _ContaFalsa();
      await _montar(tester, variante, const Scaffold(body: CgflixUserMenuSheet()));
      expect(find.text('Minha conta: foto e senha'), findsNothing);
      expect(find.byKey(const ValueKey('cgflix-menu-account')), findsNothing);
      for (final fora in ['favorites', 'libraries', 'myRequests']) {
        expect(find.byKey(ValueKey('cgflix-menu-$fora')), findsNothing, reason: fora);
      }
      for (final fica in ['downloads', 'settings', 'switchUser', 'about', 'signOut', 'support']) {
        expect(find.byKey(ValueKey('cgflix-menu-$fica')), findsOneWidget, reason: fica);
      }
      // Sem conexão, o primeiro traço vem logo depois de Baixados (refino 2).
      expect(find.byType(Divider), findsNWidgets(3));
    });

    testWidgets('$nome: menu cabe deitado', (tester) async {
      cgflixUserMenuDebugOnline = true;
      CgflixConta.debugOverride = _ContaFalsa();
      CgflixFavoritesSource.debugOverride = CgflixFavoritesSource(load: () async => const []);
      await _montar(tester, variante, const Scaffold(body: CgflixUserMenuSheet()), tela: const Size(914, 412));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nome: Favoritos em grade e vazio', (tester) async {
      await _montar(
        tester,
        variante,
        CgflixFavoritesScreen(source: CgflixFavoritesSource(load: () async => [_filme, _serie])),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Ainda Estou Aqui'), findsOneWidget);
      expect(find.bySemanticsLabel('Cidade Invisível'), findsOneWidget);

      await tester.pumpWidget(const SizedBox()); // o MaterialApp guardaria a rota anterior
      await _montar(tester, variante, CgflixFavoritesScreen(source: CgflixFavoritesSource(load: () async => const [])));
      await tester.pump();
      expect(find.text('Nenhum favorito ainda'), findsOneWidget);
    });

    testWidgets('$nome: slogan aparece parado com "remover animações"', (tester) async {
      tester.view.physicalSize = _tela;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: cgflixAppTheme(variante),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: CgflixSlogan(delay: cgflixSloganDelay)),
          ),
        ),
      );
      expect(find.text('Aperte o play'), findsOneWidget);
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
      final texto = tester.widget<Text>(find.text('Aperte o play'));
      expect(texto.style?.color, CgflixPalette.forVariant(variante).textMuted);
    });
  }

  testWidgets('sem apoio no pacote (Play), o item some do menu', (tester) async {
    cgflixApoioDebugOverride = const _SemApoioTeste();
    cgflixUserMenuDebugOnline = false;
    await _montar(tester, CgflixThemeVariant.isis, const Scaffold(body: CgflixUserMenuSheet()));
    expect(find.byKey(const ValueKey('cgflix-menu-support')), findsNothing);
  });
}

class _SemApoioTeste implements Apoio {
  const _SemApoioTeste();
  @override
  bool get disponivel => false;
  @override
  Widget conteudo(BuildContext context) => const SizedBox.shrink();
}
