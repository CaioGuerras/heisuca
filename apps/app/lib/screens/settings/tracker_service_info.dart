import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../cgflix/cgflix_trakt.dart';
import '../../i18n/strings.g.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/trackers_provider.dart';
import '../../services/trackers/tracker.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../services/trackers/trakt/trakt_tracker.dart';
import 'trakt_settings_screen.dart';

/// One watch tracker, described once for every place that lists services: the
/// services hub, the rating sheet, and the settings summary line.
///
/// [isConnected] and [username] take a [BuildContext] and read the account
/// state with `watch`, so the calling element rebuilds exactly like the
/// per-service `Consumer` these entries replaced.
class TrackerServiceInfo {
  final TrackerService service;
  final String displayName;

  /// Which brand mark to draw; the asset path itself lives only in
  /// `CatalogSourceLogo`.
  final CatalogSourceId logoSource;

  final TrackerRatingSource ratingSource;
  final bool Function(BuildContext) isConnected;
  final String? Function(BuildContext) username;
  final Future<void> Function(BuildContext) startConnection;
  final Widget Function() buildSettingsScreen;

  const TrackerServiceInfo({
    required this.service,
    required this.displayName,
    required this.logoSource,
    required this.ratingSource,
    required this.isConnected,
    required this.username,
    required this.startConnection,
    required this.buildSettingsScreen,
  });

  /// Display order shared by every list. Built per call because [displayName]
  /// reads the active locale.
  static List<TrackerServiceInfo> get all => _all.where((i) => cgflixShowsTracker(i.service)).toList(); // CGFLIX

  static List<TrackerServiceInfo> get _all => [
    TrackerServiceInfo(
      service: TrackerService.trakt,
      displayName: t.trakt.title,
      logoSource: CatalogSourceId.trakt,
      ratingSource: TraktTracker.instance,
      isConnected: (context) => context.watch<TrackersProvider>().isTraktConnected,
      username: (context) => context.watch<TrackersProvider>().traktUsername,
      startConnection: startTraktConnection,
      buildSettingsScreen: () => const TraktSettingsScreen(),
    ),
  ];
}
