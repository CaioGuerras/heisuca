import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trackers/device_code.dart';
import '../services/trackers/trakt/trakt_auth_service.dart';
import '../services/trackers/trakt/trakt_client.dart';
import '../services/trackers/trakt/trakt_tracker.dart';
import '../services/trackers/tracker_account_store.dart';
import '../services/trackers/tracker_connect_runner.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../services/trackers/tracker_session.dart';
import '../services/trackers/tracker_username_enricher.dart';
import '../utils/app_logger.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

typedef TrackerSessionConnectPipeline =
    Future<bool> Function({
      required String logLabel,
      required Future<TrackerSession?> Function() authorize,
      required Future<TrackerSession> Function(TrackerSession raw) enrich,
      required Future<void> Function(TrackerSession enriched) save,
      required void Function(TrackerSession enriched) assign,
    });

/// Owns the active Trakt session for the
/// currently-selected Plex profile. Single rebind seam:
/// [onActiveProfileChanged] loads every session from its store and pushes it
/// to the matching tracker.
class TrackersProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// [httpClientFactory] must return a fresh client for the eager auth owner,
  /// which is closed when this provider is disposed.
  TrackersProvider({http.Client Function()? httpClientFactory})
    : this._(runConnectPipeline<TrackerSession>, httpClientFactory);

  @visibleForTesting
  TrackersProvider.forTesting({
    required TrackerSessionConnectPipeline connectPipeline,
    http.Client Function()? httpClientFactory,
  }) : this._(connectPipeline, httpClientFactory);

  TrackersProvider._(this._connectPipeline, http.Client Function()? httpClientFactory)
    : _traktAuth = httpClientFactory == null ? TraktAuthService() : TraktAuthService(httpClient: httpClientFactory());

  final TrackerSessionConnectPipeline _connectPipeline;
  final TraktAuthService _traktAuth;

  final _TrackerSlot _trakt = _TrackerSlot(
    TrackerService.trakt,
    (session, {required onInvalidated, onUpdated}) =>
        TraktTracker.instance.rebindSession(session, onSessionInvalidated: onInvalidated, onSessionUpdated: onUpdated),
  );
  late final List<_TrackerSlot> _slots = [_trakt];

  String _activeUserUuid = '';
  int _profileBindingGeneration = 0;
  TrackerService? _connecting;
  Completer<void>? _cancelCompleter;
  int _connectGeneration = 0;

  TrackerSession? get trakt => _trakt.session;

  bool get isTraktConnected => _trakt.session != null;

  /// Cliente Trakt compartilhado com o tracker; nunca duplica a sessão de refresh.
  TraktClient? get traktCatalogClient => _trakt.session == null ? null : TraktTracker.instance.client;

  String? get traktUsername => _trakt.session?.username;

  bool isConnecting(TrackerService service) => _connecting == service;

  /// Cancel an in-flight connect. Completing the completer both wakes the
  /// blocking `Future.any` race and flips `isCompleted` for the next sync check.
  void cancelConnect() {
    _invalidateConnect();
  }

  Future<void> onActiveProfileChanged(String? newUserUuid) async {
    _invalidateConnect();
    final userUuid = newUserUuid ?? '';
    // Drop any in-flight scrobble state and release the resolver (which
    // holds a PlexClient + session cache) before binding to the new profile.
    TrackerCoordinator.instance.onActiveProfileChanged(userUuid);

    final generation = ++_profileBindingGeneration;
    _activeUserUuid = userUuid;
    // Detach the previous profile's clients before loading anything. Until the new
    // sessions arrive, no tracker may hold a session: a write landing in that gap
    // would reach the account we just left while being filed under this profile's
    // retry queue.
    for (final slot in _slots) {
      slot.session = null;
      _rebind(slot);
    }
    // Publish the detach before awaiting: proxy consumers cache the client they
    // were handed, and would otherwise keep using a disposed one until hydration
    // finished.
    safeNotifyListeners();
    // Snapshot each service's rebind generation after that detach, so a disconnect
    // that races this load only suppresses its own service (whose generation
    // moves) rather than dropping the freshly-loaded sessions for the others.
    final rebinds = [for (final slot in _slots) slot.rebindGeneration];
    final results = await Future.wait<TrackerSession?>([for (final slot in _slots) slot.store.load(userUuid)]);
    if (!_isCurrentProfileBinding(userUuid, generation)) return;
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.rebindGeneration != rebinds[i]) continue;
      slot.session = results[i];
      _rebind(slot);
    }
    // Connect/disconnect may flip `needsFribb` — drop cached resolver IDs so
    // the next lookup re-evaluates whether to consult Fribb.
    TrackerCoordinator.instance.invalidateResolverCache();
    unawaited(TrackerCoordinator.instance.flushWriteQueue());
    safeNotifyListeners();
  }

  Future<bool> connectTrakt({required void Function(DeviceCode code) onCodeReady}) => _runConnect(
    _trakt,
    authorize: () => _traktAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: _isConnectCancelled,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichTrakt,
  );

  /// Trakt is the one service that can revoke its token server-side. Local state
  /// is cleared first, so a failed revoke still leaves the user disconnected
  /// here — the token just stays valid on Trakt's side until it expires.
  Future<void> disconnectTrakt() async {
    final session = _trakt.session;
    await _clearAndRebind(_trakt);
    if (session == null) return;

    final client = TraktClient(session, onSessionInvalidated: () {});
    try {
      await client.revoke();
    } catch (e) {
      appLogger.w('Trakt: token revoke failed (already disconnected locally)', error: e);
    } finally {
      client.dispose();
    }
  }

  bool _isConnectCancelled() => _cancelCompleter?.isCompleted ?? false;

  /// Drive one connect under the shared generation/cancel guards. A connect
  /// fills an empty slot; with [replaces] it swaps exactly that bound session
  /// for the new one in place (a reconnect). The replaced session's queued
  /// writes are purged unless [keepQueuedWrites] vouches for them.
  Future<bool> _runConnect(
    _TrackerSlot slot, {
    required Future<TrackerSession?> Function() authorize,
    required Future<TrackerSession> Function(TrackerSession raw) enrich,
    TrackerSession? replaces,
    bool Function()? keepQueuedWrites,
  }) async {
    if (isDisposed || _connecting != null || !identical(slot.session, replaces)) return false;

    final service = slot.service;
    final userUuid = _activeUserUuid;
    final generation = ++_connectGeneration;
    _connecting = service;
    _cancelCompleter = Completer<void>();
    safeNotifyListeners();

    var assigned = false;
    try {
      final completed = await _connectPipeline(
        logLabel: service.name,
        authorize: () async {
          final session = await authorize();
          return _isCurrentConnect(service, userUuid, generation) ? session : null;
        },
        enrich: enrich,
        save: (session) async {
          if (!_isCurrentConnect(service, userUuid, generation)) return;
          await slot.store.save(userUuid, session);
        },
        assign: (session) {
          if (!_isCurrentConnect(service, userUuid, generation)) return;
          slot.session = session;
          _rebind(slot);
          // Same ordering contract as [_clearAndRebind] and the invalidation
          // teardown: the rebind above moved the account binding first, so an
          // in-flight write that fails after this point is dropped instead of
          // re-queued behind the purge.
          if (replaces != null && !(keepQueuedWrites?.call() ?? false)) {
            unawaited(TrackerCoordinator.instance.purgeWriteQueueForService(service));
          }
          TrackerCoordinator.instance.invalidateResolverCache();
          unawaited(TrackerCoordinator.instance.flushWriteQueue());
          assigned = true;
        },
      );
      return completed && assigned;
    } finally {
      final c = _cancelCompleter;
      if (c != null && !c.isCompleted) c.complete();
      _cancelCompleter = null;
      _connecting = null;
      safeNotifyListeners();
    }
  }

  /// Explicit-disconnect teardown. Every caller is one of the `disconnectX`
  /// methods — profile rebinds go through [onActiveProfileChanged] instead.
  /// The service's queued writes are purged here: they were created under the
  /// account being dropped and must never replay through whichever account
  /// connects to this service next. Session invalidation tears down through
  /// [_rebind]'s `onInvalidated`, which purges for the same reason.
  Future<void> _clearAndRebind(_TrackerSlot slot) async {
    _invalidateConnect(slot.service);
    final userUuid = _activeUserUuid;
    // The rebind bumps the affected service's generation, which is what stops
    // an in-flight profile load from resurrecting the cleared session — so we
    // no longer touch the shared profile-binding generation (which would also
    // abort that load for the other services).
    slot.session = null;
    _rebind(slot);
    safeNotifyListeners();
    await TrackerCoordinator.instance.purgeWriteQueueForService(slot.service);
    await slot.store.clear(userUuid);
  }

  void _invalidateConnect([TrackerService? service]) {
    if (service != null && _connecting != service) return;
    ++_connectGeneration;
    final c = _cancelCompleter;
    if (c != null && !c.isCompleted) c.complete();
  }

  bool _isCurrentConnect(TrackerService service, String userUuid, int generation) {
    return !isDisposed && _connecting == service && userUuid == _activeUserUuid && generation == _connectGeneration;
  }

  bool _isCurrentProfileBinding(String userUuid, int generation) {
    return !isDisposed && userUuid == _activeUserUuid && generation == _profileBindingGeneration;
  }

  Future<TrackerSession> _enrichTrakt(TrackerSession raw) => enrichTrackerSessionUsername(
    session: raw,
    failureMessage: 'Trakt: getUserSettings failed (non-fatal)',
    createClient: () => TraktClient(raw, onSessionInvalidated: () {}),
    fetchUsername: (client) async => (await client.getUserSettings()).username,
  );

  /// Push a slot's session to its tracker, snapshotting the active profile and
  /// bumping the slot's rebind generation first. Bumping here is what lets a
  /// stale client callback — or a racing profile load — detect that it has been
  /// superseded for this service.
  void _rebind(_TrackerSlot slot) {
    if (isDisposed) return;
    final boundUuid = _activeUserUuid;
    final generation = ++slot.rebindGeneration;
    bool isCurrent() => !isDisposed && boundUuid == _activeUserUuid && generation == slot.rebindGeneration;
    slot.bind(
      slot.session,
      onInvalidated: () {
        if (!isCurrent()) return;
        slot.store.clear(boundUuid);
        slot.session = null;
        _rebind(slot);
        // Same contract as the explicit-disconnect purge in [_clearAndRebind]:
        // rows queued under the session that just died must never replay
        // through whichever account connects to this service next. The rebind
        // above moved the account binding first, so an in-flight write that
        // fails after this point is dropped instead of re-queued behind the
        // purge.
        unawaited(TrackerCoordinator.instance.purgeWriteQueueForService(slot.service));
        safeNotifyListeners();
      },
      onUpdated: (next) {
        if (!isCurrent()) return;
        slot.session = next;
        slot.store.save(boundUuid, next);
        safeNotifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _invalidateConnect();
    _traktAuth.dispose();
    super.dispose();
  }
}

/// Pushes a session to one service's tracker singleton. `onUpdated` is wired
/// for every service whose client refreshes its own tokens — MAL, Trakt,
/// MDBList and Simkl's AUTH V2 sessions — so the refreshed session persists.
typedef _TrackerBind =
    void Function(
      TrackerSession? session, {
      required void Function() onInvalidated,
      void Function(TrackerSession session)? onUpdated,
    });

/// Owns one service's session, the generation guarding its rebinds, and the
/// adapter that pushes that session to the service's tracker singleton.
class _TrackerSlot {
  _TrackerSlot(this.service, this.bind) : store = trackerAccountStore(service);

  final TrackerService service;
  final TrackerAccountStore store;
  final _TrackerBind bind;
  TrackerSession? session;

  /// Bumped on every rebind so a late callback from a disposed client (e.g. an
  /// in-flight refresh that resolves after a profile switch) can't persist or
  /// clear a session under the wrong profile, and so a disconnect racing an
  /// in-flight profile load only suppresses its own service.
  int rebindGeneration = 0;
}
