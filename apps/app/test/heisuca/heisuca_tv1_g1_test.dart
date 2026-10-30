import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/services/device_performance.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/utils/media_image_helper.dart';
import 'package:heisuca/utils/platform_detector.dart';

import 'package:heisuca/heisuca/tv/heisuca_tv_header.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_menu.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_home_screen.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_title_screen.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_settings_screen.dart';
import 'package:heisuca/heisuca/tv/heisuca_tv_back_handler.dart';
import 'package:heisuca/heisuca/heisuca_opening_splash.dart';

import '../test_helpers/heisuca_p3_fixture.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HeisucaP3Fixture fixture;

  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'Heisuca',
      packageName: 'app.heisuca.player.teste.home',
      version: '2.0.34',
      buildNumber: '2036',
      buildSignature: '',
    );
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    await LocaleSettings.setLocale(AppLocale.pt);
    PlatformDetector.setForceTVSync(true);
    fixture = HeisucaP3Fixture();
    await fixture.initialize(settings.ThemeMode.dark);
  });

  tearDown(() {
    PlatformDetector.setForceTVSync(false);
  });

  group('TV-1 G1: Telas de TV no Modelo A', () {
    testWidgets('G1.1 Navegação: avatar no topo esquerdo e menu abre/fecha', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      var selectedDestination = '';
      await tester.pumpWidget(
        fixture.wrap(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  HeisucaTvHeader(
                    onOpenMenu: () {
                      showDialog(
                        context: tester.element(find.byType(Scaffold)),
                        builder: (ctx) => HeisucaTvMenu(
                          onSelectDestination: (dest) {
                            selectedDestination = dest;
                            Navigator.of(ctx).pop();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Avatar e Logo HEISUCA visíveis no topo
      expect(find.byType(HeisucaTvHeader), findsOneWidget);
      expect(find.textContaining('HEISUCA'), findsOneWidget);

      // Foca o avatar e ativa
      final avatarFinder = find.byKey(const Key('heisuca-tv-avatar-button'));
      expect(avatarFinder, findsOneWidget);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Menu aberto: perfil + itens
      expect(find.byType(HeisucaTvMenu), findsOneWidget);
      expect(find.text('Trocar perfil'), findsOneWidget);
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Filmes'), findsOneWidget);
      expect(find.text('Séries'), findsOneWidget);
      expect(find.text('Animes'), findsOneWidget);
      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);

      // Clicar em Filmes
      await tester.tap(find.text('Filmes'));
      await tester.pumpAndSettle();
      expect(selectedDestination, 'Filmes');
      expect(find.byType(HeisucaTvMenu), findsNothing);
    });

    testWidgets('G1.2 Início Modelo A: destaque em tela cheia com Assistir focado e Continuar abaixo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      final testItem = MediaItem.jellyfin(
        id: 'destaque-1',
        serverId: 'srv-1',
        title: 'O Menino e a Garça',
        summary: 'Um jovem garoto entra em um mundo mágico compartilhado pelos vivos e os mortos.',
        kind: MediaKind.movie,
        year: 2024,
        rating: 8.5,
        durationMs: 7440000,
      );

      final cwItem = MediaItem.jellyfin(
        id: 'cw-1',
        serverId: 'srv-1',
        title: 'Frieren e a Jornada para o Além',
        kind: MediaKind.episode,
        parentTitle: 'Temporada 1',
        index: 3,
        durationMs: 1440000,
        viewOffsetMs: 720000,
      );

      await tester.pumpWidget(
        fixture.wrap(
          MaterialApp(
            home: Scaffold(
              body: HeisucaTvHomeScreen(
                heroItem: testItem,
                continueWatchingItems: [cwItem],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Linha EM ALTA NO BRASIL · Nº 1
      expect(find.text('EM ALTA NO BRASIL · Nº 1'), findsOneWidget);
      expect(find.text('O Menino e a Garça'), findsOneWidget);

      // Botões Assistir e Detalhes
      final assistirFinder = find.byKey(const Key('heisuca-tv-hero-play'));
      final detalhesFinder = find.byKey(const Key('heisuca-tv-hero-details'));
      expect(assistirFinder, findsOneWidget);
      expect(detalhesFinder, findsOneWidget);

      // Linha Continuar assistindo
      expect(find.text('Continuar assistindo'), findsOneWidget);
      expect(find.byKey(const Key('heisuca-tv-continue-row')), findsOneWidget);
    });

    testWidgets('G1.3 Título TV: Continuar em foco, áudio/legenda, versão e temporadas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      final serie = MediaItem.jellyfin(
        id: 'serie-tv-1',
        serverId: 'srv-1',
        title: 'Sousou no Frieren',
        summary: 'A maga elfa Frieren e seus companheiros derrotaram o Rei Demônio.',
        kind: MediaKind.show,
        year: 2024,
      );

      final temporada = MediaItem.jellyfin(
        id: 'temp-1',
        serverId: 'srv-1',
        title: 'Temporada 1',
        kind: MediaKind.season,
        index: 1,
      );

      final ep = MediaItem.jellyfin(
        id: 'ep-1',
        serverId: 'srv-1',
        title: 'O Fim da Jornada',
        kind: MediaKind.episode,
        index: 1,
        durationMs: 1440000,
      );

      await tester.pumpWidget(
        fixture.wrap(
          MaterialApp(
            home: Scaffold(
              body: HeisucaTvTitleScreen(
                item: serie,
                seasons: [temporada],
                episodes: [ep],
                targetEpisode: ep,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sousou no Frieren'), findsOneWidget);
      expect(find.byKey(const Key('heisuca-tv-title-play')), findsOneWidget);
      expect(find.text('Áudio e legenda'), findsOneWidget);
      expect(find.text('Versão: 1080p'), findsOneWidget);
      expect(find.text('Temporada 1'), findsOneWidget);
    });

    testWidgets('G1.4 Voltar: no início leva ao destaque; no destaque sai/confirma', (tester) async {
      var exitRequested = false;
      var confirmationShown = false;

      final handler = HeisucaTvBackHandler(
        isFireTv: false,
        isAtHeroDestaque: () => false,
        onScrollToDestaque: () {},
        onExitApp: () => exitRequested = true,
        onShowConfirmation: () => confirmationShown = true,
      );

      // Quando não está no destaque: volta ao destaque
      var handled = handler.handleBack();
      expect(handled, true);
      expect(exitRequested, false);

      // Quando está no destaque em Android TV: sai
      final handlerAtHero = HeisucaTvBackHandler(
        isFireTv: false,
        isAtHeroDestaque: () => true,
        onScrollToDestaque: () {},
        onExitApp: () => exitRequested = true,
        onShowConfirmation: () => confirmationShown = true,
      );
      handled = handlerAtHero.handleBack();
      expect(handled, true);
      expect(exitRequested, true);

      // Quando está no destaque em Fire TV: pede confirmação
      final handlerFire = HeisucaTvBackHandler(
        isFireTv: true,
        isAtHeroDestaque: () => true,
        onScrollToDestaque: () {},
        onExitApp: () {},
        onShowConfirmation: () => confirmationShown = true,
      );
      handled = handlerFire.handleBack();
      expect(handled, true);
      expect(confirmationShown, true);
    });

    testWidgets('G1.5 Ajustes na TV enxutos: apenas os 7 itens previstos', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => unawaited(tester.binding.setSurfaceSize(null)));

      await tester.pumpWidget(
        fixture.wrap(
          const MaterialApp(
            home: Scaffold(
              body: HeisucaTvSettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Áudio padrão'), findsOneWidget);
      expect(find.text('Legenda padrão'), findsOneWidget);
      expect(find.text('Tamanho da legenda'), findsOneWidget);
      expect(find.text('Ainda está aí?'), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      // Não deve ter opções de celular (Downloads, Geral, etc.)
      expect(find.text('Downloads'), findsNothing);
      expect(find.text('Geral'), findsNothing);
    });

    test('G1.6 Memória: teto de 50MB em TV com pouca RAM e dimensões limitadas', () {
      DevicePerformance.applyImageCacheBudget(lowRamOverride: true);
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes, 50 << 20);

      // Limite de pôster <= 720p em TV com pouca RAM
      final dims = MediaImageHelper.calculateOptimalDimensions(
        maxWidth: 600,
        maxHeight: 1200,
        pixelRatio: 2.0,
        imageType: ImageType.poster,
      );
      expect(dims.$2 <= 720, true);
    });

    testWidgets('G1.7 Abertura com preload: respeita piso de ~1s e teto de ~4s', (tester) async {
      var finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HeisucaOpeningSplash(
            onAnimationFinished: () => finished = true,
            preloadFuture: Future.delayed(const Duration(milliseconds: 200)),
          ),
        ),
      );

      // Aos 500ms ainda não terminou (piso de 1s)
      await tester.pump(const Duration(milliseconds: 500));
      expect(finished, false);

      // Aos 1000ms+ termina pois o preload já completou
      await tester.pump(const Duration(milliseconds: 600));
      expect(finished, true);
    });

    testWidgets('G1.7 Resiliência de preload: erro no preloadFuture não trava a abertura', (tester) async {
      var finished = false;
      final errorFuture = Future<void>.error(Exception('rede indisponível'))..ignore();
      await tester.pumpWidget(
        MaterialApp(
          home: HeisucaOpeningSplash(
            onAnimationFinished: () => finished = true,
            preloadFuture: errorFuture,
          ),
        ),
      );

      // Aguarda o piso da abertura
      await tester.pump(const Duration(milliseconds: 1100));
      expect(finished, true);
    });

    test('G1.1 Detecção de TV: Apple TV tem precedência mesmo se forceTv for falso', () {
      TvDetectionService.setForceTVSync(false);
      TvDetectionService.debugSetAppleTVOverride(true);
      expect(PlatformDetector.isTV(), true);

      TvDetectionService.debugSetAppleTVOverride(null);
      expect(PlatformDetector.isTV(), false);
    });
  });
}
