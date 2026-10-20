// App de teste do job "Emulador" do CI (Etapa 1D/1E). NÃO vai para o APK de verdade: o CI compila
// este arquivo como alvo (`flutter build apk --debug -t test/cgflix/emulador/app_navegacao.dart`).
//
// Usa as peças reais do CGFLIX (temas Isis e Heitor, seguindo o modo claro/escuro do aparelho, barra do topo, menu do usuário, contas de altura do
// destaque, transições, seção "Disponível para pedir" e "Meus pedidos") com dados falsos: nada de
// login nem servidor. O roteiro em scripts/cgflix/emulador_navegacao.py toca nos itens pelo nome
// (TalkBack/uiautomator), gira a tela e tira as capturas; troca o modo do aparelho
// (`cmd uimode night`) para capturar as mesmas telas nos dois temas.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:plezy/cgflix/apoio/cgflix_apoio_screen.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/cgflix/cgflix_advanced.dart';
import 'package:plezy/cgflix/cgflix_config_itens.dart';
import 'package:plezy/cgflix/cgflix_dicas.dart';
import 'package:plezy/cgflix/cgflix_theme_picker.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:plezy/widgets/settings_page.dart';
import 'package:plezy/widgets/settings_section.dart';
import 'package:plezy/cgflix/cgflix_layout.dart';
import 'package:plezy/cgflix/cgflix_navigation.dart';
import 'package:plezy/cgflix/cgflix_logo.dart';
import 'package:plezy/cgflix/cgflix_slogan.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/cgflix/cgflix_user_menu.dart';
import 'package:plezy/cgflix/conta/cgflix_conta.dart';
import 'package:plezy/cgflix/you/cgflix_favorites_screen.dart';
import 'package:plezy/cgflix/requests/cgflix_requests_ui.dart';
import 'package:plezy/cgflix/requests/cgflix_seerr.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/services/settings_service.dart' show SettingsService;
import 'package:provider/provider.dart';

/// Títulos falsos de cada categoria (Etapa 1E: cada chip só mostra os seus).
const _porCategoria = {
  null: ['Duna', 'Ainda Estou Aqui', 'Ruptura', 'Frieren', 'Cidade de Deus', 'Spy x Family'],
  'Filmes': ['Duna', 'Bacurau', 'Ainda Estou Aqui', 'Cidade de Deus', 'O Auto da Compadecida', 'Central do Brasil'],
  'Séries': ['Ruptura', 'Sintonia', 'Cangaço Novo', 'The Bear', 'Severance', 'Arcane'],
  'Animes': ['Frieren', 'Jujutsu Kaisen', 'Spy x Family', 'One Piece', 'Dandadan', 'Solo Leveling'],
};

List<String> get _titulos => _porCategoria[null]!;

/// Seerr falso: "Disponível para pedir" e "Meus pedidos" sem servidor.
class _PedidosFalsos implements CgflixRequestsBackend {
  @override
  Future<List<CgflixRequestable>> search(String query) async => const [
    CgflixRequestable(tmdbId: 1, isMovie: true, title: 'Duna: Parte Três', year: 2026),
    CgflixRequestable(tmdbId: 2, isMovie: false, title: 'Duna: A Profecia', year: 2024),
    CgflixRequestable(tmdbId: 3, isMovie: true, title: 'Duna (1984)', year: 1984, state: CgflixRequestState.requested),
    CgflixRequestable(
      tmdbId: 4,
      isMovie: true,
      title: 'Duna de Jodorowsky',
      year: 2013,
      state: CgflixRequestState.downloading,
    ),
  ];

  @override
  Future<List<CgflixSeasonChoice>> seasons(int tmdbId) async => const [
    CgflixSeasonChoice(number: 1, name: 'Temporada 1', episodes: 6),
    CgflixSeasonChoice(number: 2, name: 'Temporada 2', episodes: 6),
  ];

  @override
  Future<void> request(CgflixRequestable item, {List<int>? seasons}) async {}

  @override
  Future<List<CgflixMyRequest>> myRequests() async => const [
    CgflixMyRequest(
      id: 1,
      tmdbId: 2,
      isMovie: false,
      title: 'Duna: A Profecia',
      year: 2024,
      status: CgflixMyRequestStatus.waitingApproval,
      seasons: [1, 2],
    ),
    CgflixMyRequest(
      id: 2,
      tmdbId: 5,
      isMovie: true,
      title: 'Ainda Estou Aqui',
      year: 2024,
      status: CgflixMyRequestStatus.available,
    ),
    CgflixMyRequest(id: 3, tmdbId: 6, isMovie: false, title: 'Frieren', status: CgflixMyRequestStatus.downloading),
  ];

  @override
  Future<CgflixTitleInfo> titleInfo(int tmdbId, {required bool isMovie}) async =>
      (title: 'Título $tmdbId', year: null, posterUrl: null);
}

/// Conta falsa (1.5.0): "Minha conta" sem servidor.
class _ContaFalsa implements CgflixConta {
  @override
  Future<CgflixPerfil> perfil() async => const CgflixPerfil(nome: 'Maria');

  @override
  Future<void> trocarFoto(Uint8List jpeg) async {}

  @override
  Future<void> removerFoto() async {}

  @override
  Future<CgflixSenhaResultado> trocarSenha({required String atual, required String nova}) async =>
      CgflixSenhaResultado.ok;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Refino 2/2b: telas reais das Configurações e das Dicas precisam das preferências e do português.
  await SettingsService.getInstance();
  await LocaleSettings.setLocale(AppLocale.pt);
  cgflixDicaPlayerDebugVista = false; // a dica dos gestos aparece na tela de vídeo falsa
  // 1.5.0: menu completo (conectado ao Jellyfin), Minha conta e Favoritos falsos.
  cgflixUserMenuDebugOnline = true;
  CgflixConta.debugOverride = _ContaFalsa();
  CgflixFavoritesSource.debugOverride = CgflixFavoritesSource(load: () async => const []);
  CgflixPages.libraries = (_) => const _PaginaSimples(titulo: 'Bibliotecas', texto: 'Filmes · Séries · Animes');
  cgflixEnableEdgeToEdge();
  CgflixPages.search = (_) => const _BuscaFalsa();
  CgflixPages.downloads = (_) => const _PaginaSimples(titulo: 'Baixados', texto: 'Nenhum título baixado ainda');
  CgflixPages.settings = () => MaterialPageRoute<void>(builder: (_) => const _ConfiguracoesFalsas());
  CgflixRequests.debugOverride = _PedidosFalsos();
  // Tema 1.4.0: aparelho escuro = Isis, claro = Heitor (como o "Automático" do app).
  runApp(
    TranslationProvider(
      child: ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: cgflixAppTheme(CgflixThemeVariant.heitor),
          darkTheme: cgflixAppTheme(),
          themeMode: ThemeMode.system,
          builder: (context, child) => cgflixSystemBars(context, child!),
          home: const _InicioFalsa(),
        ),
      ),
    ),
  );
}

class _InicioFalsa extends StatefulWidget {
  const _InicioFalsa();

  @override
  State<_InicioFalsa> createState() => _InicioFalsaState();
}

class _InicioFalsaState extends State<_InicioFalsa> {
  String? _filtro;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final heroHeight = cgflixHeroHeight(media.size);
    final compact = cgflixHeroCompact(media.size);
    return Scaffold(
      backgroundColor: context.cgflix.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: heroHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [context.cgflix.chipSelected, context.cgflix.background],
                    ),
                  ),
                  alignment: compact ? Alignment.bottomLeft : Alignment.bottomCenter,
                  padding: EdgeInsets.fromLTRB(24 + media.padding.left, 0, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Text(
                        _filtro == null ? 'Duna' : 'Duna · $_filtro',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: context.cgflix.action,
                          foregroundColor: context.cgflix.onAction,
                        ),
                        onPressed: () {},
                        child: const Text('Assistir'),
                      ),
                    ],
                  ),
                ),
              ),
              for (final linha in ['Continuar assistindo', 'Em alta no Brasil', 'Lançamentos'])
                SliverToBoxAdapter(
                  child: _LinhaFalsa(titulo: linha, titulos: _porCategoria[_filtro]!),
                ),
              SliverToBoxAdapter(child: SizedBox(height: media.padding.bottom + 24)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8 + media.padding.left, media.padding.top + 4, 8 + media.padding.right, 0),
              child: CgflixTopBar(
                onClearFilter: _filtro == null ? null : () => setState(() => _filtro = null),
                chips: [
                  for (final c in ['Filmes', 'Séries', 'Animes'])
                    if (_filtro == null || _filtro == c)
                      CgflixTopBarChip(
                        label: c,
                        selected: _filtro == c,
                        onPressed: () => setState(() => _filtro = _filtro == c ? null : c),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaFalsa extends StatelessWidget {
  const _LinhaFalsa({required this.titulo, required this.titulos});
  final String titulo;
  final List<String> titulos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: titulos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Container(
                width: 120,
                decoration: BoxDecoration(
                  color: context.cgflix.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: context.cgflix.cardShadow,
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(8),
                child: Text(titulos[i], maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Busca falsa: o que já temos (abre a página do título) e, logo abaixo, a seção real
/// "Disponível para pedir" com o Seerr falso.
class _BuscaFalsa extends StatelessWidget {
  const _BuscaFalsa();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: TextEditingController(text: 'Duna'),
            decoration: const InputDecoration(hintText: 'Títulos, pessoas...'),
          ),
          const SizedBox(height: 16),
          for (final t in _titulos.take(1))
            ListTile(
              title: Text(t),
              subtitle: const Text('Filme · 2021'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TituloFalso(titulo: t))),
            ),
          const CgflixRequestSection(query: 'Duna'),
        ],
      ),
    );
  }
}

/// Página do título: duas colunas quando cabe (deitado), uma em pé.
class _TituloFalso extends StatelessWidget {
  const _TituloFalso({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final poster = AspectRatio(
      aspectRatio: 2 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.cgflix.surfaceHigh, borderRadius: BorderRadius.circular(8)),
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('2024 · 2h 46min · 14 anos · Dublado · Legendado'),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: context.cgflix.action,
            foregroundColor: context.cgflix.onAction,
          ),
          onPressed: () {},
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Assistir'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sinopse falsa para o teste do emulador. Paul Atreides une forças com os Fremen enquanto busca vingança.',
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: constraints.maxWidth > 600
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 200, child: poster),
                    const SizedBox(width: 24),
                    Expanded(child: info),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: SizedBox(width: 180, child: poster)),
                    const SizedBox(height: 16),
                    info,
                  ],
                ),
        ),
      ),
    );
  }
}

class _PaginaSimples extends StatelessWidget {
  const _PaginaSimples({required this.titulo, required this.texto});
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(child: Text(texto)),
    );
  }
}

/// Configurações com as peças reais do refino 2b (lista plana M3, cabeçalhos, tema, idioma, Ao
/// assistir, Estilo das legendas, Avançado como subtela) e atalhos para as telas falsas.
class _ConfiguracoesFalsas extends StatelessWidget {
  const _ConfiguracoesFalsas();

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: const Text('Configurações'),
      children: [
        const SettingsGroup(title: 'Aparência', children: [CgflixThemeSelector(), CgflixAppLanguageTile()]),
        const SettingsGroup(
          title: cgflixWatchHeader,
          children: [CgflixSubtitleStyleTile(), CgflixSkipTile(), CgflixQualityTile(), CgflixCellularQualityTile()],
        ),
        SettingsGroup(
          title: 'Ajuda',
          children: [
            SettingNavigationTile(
              icon: Symbols.lightbulb_rounded,
              title: 'Dicas do CGFLIX',
              subtitle: 'Como usar as funções do app, em poucas palavras',
              destinationBuilder: (_) => const CgflixDicasScreen(),
            ),
            SettingNavigationTile(
              icon: Symbols.play_circle_rounded,
              title: 'Ver a tela de vídeo',
              destinationBuilder: (_) => const _VideoFalso(),
            ),
            SettingNavigationTile(
              icon: Symbols.login_rounded,
              title: 'Ver a tela de entrada',
              destinationBuilder: (_) => const _EntradaFalsa(),
            ),
          ],
        ),
        SettingNavigationTile(
          icon: Symbols.settings_applications_rounded,
          title: 'Avançado',
          subtitle: cgflixAdvancedSummary,
          onTap: () => cgflixOpenSettingsSubpage(
            context,
            title: 'Avançado',
            builder: (_) => const [CgflixAdvancedFeatures(), CgflixAdvancedPlayback(), CgflixAdvancedSubtitles()],
          ),
        ),
        const CgflixApoioSettingsTile(),
      ],
    );
  }
}

/// Tela de vídeo (falsa, sempre escura) com a dica única dos gestos por cima.
class _VideoFalso extends StatelessWidget {
  const _VideoFalso();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: cgflixAppTheme(),
      // Refino 2b: "cena" azulada (a mesma da prévia da legenda), clara o bastante para o detector de
      // tela preta: a dica some sozinha em 8 s e a captura deitada pegava só o fundo quase preto.
      child: const Scaffold(
        backgroundColor: Color(0xFF3A5068),
        body: Stack(
          children: [
            Center(
              child: Text('Cidade Invisível', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ),
            Positioned.fill(child: CgflixDicaPlayer()),
          ],
        ),
      ),
    );
  }
}

/// Tela de entrada (falsa) com a marca do tema, o slogan e o campo do servidor vazio.
class _EntradaFalsa extends StatelessWidget {
  const _EntradaFalsa();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CgflixEmblem(size: 120)),
                  const SizedBox(height: 16),
                  Text(
                    'CGFLIX',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const CgflixSlogan(),
                  const SizedBox(height: 32),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Servidor Jellyfin', hintText: 'https://seu.servidor.com'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () {}, child: const Text('Conectar ao Jellyfin')),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: () {}, child: const Text('Entrar com o Plex')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
