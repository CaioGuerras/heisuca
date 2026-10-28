import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focusable_wrapper.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'backend_badge.dart';
import 'bottom_sheet_page_scaffold.dart';
import 'clickable_cursor.dart';

class RatingBottomSheet extends StatefulWidget {
  final MediaItem item;
  final MediaServerClient? serverClient;
  final ValueChanged<double>? onServerRatingChanged;
  final ValueChanged<bool>? onServerFavoriteChanged;

  const RatingBottomSheet({
    super.key,
    required this.item,
    required this.serverClient,
    this.onServerRatingChanged,
    this.onServerFavoriteChanged,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  static const _autoSaveDelay = Duration(milliseconds: 600);

  late double _serverStars;
  late double _serverRating;
  late bool _serverFavorite;
  late final FocusNode _serverFocusNode;

  final Map<String, Timer> _autoSaveTimers = {};
  final Set<String> _pendingAutoSaves = {};
  final Set<String> _loading = {};
  final Map<String, _SectionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _serverFocusNode = FocusNode(debugLabel: 'rating_server');
    final rawServerRating = widget.item.userRating;
    _serverRating = rawServerRating != null && rawServerRating > 0 ? rawServerRating : 0.0;
    _serverStars = _serverRating > 0 ? _serverRating / 2.0 : 0.0;
    _serverFavorite = widget.item.isFavorite == true;
  }

  @override
  void dispose() {
    _flushPendingAutoSavesOnDispose();
    _serverFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverCaps = widget.serverClient?.capabilities;
    final showServerRow = serverCaps != null && (serverCaps.numericUserRating || serverCaps.userFavorites);

    // Só a avaliação do servidor: os serviços externos (Trakt etc.) saíram.
    return BottomSheetPageScaffold(
      title: t.rateSheet.title,
      icon: Symbols.star_rounded,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
        children: [
          if (showServerRow)
            _buildServerRow(
              widget.serverClient!,
              _serverFocusNode,
              autofocus: true,
              onNavigateUp: null,
              onNavigateDown: null,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                t.rateSheet.noConnectedServices,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerRow(
    MediaServerClient client,
    FocusNode focusNode, {
    required bool autofocus,
    required VoidCallback? onNavigateUp,
    required VoidCallback? onNavigateDown,
  }) {
    final loading = _loading.contains(_serverKey);
    final status = _statuses[_serverKey];
    final subtitle =
        '${_backendLabel(client.backend)} - ${client.serverName ?? widget.item.serverName ?? t.common.unknown}';

    if (client.capabilities.numericUserRating) {
      final value = (_serverStars * 2).round().clamp(0, 10).toInt();
      return _RatingRow(
        focusNode: focusNode,
        autofocus: autofocus,
        leading: BackendBadge(backend: client.backend, size: 22),
        title: t.rateSheet.server,
        subtitle: subtitle,
        loading: loading,
        status: status,
        enabled: !loading,
        onNavigateUp: onNavigateUp,
        onNavigateDown: onNavigateDown,
        onDecrease: () => _setServerStarUnits(value - 1),
        onIncrease: () => _setServerStarUnits(value + 1),
        onSubmit: () => unawaited(_submitServerStars()),
        control: _StarRatingControl(
          value: value,
          enabled: !loading,
          onChanged: _setServerStarUnits,
          onSubmitValue: (units) => unawaited(_submitServerStars(stars: units / 2.0)),
        ),
      );
    }

    return _RatingRow(
      focusNode: focusNode,
      autofocus: autofocus,
      leading: BackendBadge(backend: client.backend, size: 22),
      title: t.rateSheet.server,
      subtitle: subtitle,
      loading: loading,
      status: status,
      enabled: !loading,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      onDecrease: () => _setServerFavorite(false),
      onIncrease: () => _setServerFavorite(true),
      onSubmit: () => unawaited(_submitServerFavorite(value: !_serverFavorite)),
      control: _FavoriteControl(
        value: _serverFavorite,
        enabled: !loading,
        onToggle: (next) => unawaited(_submitServerFavorite(value: next)),
      ),
    );
  }

  void _setServerStarUnits(int units) {
    final clamped = units.clamp(0, 10).toInt();
    if ((_serverStars * 2).round() == clamped) return;
    setState(() {
      _serverStars = clamped / 2.0;
      _statuses.remove(_serverKey);
    });
    _scheduleAutoSave(_serverKey, _submitServerStars);
  }

  void _setServerFavorite(bool value) {
    if (_serverFavorite == value) return;
    setState(() {
      _serverFavorite = value;
      _statuses.remove(_serverKey);
    });
    _scheduleAutoSave(_serverKey, _submitServerFavorite);
  }

  Future<void> _submitServerStars({double? stars}) async {
    _cancelAutoSave(_serverKey);
    final value = stars ?? _serverStars;
    if (value <= 0) {
      await _clearServerRating();
      return;
    }

    final rating = value * 2.0;
    await _run(_serverKey, () async {
      await widget.serverClient!.rate(widget.item, rating);
      _serverRating = rating;
      _serverStars = value;
      widget.onServerRatingChanged?.call(rating);
    });
  }

  Future<void> _clearServerRating() async {
    _cancelAutoSave(_serverKey);
    await _run(_serverKey, () async {
      await widget.serverClient!.rate(widget.item, -1);
      _serverRating = 0;
      _serverStars = 0;
      widget.onServerRatingChanged?.call(0);
    });
  }

  Future<void> _submitServerFavorite({bool? value}) async {
    _cancelAutoSave(_serverKey);
    final selected = value ?? _serverFavorite;
    await _run(_serverKey, () async {
      await widget.serverClient!.setFavorite(widget.item, selected);
      _serverFavorite = selected;
      widget.onServerFavoriteChanged?.call(selected);
    });
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    setState(() {
      _loading.add(key);
      _statuses.remove(key);
    });

    try {
      await action();
      if (!mounted) return;
      setState(() {
        _statuses[key] = _SectionStatus(t.rateSheet.saved);
      });
    } catch (e) {
      appLogger.w('Failed to update rating', error: e);
      if (!mounted) return;
      setState(() {
        _statuses[key] = _SectionStatus(t.errors.failedToRate, isError: true);
      });
      showErrorSnackBar(context, t.errors.failedToRate);
    } finally {
      if (mounted) {
        setState(() {
          _loading.remove(key);
        });
      }
    }
  }

  void _scheduleAutoSave(String key, Future<void> Function() submit) {
    _pendingAutoSaves.add(key);
    _autoSaveTimers.remove(key)?.cancel();
    _autoSaveTimers[key] = Timer(_autoSaveDelay, () {
      _autoSaveTimers.remove(key);
      _pendingAutoSaves.remove(key);
      unawaited(submit());
    });
  }

  void _cancelAutoSave(String key) {
    _autoSaveTimers.remove(key)?.cancel();
    _pendingAutoSaves.remove(key);
  }

  void _flushPendingAutoSavesOnDispose() {
    final pendingKeys = Set<String>.from(_pendingAutoSaves);
    for (final key in pendingKeys) {
      _autoSaveTimers.remove(key)?.cancel();
    }
    _pendingAutoSaves.clear();

    for (final key in pendingKeys) {
      if (key == _serverKey) unawaited(_saveServerRatingDetached());
    }
  }

  Future<void> _saveServerRatingDetached() async {
    final client = widget.serverClient;
    if (client == null) return;

    try {
      if (client.capabilities.numericUserRating) {
        final rating = _serverStars <= 0 ? -1.0 : _serverStars * 2.0;
        await client.rate(widget.item, rating);
        widget.onServerRatingChanged?.call(rating < 0 ? 0 : rating);
        return;
      }

      await client.setFavorite(widget.item, _serverFavorite);
      widget.onServerFavoriteChanged?.call(_serverFavorite);
    } catch (e) {
      appLogger.w('Failed to update rating after sheet close', error: e);
    }
  }

  String _backendLabel(MediaBackend backend) => backend.dialect?.productName ?? 'Plex';
}

const _serverKey = 'server';

class _SectionStatus {
  final String text;
  final bool isError;

  const _SectionStatus(this.text, {this.isError = false});
}

class _RatingRow extends StatelessWidget {
  final FocusNode focusNode;
  final bool autofocus;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool loading;
  final _SectionStatus? status;
  final bool enabled;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSubmit;
  final Widget control;

  const _RatingRow({
    required this.focusNode,
    required this.autofocus,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.status,
    required this.enabled,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSubmit,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = this.status;
    final statusText = status?.isError == true ? status!.text : subtitle;
    final statusColor = status?.isError == true ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    final controlWidth = MediaQuery.sizeOf(context).width < 390 ? 124.0 : 142.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FocusableWrapper(
        focusNode: focusNode,
        autofocus: autofocus && InputModeTracker.isKeyboardMode(context),
        borderRadius: 12,
        autoScroll: true,
        disableScale: true,
        useBackgroundFocus: true,
        descendantsAreFocusable: false,
        onSelect: enabled ? onSubmit : null,
        onNavigateUp: onNavigateUp,
        onNavigateDown: onNavigateDown,
        onKeyEvent: (_, event) {
          if (!enabled || !event.isActionable) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key.isLeftKey) {
            onDecrease();
            return KeyEventResult.handled;
          }
          if (key.isRightKey) {
            onIncrease();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: leading)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: .w700)),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: controlWidth, child: control),
              const SizedBox(width: 8),
              SizedBox(
                width: 18,
                height: 18,
                child: _TrailingStatus(loading: loading, status: status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  final bool loading;
  final _SectionStatus? status;

  const _TrailingStatus({required this.loading, required this.status});

  @override
  Widget build(BuildContext context) {
    if (loading) return const CircularProgressIndicator(strokeWidth: 2);
    final status = this.status;
    if (status == null) return const SizedBox.shrink();
    final color = status.isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: status.text,
      child: AppIcon(
        status.isError ? Symbols.error_rounded : Symbols.check_circle_rounded,
        fill: 1,
        color: color,
        size: 18,
      ),
    );
  }
}

class _StarRatingControl extends StatefulWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSubmitValue;

  const _StarRatingControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitValue,
  });

  @override
  State<_StarRatingControl> createState() => _StarRatingControlState();
}

class _StarRatingControlState extends State<_StarRatingControl> {
  int? _pointerValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final starWidth = (constraints.maxWidth / 5).clamp(0.0, 27.0).toDouble();
        final iconSize = (starWidth * 0.9).clamp(0.0, 24.0).toDouble();
        return ClickableCursor(
          enabled: widget.enabled,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.enabled ? (details) => _setFromDx(details.localPosition.dx, constraints.maxWidth) : null,
            onTapUp: widget.enabled ? (_) => widget.onSubmitValue(_pointerValue ?? widget.value) : null,
            onPanUpdate: widget.enabled
                ? (details) => _setFromDx(details.localPosition.dx, constraints.maxWidth)
                : null,
            onPanEnd: widget.enabled ? (_) => widget.onSubmitValue(_pointerValue ?? widget.value) : null,
            child: SizedBox(
              height: 34,
              child: Row(
                mainAxisAlignment: .end,
                children: List.generate(5, (i) {
                  final threshold = (i + 1) * 2;
                  final filled = widget.value >= threshold;
                  final half = widget.value == threshold - 1;
                  return SizedBox(
                    width: starWidth,
                    child: Center(
                      child: AppIcon(
                        half ? Symbols.star_half_rounded : Symbols.star_rounded,
                        fill: filled || half ? 1 : 0,
                        color: filled || half
                            ? Colors.amber
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
                        size: iconSize,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setFromDx(double dx, double width) {
    final safeWidth = width <= 0 ? 1.0 : width;
    final value = ((dx.clamp(0.0, safeWidth) / safeWidth) * 10).round().clamp(0, 10).toInt();
    _pointerValue = value;
    widget.onChanged(value);
  }
}

class _FavoriteControl extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _FavoriteControl({required this.value, required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ClickableCursor(
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onToggle(!value) : null,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.54),
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
          child: Row(
            mainAxisAlignment: .center,
            children: [
              AppIcon(
                Symbols.favorite_rounded,
                fill: value ? 1 : 0,
                color: value ? Colors.redAccent : (enabled ? scheme.onSurfaceVariant : theme.disabledColor),
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value ? t.rateSheet.favorited : t.rateSheet.favorite,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: .w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
