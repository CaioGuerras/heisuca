import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heisuca/heisuca/heisuca_library_screen.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/media/ids.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_library.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/services/multi_server_manager.dart';
import 'package:heisuca/services/data_aggregation_service.dart';
import 'package:heisuca/providers/multi_server_provider.dart';
import 'package:heisuca/utils/media_server_http_client.dart';
class _Client extends MediaServerClient {
  _Client(this.name, this.kind);
  final String name;
  final MediaBackend kind;
  final calls = <(String, LibraryQuery)>[];
  @override ServerId get serverId => ServerId(name);
  @override MediaBackend get backend => kind;
  @override Future<List<MediaLibrary>> fetchLibraries() async => [
    MediaLibrary(id: 'films', backend: kind, title: 'Filmes', kind: MediaKind.movie, serverId: name),
    MediaLibrary(id: 'anime', backend: kind, title: 'Animes', kind: MediaKind.show, serverId: name),
  ];
  @override Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(String libraryId, {required LibraryQuery query, MediaKind? libraryKind, AbortController? abort}) async {
    calls.add((libraryId, query));
    return LibraryPage(items: [MediaItem(id: '$name-$libraryId', backend: kind, kind: libraryKind!, title: 'Título de $name', serverId: name)], totalCount: 1);
  }
  @override dynamic noSuchMethod(Invocation invocation) => null;
}
void main() {
  testWidgets('biblioteca usa fonte ativa, troca de categoria e pesquisa no servidor', (tester) async {
    final a = _Client('A', MediaBackend.jellyfin), b = _Client('B', MediaBackend.plex);
    final manager = MultiServerManager()..debugRegisterClientForTesting(a)..debugRegisterClientForTesting(b);
    final servers = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(servers.dispose); addTearDown(manager.dispose);
    manager.setNavigationSource(Object(), 'B');
    await tester.pumpWidget(ChangeNotifierProvider.value(value: servers, child: MaterialApp(
      theme: cgflixAppTheme(CgflixThemeVariant.isis), home: const HeisucaLibraryScreen())));
    await tester.pumpAndSettle();
    expect(a.calls, isEmpty); expect(b.calls.single.$1, 'films');
    // Caio, 24/10: só botões (nada de lista que abre por cima) e o nome aparece sob a capa.
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('Título de B'), findsOneWidget);
    await tester.tap(find.text('Animes').first); await tester.pumpAndSettle();
    expect(b.calls.last.$1, 'anime');
    await tester.enterText(find.byType(TextField), 'Apotecária');
    await tester.pump(const Duration(milliseconds: 350)); await tester.pumpAndSettle();
    expect(b.calls.last.$2.search, 'Apotecária');
    expect(tester.takeException(), isNull);
  });
}
