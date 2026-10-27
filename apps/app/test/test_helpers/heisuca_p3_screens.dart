import 'package:flutter/material.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/services/settings_service.dart' as settings;
import 'package:heisuca/heisuca/heisuca_home_screen.dart';
import 'package:heisuca/heisuca/heisuca_library_screen.dart';
import 'package:heisuca/heisuca/heisuca_login_screen.dart';
import 'package:heisuca/heisuca/heisuca_news.dart';
import 'package:heisuca/heisuca/heisuca_profile_screen.dart';
import 'package:heisuca/heisuca/heisuca_settings_screen.dart';
import 'package:heisuca/heisuca/heisuca_title_sheet.dart';
import 'package:heisuca/heisuca/heisuca_context_menu.dart';
import 'package:heisuca/heisuca/heisuca_floating_island.dart';
import 'package:heisuca/heisuca/kids/heisuca_kids_flow.dart';
import 'package:heisuca/screens/search_screen.dart';
import 'package:heisuca/screens/downloads/downloads_screen.dart';
import 'package:heisuca/screens/settings/about_screen.dart';
import 'package:heisuca/screens/profile/profile_switch_screen.dart';
import 'package:heisuca/screens/settings/settings_screen.dart';
import 'package:heisuca/screens/settings/general_settings_screen.dart';
import 'package:heisuca/screens/settings/appearance_settings_screen.dart';
import 'package:heisuca/screens/settings/playback_settings_screen.dart';
import 'package:heisuca/screens/settings/subtitle_styling_screen.dart';
import 'package:heisuca/screens/settings/services_settings_screen.dart';
import 'package:heisuca/screens/settings/mpv_config_screen.dart';
import 'package:heisuca/screens/settings/external_player_screen.dart';
import 'package:heisuca/screens/settings/licenses_screen.dart';
import 'heisuca_p3_fixture.dart';

/// Telas reais da matriz P3, na ordem dos casos.
final heisucaP3Screens = <String, Widget Function(HeisucaP3Fixture)> {
  'login': (_) => const HeisucaLoginScreen(),
  'inicio': (_) => const HeisucaHomeScreen(),
  'biblioteca': (_) => const HeisucaLibraryScreen(),
  'busca': (_) => const SearchScreen(),
  'baixados': (_) => const DownloadsScreen(),
  'voce': (_) => const HeisucaProfileScreen(),
  'config-geral': (_) => const HeisucaSettingsScreen(),
  'config-avancada': (_) => const HeisucaSettingsScreen(),
  'sobre': (_) => const AboutScreen(),
  'novidades': (_) => const HeisucaNewsScreen(),
  'kids-config': (_) => const HeisucaKidsSetupScreen(),
  'ficha-filme': (f) => Builder(builder: (c) => HeisucaTitleSheet(hostContext: c, item: f.movie)),
  'ficha-serie': (f) => Builder(builder: (c) => HeisucaTitleSheet(hostContext: c, item: f.show)),
  'perfis': (_) => const ProfileSwitchScreen(),
  'config-completas': (_) => const SettingsScreen(),
  'config-basicas': (_) => const GeneralSettingsScreen(),
  'config-aparencia': (_) => const AppearanceSettingsScreen(),
  'config-reproducao': (_) => const PlaybackSettingsScreen(),
  'config-reproducao-avancada': (_) => const PlaybackSettingsScreen(cgflixTechnical: true),
  'config-legendas': (_) => const SubtitleStylingScreen(),
  'config-servicos': (_) => const ServicesSettingsScreen(),
  'config-mpv': (_) => const MpvConfigScreen(),
  'config-player-externo': (_) => const ExternalPlayerScreen(),
  'licencas': (_) => const LicensesScreen(),
  'barra-abas': (_) => Scaffold(body: Stack(children: [HeisucaFloatingIsland(currentIndex: 0, onDestinationSelected: (_) {})])),
  'menu-titulo': (f) => Scaffold(body: HeisucaContextMenu(item: f.movie)),
};

/// Telas que abrem como rota inicial; as demais empilham em '/alvo' (com botão voltar).
const heisucaP3RootScreens = {'login', 'inicio', 'biblioteca', 'busca', 'baixados', 'voce', 'barra-abas'};

/// MaterialApp da matriz P3: tema, escala de fonte, animações desligadas e a cena
/// marcada com `p3-scene` dentro de [boundary] (RepaintBoundary da captura).
Widget heisucaP3App(HeisucaP3Fixture f, String screen, settings.ThemeMode mode, double scale, GlobalKey boundary) {
  final build = heisucaP3Screens[screen]!;
  final isRoot = heisucaP3RootScreens.contains(screen);
  return f.wrap(MaterialApp(
    theme: mode == settings.ThemeMode.light ? cgflixLightTheme() : cgflixDarkTheme(mode),
    debugShowCheckedModeBanner: false,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: RepaintBoundary(key: boundary, child: child!)),
    initialRoute: isRoot ? '/' : '/alvo',
    routes: {
      '/': (_) => isRoot
          ? f.scope(KeyedSubtree(key: const ValueKey('p3-scene'), child: build(f)))
          : const Scaffold(body: SizedBox()),
      '/alvo': (_) => f.scope(KeyedSubtree(key: const ValueKey('p3-scene'), child: build(f))),
    },
  ));
}
