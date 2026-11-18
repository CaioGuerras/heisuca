import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/remote/desktop_cinema_controller.dart';
import 'package:heisuca/desktop/remote/desktop_servers_controller.dart';
import 'package:heisuca/desktop/desktop_home_actions.dart';
import 'package:heisuca/desktop/desktop_preferences.dart';
import 'package:heisuca/desktop/desktop_theme.dart';
import 'package:heisuca/desktop/ui/desktop_cinema_home.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_hub.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_server_client.dart';
import 'package:heisuca/desktop/ui/desktop_session_artwork.dart';

class CinemaFakeClient implements MediaServerClient {
  Object session = Object();
  Future<List<MediaHub>> Function(HubFetchDiagnostics?)? load;
  @override Object get authenticationSessionId => session;
  @override Future<List<MediaHub>> fetchGlobalHubs({int limit = 20, bool includePlaybackHubs = true, HubFetchDiagnostics? diagnostics}) => load?.call(diagnostics) ?? Future.value([]);
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class CinemaFakeServers extends ChangeNotifier implements DesktopServersController {
  List<DesktopServerConnection> current = [];
  @override List<DesktopServerConnection> get connections => current;
  @override bool get restoring => false;
  void replace(List<DesktopServerConnection> value) {current = value; notifyListeners();}
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
DesktopServerConnection connection(String id, CinemaFakeClient client) => DesktopServerConnection(id: id, name: id, backend: MediaBackend.plex, client: client);
const movie = MediaItem.plex(id: 'movie', kind: MediaKind.movie, title: 'Filme da biblioteca', summary: 'Uma história.', year: 2024);
MediaHub hub(String title) => MediaHub(id: 'recent', title: title, type: 'movie', items: [movie]);
Future<void> settle() async {await Future<void>.delayed(Duration.zero);}

void main() {
  test('cache de arte não compartilha URL entre sessões diferentes', () {
    final session=Object();
    expect(DesktopSessionArtwork('https://server/image',const {},session),DesktopSessionArtwork('https://server/image',const {},session));
    expect(DesktopSessionArtwork('https://server/image',const {},session),isNot(DesktopSessionArtwork('https://server/image',const {},Object())));
  });
  test('troca de servidor descarta resposta antiga e limpa imediatamente os dados da outra fonte', () async {
    final a = Completer<List<MediaHub>>(), b = Completer<List<MediaHub>>();
    final ca = CinemaFakeClient()..load = (_) => a.future;
    final cb = CinemaFakeClient()..load = (_) => b.future;
    final servers = CinemaFakeServers()..current = [connection('A',ca),connection('B',cb)];
    final catalog = DesktopCinemaController(servers);
    catalog.selectServer('B');
    expect(catalog.rows,isEmpty);expect(catalog.source?.id,'B');
    b.complete([hub('Biblioteca B')]);await settle();
    a.complete([hub('Biblioteca A')]);await settle();
    expect(catalog.rows.single.title,'Biblioteca B');
    servers.replace([]);expect(catalog.rows,isEmpty);expect(catalog.featured,isNull);
    catalog.dispose();servers.dispose();
  });
  test('troca de sessão no mesmo cliente descarta catálogo privado e refaz a consulta', () async {
    final old = Completer<List<MediaHub>>();var calls=0;
    final client=CinemaFakeClient()..load=(_) {calls++;return calls==1 ? old.future : Future.value([hub('Nova sessão')]);};
    final servers=CinemaFakeServers()..current=[connection('A',client)];
    final catalog=DesktopCinemaController(servers);
    client.session=Object();old.complete([hub('Sessão antiga')]);await settle();await settle();
    expect(calls,2);expect(catalog.rows.single.title,'Nova sessão');expect(catalog.loading,isFalse);
    catalog.dispose();servers.dispose();
  });
  test('diagnóstico parcial mantém conteúdo mas não anuncia atualização completa', () async {
    final client=CinemaFakeClient()..load=(diag) async {diag!.recordFailure(StateError('private'));return [hub('Parte disponível')];};
    final servers=CinemaFakeServers()..current=[connection('A',client)];final catalog=DesktopCinemaController(servers);await settle();
    expect(catalog.rows,isNotEmpty);expect(catalog.error,contains('Parte da biblioteca'));
    catalog.dispose();servers.dispose();
  });
  test('falha não expõe payload e conclusão após dispose não notifica', () async {
    final request=Completer<List<MediaHub>>();final client=CinemaFakeClient()..load=(_) => request.future;
    final servers=CinemaFakeServers()..current=[connection('A',client)];final catalog=DesktopCinemaController(servers);
    request.completeError(StateError('https://host/?token=segredo'));await settle();
    expect(catalog.error,isNot(contains('segredo')));expect(catalog.error,isNotNull);
    final late=Completer<List<MediaHub>>();client.load=(_) => late.future;
    final refresh=catalog.refresh();var notifications=0;catalog.addListener(() => notifications++);
    catalog.dispose();late.complete([hub('Tarde')]);await refresh;expect(notifications,0);servers.dispose();
  });
  testWidgets('sem conta: não inventa catálogo e cabe a200% numa janela800x600', (tester) async {
    tester.view.physicalSize=const Size(800,600);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final servers=CinemaFakeServers();final catalog=DesktopCinemaController(servers);final prefs=DesktopPreferences();var opens=0;
    final actions=DesktopHomeActions(openFile:(){},openUrl:(){},openLibrary:()=>opens++,openSettings:(){},openRecent:(_){},dismissError:(){});
    await tester.pumpWidget(MaterialApp(theme:desktopTheme('shikkoku',Brightness.dark),home:Scaffold(body:MediaQuery(data:const MediaQueryData(textScaler:TextScaler.linear(2)),child:DesktopCinemaHome(
      catalog:catalog,preferences:prefs,actions:actions,onBrowse:(_,_,_,_){},onPlay:(_,_)async{})))));
    await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    expect(find.text('Filme da biblioteca'),findsNothing);
    await tester.ensureVisible(find.text('Conectar biblioteca'));await tester.pumpAndSettle();await tester.tap(find.text('Conectar biblioteca'));await tester.pumpAndSettle();expect(opens,1);
    await tester.pumpWidget(const SizedBox.shrink());catalog.dispose();servers.dispose();prefs.dispose();
  });
  testWidgets('só Continue assistindo mantém fonte e conteúdo sem falso estado vazio', (tester) async {
    final client=CinemaFakeClient()..load=(_)async=>[const MediaHub(id:'home.continue',identifier:'home.continue',title:'Retomar',type:'mixed',items:[movie])];
    final servers=CinemaFakeServers()..current=[connection('Fonte A',client),connection('Fonte B',CinemaFakeClient())];
    final catalog=DesktopCinemaController(servers);final prefs=DesktopPreferences();await tester.pump();
    final actions=DesktopHomeActions(openFile:(){},openUrl:(){},openLibrary:(){},openSettings:(){},openRecent:(_){},dismissError:(){});
    await tester.pumpWidget(MaterialApp(theme:desktopTheme('shikkoku',Brightness.dark),home:Scaffold(body:DesktopCinemaHome(
      catalog:catalog,preferences:prefs,actions:actions,onBrowse:(_,_,_,_){},onPlay:(_,_)async{},artworkBuilder:(_,_,_)=>const SizedBox()))));
    await tester.pumpAndSettle();expect(find.text('Continue de onde parou'),findsOneWidget);
    expect(find.textContaining('Este servidor ainda não mostrou títulos'),findsNothing);
    await tester.tap(find.byTooltip('Escolher biblioteca'));await tester.pumpAndSettle();
    await tester.tap(find.text('Fonte B'));await tester.pumpAndSettle();expect(catalog.source?.id,'Fonte B');
    expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox.shrink());catalog.dispose();servers.dispose();prefs.dispose();
  });
  testWidgets('Home com título longo mantém Assistir acessível a200% em800x600', (tester) async {
    tester.view.physicalSize=const Size(800,600);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    const item=MediaItem.plex(id:'long',kind:MediaKind.movie,title:'Um título muito longo para testar a acessibilidade da biblioteca de cinema',year:2024,durationMs:7200000,
      summary:'Uma sinopse que ocupa mais de uma linha e não pode esconder o botão de assistir quando a pessoa aumenta o tamanho do texto.');
    final client=CinemaFakeClient()..load=(_)async=>[const MediaHub(id:'recent',title:'Recentes',type:'movie',items:[item])];
    final servers=CinemaFakeServers()..current=[connection('Fonte A',client)];final catalog=DesktopCinemaController(servers);
    final prefs=DesktopPreferences();var plays=0;await tester.pump();
    final actions=DesktopHomeActions(openFile:(){},openUrl:(){},openLibrary:(){},openSettings:(){},openRecent:(_){},dismissError:(){});
    await tester.pumpWidget(MaterialApp(theme:desktopTheme('shikkoku',Brightness.dark),home:Scaffold(body:MediaQuery(
      data:const MediaQueryData(textScaler:TextScaler.linear(2)),child:DesktopCinemaHome(catalog:catalog,preferences:prefs,actions:actions,
        onBrowse:(_,_,_,_){},onPlay:(_,_)async{plays++;},artworkBuilder:(_,_,_)=>const SizedBox())))));
    await tester.pumpAndSettle();await tester.ensureVisible(find.text('Assistir'));await tester.pumpAndSettle();
    await tester.tap(find.text('Assistir'));await tester.pumpAndSettle();expect(plays,1);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());catalog.dispose();servers.dispose();prefs.dispose();
  });
  testWidgets('controles da Home levam a fonte/item/busca corretos e reproduzem pelo callback real', (tester) async {
    tester.view.physicalSize=const Size(1440,960);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final client=CinemaFakeClient()..load=(_) async => [hub('Adicionados recentemente')];
    final servers=CinemaFakeServers()..current=[connection('Servidor escolhido',client)];final catalog=DesktopCinemaController(servers);await tester.pump();
    final prefs=DesktopPreferences();final actions=DesktopHomeActions(openFile:(){},openUrl:(){},openLibrary:(){},openSettings:(){},openRecent:(_){},dismissError:(){});
    MediaItem? selected;MediaKind? selectedKind;String? query,serverId;var plays=0;
    await tester.pumpWidget(MaterialApp(theme:desktopTheme('shikkoku',Brightness.dark),home:Scaffold(body:DesktopCinemaHome(catalog:catalog,preferences:prefs,actions:actions,
      artworkBuilder:(_,_,_)=>const SizedBox(),onBrowse:(s,i,k,q){serverId=s?.id;selected=i;selectedKind=k;query=q;},onPlay:(s,i)async{expect(s.id,'Servidor escolhido');expect(i,movie);plays++;}))));
    await tester.pumpAndSettle();await tester.tap(find.text('Ver detalhes'));expect(selected,movie);expect(serverId,'Servidor escolhido');
    await tester.tap(find.text('Filmes'));expect(selectedKind,MediaKind.movie);
    await tester.enterText(find.byType(TextField),'Matrix');tester.widget<TextField>(find.byType(TextField)).onSubmitted!('Matrix');await tester.pump();expect(query,'Matrix');
    await tester.tap(find.text('Assistir'));await tester.pumpAndSettle();expect(plays,1);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());catalog.dispose();servers.dispose();prefs.dispose();
  });
}
