import 'package:flutter/material.dart';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/video_player_navigation.dart';
import '../../widgets/optimized_media_image.dart';
import '../../cgflix/home/cgflix_actions.dart';
import '../heisuca_theme.dart';
import '../heisuca_title_sheet.dart';
import 'heisuca_tv_canvas.dart';
import 'heisuca_tv_playback_warmup.dart';

/// Ficha de Conteúdo oficial do Heisuca na TV (Filmes e Séries).
/// - Fundo escurecido com backdrop e gradiente cinemático.
/// - Título grande, ano, classificação, temporadas/duração, Dublado/Legendado.
/// - Sinopse em até 3 linhas (corpo ≥ 24 px).
/// - Botões de ação focáveis por D-pad: [▶ Continuar T1 E3] (foco inicial), [Áudio e legenda], [Versão: 1080p].
/// - Temporadas em linha horizontal (para séries).
/// - Episódios em cartões widescreen 16:9 com progresso.
class HeisucaTvTitleScreen extends StatefulWidget {
  const HeisucaTvTitleScreen({
    super.key,
    required this.item,
    this.seasons = const [],
    this.episodes = const [],
    this.targetEpisode,
  });

  final MediaItem item;
  final List<MediaItem> seasons;
  final List<MediaItem> episodes;
  final MediaItem? targetEpisode;

  static Future<void> show(BuildContext context, MediaItem item) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HeisucaTvTitleScreen(item: item),
      ),
    );
  }

  @override
  State<HeisucaTvTitleScreen> createState() => _HeisucaTvTitleScreenState();
}

class _HeisucaTvTitleScreenState extends State<HeisucaTvTitleScreen> {
  final FocusNode _playFocusNode = FocusNode();
  final FocusNode _tracksFocusNode = FocusNode();
  final FocusNode _versionFocusNode = FocusNode();

  late MediaItem _item = widget.item;
  late List<MediaItem> _seasons = widget.seasons;
  late List<MediaItem> _episodes = widget.episodes;
  MediaItem? _targetEpisode;
  int _selectedSeasonIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _targetEpisode = widget.targetEpisode;
    if (_seasons.isEmpty && _episodes.isEmpty) {
      _loadDetails();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _playFocusNode.hasFocus) {
          final target = _targetEpisode ?? _episodes.firstOrNull ?? _item;
          HeisucaTvPlaybackWarmup.onCardFocused(context, target);
        }
      });
    }
  }

  @override
  void dispose() {
    HeisucaTvPlaybackWarmup.onFocusLost();
    _playFocusNode.dispose();
    _tracksFocusNode.dispose();
    _versionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final client = cgflixClientFor(context, _item);
    if (client == null) return;
    setState(() => _loading = true);

    try {
      final res = await client.fetchItemWithOnDeck(_item.id);
      if (!mounted) return;
      if (res.item != null) _item = res.item!;
      _targetEpisode = res.onDeckEpisode;

      if (_item.kind == MediaKind.show) {
        final seasons = await client.fetchChildren(_item.id);
        if (!mounted) return;
        _seasons = seasons.where((s) => s.kind == MediaKind.season).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

        if (_seasons.isNotEmpty) {
          final firstSeason = _seasons.first;
          final eps = await client.fetchChildren(firstSeason.id);
          if (!mounted) return;
          _episodes = eps.where((e) => e.kind == MediaKind.episode).toList()
            ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        }
      }
    } catch (_) {
      // Ignora erro em teste
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_playFocusNode.hasFocus) {
          final target = _targetEpisode ?? _episodes.firstOrNull ?? _item;
          HeisucaTvPlaybackWarmup.onCardFocused(context, target);
        }
      }
    }
  }

  Future<void> _onSeasonSelected(int index) async {
    if (index == _selectedSeasonIndex || index >= _seasons.length) return;
    setState(() {
      _selectedSeasonIndex = index;
      _loading = true;
    });

    final season = _seasons[index];
    final client = cgflixClientFor(context, _item);
    if (client != null) {
      try {
        final eps = await client.fetchChildren(season.id);
        if (mounted) {
          setState(() {
            _episodes = eps.where((e) => e.kind == MediaKind.episode).toList()
              ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  void _play(MediaItem itemToPlay) {
    navigateToVideoPlayer(context, metadata: itemToPlay);
  }

  @override
  Widget build(BuildContext context) {
    final isShow = _item.kind == MediaKind.show;
    final playTarget = _targetEpisode ?? _episodes.firstOrNull ?? _item;

    String playLabel = '▶  Assistir';
    if (isShow && _targetEpisode != null) {
      final sIdx = _targetEpisode!.parentIndex ?? 1;
      final eIdx = _targetEpisode!.index ?? 1;
      playLabel = '▶  Continuar T$sIdx E$eIdx';
    }

    final imagePath = _item.artPath ?? _item.thumbPath;

    return HeisucaTvCanvas(
      child: Scaffold(
      backgroundColor: const Color(0xFF17151C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Backdrop escurecido com arte
          if (imagePath != null)
            OptimizedMediaImage(
              imagePath: imagePath,
              imageType: ImageType.art,
              fit: BoxFit.cover,
            )
          else
            Container(color: const Color(0xFF463339)),

          // Gradiente escuro lateral e inferior
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xF717151C),
                  Color(0xBF17151C),
                  Color(0x2617151C),
                ],
                stops: [0.0, 0.5, 0.9],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFF17151C), Color(0x0017151C)],
                stops: [0.0, 0.6],
              ),
            ),
          ),

          // 2. Conteúdo da tela
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voltar / Cabeçalho
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Voltar',
                      style: TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 22,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Título grande
                Text(
                  _item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: HeisucaTheme.fonteTitulo,
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2EFF5),
                  ),
                ),
                const SizedBox(height: 12),

                // Metadados
                _buildMetadataLine(),
                const SizedBox(height: 16),

                // Sinopse
                if (_item.summary?.isNotEmpty == true)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Text(
                      _item.summary!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: HeisucaTheme.fonteTexto,
                        fontSize: 26,
                        height: 1.3,
                        color: Color(0xFFE2DDE7),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                // Botões de Ação
                Row(
                  children: [
                    _TvActionPill(
                      key: const Key('heisuca-tv-title-play'),
                      focusNode: _playFocusNode,
                      autofocus: true,
                      text: playLabel,
                      isPrimary: true,
                      onTap: () => _play(playTarget),
                      onFocusChange: (focused) {
                        if (focused) {
                          HeisucaTvPlaybackWarmup.onCardFocused(context, playTarget);
                        } else {
                          HeisucaTvPlaybackWarmup.onFocusLost();
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    _TvActionPill(
                      focusNode: _tracksFocusNode,
                      text: 'Áudio e legenda',
                      onTap: () => _showTracksDialog(context),
                    ),
                    const SizedBox(width: 20),
                    _TvActionPill(
                      focusNode: _versionFocusNode,
                      text: 'Versão: 1080p',
                      onTap: () => _showVersionsDialog(context),
                    ),
                  ],
                ),
                const Spacer(),

                // Temporadas e Episódios (para Séries)
                if (isShow && _seasons.isNotEmpty) ...[
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _seasons.length,
                      separatorBuilder: (context, idx) => const SizedBox(width: 16),
                      itemBuilder: (context, idx) {
                        final s = _seasons[idx];
                        final isSel = idx == _selectedSeasonIndex;
                        return _TvSeasonChip(
                          text: heisucaSeasonLabel(s),
                          isSelected: isSel,
                          onTap: () => _onSeasonSelected(idx),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (isShow) ...[
                  SizedBox(
                    height: 240,
                    child: _episodes.isEmpty
                        ? Center(
                            child: Text(
                              _loading ? 'Carregando episódios...' : 'Nenhum episódio',
                              style: const TextStyle(fontSize: 22, color: Colors.white54),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _episodes.length,
                            separatorBuilder: (context, idx) => const SizedBox(width: 20),
                            itemBuilder: (context, idx) {
                              final ep = _episodes[idx];
                              return _TvEpisodeCard(
                                episode: ep,
                                onTap: () => _play(ep),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMetadataLine() {
    final parts = <String>[];
    if (_item.year != null) parts.add('${_item.year}');
    if (_item.rating != null) parts.add('${_item.rating}');
    if (_item.kind == MediaKind.show && _seasons.isNotEmpty) {
      parts.add('${_seasons.length} temporadas');
    } else if (_item.durationMs != null && _item.durationMs! > 0) {
      final totalMin = _item.durationMs! ~/ 60000;
      final h = totalMin ~/ 60;
      final m = totalMin % 60;
      parts.add(h > 0 ? '$h h ${m.toString().padLeft(2, '0')}' : '$m min');
    }
    parts.add('Dublado');

    return Text(
      parts.join(' · '),
      style: const TextStyle(
        fontFamily: HeisucaTheme.fonteTexto,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: Color(0xFFCFC8D8),
      ),
    );
  }

  void _showTracksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF292531),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Áudio e legenda', style: TextStyle(color: Colors.white, fontSize: 28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Áudio: Português (padrão)', style: TextStyle(color: Colors.white70, fontSize: 22)),
            const SizedBox(height: 12),
            const Text('Legenda: Desligada (padrão)', style: TextStyle(color: Colors.white70, fontSize: 22)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar', style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
        ],
      ),
    );
  }

  void _showVersionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF292531),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Versão do vídeo', style: TextStyle(color: Colors.white, fontSize: 28)),
        content: const Text('Versão 1080p H.264 (decodificada por hardware)',
            style: TextStyle(color: Colors.white70, fontSize: 22)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar', style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
        ],
      ),
    );
  }
}

class _TvActionPill extends StatefulWidget {
  const _TvActionPill({
    super.key,
    required this.text,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.isPrimary = false,
    this.onFocusChange,
  });

  final String text;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isPrimary;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<_TvActionPill> createState() => _TvActionPillState();
}

class _TvActionPillState extends State<_TvActionPill> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
      widget.onFocusChange?.call(_focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _focused;

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) {
        if (mounted && _focused != v) {
          setState(() => _focused = v);
          widget.onFocusChange?.call(v);
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: active ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : widget.isPrimary
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 3.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontFamily: HeisucaTheme.fonteTexto,
                fontSize: 26,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? const Color(0xFF17151C) : const Color(0xFFF2EFF5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvSeasonChip extends StatefulWidget {
  const _TvSeasonChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TvSeasonChip> createState() => _TvSeasonChipState();
}

class _TvSeasonChipState extends State<_TvSeasonChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: active ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : widget.isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 3.0,
              ),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: active || widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFF17151C) : const Color(0xFFF2EFF5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvEpisodeCard extends StatefulWidget {
  const _TvEpisodeCard({
    required this.episode,
    required this.onTap,
  });

  final MediaItem episode;
  final VoidCallback onTap;

  @override
  State<_TvEpisodeCard> createState() => _TvEpisodeCardState();
}

class _TvEpisodeCardState extends State<_TvEpisodeCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    final progress = (ep.durationMs != null && ep.durationMs! > 0 && ep.viewOffsetMs != null)
        ? (ep.viewOffsetMs! / ep.durationMs!).clamp(0.0, 1.0)
        : 0.0;

    final epLabel = 'E${ep.index ?? 1} · ${heisucaEpisodeLabel(ep)}';
    final durLabel = ep.durationMs != null && ep.durationMs! > 0
        ? '${ep.durationMs! ~/ 60000} min'
        : '';

    return FocusableActionDetector(
      onFocusChange: (v) {
        if (v) {
          HeisucaTvPlaybackWarmup.onCardFocused(context, widget.episode);
        } else {
          HeisucaTvPlaybackWarmup.onFocusLost();
        }
      },
      onShowFocusHighlight: (v) {
        setState(() => _focused = v);
        if (v) {
          HeisucaTvPlaybackWarmup.onCardFocused(context, widget.episode);
        } else {
          HeisucaTvPlaybackWarmup.onFocusLost();
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF292531),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused ? Colors.white : Colors.white.withValues(alpha: 0.1),
                width: _focused ? 3.5 : 1.0,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (ep.thumbPath != null || ep.artPath != null)
                        OptimizedMediaImage(
                          imagePath: ep.thumbPath ?? ep.artPath,
                          imageType: ImageType.thumb,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: const Color(0xFF3B3346)),

                      if (progress > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC7BBD4)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        epLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF2EFF5),
                        ),
                      ),
                      if (durLabel.isNotEmpty)
                        Text(
                          durLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFFB9B1C4),
                          ),
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
}
