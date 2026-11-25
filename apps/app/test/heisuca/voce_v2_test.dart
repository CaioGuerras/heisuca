import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/apoio/apoio.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/cgflix/cgflix_user_menu.dart' show cgflixUserMenuDebugOnline;
import 'package:heisuca/cgflix/conta/cgflix_conta.dart';
import 'package:heisuca/design/componentes/toque.dart';
import 'package:heisuca/design/forma.dart';
import 'package:heisuca/design/tema.dart';
import 'package:heisuca/features/voce/ligacao.dart';
import 'package:heisuca/features/voce/tela_voce.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids.dart';
import 'package:heisuca/profiles/active_profile_provider.dart';
import 'package:heisuca/profiles/profile.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/services/updates/pagina_na_loja.dart';
import 'package:heisuca/services/updates/update_controller.dart';
import 'package:heisuca/services/updates/update_feed_client.dart' show OfertaAtualizacao;
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

class _Perfis extends ChangeNotifier implements ActiveProfileProvider {
  _Perfis(this._ativo);
  final Profile _ativo;
  @override
  Profile? get active => _ativo;
  @override
  String? get activeId => _ativo.id;
  @override
  List<Profile> get profiles => [_ativo];
  @override
  String? avatarUrlFor(String profileId) => null;
  @override
  bool get isBinding => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cliente implements MediaServerClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gerenciador implements MultiServerManager {
  bool online = true;
  final _cliente = _Cliente();
  @override
  Map<String, MediaServerClient> get visibleOnlineClients => online ? {'teste': _cliente} : {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servidores extends ChangeNotifier implements MultiServerProvider {
  @override
  final _Gerenciador serverManager = _Gerenciador();
  void mudarConexao(bool online) {
    serverManager.online = online;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Kids extends ChangeNotifier implements HeisucaKids {
  HeisucaKidsRecord? registro;
  void criarPerfil() {
    registro = _registro;
    notifyListeners();
  }

  @override
  HeisucaKidsRecord? forParent(String? id) => registro?.parentProfileId == id ? registro : null;
  @override
  bool isKids(String? id) => registro != null && registro!.kidsProfileId == id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Atualizacoes extends ChangeNotifier implements UpdateController {
  _Atualizacoes({this.loja = false});
  final bool loja;
  @override
  bool get permiteAjustes => !loja;
  @override
  bool get pelaLoja => loja;
  @override
  OfertaAtualizacao? get oferta => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conta implements CgflixConta {
  @override
  Future<CgflixPerfil> perfil() async => const CgflixPerfil(nome: 'Ana');
  @override
  Future<void> trocarFoto(Uint8List jpeg) async {}
  @override
  Future<void> removerFoto() async {}
  @override
  Future<CgflixSenhaResultado> trocarSenha({required String atual, required String nova}) async =>
      CgflixSenhaResultado.ok;
}

class _Apoio implements Apoio {
  const _Apoio({this.disponivel = true});
  @override
  final bool disponivel;
  @override
  Widget conteudo(BuildContext context) => const SizedBox.shrink();
}

final _agora = DateTime(2026, 11, 15);
final _pai = Profile.local(id: 'pai', displayName: 'Ana', createdAt: _agora);
final _filho = Profile.local(id: 'kids-1', displayName: 'Ana', createdAt: _agora);
final _registro = HeisucaKidsRecord(
  parentProfileId: 'pai',
  kidsProfileId: 'kids-1',
  variant: CgflixThemeVariant.ichigo,
  ceiling: 'livre',
  pinHash: computePinHash('2468'),
  name: 'Ana',
);

/// Conta as vezes que cada ação foi chamada.
class _Chamadas {
  final Map<String, int> vezes = {};
  bool confirma = true;

  void registrar(String nome) => vezes[nome] = (vezes[nome] ?? 0) + 1;
  int de(String nome) => vezes[nome] ?? 0;

  AcoesDaVoce get acoes => AcoesDaVoce(
    minhaConta: (_) => registrar('minhaConta'),
    meusPedidos: (_) => registrar('meusPedidos'),
    perfis: (_, id) => registrar('perfis:$id'),
    modoInfantil: (_) => registrar('modoInfantil'),
    perfilInfantil: (_, r) => registrar('perfilInfantil:${r.name}'),
    sairDoModoInfantil: (_) => registrar('sairDoModoInfantil'),
    configuracoes: (_) => registrar('configuracoes'),
    atualizacoes: (_) => registrar('atualizacoes'),
    atualizacoesNaLoja: (_) => registrar('atualizacoesNaLoja'),
    sobre: (_) => registrar('sobre'),
    trocarUsuario: (_) => registrar('trocarUsuario'),
    servidores: (_) => registrar('servidores'),
    confirmarSaida: (_) async {
      registrar('confirmarSaida');
      return confirma;
    },
    sair: (_) async => registrar('sair'),
    apoie: (_) => registrar('apoie'),
  );
}

const _temas = <(String, TemaHeisuca, CgflixPalette)>[
  ('shikkoku', TemaHeisuca.shikkoku, CgflixPalette.isis),
  ('hisui', TemaHeisuca.hisui, CgflixPalette.heitor),
  ('sumi', TemaHeisuca.sumi, CgflixPalette.sumi),
];

Future<void> _montar(
  WidgetTester tester,
  _Chamadas chamadas, {
  TemaHeisuca tema = TemaHeisuca.shikkoku,
  CgflixPalette paleta = CgflixPalette.isis,
  Profile? ativo,
  double letra = 1,
  bool semAnimacao = false,
  bool comAtualizacoes = true,
  bool daLoja = false,
  bool empilhada = false,
  bool comKids = true,
  HeisucaKids? kids,
  _Servidores? servidores,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final perfis = _Perfis(ativo ?? _pai);
  addTearDown(perfis.dispose);
  final atualizacoes = _Atualizacoes(loja: daLoja);
  addTearDown(atualizacoes.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: perfis),
        if (comKids) ChangeNotifierProvider<HeisucaKids>.value(value: kids ?? HeisucaKids.instance),
        if (servidores != null) ChangeNotifierProvider<MultiServerProvider>.value(value: servidores),
        if (comAtualizacoes) ChangeNotifierProvider<UpdateController>.value(value: atualizacoes),
      ],
      child: MaterialApp(
        theme: tema.paraMaterial().copyWith(extensions: [paleta, tema]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: semAnimacao, textScaler: TextScaler.linear(letra)),
          child: child!,
        ),
        home: LigacaoDaVoce(acoes: chamadas.acoes),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (empilhada) {
    unawaited(
      Navigator.of(
        tester.element(find.byType(LigacaoDaVoce)),
      ).push(MaterialPageRoute<void>(builder: (_) => LigacaoDaVoce(acoes: chamadas.acoes))),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _mostrar(WidgetTester tester, String titulo) async {
  await tester.scrollUntilVisible(find.text(titulo), 180, scrollable: find.byType(Scrollable));
  await tester.pumpAndSettle();
}

Finder _cartao(String titulo) => find.ancestor(of: find.text(titulo), matching: find.byType(Toque));

void main() {
  late _Chamadas chamadas;

  setUp(() async {
    resetSharedPreferencesForTest();
    HeisucaKids.instance.debugReset();
    chamadas = _Chamadas();
    cgflixUserMenuDebugOnline = true;
    CgflixConta.debugOverride = _Conta();
    cgflixApoioDebugOverride = const _Apoio();
  });

  tearDown(() {
    cgflixUserMenuDebugOnline = null;
    CgflixConta.debugOverride = null;
    cgflixApoioDebugOverride = null;
    HeisucaKids.instance.debugReset();
  });

  group('cada cartão chama a sua ação', () {
    for (final (nome, tema, paleta) in _temas) {
      testWidgets('no tema $nome', (tester) async {
        await _montar(tester, chamadas, tema: tema, paleta: paleta);

        const esperado = <String, String>{
          'Minha conta': 'minhaConta',
          'Meus pedidos': 'meusPedidos',
          'Trocar usuário': 'trocarUsuario',
          'Servidores': 'servidores',
          'Perfis e PIN': 'perfis:pai',
          'Modo infantil': 'modoInfantil',
          'Configurações': 'configuracoes',
          'Atualizações': 'atualizacoes',
          'Sobre o Heisuca': 'sobre',
          'Apoie': 'apoie',
        };
        for (final MapEntry(key: titulo, value: acao) in esperado.entries) {
          await _mostrar(tester, titulo);
          expect(_cartao(titulo), findsOneWidget, reason: titulo);
          await tester.tap(_cartao(titulo));
          await tester.pump();
          expect(chamadas.de(acao), 1, reason: '$titulo deveria chamar $acao');
        }
      });
    }
  });

  group('sair', () {
    testWidgets('pede confirmação e só sai com o "sim"', (tester) async {
      await _montar(tester, chamadas);
      await _mostrar(tester, 'Sair');
      await tester.tap(_cartao('Sair'));
      await tester.pumpAndSettle();
      expect(chamadas.de('confirmarSaida'), 1);
      expect(chamadas.de('sair'), 1);
    });

    testWidgets('não sai quando a pessoa desiste', (tester) async {
      chamadas.confirma = false;
      await _montar(tester, chamadas);
      await _mostrar(tester, 'Sair');
      await tester.tap(_cartao('Sair'));
      await tester.pumpAndSettle();
      expect(chamadas.de('confirmarSaida'), 1);
      expect(chamadas.de('sair'), 0);
    });
  });

  group('o que aparece', () {
    testWidgets('servidor cai e volta com a tela aberta', (tester) async {
      cgflixUserMenuDebugOnline = null;
      final servidores = _Servidores();
      addTearDown(servidores.dispose);
      await _montar(tester, chamadas, servidores: servidores);
      expect(find.text('Minha conta'), findsOneWidget);
      servidores.mudarConexao(false);
      await tester.pumpAndSettle();
      expect(find.text('Minha conta'), findsNothing);
      expect(find.text('Meus pedidos'), findsNothing);
      servidores.mudarConexao(true);
      await tester.pumpAndSettle();
      expect(find.text('Minha conta'), findsOneWidget);
      expect(find.text('Meus pedidos'), findsOneWidget);
    });

    testWidgets('sem provider de servidor os cartões de conta ficam ocultos', (tester) async {
      cgflixUserMenuDebugOnline = null;
      await _montar(tester, chamadas);
      expect(find.text('Minha conta'), findsNothing);
      expect(find.text('Meus pedidos'), findsNothing);
    });

    testWidgets('perfil infantil criado com a tela aberta aparece', (tester) async {
      final kids = _Kids();
      addTearDown(kids.dispose);
      await _montar(tester, chamadas, kids: kids);
      expect(find.text('Perfil infantil'), findsNothing);
      kids.criarPerfil();
      await tester.pumpAndSettle();
      await _mostrar(tester, 'Perfil infantil');
      expect(find.text('Entrar no perfil Ana'), findsOneWidget);
      expect(find.text('Ana: nome, foto, tema e PIN'), findsOneWidget);
      await tester.tap(_cartao('Perfil infantil'));
      expect(chamadas.de('perfilInfantil:Ana'), 1);
    });

    testWidgets('salvar perfil infantil no aparelho atualiza a tela aberta', (tester) async {
      await _montar(tester, chamadas);
      expect(find.text('Perfil infantil'), findsNothing);
      await HeisucaKids.instance.save(_registro);
      await tester.pumpAndSettle();
      await _mostrar(tester, 'Perfil infantil');
      expect(find.text('Perfil infantil'), findsOneWidget);
      expect(find.text('Entrar no perfil Ana'), findsOneWidget);
    });

    testWidgets('sem provider infantil usa o registro do aparelho', (tester) async {
      await HeisucaKids.instance.save(_registro);
      await _montar(tester, chamadas, comKids: false);
      await _mostrar(tester, 'Perfil infantil');
      expect(find.text('Perfil infantil'), findsOneWidget);
    });

    testWidgets('Voltar só aparece numa rota empilhada e retorna', (tester) async {
      await _montar(tester, chamadas);
      expect(find.bySemanticsLabel('Voltar'), findsNothing);
      await _montar(tester, chamadas, empilhada: true);
      expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.pumpAndSettle();
      expect(find.byType(LigacaoDaVoce), findsOneWidget);
      expect(find.bySemanticsLabel('Voltar'), findsNothing);
    });

    testWidgets('sem servidor somem Minha conta e Meus pedidos', (tester) async {
      cgflixUserMenuDebugOnline = false;
      await _montar(tester, chamadas);
      expect(find.text('Minha conta'), findsNothing);
      expect(find.text('Meus pedidos'), findsNothing);
      expect(find.text('Trocar usuário'), findsOneWidget);
      // Servidor fora do ar é justamente quando a pessoa precisa adicionar outro.
      expect(find.text('Servidores'), findsOneWidget);
    });

    testWidgets('sem apoio some o Apoie', (tester) async {
      cgflixApoioDebugOverride = const _Apoio(disponivel: false);
      await _montar(tester, chamadas);
      await _mostrar(tester, 'Sobre o Heisuca');
      await _mostrar(tester, 'Sair');
      expect(find.text('Apoie'), findsNothing);
      expect(find.text('Sobre o Heisuca'), findsOneWidget);
    });

    testWidgets('sem atualizações liberadas some o cartão', (tester) async {
      await _montar(tester, chamadas, comAtualizacoes: false);
      await _mostrar(tester, 'Sobre o Heisuca');
      expect(find.text('Atualizações'), findsNothing);
    });

    testWidgets('versão da loja: cartão explica que a Play Store atualiza e abre a loja', (tester) async {
      await _montar(tester, chamadas, daLoja: true);
      await _mostrar(tester, 'Atualizações');
      expect(find.text(textoAtualizacoesNaLoja), findsOneWidget);
      await tester.tap(_cartao('Atualizações'));
      await tester.pump();
      expect(chamadas.de('atualizacoesNaLoja'), 1);
      expect(chamadas.de('atualizacoes'), 0);
    });

    testWidgets('mostra o nome de quem usa o app', (tester) async {
      await _montar(tester, chamadas);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('com perfil infantil salvo, mostra o cartão dele e chama a ação', (tester) async {
      await HeisucaKids.instance.save(_registro);
      await _montar(tester, chamadas);
      expect(find.text('Entrar no perfil Ana'), findsOneWidget);
      expect(find.text('Ana: nome, foto, tema e PIN'), findsOneWidget);
      await tester.tap(_cartao('Perfil infantil'));
      await tester.pump();
      expect(chamadas.de('perfilInfantil:Ana'), 1);
    });

    testWidgets('no modo infantil só aparece "Sair do modo infantil"', (tester) async {
      await HeisucaKids.instance.save(_registro);
      await _montar(tester, chamadas, ativo: _filho);
      expect(find.text('Sair do modo infantil'), findsOneWidget);
      expect(find.text('Configurações'), findsNothing);
      expect(find.text('Servidores'), findsNothing);
      expect(find.text('Sair'), findsNothing);
      await tester.tap(_cartao('Sair do modo infantil'));
      await tester.pump();
      expect(chamadas.de('sairDoModoInfantil'), 1);
    });
  });

  group('acessibilidade', () {
    for (final (nome, tema, paleta) in _temas) {
      testWidgets('toque de 48 e letra 200 % sem estourar no tema $nome', (tester) async {
        await _montar(tester, chamadas, tema: tema, paleta: paleta, letra: 2, empilhada: true);
        expect(find.text('Ana'), findsOneWidget);
        expect(tester.getRect(find.text('Ana')).overlaps(tester.getRect(find.byType(CustomScrollView))), isTrue);
        final voltar = find.bySemanticsLabel('Voltar');
        expect(tester.getSize(voltar).height, greaterThanOrEqualTo(Forma.toqueMinimo));
        expect(tester.getSize(voltar).width, greaterThanOrEqualTo(Forma.toqueMinimo));
        expect(tester.takeException(), isNull);
        for (final titulo in [
          'Minha conta',
          'Meus pedidos',
          'Trocar usuário',
          'Perfis e PIN',
          'Modo infantil',
          'Configurações',
          'Atualizações',
          'Sobre o Heisuca',
          'Apoie',
          'Sair',
        ]) {
          await _mostrar(tester, titulo);
          final tamanho = tester.getSize(_cartao(titulo));
          expect(tamanho.height, greaterThanOrEqualTo(Forma.toqueMinimo), reason: titulo);
          expect(tamanho.width, greaterThanOrEqualTo(Forma.toqueMinimo), reason: titulo);
          expect(tester.takeException(), isNull, reason: titulo);
        }
        expect(find.text('Sair').hitTestable(), findsOneWidget);
      });
    }

    testWidgets('toque de 48 na letra normal', (tester) async {
      await _montar(tester, chamadas);
      for (final cartao in find.byType(Toque).evaluate()) {
        final tamanho = tester.getSize(find.byWidget(cartao.widget));
        expect(tamanho.height, greaterThanOrEqualTo(Forma.toqueMinimo));
        expect(tamanho.width, greaterThanOrEqualTo(Forma.toqueMinimo));
      }
    });

    testWidgets('o leitor de tela lê título e subtítulo; o nome é cabeçalho', (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, chamadas);
      expect(find.bySemanticsLabel('Configurações, Reprodução, vídeo, áudio e legendas'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Ana')),
        matchesSemantics(label: 'Ana', isHeader: true, textDirection: TextDirection.ltr),
      );
      await _mostrar(tester, 'Sair');
      expect(find.bySemanticsLabel('Sair, Encerrar a sessão neste aparelho'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('teclado ativa o cartão com Enter', (tester) async {
      await _montar(tester, chamadas);
      await _mostrar(tester, 'Sobre o Heisuca');
      final alvo = tester.widget<Toque>(_cartao('Sobre o Heisuca'));
      // Tab percorre os cartões na ordem da tela até o foco chegar no desejado.
      var chegou = false;
      for (var i = 0; i < 40 && !chegou; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        chegou = identical(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<Toque>(), alvo);
      }
      expect(chegou, isTrue, reason: 'o foco do teclado nunca chegou no cartão');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chamadas.de('sobre'), 1);
    });

    testWidgets('com "remover animações" tudo continua funcionando', (tester) async {
      await _montar(tester, chamadas, semAnimacao: true);
      await _mostrar(tester, 'Configurações');
      await tester.tap(_cartao('Configurações'));
      await tester.pump();
      expect(chamadas.de('configuracoes'), 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('tela pura', () {
    testWidgets('grupo vazio não aparece e nome vazio vira "Você"', (tester) async {
      var voltou = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaHeisuca.shikkoku.paraMaterial().copyWith(extensions: [CgflixPalette.isis, TemaHeisuca.shikkoku]),
          home: TelaVoce(
            nome: '',
            aoVoltar: () => voltou++,
            grupos: [
              const [],
              [ItemDaVoce(chave: 'a', icone: Icons.info, titulo: 'Alfa', aoTocar: () {})],
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Você'), findsOneWidget);
      expect(find.text('Alfa'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.pump();
      expect(voltou, 1);
    });
  });
}
