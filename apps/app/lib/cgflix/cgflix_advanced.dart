// Configurações › Avançado (refino 2b, versão 1.6.1): uma subtela no fim da tela principal, com
// tudo o que é técnico agrupado por assunto (cabeçalhos). Nada foi removido do app: o que saiu da
// frente das Configurações veio para cá.
//   - Recursos extras: Assistir juntos, Controle remoto (saíram da Início na Etapa 1E);
//   - Ao assistir (técnico): Reprodução avançada (reprodutor, decodificação, HDR, áudio, buffer),
//     opções do mpv, detectar abertura pelos capítulos, nomes dos capítulos, espera antes de pular;
//   - Legendas (técnico): estilo ASS (anime) e resolução da legenda;
//   - Este aparelho › Geral: forçar modo TV, perfil ao abrir, som de abertura, tela cheia (computador).
// Contas e servidores, controles, atualizações, diagnóstico e cópia de segurança são montados em
// `settings_screen.dart` (usam o estado daquela tela).

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../screens/companion_remote/mobile_remote_screen.dart';
import '../screens/settings/general_settings_screen.dart';
import '../screens/settings/mpv_config_screen.dart';
import '../screens/settings/playback_settings_screen.dart';
import '../services/settings_service.dart';
import '../utils/platform_detector.dart';
import '../watch_together/watch_together.dart';
import '../widgets/companion_remote/remote_session_dialog.dart';
import '../widgets/setting_tile.dart';
import '../widgets/settings_section.dart';
import 'cgflix_config_itens.dart';

/// Rótulo do item da tela principal e título da subtela (iguais, como pede o padrão do Android).
const cgflixAdvancedSummary = 'Contas e servidores, controle remoto e opções técnicas';

/// Recursos extras: Assistir juntos e Controle remoto.
class CgflixAdvancedFeatures extends StatelessWidget {
  const CgflixAdvancedFeatures({super.key, this.extra = const []});

  /// Linhas a mais no fim do grupo (atalhos de teclado e controle pelo celular, quando houver).
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformDetector.shouldActAsRemoteHost(context);
    void openRemote() {
      if (isDesktop) {
        RemoteSessionDialog.show(context);
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRemoteScreen()));
      }
    }

    return SettingsGroup(
      title: 'Recursos extras',
      children: [
        SettingNavigationTile(
          icon: Symbols.group_rounded,
          title: 'Assistir juntos',
          subtitle: 'Assista ao mesmo filme ou série ao mesmo tempo que outra pessoa, cada um no seu aparelho.',
          destinationBuilder: (_) => const WatchTogetherScreen(),
        ),
        SettingNavigationTile(
          icon: Symbols.phone_android_rounded,
          title: 'Controle remoto',
          // Explica o limite: não é um controle universal de TV.
          subtitle:
              'Controla OUTRO aparelho com o CGFLIX aberto, na mesma rede Wi-Fi e na mesma conta. '
              'Não reconhece TV comum.',
          onTap: openRemote,
        ),
        ...extra,
      ],
    );
  }
}

/// Ao assistir (técnico): Reprodução avançada, mpv e a parte técnica de Pular abertura.
class CgflixAdvancedPlayback extends StatelessWidget {
  const CgflixAdvancedPlayback({super.key});

  @override
  Widget build(BuildContext context) => SettingsGroup(
    title: 'Ao assistir (técnico)',
    children: [
      SettingNavigationTile(
        key: const ValueKey('cgflix-avancado-reproducao'),
        icon: Symbols.settings_video_camera_rounded,
        title: PlaybackSettingsScreen.cgflixTechnicalTitle,
        subtitle: 'Reprodutor, aceleração de vídeo, HDR, áudio e memória',
        destinationBuilder: (_) => const PlaybackSettingsScreen(cgflixTechnical: true),
      ),
      SettingNavigationTile(
        icon: Symbols.terminal_rounded,
        title: 'Opções do mpv',
        subtitle: 'Ajustes técnicos do reprodutor de vídeo. Só mexa se souber o que está fazendo.',
        destinationBuilder: (_) => const MpvConfigScreen(),
      ),
      SettingNumberTile(
        pref: SettingsService.autoSkipDelay,
        icon: Symbols.timer_rounded,
        title: t.settings.autoSkipDelay,
        subtitleBuilder: (v) => t.settings.autoSkipDelayDescription(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
      ),
      SettingSwitchTile(
        pref: SettingsService.forceSkipMarkerFallback,
        icon: Symbols.bookmarks_rounded,
        title: t.settings.forceSkipMarkerFallback,
        subtitle: t.settings.forceSkipMarkerFallbackDescription,
      ),
      SettingRegexTile(
        pref: SettingsService.introPattern,
        icon: Symbols.match_case_rounded,
        title: t.settings.introPattern,
        subtitle: t.settings.introPatternDescription,
        defaultValue: SettingsService.defaultIntroPattern,
      ),
      SettingRegexTile(
        pref: SettingsService.creditsPattern,
        icon: Symbols.match_case_rounded,
        title: t.settings.creditsPattern,
        subtitle: t.settings.creditsPatternDescription,
        defaultValue: SettingsService.defaultCreditsPattern,
      ),
    ],
  );
}

/// Legendas (técnico): estilo ASS e resolução (saíram de "Estilo das legendas").
class CgflixAdvancedSubtitles extends StatelessWidget {
  const CgflixAdvancedSubtitles({super.key});

  @override
  Widget build(BuildContext context) =>
      SettingsGroup(title: '${t.settings.subtitles} (técnico)', children: cgflixSubtitleTechTiles());
}

/// Este aparelho › Geral: a subtela Geral do upstream (forçar modo TV, perfil ao abrir, seção
/// inicial na TV, tela cheia no computador) e o som de abertura. O idioma do app saiu dela e foi
/// para Aparência, na tela principal.
class CgflixAdvancedGeneral extends StatelessWidget {
  const CgflixAdvancedGeneral({super.key});

  @override
  Widget build(BuildContext context) => SettingsGroup(
    title: 'Este aparelho',
    children: [
      SettingNavigationTile(
        key: const ValueKey('cgflix-avancado-geral'),
        icon: Symbols.devices_rounded,
        title: t.settings.general,
        subtitle: t.settings.generalDescription,
        destinationBuilder: (_) => const GeneralSettingsScreen(),
      ),
    ],
  );
}
