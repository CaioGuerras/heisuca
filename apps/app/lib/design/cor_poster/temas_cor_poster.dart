import '../../heisuca/theme/temas/tema_hisui.dart';
import '../../heisuca/theme/temas/tema_shikkoku.dart';
import '../../heisuca/theme/temas/tema_sumi.dart';
import 'paleta_poster.dart';

/// Os três temas do Heisuca, lidos dos tokens gerados (nenhum hex à mão aqui).
abstract final class TemasCorPoster {
  static final shikkoku = PapelDoTema(
    nome: 'shikkoku',
    tinta: TintaDoTema.escura,
    fundo: TemaShikkoku.temaCorFundo.toARGB32(),
    texto: TemaShikkoku.temaCorTexto.toARGB32(),
    texto2: TemaShikkoku.temaCorTexto2.toARGB32(),
    acento: TemaShikkoku.temaCorAcento.toARGB32(),
  );

  static final hisui = PapelDoTema(
    nome: 'hisui',
    tinta: TintaDoTema.pastel,
    fundo: TemaHisui.temaCorFundo.toARGB32(),
    texto: TemaHisui.temaCorTexto.toARGB32(),
    texto2: TemaHisui.temaCorTexto2.toARGB32(),
    acento: TemaHisui.temaCorAcento.toARGB32(),
  );

  static final sumi = PapelDoTema(
    nome: 'sumi',
    tinta: TintaDoTema.oled,
    fundo: TemaSumi.temaCorFundo.toARGB32(),
    texto: TemaSumi.temaCorTexto.toARGB32(),
    texto2: TemaSumi.temaCorTexto2.toARGB32(),
    acento: TemaSumi.temaCorAcento.toARGB32(),
  );

  static final todos = <PapelDoTema>[shikkoku, hisui, sumi];
}
