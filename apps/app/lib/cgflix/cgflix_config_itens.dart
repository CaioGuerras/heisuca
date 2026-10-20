// Itens da tela principal das Configurações (refino 2b, versão 1.6.1) e a subtela genérica
// (Baixados, Avançado). Cada item mostra no resumo o VALOR ATUAL ("Português", "Original",
// "Mostrar o botão"), como pede o padrão de Configurações do Android.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/account_preferences.dart';
import '../media/account_preferences_target.dart';
import '../models/transcode_quality_preset.dart';
import '../screens/settings/playback_settings_screen.dart';
import '../screens/settings/settings_utils.dart';
import '../screens/settings/subtitle_styling_screen.dart';
import '../services/account_preferences_repository.dart';
import '../services/settings_mutation_service.dart';
import '../services/settings_service.dart';
import '../utils/language_codes.dart';
import '../utils/quality_preset_labels.dart';
import '../widgets/setting_tile.dart';
import '../widgets/settings_builder.dart';
import '../widgets/settings_page.dart';
import 'cgflix_idiomas.dart';
import 'conta/cgflix_conta.dart';
import 'conta/cgflix_minha_conta_screen.dart';

/// Testes do upstream: mostra o conteúdo das subtelas (Baixados, Avançado, a parte técnica de
/// Ao assistir) direto na tela, como era antes, para acharem as linhas sem navegar.
bool cgflixSettingsDebugInline = false;

/// Subtela das Configurações montada com linhas de outra tela. [refresh] reconstrói a lista quando
/// a tela de origem muda (ex.: a pasta dos baixados foi trocada).
class CgflixSettingsSubpage extends StatelessWidget {
  const CgflixSettingsSubpage({super.key, required this.title, required this.builder, this.refresh});

  final String title;
  final List<Widget> Function(BuildContext context) builder;
  final Listenable? refresh;

  @override
  Widget build(BuildContext context) {
    Widget page(BuildContext context) =>
        SettingsPage(title: Text(title), children: [...builder(context), const SizedBox(height: 24)]);
    final listenable = refresh;
    if (listenable == null) return page(context);
    return ListenableBuilder(listenable: listenable, builder: (context, _) => page(context));
  }
}

/// Abre uma [CgflixSettingsSubpage]. O título da subtela é o rótulo do item que a abriu.
Future<void> cgflixOpenSettingsSubpage(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext context) builder,
  Listenable? refresh,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: RouteSettings(name: 'cgflix/configuracoes/$title'),
    builder: (_) => CgflixSettingsSubpage(title: title, builder: builder, refresh: refresh),
  ),
);

// ---------------------------------------------------------------------------
// Conta

/// "Minha conta" (foto e senha do Jellyfin). Só aparece com uma conta Jellyfin conectada.
class CgflixMinhaContaTile extends StatelessWidget {
  const CgflixMinhaContaTile({super.key, required this.conta});

  final CgflixConta conta;

  @override
  Widget build(BuildContext context) => SettingNavigationTile(
    key: const ValueKey('cgflix-config-minha-conta'),
    icon: Symbols.account_circle_rounded,
    title: 'Minha conta',
    subtitle: 'Foto e senha',
    onTap: () => cgflixAbrirMinhaConta(context, conta),
  );
}

// ---------------------------------------------------------------------------
// Aparência

/// Nome de cada idioma do app, escrito no próprio idioma (o português com o país).
String cgflixAppLocaleName(AppLocale locale) => switch (locale) {
  AppLocale.pt => 'Português (Brasil)',
  AppLocale.en => 'English',
  AppLocale.sv => 'Svenska',
  AppLocale.fr => 'Français',
  AppLocale.it => 'Italiano',
  AppLocale.nl => 'Nederlands',
  AppLocale.de => 'Deutsch',
  AppLocale.hu => 'Magyar',
  AppLocale.zh => '简体中文',
  AppLocale.zhHant => '繁體中文',
  AppLocale.ko => '한국어',
  AppLocale.es => 'Español',
  AppLocale.ja => '日本語',
  AppLocale.ru => 'Русский',
  AppLocale.pl => 'Polski',
  AppLocale.da => 'Dansk',
  AppLocale.nb => 'Norsk bokmål',
  AppLocale.bg => 'Български',
  AppLocale.tr => 'Türkçe',
  AppLocale.az => 'Azərbaycanca',
  AppLocale.kk => 'Қазақша',
  AppLocale.uz => 'Oʻzbekcha',
};

/// Item da Aparência que abre a subtela do upstream (cartões, bibliotecas, efeitos): o rótulo é
/// igual ao título da subtela.
const cgflixAppearanceMoreTitle = 'Mais opções de aparência';
const cgflixAppearanceMoreSummary = 'Cartões, bibliotecas e efeitos visuais';

/// "Idioma do app" (saiu da subtela Geral, que deixou de existir no celular).
class CgflixAppLanguageTile extends StatelessWidget {
  const CgflixAppLanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final current = LocaleSettings.currentLocale;
    return SettingNavigationTile(
      key: const ValueKey('cgflix-config-idioma-app'),
      icon: Symbols.language_rounded,
      title: 'Idioma do app',
      subtitle: cgflixAppLocaleName(current),
      onTap: () async {
        // Português primeiro; os outros na ordem do upstream.
        final locales = [AppLocale.pt, ...AppLocale.values.where((l) => l != AppLocale.pt)];
        final picked = await showSelectionDialog<AppLocale>(
          context: context,
          title: 'Idioma do app',
          options: [for (final l in locales) DialogOption(value: l, title: cgflixAppLocaleName(l))],
          currentValue: current,
        );
        if (picked != null && context.mounted) {
          await const SettingsMutationService().write(context, SettingsService.appLocale, picked.value);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Ao assistir

/// "Áudio e legenda": abre as preferências da conta; o resumo mostra os idiomas escolhidos.
class CgflixAudioLegendaTile extends StatefulWidget {
  const CgflixAudioLegendaTile({
    super.key,
    required this.target,
    required this.repository,
    required this.onTap,
    required this.fallback,
  });

  /// Resumo enquanto os idiomas não chegam do servidor (ou sem rede).
  final String fallback;

  /// Conta cujos idiomas aparecem no resumo (a primeira, se houver mais de uma).
  final AccountPreferenceTarget target;
  final AccountPreferencesRepository repository;
  final VoidCallback onTap;

  @override
  State<CgflixAudioLegendaTile> createState() => _CgflixAudioLegendaTileState();
}

class _CgflixAudioLegendaTileState extends State<CgflixAudioLegendaTile> {
  StreamSubscription<Object?>? _changes;
  AccountPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _changes = widget.repository.changes.listen((_) => _read());
    _read();
  }

  void _read() {
    final ref = widget.target.ref;
    final cached = widget.repository.cached(ref);
    if (cached != null) {
      if (mounted) setState(() => _prefs = cached);
      return;
    }
    widget.repository
        .load(ref)
        .then((p) {
          if (mounted) setState(() => _prefs = p);
        })
        .catchError((Object _) {}); // sem rede: o resumo fica genérico
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    String name(String? code, String none) =>
        code == null || code.isEmpty ? none : (LanguageCodes.getLanguageName(code) ?? code);
    final summary = prefs == null
        ? widget.fallback
        : 'Áudio: ${name(prefs.preferredAudioLanguageCode1, cgflixOriginalAudioLabel)} · '
              'Legenda: ${name(prefs.preferredSubtitleLanguageCode1, t.accountPreferences.noPreference)}';
    return SettingNavigationTile(
      key: const ValueKey('cgflix-config-audio-legenda'),
      icon: Symbols.voice_selection_rounded,
      title: 'Áudio e legenda',
      subtitle: summary,
      onTap: widget.onTap,
    );
  }
}

/// Nome da cor da legenda para o resumo e para o leitor de tela.
const cgflixSubtitleColors = <String, String>{
  '#FFFFFF': 'Branco',
  '#FFFF00': 'Amarelo',
  '#000000': 'Preto',
  '#808080': 'Cinza',
  '#00FFFF': 'Ciano',
  '#00FF00': 'Verde',
};

String cgflixSubtitleColorName(String hex) => cgflixSubtitleColors[hex.toUpperCase()] ?? 'Personalizada';

/// "Estilo das legendas": resumo com o tamanho e a cor atuais.
class CgflixSubtitleStyleTile extends StatelessWidget {
  const CgflixSubtitleStyleTile({super.key});

  @override
  Widget build(BuildContext context) => SettingsBuilder(
    prefs: const [SettingsService.subtitleFontSize, SettingsService.subtitleTextColor],
    builder: (context) {
      final svc = SettingsService.instance;
      final size = svc.read(SettingsService.subtitleFontSize);
      final color = cgflixSubtitleColorName(svc.read(SettingsService.subtitleTextColor));
      return Semantics(
        hint: t.settings.subtitleStylingDescription,
        child: SettingNavigationTile(
          key: const ValueKey('cgflix-config-estilo-legendas'),
          icon: Symbols.subtitles_rounded,
          title: t.settings.subtitleStyling,
          subtitle: 'Tamanho $size · Texto ${color.toLowerCase()}',
          destinationBuilder: (_) => const SubtitleStylingScreen(),
        ),
      );
    },
  );
}

String cgflixSkipModeLabel(SkipMarkerMode mode) => switch (mode) {
  SkipMarkerMode.off => t.settings.skipMarkerModeOff,
  SkipMarkerMode.button => t.settings.skipMarkerModeButton,
  SkipMarkerMode.auto => t.settings.skipMarkerModeAuto,
};

/// "Ao assistir": abre a subtela de mesmo nome (pular abertura e créditos, próximo episódio,
/// gestos, janelinha); o resumo mostra o modo atual de pular abertura.
class CgflixSkipTile extends StatelessWidget {
  const CgflixSkipTile({super.key});

  @override
  Widget build(BuildContext context) => SettingsBuilder(
    prefs: const [SettingsService.skipIntroMode, SettingsService.skipCreditsMode],
    builder: (context) {
      final svc = SettingsService.instance;
      final intro = svc.read(SettingsService.skipIntroMode);
      final credits = svc.read(SettingsService.skipCreditsMode);
      final skip = intro == credits
          ? 'Pular abertura e créditos: ${cgflixSkipModeLabel(intro)}'
          : 'Pular abertura: ${cgflixSkipModeLabel(intro)}';
      return SettingNavigationTile(
        key: const ValueKey('cgflix-config-ao-assistir'),
        icon: Symbols.play_circle_rounded,
        title: t.settings.videoPlayback,
        subtitle: '$skip · ${t.settings.videoPlaybackDescription}',
        destinationBuilder: (_) => const PlaybackSettingsScreen(),
      );
    },
  );
}

/// Cabeçalho do grupo de vídeo na tela principal (o item "Ao assistir" fica dentro dele).
const cgflixWatchHeader = 'Assistir';

/// "Qualidade": a padrão (Original, que é o que o servidor do CGFLIX toca).
class CgflixQualityTile extends StatelessWidget {
  const CgflixQualityTile({super.key});

  @override
  Widget build(BuildContext context) => SettingSelectionTile<TranscodeQualityPreset>(
    key: const ValueKey('cgflix-config-qualidade'),
    pref: SettingsService.defaultQualityPreset,
    icon: Symbols.high_quality_rounded,
    title: t.settings.defaultQualityTitle,
    subtitleBuilder: qualityPresetLabel,
    options: TranscodeQualityPreset.displayOrder
        .map((p) => DialogOption(value: p, title: qualityPresetLabel(p)))
        .toList(),
  );
}

/// "Qualidade nos dados móveis" (só celular e tablet, que têm 4G/5G).
class CgflixCellularQualityTile extends StatelessWidget {
  const CgflixCellularQualityTile({super.key});

  @override
  Widget build(BuildContext context) => SettingSelectionTile<TranscodeQualityPreset?>(
    key: const ValueKey('cgflix-config-dados-moveis'),
    pref: SettingsService.cellularQualityPreset,
    icon: Symbols.signal_cellular_alt_rounded,
    title: 'Qualidade nos dados móveis',
    subtitleBuilder: (p) => p == null ? t.settings.cellularQualitySameAsDefault : qualityPresetLabel(p),
    options: [
      DialogOption<TranscodeQualityPreset?>(value: null, title: t.settings.cellularQualitySameAsDefault),
      ...TranscodeQualityPreset.displayOrder.map(
        (p) => DialogOption<TranscodeQualityPreset?>(value: p, title: qualityPresetLabel(p)),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Avançado › Legendas (técnico): estilo ASS e resolução, que saíram de "Estilo das legendas".

String cgflixAssOverrideLabel(SubAssOverride value) => switch (value) {
  SubAssOverride.no => t.common.no,
  SubAssOverride.yes => t.common.yes,
  SubAssOverride.scale => t.subtitlingStyling.overrideScale,
  SubAssOverride.force => t.subtitlingStyling.overrideForce,
  SubAssOverride.strip => t.subtitlingStyling.overrideStrip,
};

String cgflixRenderResolutionLabel(SubtitleRenderResolution value) => switch (value) {
  SubtitleRenderResolution.screen => t.subtitlingStyling.renderResolutionScreen,
  SubtitleRenderResolution.video => t.subtitlingStyling.renderResolutionVideo,
  SubtitleRenderResolution.threeQuarter => '¾',
  SubtitleRenderResolution.half => '½',
  SubtitleRenderResolution.third => '⅓',
  SubtitleRenderResolution.quarter => '¼',
};

/// As duas linhas técnicas de legenda (iguais às do upstream, só mudaram de tela).
List<Widget> cgflixSubtitleTechTiles() => [
  SettingSelectionTile<SubAssOverride>(
    pref: SettingsService.subAssOverride,
    icon: Symbols.subtitles_rounded,
    title: t.subtitlingStyling.assOverride,
    subtitleBuilder: cgflixAssOverrideLabel,
    options: SubAssOverride.values.map((v) => DialogOption(value: v, title: cgflixAssOverrideLabel(v))).toList(),
  ),
  if (Platform.isIOS || Platform.isAndroid)
    SettingSelectionTile<SubtitleRenderResolution>(
      pref: SettingsService.subtitleRenderResolution,
      icon: Symbols.aspect_ratio_rounded,
      title: t.subtitlingStyling.renderResolution,
      subtitleBuilder: cgflixRenderResolutionLabel,
      options: [
        for (final v
            in Platform.isIOS
                ? const [SubtitleRenderResolution.screen, SubtitleRenderResolution.video]
                : const [
                    SubtitleRenderResolution.screen,
                    SubtitleRenderResolution.threeQuarter,
                    SubtitleRenderResolution.half,
                    SubtitleRenderResolution.third,
                    SubtitleRenderResolution.quarter,
                  ])
          DialogOption(value: v, title: cgflixRenderResolutionLabel(v)),
      ],
    ),
];
