import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../cgflix/cgflix_theme_picker.dart';
import '../../design/componentes/toque.dart';
import '../../design/forma.dart';
import '../../design/movimento.dart';
import '../../design/tema.dart';
import '../../design/tipo.dart';
import '../../features/tema_da_v2.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/profile/profile_switch_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/updates/update_settings_screen.dart';
import '../../services/settings_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/updates/pagina_na_loja.dart';
import '../../services/updates/update_controller.dart';
import '../theme/heisuca_base.dart';
import 'heisuca_tv_area_segura.dart';
import 'heisuca_tv_canvas.dart';
import 'heisuca_tv_pecas.dart';

/// Ajustes oficiais do Heisuca na TV, no desenho dos ajustes do Apple TV e do app de Windows: título grande e
/// uma coluna central de linhas da mesma altura, com o nome à esquerda e o valor atual à direita.
///
/// Montada na tela de referência da TV ([HeisucaTvCanvas], 1920 de largura), dentro da margem segura de 5 %.
/// O foco só mexe na pintura (anel e fundo), nunca no tamanho da linha; a lista centraliza a linha com
/// foco, para nenhuma encostar na borda. Atualizações aparece na distribuição direta (e explica a da Play).
class HeisucaTvSettingsScreen extends StatefulWidget {
  const HeisucaTvSettingsScreen({super.key});

  /// Largura da coluna na tela de referência: 550 dp numa TV 1080p (960 dp) e 733 dp numa TV box 720p.
  static const double largura = 1100;

  /// Folga lateral da lista para o anel de foco ficar inteiro dentro da coluna.
  static const double folgaDoFoco = Forma.anelDeFoco;

  @override
  State<HeisucaTvSettingsScreen> createState() => _HeisucaTvSettingsScreenState();
}

class _HeisucaTvSettingsScreenState extends State<HeisucaTvSettingsScreen> {
  bool _preferPortuguese = true;
  String _subtitleLang = 'Português';
  int _subtitleSize = 38;
  bool _stillWatching = true;
  bool _performanceOverlay = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = SettingsService.instanceOrNull;
    if (settings != null) {
      _preferPortuguese = settings.read(SettingsService.heisucaPreferPortugueseAudio);
      _subtitleSize = settings.read(SettingsService.subtitleFontSize);
      final count = settings.read(SettingsService.stillWatchingEpisodes);
      _stillWatching = count > 0;
      _performanceOverlay = settings.read(SettingsService.showPerformanceOverlay);
      final lang = settings.read(SettingsService.subtitleSearchLanguage);
      _subtitleLang = (lang == 'por' || lang == 'pt') ? 'Português' : 'Desligada';
    }
  }

  Future<void> _toggleAudio() async {
    final next = !_preferPortuguese;
    setState(() => _preferPortuguese = next);
    await SettingsService.instanceOrNull?.write(SettingsService.heisucaPreferPortugueseAudio, next);
  }

  Future<void> _toggleSubtitle() async {
    final next = _subtitleLang == 'Português' ? 'Desligada' : 'Português';
    setState(() => _subtitleLang = next);
    await SettingsService.instanceOrNull?.write(
      SettingsService.subtitleSearchLanguage,
      next == 'Português' ? 'por' : null,
    );
  }

  Future<void> _cycleSubtitleSize() async {
    final nextSize = switch (_subtitleSize) {
      28 => 38,
      38 => 48,
      _ => 28,
    };
    setState(() => _subtitleSize = nextSize);
    await SettingsService.instanceOrNull?.write(SettingsService.subtitleFontSize, nextSize);
  }

  Future<void> _toggleStillWatching() async {
    final next = !_stillWatching;
    setState(() => _stillWatching = next);
    await SettingsService.instanceOrNull?.write(SettingsService.stillWatchingEpisodes, next ? 3 : 0);
  }

  Future<void> _togglePerformanceOverlay() async {
    final next = !_performanceOverlay;
    setState(() => _performanceOverlay = next);
    await SettingsService.instanceOrNull?.write(SettingsService.showPerformanceOverlay, next);
  }

  Future<void> _trocarTema() async {
    final provider = context.read<ThemeProvider>();
    await provider.setThemeMode(
      provider.themeMode == settings.ThemeMode.sumi ? settings.ThemeMode.oled : settings.ThemeMode.sumi,
    );
  }

  void _abrir(Widget tela) => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela)));

  Future<void> _sair() async {
    final confirmed = await ConfirmarSaidaTv.mostrar(context);
    if (confirmed && mounted) unawaited(SystemNavigator.pop());
  }

  @override
  Widget build(BuildContext context) {
    final atualizacoes = context.watch<UpdateController?>();
    final profileName = context.watch<ActiveProfileProvider?>()?.active?.displayName ?? 'Família';
    final temaEscolhido =
        context.watch<ThemeProvider?>()?.themeMode ??
        SettingsService.instanceOrNull?.read(SettingsService.themeMode) ??
        settings.ThemeMode.oled;

    final sizeLabel = switch (_subtitleSize) {
      28 => 'Pequeno (28)',
      48 => 'Grande (48)',
      _ => 'Normal (38)',
    };

    final linhas = <Widget>[
      _LinhaDeAjuste(
        focoInicial: true,
        titulo: 'Perfil',
        valor: profileName,
        abreTela: true,
        aoTocar: () => _abrir(const ProfileSwitchScreen(requireSelection: false)),
      ),
      _LinhaDeAjuste(titulo: 'Tema', valor: cgflixThemeName(temaEscolhido), aoTocar: () => unawaited(_trocarTema())),
      _LinhaDeAjuste(
        titulo: 'Áudio padrão',
        valor: _preferPortuguese ? 'Português (dublado)' : 'Idioma original',
        aoTocar: () => unawaited(_toggleAudio()),
      ),
      _LinhaDeAjuste(titulo: 'Legenda padrão', valor: _subtitleLang, aoTocar: () => unawaited(_toggleSubtitle())),
      _LinhaDeAjuste(titulo: 'Tamanho da legenda', valor: sizeLabel, aoTocar: () => unawaited(_cycleSubtitleSize())),
      _LinhaDeAjuste(
        titulo: 'Ainda está aí?',
        valor: _stillWatching ? 'Após 3 episódios' : 'Desligado',
        aoTocar: () => unawaited(_toggleStillWatching()),
      ),
      _LinhaDeAjuste(
        titulo: 'Desempenho na tela',
        valor: _performanceOverlay ? 'Ligado' : 'Desligado',
        aoTocar: () => unawaited(_togglePerformanceOverlay()),
      ),
      if (atualizacoes?.permiteAjustes == true)
        _LinhaDeAjuste(
          titulo: 'Atualizações',
          valor: atualizacoes!.oferta != null ? 'Versão nova' : 'Canal ${atualizacoes.canal}',
          abreTela: true,
          aoTocar: () => _abrir(const UpdateSettingsScreen()),
        )
      else if (atualizacoes?.pelaLoja == true)
        _LinhaDeAjuste(
          titulo: 'Atualizações',
          valor: 'Pela Play Store',
          abreTela: true,
          aoTocar: () => unawaited(abrirPaginaNaLoja()),
        ),
      _LinhaDeAjuste(titulo: 'Sobre', valor: 'Heisuca 2.0', abreTela: true, aoTocar: () => _abrir(const AboutScreen())),
      _LinhaDeAjuste(titulo: 'Sair', valor: 'Fechar o app', destrutiva: true, aoTocar: () => unawaited(_sair())),
    ];

    return HeisucaTvCanvas(
      child: SobOTemaDaV2(
        child: Builder(
          builder: (context) {
            final tema = TemaHeisuca.de(context);
            return Scaffold(
              backgroundColor: tema.fundo,
              body: HeisucaTvAreaSegura(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: HeisucaTvSettingsScreen.largura),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: HeisucaTvSettingsScreen.folgaDoFoco),
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Ajustes',
                              style: Tipo.destaque(tema).copyWith(fontSize: HeisucaBase.tamanhoTvTitulo),
                            ),
                          ),
                        ),
                        const SizedBox(height: Forma.espaco4),
                        Expanded(
                          child: HeisucaTvBordasSuaves(
                            altura: HeisucaBase.espaco8,
                            child: FocusTraversalGroup(
                              policy: WidgetOrderTraversalPolicy(),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: HeisucaTvSettingsScreen.folgaDoFoco,
                                  // A última linha e seu anel param antes do degradê, inclusive com letra grande.
                                  vertical: HeisucaBase.espaco8 + Forma.anelDeFoco,
                                ),
                                itemCount: linhas.length,
                                itemBuilder: (_, i) => linhas[i],
                                separatorBuilder: (_, _) => const SizedBox(height: Forma.espaco3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Uma linha dos ajustes: nome à esquerda, valor atual à direita e a seta quando abre outra tela.
///
/// A altura vem só do texto e do espaçamento fixo; o foco muda o anel e o fundo, conservando a largura
/// das demais linhas. Com foco, a lista rola até deixar a linha no meio.
class _LinhaDeAjuste extends StatefulWidget {
  const _LinhaDeAjuste({
    required this.titulo,
    required this.valor,
    required this.aoTocar,
    this.abreTela = false,
    this.focoInicial = false,
    this.destrutiva = false,
  });

  final String titulo;
  final String valor;
  final VoidCallback aoTocar;

  /// Mostra a seta: a linha abre outra tela em vez de trocar o valor ali mesmo.
  final bool abreTela;
  final bool focoInicial;
  final bool destrutiva;

  @override
  State<_LinhaDeAjuste> createState() => _LinhaDeAjusteState();
}

class _LinhaDeAjusteState extends State<_LinhaDeAjuste> {
  final _foco = FocusNode(debugLabel: 'tv-ajuste');
  bool _comFoco = false;

  @override
  void initState() {
    super.initState();
    _foco.addListener(_mudouFoco);
  }

  @override
  void dispose() {
    _foco
      ..removeListener(_mudouFoco)
      ..dispose();
    super.dispose();
  }

  void _mudouFoco() {
    if (!mounted || _foco.hasFocus == _comFoco) return;
    setState(() => _comFoco = _foco.hasFocus);
    if (!_comFoco) return;
    unawaited(
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: Movimento.tempo(context, Movimento.tela),
        curve: Movimento.padrao,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaHeisuca.de(context);
    final forma = Forma.superelipse(Forma.raioMedio);
    final fundo = _comFoco ? (widget.destrutiva ? tema.erro : tema.botaoFundo) : tema.superficie;
    final tinta = _comFoco ? tema.botaoTexto : (widget.destrutiva ? tema.erro : tema.texto);
    final tinta2 = _comFoco ? tema.botaoTexto : tema.texto2;
    final tempo = Movimento.tempo(context, Movimento.troca);
    final nome = Tipo.subtitulo(tema).copyWith(fontSize: HeisucaBase.tamanhoTitulo, color: tinta);
    final valor = Tipo.texto(tema).copyWith(fontSize: HeisucaBase.tamanhoTvTexto, color: tinta2, height: 1.2);

    return Toque(
      key: ValueKey('tv-ajuste-${widget.titulo}'),
      forma: forma,
      foco: _foco,
      focoInicial: widget.focoInicial,
      escala: 1,
      aoTocar: widget.aoTocar,
      child: AnimatedContainer(
        duration: tempo,
        curve: Movimento.padrao,
        // Com o texto normal, as dez linhas e a folga do degradê cabem em 1080p.
        // A letra ampliada aumenta a altura naturalmente e a lista passa a rolar.
        padding: const EdgeInsets.symmetric(horizontal: HeisucaBase.espaco8, vertical: Forma.espaco4),
        decoration: ShapeDecoration(color: fundo, shape: forma),
        child: Row(
          children: [
            Expanded(child: Text(widget.titulo, style: nome)),
            const SizedBox(width: Forma.espaco6),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(widget.valor, style: valor, textAlign: TextAlign.end),
              ),
            ),
            if (widget.abreTela) ...[
              const SizedBox(width: Forma.espaco3),
              ExcludeSemantics(
                child: Icon(Symbols.chevron_right_rounded, size: HeisucaBase.tamanhoTitulo, color: tinta2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
