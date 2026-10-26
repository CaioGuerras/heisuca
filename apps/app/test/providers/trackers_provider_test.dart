// Caio, 25/10: MAL/AniList removidos. Mantidas as provas de sessão, isolamento e corrida com Trakt/Simkl/MDBList.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:heisuca/models/trackers/tracker_context.dart';
import 'package:heisuca/providers/trackers_provider.dart';
import 'package:heisuca/services/base_shared_preferences_service.dart';
import 'package:heisuca/services/trackers/tracker_account_store.dart';
import 'package:heisuca/services/trackers/tracker_constants.dart';
import 'package:heisuca/services/trackers/tracker_coordinator.dart';
import 'package:heisuca/services/trackers/tracker_session.dart';
import 'package:heisuca/services/trackers/tracker_write_queue.dart';
import 'package:heisuca/services/trackers/mdblist/mdblist_tracker.dart';
import 'package:heisuca/services/trackers/simkl/simkl_constants.dart';
import 'package:heisuca/services/trackers/simkl/simkl_tracker.dart';
import 'package:heisuca/services/trackers/trakt/trakt_tracker.dart';
import 'package:heisuca/utils/external_ids.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';

final _simklStore = trackerAccountStore(TrackerService.simkl);
final _traktStore = trackerAccountStore(TrackerService.trakt);
final _mdblistStore = trackerAccountStore(TrackerService.mdblist);

TrackerSession _simkl({String? username}) => TrackerSession(
  accessToken: 'simkl-at',
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

/// An AUTH V2 Simkl session, as every new sign-in now produces.
TrackerSession _simklV2({String token = 'simkl_at_new'}) =>
    TrackerSession(accessToken: token, refreshToken: 'simkl_rt_new', expiresAt: 2000000000, createdAt: 1900000000);

TrackerSession _trakt({String? username}) => TrackerSession(
  accessToken: 'trakt-at',
  refreshToken: 'trakt-rt',
  expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

Future<void> _bindProfile(TrackersProvider provider, String? userUuid) async {
  await provider.onActiveProfileChanged(userUuid);
  await TrackerCoordinator.instance.flushWriteQueue();
}

/// A queued watched write for [service], as a failed live write would leave it.
TrackerWriteQueueItem _queuedItem(TrackerService service) {
  final ctx = TrackerContext.movie(
    external: const ExternalIds(tmdb: 456),
    anime: null,
    ratingKey: 'movie-1',
    libraryGlobalKey: 'server-1:8',
  );
  return TrackerWriteQueueItem(
    service: service,
    watched: true,
    ctx: ctx,
    coalesceKey: trackerItemCoalesceKey(service, ctx, trackerExternalRowIdentity(ctx.external))!,
    progressClaim: null,
    watchedAtIso: '2026-05-12T00:00:00.000Z',
  );
}

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    _resetTrackerBindings();
  });
  tearDown(_resetTrackerBindings);

  group('TrackersProvider', () {
    test('sessões legadas de MAL/AniList não iniciam fontes nem chamadas', () async {
      const uuid = 'legacy-profile';
      await trackerAccountStore(TrackerService.mal).save(uuid, _session(TrackerService.mal, 'legacy'));
      await trackerAccountStore(TrackerService.anilist).save(uuid, _session(TrackerService.anilist, 'legacy'));
      BaseSharedPreferencesService.resetForTesting();
      final calls = <Uri>[];
      final p = TrackersProvider(httpClientFactory: () => MockClient((request) async {
        calls.add(request.url);
        return http.Response('{}', 500);
      }));
      await _bindProfile(p, uuid);
      expect(p.isTraktConnected, isFalse);
      expect(p.isSimklConnected, isFalse);
      expect(p.isMdblistConnected, isFalse);
      expect(calls, isEmpty);
      p.dispose();
    });

    test('starts with all trackers disconnected', () {
      final p = TrackersProvider();
      expect(p.simkl, isNull);
      expect(p.trakt, isNull);
      expect(p.mdblist, isNull);
      expect(p.isSimklConnected, isFalse);
      expect(p.isTraktConnected, isFalse);
      expect(p.isMdblistConnected, isFalse);
      expect(p.mdblistCatalogClient, isNull);
      expect(p.simklUsername, isNull);
      expect(p.traktUsername, isNull);
      expect(p.mdblistUsername, isNull);
      expect(p.isConnecting(TrackerService.simkl), isFalse);
      expect(p.isConnecting(TrackerService.trakt), isFalse);
      expect(p.isConnecting(TrackerService.mdblist), isFalse);
      p.dispose();
    });

    test('forTesting owns one fresh client per eager auth owner', () {
      final clients = <FakeHttpClient>[];
      final p = TrackersProvider.forTesting(
        connectPipeline: _ControlledConnectPipeline(_trakt()).call,
        httpClientFactory: () {
          final client = FakeHttpClient(200, const <int>[]);
          clients.add(client);
          return client;
        },
      );

      expect(clients, hasLength(3));
      expect(clients.toSet(), hasLength(3));
      for (final client in clients) {
        expect(client.closeCount, 0);
      }

      p.dispose();

      for (final client in clients) {
        expect(client.closeCount, 1);
        expect(client.isClosed, isTrue);
      }
    });

    test('onActiveProfileChanged loads sessions from per-profile stores', () async {
      const uuid = 'profile-1';
      await _simklStore.save(uuid, _simkl(username: 'carol'));
      await _traktStore.save(uuid, _trakt(username: 'dave'));

      await _mdblistStore.save(uuid, _session(TrackerService.mdblist, 'eve'));
      // Reset cached singletons so the provider reads fresh prefs state.
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await _bindProfile(p, uuid);
      expect(p.isSimklConnected, isTrue);
      expect(p.isTraktConnected, isTrue);
      expect(p.isMdblistConnected, isTrue);
      expect(p.simklUsername, 'carol');
      expect(p.traktUsername, 'dave');
      expect(p.mdblistUsername, 'eve');
      expect(p.mdblistCatalogClient, same(MdblistTracker.instance.client));
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('onActiveProfileChanged switching to empty profile clears all sessions', () async {
      const uuid = 'profile-1';
      await _simklStore.save(uuid, _simkl(username: 'carol'));
      await _traktStore.save(uuid, _trakt(username: 'dave'));
      await _mdblistStore.save(uuid, _session(TrackerService.mdblist, 'eve'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);

      await _bindProfile(p, 'other-profile');
      expect(p.isSimklConnected, isFalse);
      expect(p.isTraktConnected, isFalse);
      expect(p.isMdblistConnected, isFalse);
      expect(p.mdblistCatalogClient, isNull);

      p.dispose();
    });

    test('onActiveProfileChanged loads only the populated stores', () async {
      const uuid = 'profile-2';
      await _traktStore.save(uuid, _trakt(username: 'dave'));
      BaseSharedPreferencesService.resetForTesting();
      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      expect(p.isTraktConnected, isTrue);
      expect(p.traktUsername, 'dave');
      expect(p.isSimklConnected, isFalse);
      expect(p.isMdblistConnected, isFalse);
      p.dispose();
    });

    test('disconnectTrakt clears stored session and notifies', () async {
      const uuid = 'profile-3';
      await _traktStore.save(uuid, _trakt(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      expect(p.isTraktConnected, isTrue);

      var notified = 0;
      p.addListener(() => notified++);

      await p.disconnectTrakt();
      expect(p.isTraktConnected, isFalse);
      expect(p.trakt, isNull);
      // _clearAndRebind notifies once.
      expect(notified, 1);

      // Persistence is cleared too.
      expect(await _traktStore.load(uuid), isNull);

      p.dispose();
    });

    test('disconnectSimkl clears simkl while leaving Trakt intact', () async {
      const uuid = 'profile-4';
      await _traktStore.save(uuid, _trakt(username: 'alice'));
      await _simklStore.save(uuid, _simkl(username: 'bob'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);

      await p.disconnectSimkl();
      expect(p.isSimklConnected, isFalse);
      expect(p.isTraktConnected, isTrue);
      expect(p.traktUsername, 'alice');

      p.dispose();
    });

    test('session invalidation purges the service queued writes so the next account cannot replay them', () async {
      const uuid = 'profile-invalidated';
      await _simklStore.save(uuid, _simkl(username: 'carol'));
      BaseSharedPreferencesService.resetForTesting();

      // Rows queued under the Simkl account about to be invalidated, plus a
      // Trakt control row that must survive the purge.
      final queue = TrackerWriteQueue();
      await queue.enqueue(uuid, _queuedItem(TrackerService.simkl));
      await queue.enqueue(uuid, _queuedItem(TrackerService.trakt));

      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      expect(p.isSimklConnected, isTrue);

      // Fire the auth-failure teardown exactly as the client does on a 401.
      SimklTracker.instance.client!.onSessionInvalidated();
      expect(p.isSimklConnected, isFalse);
      await pumpEventQueue();

      // Account B connecting starts with a flush; nothing of A's may be waiting.
      await TrackerCoordinator.instance.flushWriteQueue();
      final survivors = await queue.load(uuid);
      expect(survivors.map((item) => item.service), [
        TrackerService.trakt,
      ], reason: 'the invalidated service rows must not wait for the next account');
      expect(await _simklStore.load(uuid), isNull);

      p.dispose();
    });

    test('disconnect during an in-flight profile load keeps the other trackers loaded', () async {
      const uuid = 'profile-race';
      await _traktStore.save(uuid, _trakt(username: 'dave'));
      await _simklStore.save(uuid, _simkl(username: 'carol'));
      BaseSharedPreferencesService.resetForTesting();
      final p = TrackersProvider();
      final load = _bindProfile(p, uuid);
      await p.disconnectTrakt();
      await load;
      expect(p.isTraktConnected, isFalse);
      expect(await _traktStore.load(uuid), isNull);
      expect(p.isSimklConnected, isTrue);
      expect(p.simklUsername, 'carol');
      p.dispose();
    });

    test('disconnectSimkl on a profile with no session is safe', () async {
      final p = TrackersProvider();
      // No `onActiveProfileChanged` — uuid is empty (global slot).
      // disconnectSimkl just clears the (already absent) entry and rebinds.
      await p.disconnectSimkl();
      expect(p.isSimklConnected, isFalse);
      p.dispose();
    });

    test('cancelConnect is a no-op when not connecting', () {
      final p = TrackersProvider();
      expect(() => p.cancelConnect(), returnsNormally);
      expect(p.isConnecting(TrackerService.trakt), isFalse);
      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = TrackersProvider();
      p.dispose();
      // Post-dispose rebind should not throw.
      await _bindProfile(p, 'any-uuid');
    });
    for (final service in [
      TrackerService.simkl,
      TrackerService.trakt,
      TrackerService.mdblist,
    ]) {
      test('$service stale connect cannot save or replace a newer binding after dispose', () async {
        const oldUuid = 'profile-old';
        const newUuid = 'profile-new';
        final oldSession = _session(service, 'old');
        final newSession = _session(service, 'new');
        await _store(service).save(newUuid, newSession);
        BaseSharedPreferencesService.resetForTesting();

        final pipeline = _ControlledConnectPipeline(oldSession);
        final oldProvider = TrackersProvider.forTesting(connectPipeline: pipeline.call);
        await _bindProfile(oldProvider, oldUuid);
        final connect = _connect(oldProvider, service);
        await pipeline.beforeSave.future;

        oldProvider.dispose();
        final newProvider = TrackersProvider();
        await _bindProfile(newProvider, newUuid);
        final newBinding = _boundClient(service);
        expect(newBinding, isNotNull);
        expect(_providerSession(newProvider, service)?.accessToken, newSession.accessToken);

        pipeline.releaseBeforeSave.complete();
        expect(await connect, isFalse);
        expect(await _store(service).load(oldUuid), isNull);
        expect((await _store(service).load(newUuid))?.accessToken, newSession.accessToken);
        expect(_boundClient(service), same(newBinding));
        expect(_boundSession(service)?.accessToken, newSession.accessToken);
        expect(_providerSession(oldProvider, service), isNull);

        newProvider.dispose();
      });
    }

    test('cancel invalidates a connect after authorization and before save', () async {
      const uuid = 'profile-cancel';
      final pipeline = _ControlledConnectPipeline(_session(TrackerService.trakt, 'cancelled'));
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await _bindProfile(p, uuid);

      final connect = _connect(p, TrackerService.trakt);
      await pipeline.beforeSave.future;
      p.cancelConnect();
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isFalse);
      expect(p.isConnecting(TrackerService.trakt), isFalse);
      expect(p.trakt, isNull);
      expect(await _traktStore.load(uuid), isNull);
      expect(TraktTracker.instance.client, isNull);
      p.dispose();
    });

    test('profile change invalidates the old connect and preserves the new binding', () async {
      const oldUuid = 'profile-change-old';
      const newUuid = 'profile-change-new';
      final oldSession = _session(TrackerService.simkl, 'old');
      final newSession = _session(TrackerService.simkl, 'new');
      await _simklStore.save(newUuid, newSession);
      BaseSharedPreferencesService.resetForTesting();

      final pipeline = _ControlledConnectPipeline(oldSession);
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await _bindProfile(p, oldUuid);
      final connect = _connect(p, TrackerService.simkl);
      await pipeline.beforeSave.future;

      await _bindProfile(p, newUuid);
      final newBinding = SimklTracker.instance.client;
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isFalse);
      expect(await _simklStore.load(oldUuid), isNull);
      expect((await _simklStore.load(newUuid))?.accessToken, newSession.accessToken);
      expect(p.simkl?.accessToken, newSession.accessToken);
      expect(SimklTracker.instance.client, same(newBinding));
      expect(SimklTracker.instance.client?.session.accessToken, newSession.accessToken);
      p.dispose();
    });

    test('same-service disconnect invalidates an in-flight connect', () async {
      const uuid = 'profile-same-disconnect';
      final pipeline = _ControlledConnectPipeline(_session(TrackerService.simkl, 'late'));
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await _bindProfile(p, uuid);
      final connect = _connect(p, TrackerService.simkl);
      await pipeline.beforeSave.future;

      await p.disconnectSimkl();
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isFalse);
      expect(p.simkl, isNull);
      expect(await _simklStore.load(uuid), isNull);
      expect(SimklTracker.instance.client, isNull);
      p.dispose();
    });

    test('unrelated disconnect leaves an allowed connect current', () async {
      const uuid = 'profile-unrelated-disconnect';
      final linkedSimkl = _session(TrackerService.simkl, 'linked');
      final connectedTrakt = _session(TrackerService.trakt, 'connected');
      await _simklStore.save(uuid, linkedSimkl);
      BaseSharedPreferencesService.resetForTesting();

      final pipeline = _ControlledConnectPipeline(connectedTrakt);
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await _bindProfile(p, uuid);
      final connect = _connect(p, TrackerService.trakt);
      await pipeline.beforeSave.future;

      await p.disconnectSimkl();
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isTrue);
      await TrackerCoordinator.instance.flushWriteQueue();
      expect(p.simkl, isNull);
      expect(p.trakt?.accessToken, connectedTrakt.accessToken);
      expect((await _traktStore.load(uuid))?.accessToken, connectedTrakt.accessToken);
      expect(TraktTracker.instance.client?.session.accessToken, connectedTrakt.accessToken);
      p.dispose();
    });

    test('dispose after save cannot assign or erase a newer same-profile binding', () async {
      const uuid = 'profile-save-race';
      final staleSession = _session(TrackerService.trakt, 'stale');
      final freshSession = _session(TrackerService.trakt, 'fresh');
      final pipeline = _ControlledConnectPipeline(staleSession, pauseAfterSave: true);
      final staleProvider = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await _bindProfile(staleProvider, uuid);
      final connect = _connect(staleProvider, TrackerService.trakt);
      await pipeline.beforeSave.future;
      pipeline.releaseBeforeSave.complete();
      await pipeline.afterSave.future;

      staleProvider.dispose();
      await _traktStore.save(uuid, freshSession);
      BaseSharedPreferencesService.resetForTesting();
      final freshProvider = TrackersProvider();
      await _bindProfile(freshProvider, uuid);
      final freshBinding = TraktTracker.instance.client;
      pipeline.releaseAfterSave.complete();

      expect(await connect, isFalse);
      expect((await _traktStore.load(uuid))?.accessToken, freshSession.accessToken);
      expect(TraktTracker.instance.client, same(freshBinding));
      expect(TraktTracker.instance.client?.session.accessToken, freshSession.accessToken);
      expect(staleProvider.trakt, isNull);
      freshProvider.dispose();
    });

    group('Simkl AUTH V2', () {
      test('a refreshed Simkl session is persisted and published', () async {
        const uuid = 'profile-simkl-refresh';
        await _simklStore.save(uuid, _simklV2(token: 'simkl_at_old'));
        BaseSharedPreferencesService.resetForTesting();

        final p = TrackersProvider();
        await _bindProfile(p, uuid);
        var notified = 0;
        p.addListener(() => notified++);

        // Fire the refresh publication exactly as the client does.
        SimklTracker.instance.client!.onSessionUpdated!(_simklV2());
        await pumpEventQueue();

        expect(p.simkl?.accessToken, 'simkl_at_new');
        expect((await _simklStore.load(uuid))?.accessToken, 'simkl_at_new');
        expect(notified, 1);
        p.dispose();
      });

      test('disconnect clears locally, then revokes an AUTH V2 grant', () async {
        const uuid = 'profile-simkl-revoke';
        await _simklStore.save(uuid, _simklV2());
        BaseSharedPreferencesService.resetForTesting();
        final simkl = _SimklAccounts(const {});

        final p = TrackersProvider.forTesting(
          connectPipeline: _ControlledConnectPipeline(_trakt()).call,
          httpClientFactory: simkl.client,
        );
        await _bindProfile(p, uuid);
        expect(p.isSimklLegacy, isFalse);

        await p.disconnectSimkl();

        expect(p.isSimklConnected, isFalse);
        expect(await _simklStore.load(uuid), isNull);
        final revoke = simkl.requests.single;
        expect(revoke.url.toString(), SimklConstants.revokeUrl);
        expect(revoke.bodyFields, {'client_id': SimklConstants.v2ClientId, 'token': 'simkl_rt_new'});
        p.dispose();
      });

      test('disconnecting a legacy session sends nothing: AUTH V1 has no revoke', () async {
        const uuid = 'profile-simkl-legacy-disconnect';
        await _simklStore.save(uuid, _simkl(username: 'carol'));
        BaseSharedPreferencesService.resetForTesting();
        final simkl = _SimklAccounts(const {});

        final p = TrackersProvider.forTesting(
          connectPipeline: _ControlledConnectPipeline(_trakt()).call,
          httpClientFactory: simkl.client,
        );
        await _bindProfile(p, uuid);
        expect(p.isSimklLegacy, isTrue);

        await p.disconnectSimkl();

        expect(p.isSimklConnected, isFalse);
        expect(simkl.requests, isEmpty);
        p.dispose();
      });

      test('reconnect only runs while a legacy session is bound', () async {
        const uuid = 'profile-simkl-reconnect-guard';
        var pipelineRuns = 0;
        final p = TrackersProvider.forTesting(
          connectPipeline:
              ({required logLabel, required authorize, required enrich, required save, required assign}) async {
                pipelineRuns++;
                return true;
              },
        );
        await _bindProfile(p, uuid);
        expect(p.isSimklLegacy, isFalse);
        expect(await p.reconnectSimkl(onCodeReady: (_) {}), isFalse);

        await _simklStore.save(uuid, _simklV2());
        BaseSharedPreferencesService.resetForTesting();
        await _bindProfile(p, uuid);
        expect(p.isSimklConnected, isTrue);
        expect(p.isSimklLegacy, isFalse);
        expect(await p.reconnectSimkl(onCodeReady: (_) {}), isFalse);

        expect(pipelineRuns, 0);
        p.dispose();
      });

      test('reconnecting to the same account replaces the session and keeps queued writes', () async {
        const uuid = 'profile-simkl-reconnect-same';
        await _simklStore.save(uuid, _simkl(username: 'carol'));
        BaseSharedPreferencesService.resetForTesting();
        final queue = TrackerWriteQueue();
        await queue.enqueue(uuid, _queuedItem(TrackerService.simkl));
        // Replay stays off so the kept row is observable rather than sent.
        await SimklTracker.instance.setEnabled(false);
        final simkl = _SimklAccounts({'simkl-at': 7, 'simkl_at_new': 7});

        final p = TrackersProvider.forTesting(
          connectPipeline: _enrichingPipeline(_simklV2()),
          httpClientFactory: simkl.client,
        );
        await _bindProfile(p, uuid);
        expect(p.isSimklLegacy, isTrue);

        expect(await p.reconnectSimkl(onCodeReady: (_) {}), isTrue);
        await TrackerCoordinator.instance.flushWriteQueue();

        expect(simkl.settingsTokens, unorderedEquals(['simkl-at', 'simkl_at_new']));
        expect(p.isSimklLegacy, isFalse);
        expect(p.simkl?.accessToken, 'simkl_at_new');
        expect(p.simklUsername, 'user-7');
        expect(SimklTracker.instance.client?.session.accessToken, 'simkl_at_new');
        expect((await _simklStore.load(uuid))?.accessToken, 'simkl_at_new');
        expect((await queue.load(uuid)).map((item) => item.service), [TrackerService.simkl]);
        p.dispose();
      });

      for (final (label, accounts) in [
        ('a different account', <String, Object>{'simkl-at': 7, 'simkl_at_new': 8}),
        ('an unverifiable account', <String, Object>{'simkl_at_new': 8}),
      ]) {
        test('reconnecting to $label purges the legacy queued writes', () async {
          const uuid = 'profile-simkl-reconnect-other';
          await _simklStore.save(uuid, _simkl(username: 'carol'));
          BaseSharedPreferencesService.resetForTesting();
          final queue = TrackerWriteQueue();
          await queue.enqueue(uuid, _queuedItem(TrackerService.simkl));
          await queue.enqueue(uuid, _queuedItem(TrackerService.trakt));
          await SimklTracker.instance.setEnabled(false);
          final simkl = _SimklAccounts(accounts);

          final p = TrackersProvider.forTesting(
            connectPipeline: _enrichingPipeline(_simklV2()),
            httpClientFactory: simkl.client,
          );
          await _bindProfile(p, uuid);

          expect(await p.reconnectSimkl(onCodeReady: (_) {}), isTrue);
          await TrackerCoordinator.instance.flushWriteQueue();

          expect(p.simkl?.accessToken, 'simkl_at_new');
          expect(SimklTracker.instance.client?.session.accessToken, 'simkl_at_new');
          expect((await queue.load(uuid)).map((item) => item.service), [TrackerService.trakt]);
          p.dispose();
        });
      }
    });
  });
}

void _resetTrackerBindings() {
  SimklTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  TraktTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  MdblistTracker.instance.rebindSession(null, onSessionInvalidated: () {});
}

TrackerAccountStore _store(TrackerService service) => switch (service) {
  TrackerService.mal || TrackerService.anilist => throw UnsupportedError('Serviço removido'),
  TrackerService.simkl => _simklStore,
  TrackerService.trakt => _traktStore,
  TrackerService.mdblist => _mdblistStore,
};

TrackerSession _session(TrackerService service, String owner) => switch (service) {
  TrackerService.mal => TrackerSession(
    accessToken: '$owner-mal-at',
    refreshToken: '$owner-mal-rt',
    expiresAt: 2000000000,
    createdAt: 1900000000,
    username: owner,
  ),
  TrackerService.anilist => TrackerSession(
    accessToken: '$owner-anilist-at',
    expiresAt: 2000000000,
    createdAt: 1900000000,
    username: owner,
  ),
  TrackerService.simkl => TrackerSession(accessToken: '$owner-simkl-at', createdAt: 1900000000, username: owner),
  TrackerService.trakt => TrackerSession(
    accessToken: '$owner-trakt-at',
    refreshToken: '$owner-trakt-rt',
    expiresAt: 2000000000,
    createdAt: 1900000000,
    username: owner,
  ),
  TrackerService.mdblist => TrackerSession(
    accessToken: '$owner-mdblist-at',
    refreshToken: '$owner-mdblist-rt',
    expiresAt: 2000000000,
    createdAt: 1900000000,
    username: owner,
  ),
};

Future<bool> _connect(TrackersProvider provider, TrackerService service) => switch (service) {
  TrackerService.mal || TrackerService.anilist => throw UnsupportedError('Serviço removido'),
  TrackerService.simkl => provider.connectSimkl(onCodeReady: (_) {}),
  TrackerService.trakt => provider.connectTrakt(onCodeReady: (_) {}),
  TrackerService.mdblist => provider.connectMdblist(onCodeReady: (_) {}),
};

TrackerSession? _providerSession(TrackersProvider provider, TrackerService service) => switch (service) {
  TrackerService.mal || TrackerService.anilist => null,
  TrackerService.simkl => provider.simkl,
  TrackerService.trakt => provider.trakt,
  TrackerService.mdblist => provider.mdblist,
};

Object? _boundClient(TrackerService service) => switch (service) {
  TrackerService.mal || TrackerService.anilist => null,
  TrackerService.simkl => SimklTracker.instance.client,
  TrackerService.trakt => TraktTracker.instance.client,
  TrackerService.mdblist => MdblistTracker.instance.client,
};

TrackerSession? _boundSession(TrackerService service) => switch (service) {
  TrackerService.mal || TrackerService.anilist => null,
  TrackerService.simkl => SimklTracker.instance.client?.session,
  TrackerService.trakt => TraktTracker.instance.client?.session,
  TrackerService.mdblist => MdblistTracker.instance.client?.session,
};

class _ControlledConnectPipeline {
  _ControlledConnectPipeline(this.session, {this.pauseAfterSave = false});

  final TrackerSession session;
  final bool pauseAfterSave;
  final beforeSave = Completer<void>();
  final releaseBeforeSave = Completer<void>();
  final afterSave = Completer<void>();
  final releaseAfterSave = Completer<void>();

  Future<bool> call({
    required String logLabel,
    required Future<TrackerSession?> Function() authorize,
    required Future<TrackerSession> Function(TrackerSession raw) enrich,
    required Future<void> Function(TrackerSession enriched) save,
    required void Function(TrackerSession enriched) assign,
  }) async {
    beforeSave.complete();
    await releaseBeforeSave.future;
    await save(session);
    afterSave.complete();
    if (pauseAfterSave) await releaseAfterSave.future;
    assign(session);
    return true;
  }
}

/// The production pipeline's step order with a scripted authorization, so the
/// provider's own enrichment runs.
TrackerSessionConnectPipeline _enrichingPipeline(TrackerSession authorized) =>
    ({required logLabel, required authorize, required enrich, required save, required assign}) async {
      final enriched = await enrich(authorized);
      await save(enriched);
      assign(enriched);
      return true;
    };

/// Simkl's API as seen by the provider's short-lived clients: who each token
/// belongs to, plus every request made.
class _SimklAccounts {
  _SimklAccounts(this.accountIdsByToken);

  /// Tokens missing here answer 401. Only use legacy tokens for that: a V2
  /// 401 would try a real refresh.
  final Map<String, Object> accountIdsByToken;
  final requests = <http.Request>[];

  Iterable<String?> get settingsTokens => requests
      .where((request) => request.url.path == '/users/settings')
      .map((request) => request.headers['authorization']?.replaceFirst('Bearer ', ''));

  http.Client client() => MockClient((request) async {
    requests.add(request);
    if (request.url.path != '/users/settings') return http.Response('', 200);
    final token = request.headers['authorization']?.replaceFirst('Bearer ', '');
    final id = accountIdsByToken[token];
    if (id == null) return http.Response('', 401);
    return http.Response(
      json.encode({
        'user': {'name': 'user-$id'},
        'account': {'id': id},
      }),
      200,
    );
  });
}
