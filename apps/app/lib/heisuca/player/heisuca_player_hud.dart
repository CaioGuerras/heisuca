// HUD do player no celular (Esboço 07A/07B): ações rápidas em pílulas no topo direito e, embaixo
// da linha do tempo, uma linha de texto "Áudio: … · Legendas: … · Episódios · Ajustes".
// Tudo chama os MESMOS callbacks e painéis reais do VideoPlayerScreen (TrackControlsState,
// VideoSettingsSheet, TrackSheet); aqui só muda a disposição. Tablet, desktop e TV seguem a régua.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../cgflix/cgflix_palette.dart';
import '../../mpv/mpv.dart';
import '../../utils/codec_utils.dart';
import '../../utils/track_label_builder.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/video_controls/models/track_controls_state.dart';
import '../../widgets/video_controls/sheets/track_sheet.dart';
import '../../widgets/video_controls/sheets/video_settings_sheet.dart';

const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

String heisucaBoxFitLabel(int mode) => switch (mode) { 1 => 'Preencher', 2 => 'Esticar', _ => 'Original' };

String heisucaRateLabel(double rate) {
  final text = rate == rate.roundToDouble() ? rate.toStringAsFixed(1) : rate.toString();
  return '${text.replaceAll('.', ',')}x';
}

/// Ícones de avanço/retrocesso que dizem a verdade sobre o salto configurado (não "10" fixo).
IconData heisucaSeekIcon(int seconds, {required bool forward}) => switch ((seconds, forward)) {
  (5, false) => Symbols.replay_5_rounded,
  (10, false) => Symbols.replay_10_rounded,
  (30, false) => Symbols.replay_30_rounded,
  (5, true) => Symbols.forward_5_rounded,
  (10, true) => Symbols.forward_10_rounded,
  (30, true) => Symbols.forward_30_rounded,
  (_, false) => Symbols.replay_rounded,
  (_, true) => Symbols.forward_media_rounded,
};

void _openSheet(BuildContext context, TrackControlsState state, WidgetBuilder builder) {
  state.onCancelAutoHide?.call();
  OverlaySheetController.of(context).show(builder: builder).whenComplete(() => state.onStartAutoHide?.call());
}

/// Pílula de vidro escuro do topo (07A: "20:9 ▾", "1.0x ▾") ou botão redondo só com ícone.
class HeisucaPlayerPill extends StatelessWidget {
  const HeisucaPlayerPill({super.key, this.label, this.icon, required this.semanticLabel, this.onTap, this.active = false});
  final String? label;
  final IconData? icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final accent = context.cgflix.accent;
    return Semantics(button: true, label: semanticLabel, value: label, child: Material(
      color: Colors.black.withValues(alpha: .38),
      shape: StadiumBorder(side: BorderSide(color: active ? accent : Colors.white.withValues(alpha: .22), width: 1.2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(
        padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 14, vertical: 9),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, size: 20, color: active ? accent : Colors.white),
          if (icon != null && label != null) const SizedBox(width: 6),
          if (label != null) Text(label!, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()])),
          if (label != null && onTap != null) const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Colors.white70),
        ]),
      )),
    ));
  }
}

/// Ações rápidas do topo direito: proporção, velocidade, janelinha, rotação e travar tela.
class HeisucaPlayerQuickActions extends StatelessWidget {
  const HeisucaPlayerQuickActions({super.key, required this.player, required this.state, this.compact = false});
  final Player player;
  final TrackControlsState state;
  /// Retrato: só ícones, para caber ao lado do título.
  final bool compact;


  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (state.onCycleBoxFitMode != null) HeisucaPlayerPill(
        icon: compact ? Symbols.aspect_ratio_rounded : null,
        label: compact ? null : heisucaBoxFitLabel(state.boxFitMode),
        semanticLabel: 'Proporção da imagem: ${heisucaBoxFitLabel(state.boxFitMode)}',
        onTap: state.onCycleBoxFitMode),
      if (state.onTogglePIPMode != null) HeisucaPlayerPill(icon: Symbols.picture_in_picture_alt_rounded,
        semanticLabel: 'Janelinha', onTap: state.onTogglePIPMode),
      if (state.onToggleRotationLock != null) HeisucaPlayerPill(
        icon: state.isRotationLocked ? Symbols.screen_lock_rotation_rounded : Symbols.screen_rotation_rounded,
        active: state.isRotationLocked,
        semanticLabel: state.isRotationLocked ? 'Destravar rotação' : 'Travar rotação', onTap: state.onToggleRotationLock),
      if (state.onToggleScreenLock != null) HeisucaPlayerPill(icon: Symbols.lock_rounded,
        semanticLabel: 'Travar tela', onTap: state.onToggleScreenLock),
    ];
    return Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);
  }
}

/// Caio, 24/10: áudio/legendas, velocidade e ajustes no grupo à direita; episódios ficam no logo.
class HeisucaPlayerTabs extends StatelessWidget {
  const HeisucaPlayerTabs({super.key, required this.player, required this.state, this.onEpisodes, this.episodesLabel, this.onNext});
  final Player player;
  final TrackControlsState state;
  final VoidCallback? onEpisodes;
  final String? episodesLabel;
  final VoidCallback? onNext;

  static String? audioValue(Tracks? tracks, TrackSelection selection) {
    final audio = selection.audio;
    if (audio == null || audio.id == AudioTrack.off.id) return null;
    final index = tracks?.audio.indexWhere((t) => t.id == audio.id) ?? -1;
    final label = TrackLabelBuilder.audioLabel(title: audio.title, language: audio.language, codec: audio.codec,
      channels: audio.channelsCount, index: index < 0 ? 0 : index);
    final channels = CodecUtils.formatAudioChannels(audio.channelsCount);
    return channels == null || label.primary.contains(channels) ? label.primary : '${label.primary} $channels';
  }

  static String subtitleValue(Tracks? tracks, TrackSelection selection, {required bool visible}) {
    final sub = selection.subtitle;
    if (sub == null || sub.id == SubtitleTrack.off.id || !visible) return 'Desligadas';
    final index = tracks?.subtitle.indexWhere((t) => t.id == sub.id) ?? -1;
    final label = TrackLabelBuilder.subtitleLabel(title: sub.title, language: sub.language, codec: sub.codec,
      forced: sub.isForced, index: index < 0 ? 0 : index);
    final codec = (sub.codec ?? '').toLowerCase();
    final ass = codec == 'ass' || codec == 'ssa';
    return ass ? '${label.primary} (ASS)' : label.primary;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.cgflix.accent;
    Widget tab({required String text, String? value, required VoidCallback onTap, IconData? icon, required String semantic}) =>
      Semantics(button: true, label: semantic, child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap,
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 6)],
            Text.rich(TextSpan(children: [
              TextSpan(text: value == null ? text : '$text: ', style: TextStyle(color: value == null ? Colors.white : accent)),
              if (value != null) TextSpan(text: value, style: TextStyle(color: accent)),
            ]), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
          ])))));
    return StreamBuilder<Tracks>(stream: player.streams.tracks, initialData: player.state.tracks, builder: (context, tracksSnap) =>
      StreamBuilder<TrackSelection>(stream: player.streams.track, initialData: player.state.track, builder: (context, selSnap) {
        final tracks = tracksSnap.data;
        final selection = selSnap.data ?? player.state.track;
        final audio = audioValue(tracks, selection);
        final hasSubs = state.hasSubtitleControls(tracks);
        void openTracks() => _openSheet(context, state, (_) => TrackSheet(player: player, trackControlsState: state));
        return LayoutBuilder(builder: (context, box) => SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: ConstrainedBox(constraints: BoxConstraints(minWidth: box.maxWidth),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, spacing: 12, children: [
          if (audio != null) tab(text: 'Áudio', value: audio, onTap: openTracks, semantic: 'Áudio: $audio. Trocar faixas'),
          if (hasSubs) tab(text: 'Legendas', value: subtitleValue(tracks, selection, visible: state.subtitlesVisible),
            onTap: openTracks, semantic: 'Legendas. Trocar faixas'),
          if (audio == null && !hasSubs) tab(text: 'Áudio e legendas', onTap: openTracks, semantic: 'Áudio e legendas'),
          if (!state.isLive) StreamBuilder<double>(stream: player.streams.rate, initialData: player.state.rate,
            builder: (context, snapshot) {
              final rate = snapshot.data ?? 1.0;
              return tab(text: 'Velocidade', value: heisucaRateLabel(rate),
                onTap: () => heisucaChooseRate(context, player, state, rate), semantic: 'Velocidade');
            }),
          tab(text: 'Ajustes', onTap: () => _openSheet(context, state, (_) => VideoSettingsSheet(player: player, trackControlsState: state)),
            semantic: 'Ajustes do vídeo'),

        ]))));
      }));
  }
}

Future<void> heisucaChooseRate(BuildContext context, Player player, TrackControlsState state, double current) async {
    state.onCancelAutoHide?.call();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    final rate = await showMenu<double>(context: context, color: const Color(0xF0141018),
      position: RelativeRect.fromLTRB(origin.dx, origin.dy + size.height + 4, origin.dx + size.width, 0),
      items: [for (final r in _speeds) CheckedPopupMenuItem(value: r, checked: (r - current).abs() < .01,
        child: Text(r == 1 ? '1,0x (normal)' : heisucaRateLabel(r), style: const TextStyle(color: Colors.white)))]);
    state.onStartAutoHide?.call();
    if (rate == null) return;
    if (state.onRateRequested != null) { await state.onRateRequested!(rate); } else { await player.setRate(rate); }
  }

