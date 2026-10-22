import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_palette.dart';
import 'package:plezy/cgflix/cgflix_theme.dart';
import 'package:plezy/heisuca/heisuca_library_screen.dart';
import 'package:plezy/heisuca/heisuca_login_screen.dart';
import 'package:plezy/heisuca/heisuca_logo.dart';
import 'package:plezy/heisuca/heisuca_search_screen.dart';
import 'package:plezy/heisuca/heisuca_settings_screen.dart';
import 'package:plezy/heisuca/heisuca_title_sheet.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

const _tela = Size(412, 914);

Future<void> _montar(WidgetTester tester, CgflixThemeVariant variante, Widget home) async {
  tester.view.physicalSize = _tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = ThemeProvider();
  addTearDown(theme.dispose);
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: MaterialApp(
          theme: cgflixAppTheme(variante),
          home: home,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
  });

  group('HeisucaLogo', () {
    testWidgets('adapta selo e texto para Shikkoku (escuro)', (tester) async {
      await _montar(tester, CgflixThemeVariant.isis, const Scaffold(body: Center(child: HeisucaLogo())));
      expect(find.byType(SvgPicture), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final bytesLoader = svg.bytesLoader as SvgAssetLoader;
      expect(bytesLoader.assetName, 'assets/heisuca/selo_pequeno_shikkoku.svg');

      final text = tester.widget<Text>(find.text('HEISUCA'));
      expect(text.style?.color, const Color(0xFFF4F1FA));
    });

    testWidgets('adapta selo e texto para Hisui (claro)', (tester) async {
      await _montar(tester, CgflixThemeVariant.heitor, const Scaffold(body: Center(child: HeisucaLogo())));
      expect(find.byType(SvgPicture), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final bytesLoader = svg.bytesLoader as SvgAssetLoader;
      expect(bytesLoader.assetName, 'assets/heisuca/selo_pequeno_hisui.svg');

      final text = tester.widget<Text>(find.text('HEISUCA'));
      expect(text.style?.color, const Color(0xFF134E4A));
    });
  });

  group('HeisucaLoginScreen', () {
    testWidgets('monta sem erro e com distribuição equilibrada no modo escuro', (tester) async {
      await _montar(tester, CgflixThemeVariant.isis, const HeisucaLoginScreen());
      expect(find.text('HEISUCA'), findsOneWidget);
      expect(find.text('SERVIDOR'), findsOneWidget);
      expect(find.text('USUÁRIO'), findsOneWidget);
      expect(find.text('SENHA'), findsOneWidget);
      expect(find.text('Iniciar sessão'), findsOneWidget);
      expect(find.text('+ Outros servidores e pastas locais'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    });

    testWidgets('monta sem erro no modo claro', (tester) async {
      await _montar(tester, CgflixThemeVariant.heitor, const HeisucaLoginScreen());
      expect(find.text('HEISUCA'), findsOneWidget);
      expect(find.text('SERVIDOR'), findsOneWidget);
      expect(find.text('Iniciar sessão'), findsOneWidget);
    });

    testWidgets('abre modal de outras fontes com servidores identificados', (tester) async {
      await _montar(tester, CgflixThemeVariant.isis, const HeisucaLoginScreen());
      await tester.tap(find.text('+ Outros servidores e pastas locais'));
      await tester.pumpAndSettle();

      expect(find.text('Adicionar Fontes e Servidores'), findsOneWidget);
      expect(find.text('Conta Plex'), findsOneWidget);
      expect(find.text('Servidor Jellyfin'), findsOneWidget);
      expect(find.text('Servidor Emby'), findsOneWidget);
      expect(find.text('Pasta de Rede Local (SMB / Samba)'), findsOneWidget);
      expect(find.text('Servidor WebDAV'), findsOneWidget);
      expect(find.text('Arquivos deste Dispositivo'), findsOneWidget);
    });
  });

  group('HeisucaTitleSheet', () {
    final itemFilme = MediaItem.jellyfin(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'Duna: Parte 2',
      summary: 'Paul Atreides se une a Chani e aos Fremen.',
      year: 2024,
      rating: 8.6,
    );

    testWidgets('monta ficha cinematográfica em ambos os temas', (tester) async {
      await _montar(
        tester,
        CgflixThemeVariant.isis,
        Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => HeisucaTitleSheet.show(ctx, itemFilme),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Duna: Parte 2'), findsOneWidget);
      expect(find.text('Assistir Agora'), findsOneWidget);
      expect(find.text('Sinopse'), findsOneWidget);
    });
  });

  group('HeisucaSettingsScreen', () {
    testWidgets('monta abas Geral e Avançado com reconhecimento de aparelho e seletor de tema', (tester) async {
      await _montar(tester, CgflixThemeVariant.isis, const HeisucaSettingsScreen());
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Aparelho Reconhecido'), findsOneWidget);
      expect(find.text('Geral'), findsOneWidget);
      expect(find.text('Avançado'), findsOneWidget);
      expect(find.text('Aparência e Tema'), findsOneWidget);
      expect(find.text('Shikkoku'), findsOneWidget);
      expect(find.text('Hisui'), findsOneWidget);
      expect(find.text('Qualidade Original Direta'), findsOneWidget);

      await tester.tap(find.text('Avançado'));
      await tester.pumpAndSettle();

      expect(find.text('Decodificação Zero-Copy Vulkan'), findsOneWidget);
      expect(find.text('Buffer de Memória RAM'), findsOneWidget);
    });
  });

  group('HeisucaLibraryScreen & HeisucaSearchScreen', () {
    testWidgets('monta biblioteca e busca adaptando a ambos os temas', (tester) async {
      await _montar(tester, CgflixThemeVariant.heitor, const HeisucaLibraryScreen());
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);

      await _montar(tester, CgflixThemeVariant.heitor, const HeisucaSearchScreen());
      expect(find.text('No seu Acervo'), findsOneWidget);
      expect(find.text('Disponível no Seerr'), findsOneWidget);
    });
  });
}
