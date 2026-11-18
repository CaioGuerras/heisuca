import 'dart:async';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../heisuca/heisuca_design_system.dart';
import '../heisuca/heisuca_motion.dart';
import '../heisuca/heisuca_theme.dart';
import '../mpv/models.dart';
import '../mpv/player/player.dart';
import '../mpv/player/player_state.dart';
import '../mpv/video.dart';
import 'desktop_playback_controller.dart';

/// Shell desktop Heisuca para reprodução direta de arquivos locais e URLs HTTP(S).
class DesktopApp extends StatefulWidget {
  const DesktopApp({
    super.key,
    this.controller,
    this.initialSource,
    this.onPickVideoFile,
    this.onPickSubtitleFile,
    this.onRequestUrl,
    this.onSetFullScreen,
  });

  final DesktopPlaybackController? controller;
  final String? initialSource;
  final Future<String?> Function()? onPickVideoFile;
  final Future<String?> Function()? onPickSubtitleFile;
  final Future<String?> Function(BuildContext context)? onRequestUrl;
  final Future<bool> Function(bool fullScreen)? onSetFullScreen;

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> with WindowListener {
  DesktopPlaybackController? _ownedController;
  late DesktopPlaybackController _controller;

  final FocusNode _shortcutFocusNode = FocusNode(debugLabel: 'heisuca_desktop_shortcuts');
  final ValueNotifier<bool> _hasFirstFrameNotifier = ValueNotifier<bool>(false);

  BuildContext? _shellContext;
  Player? _observedPlayer;
  StreamSubscription<void>? _playbackRestartSub;
  StreamSubscription<void>? _fileStartedSub;
  Timer? _controlsHideTimer;

  bool _listeningWindow = false;
  bool _isFullScreen = false;
  bool _controlsVisible = true;
  bool _wasOpening = false;
  bool _changingFullScreen = false;
  bool _pickingFile = false;
  bool _pickingSubtitle = false;
  bool _openingUrlDialog = false;
  double? _draggingSeekMs;
  double _lastNonZeroVolume = 100.0;
  String? _lastErrorSeen;
  String? _dismissedError;

  @override
  void initState() {
    super.initState();
    _attachController();
    _attachWindowListenerIfDesktop();
    final initialSource = widget.initialSource;
    if (initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.open(initialSource));
      });
    }
  }

  @override
  void didUpdateWidget(covariant DesktopApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController();
    }
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    _detachWindowListener();
    _detachController();
    _playbackRestartSub?.cancel();
    _fileStartedSub?.cancel();
    _hasFirstFrameNotifier.dispose();
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  void _attachController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownedController = DesktopPlaybackController();
      _controller = _ownedController!;
    }
    _controller.addListener(_onControllerChanged);
    _syncControllerState(notifyUi: false);
  }

  void _detachController() {
    _controller.removeListener(_onControllerChanged);
    _playbackRestartSub?.cancel();
    _playbackRestartSub = null;
    _fileStartedSub?.cancel();
    _fileStartedSub = null;
    _observedPlayer = null;
    _ownedController?.dispose();
    _ownedController = null;
    _draggingSeekMs = null;
    _lastErrorSeen = null;
    _dismissedError = null;
  }

  void _attachWindowListenerIfDesktop() {
    if (widget.onSetFullScreen != null) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
      _listeningWindow = true;
    }
  }

  void _detachWindowListener() {
    if (_listeningWindow) {
      windowManager.removeListener(this);
      _listeningWindow = false;
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (!mounted || _isFullScreen) return;
    setState(() => _isFullScreen = true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (!mounted || !_isFullScreen) return;
    setState(() => _isFullScreen = false);
  }

  void _onControllerChanged() {
    _syncControllerState(notifyUi: true);
  }

  void _syncControllerState({required bool notifyUi}) {
    if (_controller.error != _lastErrorSeen) {
      _lastErrorSeen = _controller.error;
      _dismissedError = null;
    }

    final nowOpening = _controller.opening;
    if (nowOpening && !_wasOpening) {
    }
    _wasOpening = nowOpening;

    if (!_controller.hasMedia && !nowOpening) {
    }

    if (_controller.state.volume > 0) {
      _lastNonZeroVolume = _controller.state.volume;
    }

    final currentPlayer = _controller.player;
    if (!identical(currentPlayer, _observedPlayer)) {
      _playbackRestartSub?.cancel();
      _fileStartedSub?.cancel();
      _observedPlayer = currentPlayer;
      if (currentPlayer != null) {
        _playbackRestartSub = currentPlayer.streams.playbackRestart.listen((_) {
          _refreshFirstFrameNotifier();
        });
        _fileStartedSub = currentPlayer.streams.fileStarted.listen((_) {
          _refreshFirstFrameNotifier();
        });
      }
    }

    _refreshFirstFrameNotifier();
    if (!_controller.hasMedia || _controller.opening || _controller.error != null ||
        !_controller.state.seekable || _controller.state.duration <= Duration.zero) {
      _draggingSeekMs = null;
    }

    if (_controller.opening || _controller.error != null || !_controller.state.isActive) {
      _controlsHideTimer?.cancel();
      _controlsVisible = true;
    } else if (_controlsVisible && _draggingSeekMs == null) {
      _scheduleHideControls();
    }

    if (notifyUi && mounted) {
      setState(() {});
    }
  }

  void _refreshFirstFrameNotifier() {
    final confirmed = _controller.hasMedia && !_controller.opening &&
        _controller.error == null && _controller.state.hasRenderedFrame;
    if (_hasFirstFrameNotifier.value != confirmed) {
      _hasFirstFrameNotifier.value = confirmed;
    }
  }

  bool _isTextInputFocused() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _isModalOnTop() {
    if (_openingUrlDialog || _pickingFile || _pickingSubtitle) return true;
    final ctx = _shellContext;
    if (ctx == null || !ctx.mounted) return false;
    return ModalRoute.of(ctx)?.isCurrent == false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_isTextInputFocused() || _isModalOnTop()) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final primaryModifier = keyboard.isControlPressed || (isMac && keyboard.isMetaPressed);
    final anyModifier = keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed;

    if (event is KeyDownEvent && primaryModifier && !keyboard.isAltPressed && !keyboard.isShiftPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyO) {
        unawaited(_openFile());
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        unawaited(_openUrl());
        return KeyEventResult.handled;
      }
    }

    if (anyModifier) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyF) {
      unawaited(_toggleFullScreen());
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isFullScreen) {
        unawaited(_setFullScreen(false));
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (!_controller.hasMedia) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _revealControlsAndScheduleHide();
      unawaited(_controller.togglePause().catchError((_) {}));
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      unawaited(_seekRelative(const Duration(seconds: -10)));
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      unawaited(_seekRelative(const Duration(seconds: 10)));
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      unawaited(_adjustVolume(5.0));
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      unawaited(_adjustVolume(-5.0));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _openFile() async {
    if (_pickingFile) return;
    _pickingFile = true;
    String? path;
    try {
      if (widget.onPickVideoFile != null) {
        path = await widget.onPickVideoFile!();
      } else {
        final result = await FilePicker.pickFiles(
          dialogTitle: 'Abrir arquivo de vídeo',
          type: FileType.video,
          lockParentWindow: true,
        );
        path = result?.files.firstOrNull?.path;
      }
    } on MissingPluginException {
      path = null;
    } on Object {
      _showOperationError('Não foi possível abrir o seletor de arquivos. Tente novamente.');
      path = null;
    } finally {
      _pickingFile = false;
    }

    if (!mounted || path == null || path.trim().isEmpty) {
      if (mounted) _shortcutFocusNode.requestFocus();
      return;
    }
    _shortcutFocusNode.requestFocus();
    try {
      _dismissedError = null;
      _lastErrorSeen = null;
      await _controller.open(path);
    } catch (_) {}
  }

  Future<void> _openUrl() async {
    if (_openingUrlDialog || !mounted) return;
    final dialogContext = _shellContext;
    if (dialogContext == null || !dialogContext.mounted) return;
    _openingUrlDialog = true;
    String? url;
    try {
      if (widget.onRequestUrl != null) {
        url = await widget.onRequestUrl!(dialogContext);
      } else {
        url = await showDialog<String>(
          context: dialogContext,
          builder: (_) => const _OpenUrlDialog(),
        );
      }
    } finally {
      _openingUrlDialog = false;
    }

    if (!mounted || url == null || url.trim().isEmpty) {
      if (mounted) _shortcutFocusNode.requestFocus();
      return;
    }
    _shortcutFocusNode.requestFocus();
    try {
      _dismissedError = null;
      _lastErrorSeen = null;
      await _controller.open(url.trim());
    } catch (_) {}
  }

  Future<void> _pickAndAddSubtitle() async {
    if (_pickingSubtitle) return;
    _pickingSubtitle = true;
    final playerBefore = _controller.player;
    final titleBefore = _controller.title;
    String? path;
    try {
      if (widget.onPickSubtitleFile != null) {
        path = await widget.onPickSubtitleFile!();
      } else {
        final result = await FilePicker.pickFiles(
          dialogTitle: 'Abrir legenda externa',
          type: FileType.custom,
          allowedExtensions: const ['srt', 'ass', 'ssa', 'vtt'],
          lockParentWindow: true,
        );
        path = result?.files.firstOrNull?.path;
      }
    } on MissingPluginException {
      path = null;
    } on Object {
      _showOperationError('Não foi possível abrir o seletor de arquivos. Tente novamente.');
      path = null;
    } finally {
      _pickingSubtitle = false;
    }

    if (!mounted || path == null || path.trim().isEmpty) {
      if (mounted) _shortcutFocusNode.requestFocus();
      return;
    }
    _shortcutFocusNode.requestFocus();
    if (!_controller.hasMedia || !identical(_controller.player, playerBefore) ||
        _controller.title != titleBefore) return;
    try {
      await _controller.addSubtitle(path);
    } catch (_) {}
  }

  Future<void> _toggleFullScreen() => _setFullScreen(!_isFullScreen);

  void _showOperationError(String message) {
    final context = _shellContext;
    if (!mounted || context == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setFullScreen(bool value) async {
    if (_isFullScreen == value || _changingFullScreen) return;
    _changingFullScreen = true;
    final previous = _isFullScreen;
    try {
      var next = value;
      if (widget.onSetFullScreen != null) {
        next = await widget.onSetFullScreen!(value).timeout(const Duration(seconds: 5));
      } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await windowManager.setFullScreen(value).timeout(const Duration(seconds: 5));
      }
      if (mounted) setState(() => _isFullScreen = next);
    } on Object {
      if (mounted) {
        setState(() => _isFullScreen = previous);
        _showOperationError('Não foi possível alternar a tela cheia.');
      }
    } finally {
      _changingFullScreen = false;
    }
  }

  Future<void> _closeMedia() async {
    _controlsHideTimer?.cancel();
    _draggingSeekMs = null;
    // Closing playback must not wait for an unresponsive window manager.
    final closing = _controller.close();
    if (_isFullScreen) unawaited(_setFullScreen(false));
    await closing;
    if (mounted) _shortcutFocusNode.requestFocus();
  }

  Future<void> _seekRelative(Duration delta) async {
    final state = _controller.state;
    if (!_controller.hasMedia || !state.seekable || state.duration <= Duration.zero) {
      return;
    }
    var target = state.position + delta;
    if (target < Duration.zero) {
      target = Duration.zero;
    } else if (target > state.duration) {
      target = state.duration;
    }
    _revealControlsAndScheduleHide();
    try {
      await _controller.seek(target);
    } catch (_) {}
  }

  Future<void> _adjustVolume(double delta) async {
    if (!_controller.hasMedia) return;
    final next = (_controller.state.volume + delta).clamp(0.0, 100.0).toDouble();
    if (next > 0) _lastNonZeroVolume = next;
    _revealControlsAndScheduleHide();
    try {
      await _controller.setVolume(next);
    } catch (_) {}
  }

  Future<void> _toggleMute() async {
    if (!_controller.hasMedia) return;
    final current = _controller.state.volume;
    final target = current > 0 ? 0.0 : (_lastNonZeroVolume > 0 ? _lastNonZeroVolume : 100.0);
    if (current > 0) _lastNonZeroVolume = current;
    _revealControlsAndScheduleHide();
    try {
      await _controller.setVolume(target);
    } catch (_) {}
  }

  void _revealControlsAndScheduleHide() {
    if (!_controlsVisible && mounted) {
      setState(() => _controlsVisible = true);
    }
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _controlsHideTimer?.cancel();
    if (!_controller.hasMedia || _controller.opening || _controller.error != null || !_controller.state.isActive) {
      return;
    }
    _controlsHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_controller.state.isActive && _draggingSeekMs == null && !_controller.opening && _controller.error == null) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _handleVideoSurfaceTap() {
    _shortcutFocusNode.requestFocus();
    if (!mounted) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHideControls();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  ThemeData _buildDesktopTheme() {
    final base = HeisucaTheme.criarTema();
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: HeisucaTheme.roxoPrimaria, width: 2.0);
      }
      return null;
    });

    return base.copyWith(
      scaffoldBackgroundColor: HeisucaTheme.roxoFundo,
      canvasColor: HeisucaTheme.roxoSuperficie,
      focusColor: HeisucaTheme.roxoPrimaria.withValues(alpha: 0.24),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: HeisucaTheme.roxoSuperficieElevada,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: HeisucaTheme.roxoLinha),
        ),
        textStyle: HeisucaTypography.bodyMetadata.copyWith(color: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: focusSide,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: HeisucaTheme.roxoPrimaria, width: 2.0);
            }
            return const BorderSide(color: HeisucaTheme.roxoLinha);
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: (base.iconButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: focusSide,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heisuca',
      debugShowCheckedModeBanner: false,
      theme: _buildDesktopTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return Focus(
          focusNode: _shortcutFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(
        builder: (shellContext) {
          _shellContext = shellContext;
          return _buildScaffold(shellContext);
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final showPlayerStage = _controller.hasMedia ||
        _controller.opening ||
        (_controller.player != null && _controller.error != null);
    final hasVideoWidget = showPlayerStage && _controller.player != null;

    return Scaffold(
      backgroundColor: hasVideoWidget ? Colors.transparent : HeisucaTheme.roxoFundo,
      body: showPlayerStage ? _buildPlayerStage(context) : _buildHomeStage(context),
    );
  }

  Widget _buildHomeStage(BuildContext context) {
    final visibleError = _controller.error != null && _controller.error != _dismissedError
        ? _controller.error
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HeisucaTheme.roxoFundo,
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.55),
          radius: 1.15,
          colors: [
            HeisucaTheme.roxoPrimaria.withValues(alpha: 0.14),
            HeisucaTheme.roxoSelo.withValues(alpha: 0.06),
            HeisucaTheme.roxoFundo,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 900 ? 24.0 : 48.0;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (constraints.maxHeight - 56).clamp(0.0, double.infinity)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 14,
                        runSpacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: HeisucaTheme.roxoSuperficie,
                              borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
                              border: Border.all(color: HeisucaTheme.roxoLinha),
                            ),
                            child: SvgPicture.asset(
                              'assets/cgflix_emblema.svg',
                              width: 34,
                              height: 34,
                              semanticsLabel: 'Emblema Heisuca',
                            ),
                          ),
                          Text(
                            'Heisuca',
                            style: HeisucaTypography.displayCinematic.copyWith(color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: HeisucaTheme.roxoSelo.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(HeisucaTheme.raioPilula),
                              border: Border.all(color: HeisucaTheme.roxoSelo.withValues(alpha: 0.55)),
                            ),
                            child: Text(
                              '炳素華 · DESKTOP',
                              style: HeisucaTypography.labelBadge.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Nada entre você e o filme.',
                        style: HeisucaTypography.titleHero.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reprodução direta de arquivos locais e endereços HTTP ou HTTPS neste primeiro marco para desktop, sem necessidade de conta ou servidor.',
                        style: HeisucaTypography.bodySynopsis.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      if (visibleError != null) ...[
                        const SizedBox(height: 20),
                        _buildHomeErrorBanner(visibleError),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: HeisucaTheme.roxoSuperficie,
                          borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
                          border: Border.all(color: HeisucaTheme.roxoLinha),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Abrir fonte de mídia',
                              style: HeisucaTypography.titleSection.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selecione um vídeo armazenado no computador ou informe um endereço HTTP(S) válido. Faixas de áudio e legendas SRT, ASS e VTT podem ser alternadas durante a exibição.',
                              style: HeisucaTypography.bodyMetadata.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                Tooltip(
                                  message: 'Abrir arquivo de vídeo local (Ctrl+O)',
                                  child: FilledButton.icon(
                                    onPressed: _openFile,
                                    icon: const Icon(Icons.folder_open_rounded),
                                    label: const Text('Abrir arquivo'),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Abrir endereço HTTP ou HTTPS (Ctrl+L)',
                                  child: OutlinedButton.icon(
                                    onPressed: _openUrl,
                                    icon: const Icon(Icons.link_rounded),
                                    label: const Text('Abrir URL'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildShortcutHints(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeErrorBanner(String message) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HeisucaTheme.roxoSelo.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(HeisucaTheme.raioSquircle),
          border: Border.all(color: HeisucaTheme.roxoSelo.withValues(alpha: 0.65)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Falha ao abrir mídia',
                    style: HeisucaTypography.bodyMetadata.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: HeisucaTypography.bodyMetadata.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _dismissedError = _controller.error),
                    child: const Text('Dispensar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutHints() {
    const shortcuts = [
      ('Ctrl+O', 'Arquivo'),
      ('Ctrl+L', 'URL'),
      ('Espaço', 'Pausar'),
      ('F', 'Tela cheia'),
      ('Esc', 'Sair tela cheia'),
      ('← / →', '10s'),
      ('↑ / ↓', 'Volume'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final (keys, action) in shortcuts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HeisucaTheme.roxoSuperficie,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: HeisucaTheme.roxoLinha),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: HeisucaTheme.roxoSuperficieElevada,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: HeisucaTheme.roxoLinha),
                  ),
                  child: Text(
                    keys,
                    style: HeisucaTypography.labelBadge.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  action,
                  style: HeisucaTypography.bodyMetadata.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerStage(BuildContext context) {
    final player = _controller.player;
    return Column(
      children: [
        if (!_isFullScreen) _buildTopBar(context),
        Expanded(
          child: player != null
              ? Video(
                  key: ObjectKey(player),
                  player: player,
                  backgroundColor: HeisucaTheme.roxoFundo,
                  hasFirstFrame: _hasFirstFrameNotifier,
                  controls: (overlayContext) => _buildVideoOverlay(overlayContext),
                )
              : ColoredBox(
                  color: HeisucaTheme.roxoFundo,
                  child: _buildStatusCenterCard(context) ?? const SizedBox.expand(),
                ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final title = (_controller.title?.trim().isNotEmpty ?? false)
        ? _controller.title!.trim()
        : 'Reprodução local';

    return Container(
      decoration: const BoxDecoration(
        color: HeisucaTheme.roxoSuperficie,
        border: Border(bottom: BorderSide(color: HeisucaTheme.roxoLinha)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar ao início',
            onPressed: _closeMedia,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/cgflix_emblema.svg',
            width: 22,
            height: 22,
            semanticsLabel: 'Heisuca',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HeisucaTypography.bodyMetadata.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Abrir arquivo (Ctrl+O)',
            onPressed: _openFile,
            icon: const Icon(Icons.folder_open_rounded),
          ),
          IconButton(
            tooltip: 'Abrir URL (Ctrl+L)',
            onPressed: _openUrl,
            icon: const Icon(Icons.link_rounded),
          ),
          IconButton(
            tooltip: _isFullScreen ? 'Sair da tela cheia (Esc)' : 'Tela cheia (F)',
            onPressed: _toggleFullScreen,
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay(BuildContext context) {
    final state = _controller.state;
    final statusCard = _buildStatusCenterCard(context);
    final showControls = _controlsVisible || statusCard != null;
    final fadeDuration = HeisucaMotion.durationFor(context);

    return MouseRegion(
      onHover: (_) => _revealControlsAndScheduleHide(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _handleVideoSurfaceTap,
            onDoubleTap: _toggleFullScreen,
            child: const SizedBox.expand(),
          ),
          if (statusCard == null && state.buffering)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: HeisucaTheme.roxoSuperficie.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(HeisucaTheme.raioPilula),
                    border: Border.all(color: HeisucaTheme.roxoLinha),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Armazenando em buffer...',
                          style: HeisucaTypography.bodyMetadata.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isFullScreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !showControls,
                child: AnimatedOpacity(
                  opacity: showControls ? 1.0 : 0.0,
                  duration: fadeDuration,
                  curve: HeisucaMotion.curve,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: CubicScrimGradient.create(
                        baseColor: Colors.black,
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: _buildFullScreenTopOverlay(),
                  ),
                ),
              ),
            ),
          if (_controller.hasMedia)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !showControls,
                child: AnimatedOpacity(
                  opacity: showControls ? 1.0 : 0.0,
                  duration: fadeDuration,
                  curve: HeisucaMotion.curve,
                  child: _buildBottomControls(context, state),
                ),
              ),
            ),
          ?statusCard,
        ],
      ),
    );
  }

  Widget _buildFullScreenTopOverlay() {
    final title = (_controller.title?.trim().isNotEmpty ?? false)
        ? _controller.title!.trim()
        : 'Reprodução local';
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Voltar ao início',
              onPressed: _closeMedia,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HeisucaTypography.titleSection.copyWith(color: Colors.white),
              ),
            ),
            IconButton(
              tooltip: 'Sair da tela cheia (Esc)',
              onPressed: () => _setFullScreen(false),
              icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildStatusCenterCard(BuildContext context) {
    if (_controller.opening) {
      final title = _controller.title?.trim();
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HeisucaTheme.roxoSuperficie.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
                border: Border.all(color: HeisucaTheme.roxoLinha),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Abrindo mídia...',
                    textAlign: TextAlign.center,
                    style: HeisucaTypography.titleSection.copyWith(color: Colors.white),
                  ),
                  if (title != null && title.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HeisucaTypography.bodyMetadata.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Aguardando confirmação do primeiro quadro.',
                    textAlign: TextAlign.center,
                    style: HeisucaTypography.bodyMetadata.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _closeMedia,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final errorMessage = _controller.error;
    if (errorMessage != null) {
      return Semantics(
        liveRegion: true,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: HeisucaTheme.roxoSuperficie.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
                  border: Border.all(color: HeisucaTheme.roxoSelo.withValues(alpha: 0.75)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Não foi possível reproduzir',
                            style: HeisucaTypography.titleSection.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorMessage,
                      style: HeisucaTypography.bodySynopsis.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _openFile,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Abrir arquivo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openUrl,
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Abrir URL'),
                        ),
                        TextButton(
                          onPressed: _closeMedia,
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildBottomControls(BuildContext context, PlayerState state) {
    final durationMs = state.duration.inMilliseconds;
    final canSeek = state.seekable && durationMs > 0;
    final displayedMs = _draggingSeekMs ??
        state.position.inMilliseconds.clamp(0, durationMs > 0 ? durationMs : 0).toDouble();
    final displayedPosition = Duration(milliseconds: displayedMs.round());
    final volume = state.volume.clamp(0.0, 100.0).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CubicScrimGradient.create(baseColor: Colors.black),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: HeisucaTheme.roxoSuperficie.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
              border: Border.all(color: HeisucaTheme.roxoLinha),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(displayedPosition),
                      style: HeisucaTypography.tabularTimestamp.copyWith(color: Colors.white),
                    ),
                    Expanded(
                      child: Semantics(
                        label: 'Linha do tempo',
                        child: Slider(
                          value: durationMs > 0 ? displayedMs.clamp(0.0, durationMs.toDouble()) : 0.0,
                          min: 0.0,
                          max: durationMs > 0 ? durationMs.toDouble() : 1.0,
                          onChanged: canSeek
                              ? (value) {
                                  _controlsHideTimer?.cancel();
                                  setState(() => _draggingSeekMs = value);
                                }
                              : null,
                          onChangeEnd: canSeek
                              ? (value) {
                                  setState(() => _draggingSeekMs = null);
                                  unawaited(_controller.seek(Duration(milliseconds: value.round())).catchError((_) {}));
                                  _scheduleHideControls();
                                }
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(state.duration),
                      style: HeisucaTypography.tabularTimestamp.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          IconButton(
                            tooltip: state.isActive ? 'Pausar (Espaço)' : 'Reproduzir (Espaço)',
                            onPressed: () {
                              _revealControlsAndScheduleHide();
                              unawaited(_controller.togglePause().catchError((_) {}));
                            },
                            icon: Icon(
                              state.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Voltar 10 segundos (←)',
                            onPressed: canSeek ? () => _seekRelative(const Duration(seconds: -10)) : null,
                            icon: const Icon(Icons.replay_10_rounded),
                          ),
                          IconButton(
                            tooltip: 'Avançar 10 segundos (→)',
                            onPressed: canSeek ? () => _seekRelative(const Duration(seconds: 10)) : null,
                            icon: const Icon(Icons.forward_10_rounded),
                          ),
                          IconButton(
                            tooltip: volume > 0 ? 'Silenciar' : 'Restaurar volume',
                            onPressed: _toggleMute,
                            icon: Icon(
                              volume <= 0
                                  ? Icons.volume_off_rounded
                                  : (volume < 50 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                            ),
                          ),
                          SizedBox(
                            width: 96,
                            child: Semantics(
                              label: 'Volume',
                              child: Slider(
                                value: volume,
                                min: 0.0,
                                max: 100.0,
                                onChanged: (value) {
                                  if (value > 0) _lastNonZeroVolume = value;
                                  _controlsHideTimer?.cancel();
                                  unawaited(_controller.setVolume(value).catchError((_) {}));
                                },
                                onChangeEnd: (_) => _scheduleHideControls(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildAudioMenu(state),
                          _buildSubtitleMenu(state),
                          IconButton(
                            tooltip: _isFullScreen ? 'Sair da tela cheia (Esc)' : 'Tela cheia (F)',
                            onPressed: _toggleFullScreen,
                            icon: Icon(
                              _isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMenu(PlayerState state) {
    final tracks = state.tracks.audio
        .where((track) => track.id != AudioTrack.auto.id && track.id != AudioTrack.off.id)
        .toList();
    final selectedId = state.track.audio?.id;

    return Tooltip(
      message: 'Faixas de áudio',
      child: PopupMenuButton<AudioTrack>(
        tooltip: '',
        color: HeisucaTheme.roxoSuperficieElevada,
        onOpened: () => _controlsHideTimer?.cancel(),
        onCanceled: () {
          _shortcutFocusNode.requestFocus();
          _scheduleHideControls();
        },
        onSelected: (track) {
          _shortcutFocusNode.requestFocus();
          unawaited(_controller.selectAudio(track).catchError((_) {}));
          _scheduleHideControls();
        },
        itemBuilder: (context) => [
          _buildAudioMenuItem(AudioTrack.auto, selectedId == AudioTrack.auto.id),
          _buildAudioMenuItem(AudioTrack.off, selectedId == AudioTrack.off.id),
          if (tracks.isNotEmpty) const PopupMenuDivider(),
          for (final track in tracks) _buildAudioMenuItem(track, selectedId == track.id),
        ],
        child: _MenuButtonPill(
          icon: Icons.audiotrack_rounded,
          label: 'Áudio',
        ),
      ),
    );
  }

  PopupMenuItem<AudioTrack> _buildAudioMenuItem(AudioTrack track, bool selected) {
    return PopupMenuItem<AudioTrack>(
      value: track,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_rounded : Icons.circle_outlined,
            size: 16,
            color: selected ? HeisucaTheme.roxoPrimaria : Colors.white.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatAudioTrackLabel(track),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleMenu(PlayerState state) {
    final tracks = state.tracks.subtitle
        .where((track) => track.id != SubtitleTrack.auto.id && track.id != SubtitleTrack.off.id)
        .toList();
    final selectedId = state.track.subtitle?.id;

    return Tooltip(
      message: 'Legendas e arquivo externo',
      child: PopupMenuButton<_SubtitleMenuChoice>(
        tooltip: '',
        color: HeisucaTheme.roxoSuperficieElevada,
        onOpened: () => _controlsHideTimer?.cancel(),
        onCanceled: () {
          _shortcutFocusNode.requestFocus();
          _scheduleHideControls();
        },
        onSelected: (choice) {
          _shortcutFocusNode.requestFocus();
          switch (choice) {
            case _ExternalSubtitleChoice():
              unawaited(_pickAndAddSubtitle());
            case _SelectSubtitleChoice(:final track):
              unawaited(_controller.selectSubtitle(track).catchError((_) {}));
          }
          _scheduleHideControls();
        },
        itemBuilder: (context) => [
          const PopupMenuItem<_SubtitleMenuChoice>(
            value: _ExternalSubtitleChoice(),
            child: Row(
              children: [
                Icon(Icons.subtitles_outlined, size: 16),
                SizedBox(width: 10),
                Expanded(child: Text('Abrir legenda externa (SRT, ASS, VTT)...')),
              ],
            ),
          ),
          const PopupMenuDivider(),
          _buildSubtitleMenuItem(SubtitleTrack.off, selectedId == SubtitleTrack.off.id),
          _buildSubtitleMenuItem(SubtitleTrack.auto, selectedId == SubtitleTrack.auto.id),
          if (tracks.isNotEmpty) const PopupMenuDivider(),
          for (final track in tracks) _buildSubtitleMenuItem(track, selectedId == track.id),
        ],
        child: const _MenuButtonPill(
          icon: Icons.subtitles_rounded,
          label: 'Legendas',
        ),
      ),
    );
  }

  PopupMenuItem<_SubtitleMenuChoice> _buildSubtitleMenuItem(SubtitleTrack track, bool selected) {
    return PopupMenuItem<_SubtitleMenuChoice>(
      value: _SelectSubtitleChoice(track),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_rounded : Icons.circle_outlined,
            size: 16,
            color: selected ? HeisucaTheme.roxoPrimaria : Colors.white.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatSubtitleTrackLabel(track),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAudioTrackLabel(AudioTrack track) {
    if (track.id == AudioTrack.auto.id) return 'Automático';
    if (track.id == AudioTrack.off.id) return 'Desligado';
    final parts = <String>[];
    final title = track.title?.trim();
    if (title != null && title.isNotEmpty) parts.add(title);
    final language = track.language?.trim();
    if (language != null && language.isNotEmpty && !parts.any((p) => p.toLowerCase() == language.toLowerCase())) {
      parts.add(language.toUpperCase());
    }
    final codec = track.codec?.trim();
    if (codec != null && codec.isNotEmpty) parts.add(codec.toUpperCase());
    final channels = track.channels;
    if (channels != null && channels > 0) {
      parts.add(switch (channels) {
        1 => 'Mono',
        2 => 'Estéreo',
        6 => '5.1',
        8 => '7.1',
        final count => '${count}ch',
      });
    }
    return parts.isEmpty ? 'Faixa de áudio ${track.id}' : parts.join(' · ');
  }

  static String _formatSubtitleTrackLabel(SubtitleTrack track) {
    if (track.id == SubtitleTrack.off.id) return 'Desligada';
    if (track.id == SubtitleTrack.auto.id) return 'Automática';
    final parts = <String>[];
    final title = track.title?.trim();
    if (title != null && title.isNotEmpty) parts.add(title);
    final language = track.language?.trim();
    if (language != null && language.isNotEmpty && !parts.any((p) => p.toLowerCase() == language.toLowerCase())) {
      parts.add(language.toUpperCase());
    }
    final codec = track.codec?.trim();
    if (codec != null && codec.isNotEmpty) parts.add(codec.toUpperCase());
    if (track.isExternal) parts.add('Externa');
    if (track.isForced) parts.add('Forçada');
    return parts.isEmpty ? 'Legenda ${track.id}' : parts.join(' · ');
  }

  static String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _MenuButtonPill extends StatelessWidget {
  const _MenuButtonPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: HeisucaTheme.roxoSuperficieElevada,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HeisucaTheme.roxoLinha),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: HeisucaTypography.bodyMetadata.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

sealed class _SubtitleMenuChoice {
  const _SubtitleMenuChoice();
}

final class _ExternalSubtitleChoice extends _SubtitleMenuChoice {
  const _ExternalSubtitleChoice();
}

final class _SelectSubtitleChoice extends _SubtitleMenuChoice {
  const _SelectSubtitleChoice(this.track);

  final SubtitleTrack track;
}

class _OpenUrlDialog extends StatefulWidget {
  const _OpenUrlDialog();

  @override
  State<_OpenUrlDialog> createState() => _OpenUrlDialogState();
}

class _OpenUrlDialogState extends State<_OpenUrlDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _submittedOnce = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Informe um endereço HTTP ou HTTPS.';
    }
    if (trimmed.contains(RegExp(r'\s'))) {
      return 'O endereço não pode conter espaços.';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return 'Endereço inválido. Use http:// ou https://.';
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return 'Protocolo não suportado. Use apenas http:// ou https://.';
    }
    if (uri.host.isEmpty) {
      return 'Endereço incompleto: informe o servidor.';
    }
    return null;
  }

  void _submit() {
    final error = _validateUrl(_controller.text);
    if (error != null) {
      setState(() {
        _submittedOnce = true;
        _errorText = error;
      });
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: HeisucaTheme.roxoSuperficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HeisucaTheme.raioCard),
        side: const BorderSide(color: HeisucaTheme.roxoLinha),
      ),
      title: const Text('Abrir URL HTTP(S)'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informe um endereço direto http:// ou https:// para reprodução.',
              style: HeisucaTypography.bodyMetadata.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Endereço da mídia',
                hintText: 'https://...',
                errorText: _errorText,
                filled: true,
                fillColor: HeisucaTheme.roxoSuperficieElevada,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HeisucaTheme.raioInput),
                ),
              ),
              onChanged: (value) {
                if (_submittedOnce) {
                  setState(() => _errorText = _validateUrl(value));
                }
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Reproduzir'),
        ),
      ],
    );
  }
}
