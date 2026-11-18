// Captura o componente usado por DesktopRoot, com cliente e catálogo de demonstração.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_home_actions.dart';
import 'package:heisuca/desktop/desktop_preferences.dart';
import 'package:heisuca/desktop/desktop_theme.dart';
import 'package:heisuca/desktop/remote/desktop_cinema_controller.dart';
import 'package:heisuca/desktop/ui/desktop_cinema_home.dart';
import 'package:heisuca/media/media_hub.dart';
import 'package:heisuca/media/media_item.dart';
import 'package:heisuca/media/media_kind.dart';
import 'package:heisuca/media/media_backend.dart';
import 'package:heisuca/media/media_library.dart';
import 'package:heisuca/media/library_query.dart';
import 'package:heisuca/utils/media_server_http_client.dart' show AbortController;
import 'package:heisuca/desktop/ui/desktop_library_screen.dart';
import '../test/desktop/desktop_cinema_test.dart' show CinemaFakeClient, CinemaFakeServers, connection;

class _PreviewLibraryClient extends CinemaFakeClient {
  _PreviewLibraryClient(this.items);
  final List<MediaItem> items;
  @override MediaBackend get backend=>MediaBackend.plex;
  @override Map<String,String> get streamHeaders=>const {};
  @override String thumbnailUrl(String? path,{int? width,int? height,bool cover=true})=>path??'';
  @override Future<List<MediaLibrary>> fetchLibraries()async=>[const MediaLibrary(id:'filmes',backend:MediaBackend.plex,title:'Filmes',kind:MediaKind.movie)];
  @override Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(String id,{required LibraryQuery query,MediaKind? libraryKind,AbortController? abort})async=>LibraryPage(items:items,totalCount:items.length);
  @override Future<({MediaItem? item,MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id,{void Function(MediaItem item)? onItemReady})async=>(item:items.firstWhere((i)=>i.id==id),onDeckEpisode:null);
}
class _PreviewServers extends CinemaFakeServers {
  @override bool get persistentSessions=>true;
  @override String? get error=>null;
  @override bool get busy=>false;
}

void main() {
  testWidgets('capturas Home Cinema integrada: catálogo, sem conta e carregamento', (tester) async {
    final dir=Platform.environment['HEISUCA_VISUAL_DIR']!;
    for(final font in {'Inter':'assets/fonts/Inter-Regular.ttf','MaterialIcons':'fonts/MaterialIcons-Regular.otf'}.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    final images=<String,ui.Image>{};
    await tester.runAsync(()async{
      for(final file in Directory('$dir/assets').listSync().whereType<File>().where((f)=>f.path.endsWith('.jpg'))){
        final codec=await ui.instantiateImageCodec(await file.readAsBytes());images[file.uri.pathSegments.last]=(await codec.getNextFrame()).image;codec.dispose();
      }
    });
    addTearDown((){for(final i in images.values){i.dispose();}});
    tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(1440,960);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final movies=[
      const MediaItem.plex(id:'dune',kind:MediaKind.movie,title:'Duna: Parte Dois',thumbPath:'dune.jpg',artPath:'dune-hero.jpg',year:2024,durationMs:10020000,
        summary:'Paul e Chani enfrentam um império nas areias de Arrakis. Uma escolha entre o amor e o destino do universo.'),
      const MediaItem.plex(id:'interstellar',kind:MediaKind.movie,title:'Interestelar',thumbPath:'interstellar.jpg',year:2014,durationMs:10140000,viewOffsetMs:3200000),
      const MediaItem.plex(id:'blade',kind:MediaKind.movie,title:'Blade Runner 2049',thumbPath:'blade-runner.jpg',year:2017,durationMs:9840000,viewOffsetMs:6500000),
      const MediaItem.plex(id:'arrival',kind:MediaKind.movie,title:'A Chegada',thumbPath:'arrival.jpg',year:2016),
      const MediaItem.plex(id:'oppenheimer',kind:MediaKind.movie,title:'Oppenheimer',thumbPath:'oppenheimer.jpg',year:2023,durationMs:10800000,viewOffsetMs:2500000),
      const MediaItem.plex(id:'whiplash',kind:MediaKind.movie,title:'Whiplash',thumbPath:'whiplash.jpg',year:2014,durationMs:6360000,viewOffsetMs:4700000),
      const MediaItem.plex(id:'1917',kind:MediaKind.movie,title:'1917',thumbPath:'1917.jpg',year:2019),
      const MediaItem.plex(id:'batman',kind:MediaKind.movie,title:'Batman',thumbPath:'batman.jpg',year:2022),
    ];
    for(final state in ['catalogo','sem-conta','carregando','biblioteca','ficha']){
      final pending=Completer<List<MediaHub>>();final client=_PreviewLibraryClient(movies)..load=(_)=>state=='carregando'?pending.future:Future.value([
        MediaHub(id:'home.continue',title:'Continuar',type:'movie',items:[movies[1],movies[2],movies[4],movies[5]]),
        MediaHub(id:'recent',title:'Uma boa noite começa aqui',type:'movie',items:movies)]);
      final servers=_PreviewServers()..current=state=='sem-conta'?[]:[connection('Biblioteca de demonstração',client)];
      final catalog=DesktopCinemaController(servers);final prefs=DesktopPreferences();final key=GlobalKey();
      final actions=DesktopHomeActions(openFile:(){},openUrl:(){},openLibrary:(){},openSettings:(){},openRecent:(_){},dismissError:(){});
      await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(theme:desktopTheme('shikkoku',Brightness.dark),debugShowCheckedModeBanner:false,
        home:state=='biblioteca'||state=='ficha' ? DesktopLibraryScreen(servers:servers,
          initialServerId:'Biblioteca de demonstração',initialItem:state=='ficha'?movies.first:null,onPlay:(_,_,_)async{},
          artworkBuilder:(item,landscape)=>RawImage(image:images[landscape&&item.artPath!=null?item.artPath!:item.thumbPath!],fit:BoxFit.cover)) : Scaffold(body:DesktopCinemaHome(catalog:catalog,preferences:prefs,actions:actions,onBrowse:(_,_,_,_){},onPlay:(_,_)async{},
          artworkBuilder:(s,item,landscape){final name=landscape&&item.artPath!=null?item.artPath!:item.thumbPath!;return RawImage(image:images[name],fit:BoxFit.cover);})) )));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
      final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(()async{final image=await boundary.toImage(pixelRatio:1);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
        await File('$dir/integrada-$state.png').writeAsBytes(bytes!.buffer.asUint8List());image.dispose();});
      if(state=='carregando'){pending.complete([]);await tester.pumpAndSettle();}
      await tester.pumpWidget(const SizedBox.shrink());catalog.dispose();servers.dispose();prefs.dispose();
    }
  });
}
