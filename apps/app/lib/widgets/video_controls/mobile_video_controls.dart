import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../media/media_item.dart';
import '../../mpv/mpv.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../media/media_source_info.dart';
import '../../services/scrub_preview_source.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/platform_detector.dart';
import '../../i18n/strings.g.dart';
import 'player_chrome_controller.dart';
import 'widgets/circular_control_button.dart';
import 'widgets/content_strip.dart';
import 'widgets/content_strip_panel.dart';
import 'widgets/first_frame_guard.dart';
import 'widgets/play_pause_stream_builder.dart';
import 'widgets/live_timeline_bar.dart';
import 'widgets/video_controls_header.dart';
import 'widgets/video_timeline_bar.dart';
import 'models/track_controls_state.dart';
import '../../heisuca/player/heisuca_player_hud.dart';
import '../../heisuca/player/heisuca_series_episodes.dart'; // CGFLIX
import '../../cgflix/cgflix_palette.dart';

/// Mobile video controls layout for Plex video player
///
/// Displays a full-screen overlay with:
/// - Top bar: Back button, title, and track/chapter controls
/// - Center: Large playback controls (seek backward, play/pause, seek forward)
/// - Bottom bar: Timeline slider with chapter markers and timestamps
///
/// When chapters or queue are available, the user can swipe up on the bottom
/// area to slide a content strip into view. The playback controls and timeline
/// fade out while the strip slides up — only the top bar stays fixed.
class MobileVideoControls extends StatefulWidget {
  final Player player;
  final MediaItem metadata;
  final List<MediaChapter> chapters;
  final bool chaptersLoaded;
  final bool showChapterMarkersOnTimeline;
  final int seekTimeSmall;
  final Widget trackChapterControls;
  final Function(Duration) onSeek;
  final Function(Duration) onSeekEnd;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final Future<void> Function(Duration position)? onSeekRequested;
  final Function(Duration)? onSeekCompleted;
  final VoidCallback onPlayPause;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  /// Whether the user can control playback (false in host-only mode for non-host).
  final bool canControl;

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  /// Optional callback that returns thumbnail image bytes for a given timestamp.
  final ScrubFrame? Function(Duration time)? thumbnailDataBuilder;

  /// Whether this is a live TV stream
  final bool isLive;

  final String? liveChannelName;

  // Live TV time-shift
  final CaptureBuffer? captureBuffer;
  final bool isAtLiveEdge;
  final int Function(Duration position)? liveEpochForPosition;
  final ValueChanged<int>? onLiveSeek;

  /// Server ID for chapter thumbnails in the content strip
  final String? serverId;

  final bool showQueueTab;

  /// Callback when a queue item is selected from the content strip
  final Function(MediaItem)? onQueueItemSelected;
  final Function(MediaItem)? onSeriesEpisodeSelected; // CGFLIX: seleção fora da temporada da fila

  /// Shared controller for chrome visibility (used to reset strip on hide)
  final PlayerChromeController? chromeController;

  /// Called when the content strip visibility changes
  final ValueChanged<bool>? onStripVisibilityChanged;

  /// Returns true when a global touch position belongs to the parent edge-adjustment zone.
  final bool Function(Offset globalPosition)? isInEdgeAdjustmentZone;

  /// Heisuca (celular): estado real das faixas para o HUD do Esboço 07A. Nulo = régua original.
  final TrackControlsState? heisucaTrackState;

  const MobileVideoControls({
    super.key,
    required this.player,
    this.heisucaTrackState,
    required this.metadata,
    required this.chapters,
    required this.chaptersLoaded,
    this.showChapterMarkersOnTimeline = true,
    required this.seekTimeSmall,
    required this.trackChapterControls,
    required this.onSeek,
    required this.onSeekEnd,
    this.onScrubStart,
    this.onScrubEnd,
    required this.onPlayPause,
    this.onSeekRequested,
    this.onSeekCompleted,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.onBack,
    this.onNext,
    this.onPrevious,
    this.canControl = true,
    this.hasFirstFrame,
    this.thumbnailDataBuilder,
    this.isLive = false,
    this.liveChannelName,
    this.captureBuffer,
    this.isAtLiveEdge = true,
    this.liveEpochForPosition,
    this.onLiveSeek,
    this.serverId,
    this.showQueueTab = false,
    this.onQueueItemSelected,
    this.onSeriesEpisodeSelected,
    this.chromeController,
    this.onStripVisibilityChanged,
    this.isInEdgeAdjustmentZone,
  });

  @override
  State<MobileVideoControls> createState() => _MobileVideoControlsState();
}

class _MobileVideoControlsState extends State<MobileVideoControls> with SingleTickerProviderStateMixin {
  late final AnimationController _stripAnim;
  bool _stripVisible = false;
  late bool _lastControlsVisible;
  bool _stripDragEnabled = true;

  /// Drag distance (in pixels) required to fully reveal the strip.
  static const _dragExtent = 150.0;

  bool get _hasStripContent =>
      widget.chapters.isNotEmpty || (widget.showQueueTab && widget.onQueueItemSelected != null);

  @override
  void initState() {
    super.initState();
    _stripAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _stripAnim.addListener(_onStripAnimChanged);
    _lastControlsVisible = widget.chromeController?.controlsVisible ?? true;
    widget.chromeController?.addListener(_onChromeVisibilityChanged);
  }

  @override
  void didUpdateWidget(MobileVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chromeController != widget.chromeController) {
      oldWidget.chromeController?.removeListener(_onChromeVisibilityChanged);
      _lastControlsVisible = widget.chromeController?.controlsVisible ?? true;
      widget.chromeController?.addListener(_onChromeVisibilityChanged);
    }
  }

  @override
  void dispose() {
    widget.chromeController?.removeListener(_onChromeVisibilityChanged);
    _stripAnim.removeListener(_onStripAnimChanged);
    _stripAnim.dispose();
    super.dispose();
  }

  void _onStripAnimChanged() {
    final visible = _stripAnim.value > 0.5;
    if (visible != _stripVisible) {
      _stripVisible = visible;
      widget.onStripVisibilityChanged?.call(visible);
    }
  }

  void _onChromeVisibilityChanged() {
    final chromeController = widget.chromeController;
    final controlsVisible = chromeController?.controlsVisible ?? true;
    final wasControlsVisible = _lastControlsVisible;
    _lastControlsVisible = controlsVisible;

    if (chromeController?.contentStripVisible == false && _stripAnim.value > 0) {
      _stripAnim.reverse();
    }

    if (!controlsVisible && wasControlsVisible && _stripVisible) {
      // Just notify parent that strip is no longer active — don't animate,
      // let the overlay fade out with the strip still showing.
      _stripVisible = false;
      widget.onStripVisibilityChanged?.call(false);
    } else if (controlsVisible && !wasControlsVisible && _stripAnim.value > 0) {
      // Reset strip when controls reappear so page 0 is shown.
      _stripAnim.value = 0;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _stripDragEnabled = widget.isInEdgeAdjustmentZone?.call(details.globalPosition) != true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_stripDragEnabled) return;
    // Negative primaryDelta = swipe up = reveal strip (increase value)
    _stripAnim.value -= (details.primaryDelta ?? 0) / _dragExtent;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_stripDragEnabled) {
      _stripDragEnabled = true;
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    // Fast swipe up or past halfway without fast swipe down → show strip
    if (velocity < -200 || (_stripAnim.value > 0.5 && velocity < 200)) {
      _stripAnim.forward();
    } else {
      _stripAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStripContent) {
      return Column(
        children: [
          _buildTopBar(context),
          const Spacer(),
          _buildPlaybackControls(context),
          const Spacer(),
          if (widget.isLive) _buildActionDock(),
          _buildBottomBar(context),
        ],
      );
    }

    // Top bar stays fixed. Everything below it is a Stack where the controls
    // fade out and the content strip slides up from the bottom on swipe.
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(
          child: GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            behavior: HitTestBehavior.translucent,
            child: ListenableBuilder(
              listenable: _stripAnim,
              builder: (context, _) {
                final t = _stripAnim.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Normal controls — fade out as strip appears
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: t > 0.5,
                        child: Opacity(
                          opacity: (1 - t * 2).clamp(0.0, 1.0),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  const Spacer(),
                                  _buildPlaybackControls(context),
                                  const Spacer(),
                                  _buildBottomBar(context),
                                ],
                              ),
                              const ContentStripHint(Symbols.keyboard_arrow_up_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content strip — slides up from below the bottom edge
                    Align(
                      alignment: .bottomCenter,
                      child: FractionalTranslation(
                        translation: Offset(0, 1 - t),
                        child: IgnorePointer(
                          ignoring: t < 0.5,
                          child: Opacity(
                            opacity: (t * 2).clamp(0.0, 1.0),
                            child: ContentStripPanel(
                              padding: const EdgeInsets.only(top: 32),
                              chevron: Symbols.keyboard_arrow_down_rounded,
                              child: ContentStrip(
                                player: widget.player,
                                chapters: widget.chapters,
                                canControl: widget.canControl,
                                serverId: widget.serverId,
                                showQueueTab: widget.showQueueTab,
                                onQueueItemSelected: widget.onQueueItemSelected,
                                onSeekRequested: widget.onSeekRequested,
                                onSeekCompleted: widget.onSeekCompleted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    // A portrait phone header is too narrow for the clock beside the back button,
    // title, and track/chapter controls.
    final isPortraitPhone =
        PlatformDetector.isPhone(context) && MediaQuery.orientationOf(context) == Orientation.portrait;
    final topBar = _conditionalSafeArea(
      context: context,
      bottom: false, // Only respect top safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: VideoControlsHeader(
          metadata: widget.metadata,
          // CGFLIX: o logo abre temporadas da série; filme continua somente título.
          title: widget.heisucaTrackState == null ? null : HeisucaPlayerTitle(metadata: widget.metadata,
            onEpisodes: widget.canControl && widget.onSeriesEpisodeSelected != null && heisucaPlayerSeriesId(widget.metadata) != null
              ? _showSeriesEpisodes : null),
          style: VideoHeaderStyle.multiLine,
          onCancelAutoHide: widget.onCancelAutoHide,
          onStartAutoHide: widget.onStartAutoHide,
          trailing: widget.heisucaTrackState == null || !widget.canControl ? null
              : HeisucaPlayerQuickActions(player: widget.player, state: widget.heisucaTrackState!, compact: isPortraitPhone),
          onBack: widget.onBack,
          showClock: !isPortraitPhone,
        ),
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  // CGFLIX: usa a mesma navegação real e as mesmas permissões da fila.
  Future<void> _showSeriesEpisodes() async {
    widget.onCancelAutoHide?.call();
    widget.onStripVisibilityChanged?.call(true);
    try {
      final selected = await showHeisucaSeriesEpisodes(context, widget.metadata);
      if (mounted && selected != null) widget.onSeriesEpisodeSelected?.call(selected);
    } finally {
      if (mounted) {
        widget.onStripVisibilityChanged?.call(false);
        widget.onStartAutoHide?.call();
      }
    }
  }

  Widget _buildPlaybackControls(BuildContext _) {
    // Hide all playback controls in host-only mode for non-host
    if (!widget.canControl) {
      return const SizedBox.shrink();
    }

    return FirstFrameGuard(
      hasFirstFrame: widget.hasFirstFrame,
      builder: (context) => _buildPlaybackControlsContent(context),
    );
  }

  Widget _buildPlaybackControlsContent(BuildContext _) {
    return PlayPauseStreamBuilder(
      player: widget.player,
      builder: (context, isPlaying) {
        return Row(
          mainAxisAlignment: .center,
          children: [
            if (!widget.isLive) ...[
              CircularControlButton(
                semanticLabel: 'Voltar ${widget.seekTimeSmall} segundos',
                icon: heisucaSeekIcon(widget.seekTimeSmall, forward: false),
                iconSize: 40,
                onPressed: () => _seekRelative(-widget.seekTimeSmall),
              ),
              const SizedBox(width: 24),
            ],
            CircularControlButton(
              semanticLabel: isPlaying ? t.videoControls.pauseButton : t.videoControls.playButton,
              icon: isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
              iconSize: 72,
              background: widget.heisucaTrackState != null
                  ? context.cgflix.accent.withValues(alpha: .9)
                  : null,
              onPressed: () {
                widget.onPlayPause();
                if (isPlaying) {
                  widget.onCancelAutoHide?.call();
                } else {
                  widget.onStartAutoHide?.call();
                }
              },
            ),
            if (!widget.isLive) ...[
              const SizedBox(width: 24),
              CircularControlButton(
                semanticLabel: 'Avançar ${widget.seekTimeSmall} segundos',
                icon: heisucaSeekIcon(widget.seekTimeSmall, forward: true),
                iconSize: 40,
                onPressed: () => _seekRelative(widget.seekTimeSmall),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _seekRelative(int seconds) async {
    final maximum = widget.player.state.duration.inMilliseconds;
    if (maximum <= 0) return;
    final milliseconds = (widget.player.state.position.inMilliseconds + seconds * 1000).clamp(0, maximum);
    final target = Duration(milliseconds: milliseconds);
    widget.onCancelAutoHide?.call();
    try {
      if (widget.onSeekRequested != null) {
        await widget.onSeekRequested!(target);
        widget.onSeekCompleted?.call(target);
      } else {
        widget.onSeekEnd(target);
      }
    } finally { if (mounted) widget.onStartAutoHide?.call(); }
  }

  Widget _buildActionDock() => DecoratedBox(
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .32), borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12))),
    child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        widget.trackChapterControls,
        if (_hasStripContent) TextButton.icon(
          onPressed: () { widget.onCancelAutoHide?.call(); _stripAnim.forward(); },
          icon: const Icon(Icons.video_library_outlined, color: Colors.white),
          label: Text(widget.showQueueTab ? 'Episódios' : 'Capítulos', style: const TextStyle(color: Colors.white))),
        if (widget.onPrevious != null) IconButton(tooltip: 'Anterior', onPressed: widget.onPrevious,
          icon: const Icon(Icons.skip_previous, color: Colors.white)),
        if (widget.onNext != null && widget.heisucaTrackState == null) IconButton(tooltip: 'Próximo', onPressed: widget.onNext,
          icon: const Icon(Icons.skip_next, color: Colors.white)),
      ])));

  /// Celular (07A): linha de texto com áudio, legendas, episódios e ajustes. Sem estado: régua original.
  Widget _buildBottomActions() {
    final state = widget.heisucaTrackState;
    if (state == null || !widget.canControl) return _buildActionDock();
    return Align(alignment: Alignment.centerRight, child: HeisucaPlayerTabs(
      player: widget.player,
      state: state,
      episodesLabel: widget.showQueueTab ? 'Episódios' : 'Capítulos',
      onEpisodes: _hasStripContent ? () { widget.onCancelAutoHide?.call(); _stripAnim.forward(); } : null,
    ));
  }

  Widget _buildBottomBar(BuildContext context) {
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    return SafeArea(
      top: false,
      left: isPortrait,
      right: isPortrait,
      minimum: MediaQuery.systemGestureInsetsOf(context),
      child: _buildBottomBarWithoutInsets(context),
    );
  }

  Widget _buildBottomBarWithoutInsets(BuildContext _) {
    if (widget.isLive) {
      if (widget.captureBuffer != null) {
        // Live TV with time-shift: show seekable timeline
        return FirstFrameGuard(
          hasFirstFrame: widget.hasFirstFrame,
          builder: (context) => LiveTimelineBar(
            player: widget.player,
            captureBuffer: widget.captureBuffer!,
            epochForPosition: widget.liveEpochForPosition!,
            isAtLiveEdge: widget.isAtLiveEdge,
            onSeekEnd: widget.onLiveSeek,
            horizontalLayout: false,
            enabled: widget.canControl,
          ),
        );
      }
      // Fallback: static LIVE badge (no capture buffer)
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Text(
                t.liveTv.live,
                style: const TextStyle(color: Colors.white, fontWeight: .bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return FirstFrameGuard(hasFirstFrame: widget.hasFirstFrame, builder: (context) => _buildBottomBarContent(context));
  }

  Widget _buildBottomBarContent(BuildContext context) {
    return _conditionalSafeArea(
      context: context,
      top: false, // Only respect bottom safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [VideoTimelineBar(
          player: widget.player,
          chapters: widget.chapters,
          chaptersLoaded: widget.chaptersLoaded,
          showChapterMarkersOnTimeline: widget.showChapterMarkersOnTimeline,
          onSeek: widget.onSeek,
          onSeekEnd: widget.onSeekEnd,
          onScrubStart: widget.onScrubStart,
          onScrubEnd: widget.onScrubEnd,
          horizontalLayout: false,
          enabled: widget.canControl,
          showFinishTime: true,
          thumbnailDataBuilder: widget.thumbnailDataBuilder,
        ), const SizedBox(height: 4), _buildBottomActions()]),
      ),
    );
  }

  /// Wraps [child] in a SafeArea: full insets in portrait, horizontal-only in
  /// landscape. Em paisagem a margem é simétrica, max(esquerda, direita): com a
  /// câmera num lado só (Edge 60 Pro), os controles ficam centrados na tela.
  /// O SafeArea consome o recuo, para nenhum filho reaplicar só o lado da câmera.
  Widget _conditionalSafeArea({
    required BuildContext context,
    required Widget child,
    bool top = true,
    bool bottom = true,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    if (isPortrait) {
      return SafeArea(top: top, bottom: bottom, child: child);
    }
    final lado = math.max(mediaQuery.padding.left, mediaQuery.padding.right);
    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.symmetric(horizontal: lado),
      child: child,
    );
  }
}

