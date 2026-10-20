// Etapa 1E: telas dos pedidos (Seerr), todas nativas e sem login:
//   - CgflixRequestSection: "Disponível para pedir", logo abaixo do que já temos na busca;
//   - escolha de temporadas ao pedir uma série (padrão: todas);
//   - CgflixMyRequestsScreen: "Meus pedidos" (menu do usuário).
// Se o Seerr não responder, a seção vira um aviso pequeno ("Pedidos indisponíveis agora").
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../providers/multi_server_provider.dart';
import '../../services/jellyfin_client.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';
import '../cgflix_palette.dart';
import '../cgflix_style.dart';
import '../home/cgflix_cards.dart';
import 'cgflix_seerr.dart';

// ---------------------------------------------------------------------------
// De onde vêm os pedidos

abstract final class CgflixRequests {
  /// Testes e o app do emulador põem aqui um falso (sem servidor).
  static CgflixRequestsBackend? debugOverride;

  static final _byAccount = <String, ({JellyfinClient client, CgflixSeerrRequests backend})>{};

  /// Pedidos da conta Jellyfin conectada (a mesma da Início); null sem Jellyfin.
  static CgflixRequestsBackend? of(BuildContext context) {
    final override = debugOverride;
    if (override != null) return override;
    final MultiServerProvider? servers;
    try {
      servers = Provider.of<MultiServerProvider?>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
    final client = servers?.serverManager.visibleOnlineClients.values.whereType<JellyfinClient>().firstOrNull;
    if (client == null) return null;
    final key = '${client.serverId.value}:${client.cgflixUserId}';
    final known = _byAccount[key];
    // Mesmo cliente: reaproveita (a sessão do Seerr fica na memória dele).
    if (known != null && identical(known.client, client)) return known.backend;
    final backend = CgflixSeerrRequests(
      jellyfinBaseUrl: client.cgflixBaseUrl,
      accountKey: key,
      authorizeQuickConnect: client.cgflixAuthorizeQuickConnect,
    );
    _byAccount[key] = (client: client, backend: backend);
    return backend;
  }
}

const cgflixRequestDoneMessage = 'Pedido feito. Avisamos quando chegar.';
const cgflixRequestsUnavailableMessage = 'Pedidos indisponíveis agora';

// ---------------------------------------------------------------------------
// Busca: "Disponível para pedir"

class CgflixRequestSection extends StatefulWidget {
  const CgflixRequestSection({super.key, required this.query, this.enabled = true});
  final String query;
  final bool enabled;

  @override
  State<CgflixRequestSection> createState() => _CgflixRequestSectionState();
}

enum _SectionState { loading, ready, unavailable }

class _CgflixRequestSectionState extends State<CgflixRequestSection> {
  _SectionState _state = _SectionState.loading;
  List<CgflixRequestable> _items = const [];
  final _busy = <int>{};
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CgflixRequestSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query || oldWidget.enabled != widget.enabled) _load();
  }

  void _load() {
    final request = ++_request;
    final query = widget.query.trim();
    final backend = widget.enabled && query.length >= 2 ? CgflixRequests.of(context) : null;
    if (backend == null) {
      setState(() {
        _state = _SectionState.ready;
        _items = const [];
      });
      return;
    }
    if (_state != _SectionState.loading) setState(() => _state = _SectionState.loading);
    backend
        .search(query)
        .then((items) {
          if (!mounted || request != _request) return;
          setState(() {
            _items = items;
            _state = _SectionState.ready;
          });
        })
        .catchError((Object e) {
          appLogger.i('CGFLIX: "Disponível para pedir" fora do ar', error: e);
          if (!mounted || request != _request) return;
          setState(() => _state = _SectionState.unavailable);
        });
  }

  Future<void> _ask(CgflixRequestable item) async {
    final backend = CgflixRequests.of(context);
    if (backend == null || _busy.contains(item.tmdbId)) return;
    unawaited(HapticFeedback.lightImpact());
    List<int>? seasons;
    if (!item.isMovie) {
      final picked = await showCgflixSeasonPicker(context, backend: backend, item: item);
      if (picked == null || !mounted) return;
      seasons = picked.isEmpty ? null : picked;
    }
    setState(() => _busy.add(item.tmdbId));
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await backend.request(item, seasons: seasons);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final i in _items) i.tmdbId == item.tmdbId ? i.copyWith(state: CgflixRequestState.requested) : i,
        ];
      });
      messenger?.showSnackBar(const SnackBar(content: Text(cgflixRequestDoneMessage)));
    } on CgflixRequestRejected catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      appLogger.w('CGFLIX: pedido falhou', error: e);
      messenger?.showSnackBar(const SnackBar(content: Text('Não deu para pedir agora. Tente de novo mais tarde.')));
    } finally {
      if (mounted) setState(() => _busy.remove(item.tmdbId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (_state) {
      _SectionState.loading => const _SectionSkeleton(key: ValueKey('carregando')),
      _SectionState.unavailable => Padding(
        key: const ValueKey('indisponivel'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Row(
          children: [
            AppIcon(Symbols.cloud_off_rounded, size: 18, color: context.cgflix.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(cgflixRequestsUnavailableMessage, style: TextStyle(color: context.cgflix.textMuted)),
            ),
          ],
        ),
      ),
      _SectionState.ready when _items.isEmpty => const SizedBox.shrink(key: ValueKey('vazio')),
      _SectionState.ready => Column(
        key: const ValueKey('resultados'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Semantics(
              header: true,
              child: Text(
                'Disponível para pedir',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Ainda não temos. Peça e avisamos quando chegar.',
              style: TextStyle(color: context.cgflix.textMuted, fontSize: 13),
            ),
          ),
          for (final item in _items)
            CgflixRequestTile(
              key: ValueKey('cgflix-pedir-${item.isMovie ? 'filme' : 'serie'}-${item.tmdbId}'),
              item: item,
              busy: _busy.contains(item.tmdbId),
              onRequest: () => _ask(item),
            ),
          const SizedBox(height: 24),
        ],
      ),
    };
    return AnimatedSize(
      duration: CgflixMotion.medium,
      curve: CgflixMotion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(duration: CgflixMotion.medium, child: child),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: CgflixShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CgflixSkeletonBox(width: 180, height: 18, radius: 4),
          SizedBox(height: 12),
          Row(
            children: [
              CgflixSkeletonBox(width: 56, height: 84),
              SizedBox(width: 12),
              CgflixSkeletonBox(width: 140, height: 14, radius: 4),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Cartão de um título do Seerr: capa, nome, ano/tipo e o botão "Pedir" (ou o selo da situação).
class CgflixRequestTile extends StatelessWidget {
  const CgflixRequestTile({super.key, required this.item, required this.onRequest, this.busy = false});
  final CgflixRequestable item;
  final VoidCallback onRequest;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [if (item.year != null) '${item.year}', item.isMovie ? 'Filme' : 'Série'].join(' · ');
    final Widget action = switch (item.state) {
      CgflixRequestState.requestable => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: context.cgflix.action,
          foregroundColor: context.cgflix.onAction,
          minimumSize: const Size(96, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: busy ? null : onRequest,
        icon: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.cgflix.onAction),
              )
            : AppIcon(Symbols.add_rounded, size: 18, color: context.cgflix.onAction),
        label: Text('Pedir', semanticsLabel: 'Pedir ${item.title}'),
      ),
      CgflixRequestState.requested => const CgflixStatusBadge(label: 'Pedido', icon: Symbols.schedule_rounded),
      CgflixRequestState.downloading => const CgflixStatusBadge(label: 'Baixando', icon: Symbols.download_rounded),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 84,
              child: ColoredBox(
                color: context.cgflix.surfaceHigh,
                child: OptimizedMediaImage.poster(imagePath: item.posterUrl, width: 56, height: 84),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: context.cgflix.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class CgflixStatusBadge extends StatelessWidget {
  const CgflixStatusBadge({super.key, required this.label, required this.icon, this.color});
  final String label;
  final IconData icon;

  /// Cor do selo; sem ela, o destaque suave do tema (lilás na Isis, verde no Heitor).
  final Color? color;

  @override
  Widget build(BuildContext context) => _build(color ?? context.cgflix.accentSoft);

  Widget _build(Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Escolha das temporadas

/// Folha com as temporadas da série (todas marcadas). Devolve as escolhidas (`[]` = todas,
/// para o Seerr pegar também as que vierem depois) ou null se cancelou.
Future<List<int>?> showCgflixSeasonPicker(
  BuildContext context, {
  required CgflixRequestsBackend backend,
  required CgflixRequestable item,
}) => showModalBottomSheet<List<int>>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.cgflix.surface,
  constraints: const BoxConstraints(maxWidth: 560),
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => CgflixSeasonPickerSheet(backend: backend, item: item),
);

class CgflixSeasonPickerSheet extends StatefulWidget {
  const CgflixSeasonPickerSheet({super.key, required this.backend, required this.item});
  final CgflixRequestsBackend backend;
  final CgflixRequestable item;

  @override
  State<CgflixSeasonPickerSheet> createState() => _CgflixSeasonPickerSheetState();
}

class _CgflixSeasonPickerSheetState extends State<CgflixSeasonPickerSheet> {
  List<CgflixSeasonChoice>? _seasons;
  Set<int> _picked = {};
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.backend
        .seasons(widget.item.tmdbId)
        .then((seasons) {
          if (!mounted) return;
          setState(() {
            _seasons = seasons;
            _picked = {
              for (final s in seasons)
                if (s.lockedLabel == null) s.number,
            };
          });
        })
        .catchError((Object e) {
          appLogger.w('CGFLIX: temporadas do pedido falharam', error: e);
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seasons = _seasons;
    final open = seasons?.where((s) => s.lockedLabel == null).toList() ?? const <CgflixSeasonChoice>[];
    final allPicked = open.isNotEmpty && open.every((s) => _picked.contains(s.number));
    final Widget body;
    if (_failed) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(cgflixRequestsUnavailableMessage, style: TextStyle(color: context.cgflix.textMuted)),
      );
    } else if (seasons == null) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      body = Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            if (open.length > 1)
              CheckboxListTile(
                key: const ValueKey('cgflix-temporadas-todas'),
                value: allPicked,
                title: const Text('Todas as temporadas', style: TextStyle(fontWeight: FontWeight.w700)),
                onChanged: (v) => setState(() => _picked = v == true ? {for (final s in open) s.number} : {}),
              ),
            for (final season in seasons)
              CheckboxListTile(
                value: season.lockedLabel != null || _picked.contains(season.number),
                title: Text(season.name),
                // Sem contagem de episódios: sem a linha vazia embaixo do nome.
                subtitle: season.lockedLabel == null && season.episodes == null
                    ? null
                    : Text(
                        season.lockedLabel ?? '${season.episodes} episódios',
                        style: TextStyle(color: context.cgflix.textMuted),
                      ),
                onChanged: season.lockedLabel != null
                    ? null
                    : (v) => setState(() => v == true ? _picked.add(season.number) : _picked.remove(season.number)),
              ),
          ],
        ),
      );
    }
    final count = _picked.length;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Pedir ${widget.item.title}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body,
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: FilledButton(
              key: const ValueKey('cgflix-temporadas-pedir'),
              style: FilledButton.styleFrom(
                backgroundColor: context.cgflix.action,
                foregroundColor: context.cgflix.onAction,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: count == 0
                  ? null
                  : () => Navigator.of(context).pop(allPicked ? const <int>[] : (_picked.toList()..sort())),
              child: Text(
                count == 0
                    ? 'Escolha uma temporada'
                    : allPicked
                    ? 'Pedir todas'
                    : 'Pedir $count ${count == 1 ? 'temporada' : 'temporadas'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meus pedidos

class CgflixMyRequestsScreen extends StatefulWidget {
  const CgflixMyRequestsScreen({super.key});

  @override
  State<CgflixMyRequestsScreen> createState() => _CgflixMyRequestsScreenState();
}

class _CgflixMyRequestsScreenState extends State<CgflixMyRequestsScreen> {
  Future<List<CgflixMyRequest>>? _future;
  CgflixRequestsBackend? _backend;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) _reload();
  }

  void _reload() {
    _backend = CgflixRequests.of(context);
    final backend = _backend;
    _future = backend == null
        ? Future.error(const CgflixRequestsUnavailable('sem servidor Jellyfin'))
        : backend.myRequests();
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _future;
    } catch (_) {
      // A tela mostra o aviso.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pedidos')),
      body: FutureBuilder<List<CgflixMyRequest>>(
        future: _future,
        builder: (context, snapshot) {
          // Puxar para atualizar mantém a lista na tela (sem piscar nem dois indicadores).
          if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final Widget content;
          if (snapshot.hasError) {
            content = _CenteredMessage(
              icon: Symbols.cloud_off_rounded,
              text: '$cgflixRequestsUnavailableMessage. Confira a internet e tente de novo.',
              action: ('Tentar de novo', _refresh),
            );
          } else if (snapshot.data!.isEmpty) {
            content = const _CenteredMessage(
              icon: Symbols.playlist_add_rounded,
              text: 'Você ainda não pediu nada. Use a busca: o que não temos aparece em "Disponível para pedir".',
            );
          } else {
            final requests = snapshot.data!;
            content = ListView.builder(
              padding: EdgeInsets.fromLTRB(0, 8, 0, MediaQuery.paddingOf(context).bottom + 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) => _MyRequestTile(request: requests[index], backend: _backend),
            );
          }
          return RefreshIndicator(
            color: context.cgflix.accent,
            onRefresh: _refresh,
            child: content is ListView
                ? content
                : LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: content),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;

  /// Botão opcional (rótulo, ação), ex.: "Tentar de novo".
  final (String, Future<void> Function())? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 48, color: context.cgflix.textMuted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.cgflix.textMuted),
          ),
          if (action case (final label, final onPressed)) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
              onPressed: onPressed,
              child: Text(label),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MyRequestTile extends StatefulWidget {
  const _MyRequestTile({required this.request, required this.backend});
  final CgflixMyRequest request;
  final CgflixRequestsBackend? backend;

  @override
  State<_MyRequestTile> createState() => _MyRequestTileState();
}

class _MyRequestTileState extends State<_MyRequestTile> {
  CgflixTitleInfo? _info;

  @override
  void initState() {
    super.initState();
    final request = widget.request;
    if (request.title != null) {
      _info = (title: request.title!, year: request.year, posterUrl: request.posterUrl);
    } else {
      unawaited(_loadInfo());
    }
  }

  Future<void> _loadInfo() async {
    try {
      final info = await widget.backend?.titleInfo(widget.request.tmdbId, isMovie: widget.request.isMovie);
      if (mounted && info != null) setState(() => _info = info);
    } catch (e) {
      appLogger.d('CGFLIX: nome do pedido indisponível', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final info = _info;
    final kind = request.isMovie ? 'Filme' : 'Série';
    final seasons = request.seasons.isEmpty || request.isMovie
        ? null
        : (request.seasons.length == 1
              ? 'Temporada ${request.seasons.single}'
              : '${request.seasons.length} temporadas');
    final (color, icon) = switch (request.status) {
      CgflixMyRequestStatus.available => (context.cgflix.success, Symbols.check_circle_rounded),
      CgflixMyRequestStatus.partiallyAvailable => (context.cgflix.success, Symbols.check_rounded),
      CgflixMyRequestStatus.declined || CgflixMyRequestStatus.failed => (context.cgflix.danger, Symbols.block_rounded),
      CgflixMyRequestStatus.downloading => (context.cgflix.accentSoft, Symbols.download_rounded),
      _ => (context.cgflix.accentSoft, Symbols.schedule_rounded),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 72,
              child: ColoredBox(
                color: context.cgflix.surfaceHigh,
                child: OptimizedMediaImage.poster(imagePath: info?.posterUrl, width: 48, height: 72),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info?.title.isNotEmpty == true ? info!.title : kind,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  [if (info?.year != null) '${info!.year}', kind, ?seasons].join(' · '),
                  style: TextStyle(color: context.cgflix.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                CgflixStatusBadge(label: cgflixMyRequestStatusLabel(request.status), icon: icon, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
