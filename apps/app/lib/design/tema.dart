import 'package:flutter/material.dart';

import '../heisuca/theme/heisuca_base.dart';
import '../heisuca/theme/temas/tema_hisui.dart';
import '../heisuca/theme/temas/tema_ichigo.dart';
import '../heisuca/theme/temas/tema_ichigo_noite.dart';
import '../heisuca/theme/temas/tema_shikkoku.dart';
import '../heisuca/theme/temas/tema_sorairo.dart';
import '../heisuca/theme/temas/tema_sorairo_noite.dart';
import '../heisuca/theme/temas/tema_sumi.dart';
import 'tipo.dart';

/// Papéis de cor de um tema da V2.
///
/// Os valores vêm dos tokens gerados em `lib/heisuca/theme/`. Nenhuma cor é escrita à mão em
/// `lib/design/` nem em `lib/features/` (o teste `sem_cor_a_mao_test.dart` vigia isso).
@immutable
class TemaHeisuca extends ThemeExtension<TemaHeisuca> {
  const TemaHeisuca({
    required this.nome,
    required this.brilho,
    required this.fundo,
    required this.superficie,
    required this.superficie2,
    required this.borda,
    required this.texto,
    required this.texto2,
    required this.acento,
    required this.acentoSuave,
    required this.botaoFundo,
    required this.botaoTexto,
    required this.foco,
    required this.selo,
    required this.erro,
    required this.aviso,
    required this.sucesso,
  });

  final String nome;
  final Brightness brilho;
  final Color fundo;
  final Color superficie;
  final Color superficie2;
  final Color borda;
  final Color texto;
  final Color texto2;

  /// Só em item pequeno: interruptor, progresso, seleção. O botão principal é neutro.
  final Color acento;
  final Color acentoSuave;
  final Color botaoFundo;
  final Color botaoTexto;
  final Color foco;

  /// Só no logo, no ícone e na abertura.
  final Color selo;
  final Color erro;
  final Color aviso;
  final Color sucesso;

  static const shikkoku = TemaHeisuca(
    nome: 'shikkoku',
    brilho: Brightness.dark,
    fundo: TemaShikkoku.temaCorFundo,
    superficie: TemaShikkoku.temaCorSuperficie,
    superficie2: TemaShikkoku.temaCorSuperficie2,
    borda: TemaShikkoku.temaCorBorda,
    texto: TemaShikkoku.temaCorTexto,
    texto2: TemaShikkoku.temaCorTexto2,
    acento: TemaShikkoku.temaCorAcento,
    acentoSuave: TemaShikkoku.temaCorAcentoSuave,
    botaoFundo: TemaShikkoku.temaCorBotaoFundo,
    botaoTexto: TemaShikkoku.temaCorBotaoTexto,
    foco: TemaShikkoku.temaCorFoco,
    selo: TemaShikkoku.temaCorSelo,
    erro: TemaShikkoku.temaCorErro,
    aviso: TemaShikkoku.temaCorAviso,
    sucesso: TemaShikkoku.temaCorSucesso,
  );

  static const hisui = TemaHeisuca(
    nome: 'hisui',
    brilho: Brightness.light,
    fundo: TemaHisui.temaCorFundo,
    superficie: TemaHisui.temaCorSuperficie,
    superficie2: TemaHisui.temaCorSuperficie2,
    borda: TemaHisui.temaCorBorda,
    texto: TemaHisui.temaCorTexto,
    texto2: TemaHisui.temaCorTexto2,
    acento: TemaHisui.temaCorAcento,
    acentoSuave: TemaHisui.temaCorAcentoSuave,
    botaoFundo: TemaHisui.temaCorBotaoFundo,
    botaoTexto: TemaHisui.temaCorBotaoTexto,
    foco: TemaHisui.temaCorFoco,
    selo: TemaHisui.temaCorSelo,
    erro: TemaHisui.temaCorErro,
    aviso: TemaHisui.temaCorAviso,
    sucesso: TemaHisui.temaCorSucesso,
  );

  static const sumi = TemaHeisuca(
    nome: 'sumi',
    brilho: Brightness.dark,
    fundo: TemaSumi.temaCorFundo,
    superficie: TemaSumi.temaCorSuperficie,
    superficie2: TemaSumi.temaCorSuperficie2,
    borda: TemaSumi.temaCorBorda,
    texto: TemaSumi.temaCorTexto,
    texto2: TemaSumi.temaCorTexto2,
    acento: TemaSumi.temaCorAcento,
    acentoSuave: TemaSumi.temaCorAcentoSuave,
    botaoFundo: TemaSumi.temaCorBotaoFundo,
    botaoTexto: TemaSumi.temaCorBotaoTexto,
    foco: TemaSumi.temaCorFoco,
    selo: TemaSumi.temaCorSelo,
    erro: TemaSumi.temaCorErro,
    aviso: TemaSumi.temaCorAviso,
    sucesso: TemaSumi.temaCorSucesso,
  );

  // O kids não é um tema: é o claro ou o escuro com outro acento. O nome continua o do tema de base,
  // para a cor do pôster tingir o fundo do mesmo jeito.

  /// Kids Ichigo (morango) de dia: o Hisui com o acento do Ichigo.
  static const ichigo = TemaHeisuca(
    nome: 'hisui',
    brilho: Brightness.light,
    fundo: TemaHisui.temaCorFundo,
    superficie: TemaHisui.temaCorSuperficie,
    superficie2: TemaHisui.temaCorSuperficie2,
    borda: TemaHisui.temaCorBorda,
    texto: TemaHisui.temaCorTexto,
    texto2: TemaHisui.temaCorTexto2,
    acento: TemaIchigo.temaCorAcento,
    acentoSuave: TemaIchigo.temaCorAcentoSuave,
    botaoFundo: TemaHisui.temaCorBotaoFundo,
    botaoTexto: TemaHisui.temaCorBotaoTexto,
    foco: TemaHisui.temaCorFoco,
    selo: TemaHisui.temaCorSelo,
    erro: TemaHisui.temaCorErro,
    aviso: TemaHisui.temaCorAviso,
    sucesso: TemaHisui.temaCorSucesso,
  );

  /// Kids Ichigo à noite: o Shikkoku com o acento do Ichigo.
  static const ichigoNoite = TemaHeisuca(
    nome: 'shikkoku',
    brilho: Brightness.dark,
    fundo: TemaShikkoku.temaCorFundo,
    superficie: TemaShikkoku.temaCorSuperficie,
    superficie2: TemaShikkoku.temaCorSuperficie2,
    borda: TemaShikkoku.temaCorBorda,
    texto: TemaShikkoku.temaCorTexto,
    texto2: TemaShikkoku.temaCorTexto2,
    acento: TemaIchigoNoite.temaCorAcento,
    acentoSuave: TemaIchigoNoite.temaCorAcentoSuave,
    botaoFundo: TemaShikkoku.temaCorBotaoFundo,
    botaoTexto: TemaShikkoku.temaCorBotaoTexto,
    foco: TemaShikkoku.temaCorFoco,
    selo: TemaShikkoku.temaCorSelo,
    erro: TemaShikkoku.temaCorErro,
    aviso: TemaShikkoku.temaCorAviso,
    sucesso: TemaShikkoku.temaCorSucesso,
  );

  /// Kids Sorairo (céu) de dia: o Hisui com o acento do Sorairo.
  static const sorairo = TemaHeisuca(
    nome: 'hisui',
    brilho: Brightness.light,
    fundo: TemaHisui.temaCorFundo,
    superficie: TemaHisui.temaCorSuperficie,
    superficie2: TemaHisui.temaCorSuperficie2,
    borda: TemaHisui.temaCorBorda,
    texto: TemaHisui.temaCorTexto,
    texto2: TemaHisui.temaCorTexto2,
    acento: TemaSorairo.temaCorAcento,
    acentoSuave: TemaSorairo.temaCorAcentoSuave,
    botaoFundo: TemaHisui.temaCorBotaoFundo,
    botaoTexto: TemaHisui.temaCorBotaoTexto,
    foco: TemaHisui.temaCorFoco,
    selo: TemaHisui.temaCorSelo,
    erro: TemaHisui.temaCorErro,
    aviso: TemaHisui.temaCorAviso,
    sucesso: TemaHisui.temaCorSucesso,
  );

  /// Kids Sorairo à noite: o Shikkoku com o acento do Sorairo.
  static const sorairoNoite = TemaHeisuca(
    nome: 'shikkoku',
    brilho: Brightness.dark,
    fundo: TemaShikkoku.temaCorFundo,
    superficie: TemaShikkoku.temaCorSuperficie,
    superficie2: TemaShikkoku.temaCorSuperficie2,
    borda: TemaShikkoku.temaCorBorda,
    texto: TemaShikkoku.temaCorTexto,
    texto2: TemaShikkoku.temaCorTexto2,
    acento: TemaSorairoNoite.temaCorAcento,
    acentoSuave: TemaSorairoNoite.temaCorAcentoSuave,
    botaoFundo: TemaShikkoku.temaCorBotaoFundo,
    botaoTexto: TemaShikkoku.temaCorBotaoTexto,
    foco: TemaShikkoku.temaCorFoco,
    selo: TemaShikkoku.temaCorSelo,
    erro: TemaShikkoku.temaCorErro,
    aviso: TemaShikkoku.temaCorAviso,
    sucesso: TemaShikkoku.temaCorSucesso,
  );

  static const todos = <TemaHeisuca>[shikkoku, hisui, sumi];

  /// Os acentos do kids, sobre o claro e o escuro.
  static const doKids = <TemaHeisuca>[ichigo, ichigoNoite, sorairo, sorairoNoite];

  /// O tema da tela. Fora de um `Theme` da V2, vale o padrão (Shikkoku).
  static TemaHeisuca de(BuildContext context) => Theme.of(context).extension<TemaHeisuca>() ?? shikkoku;

  /// Tinta legível sobre [base]: a que contrasta mais, entre o texto e o fundo do tema.
  Color sobre(Color base) => contraste(texto, base) >= contraste(fundo, base) ? texto : fundo;

  /// Contraste WCAG 2 entre duas cores opacas (1 a 21).
  static double contraste(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final claro = la > lb ? la : lb, escuro = la > lb ? lb : la;
    return (claro + 0.05) / (escuro + 0.05);
  }

  /// O tema do Material: o comportamento é o do sistema, a aparência é a nossa.
  ThemeData paraMaterial() {
    final esquema = ColorScheme(
      brightness: brilho,
      primary: acento,
      onPrimary: sobre(acento),
      primaryContainer: acentoSuave,
      onPrimaryContainer: texto,
      secondary: acento,
      onSecondary: sobre(acento),
      secondaryContainer: superficie2,
      onSecondaryContainer: texto,
      error: erro,
      onError: sobre(erro),
      surface: fundo,
      onSurface: texto,
      onSurfaceVariant: texto2,
      surfaceContainerLowest: fundo,
      surfaceContainerLow: superficie,
      surfaceContainer: superficie,
      surfaceContainerHigh: superficie2,
      surfaceContainerHighest: superficie2,
      outline: borda,
      outlineVariant: borda,
      inverseSurface: texto,
      onInverseSurface: fundo,
      inversePrimary: acentoSuave,
      surfaceTint: fundo.withValues(alpha: 0),
    );
    final botao = ButtonStyle(
      // Sem ação o botão apaga; foco e toque seguem a camada padrão do Material sobre a cor do texto.
      backgroundColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.disabled) ? botaoFundo.withValues(alpha: 0.38) : botaoFundo,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.disabled) ? botaoTexto.withValues(alpha: 0.6) : botaoTexto,
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      canvasColor: fundo,
      dividerColor: borda,
      focusColor: foco.withValues(alpha: 0.16),
      fontFamily: HeisucaBase.fonteTexto,
      textTheme: Tipo.textos(this),
      filledButtonTheme: FilledButtonThemeData(style: botao),
      extensions: <ThemeExtension<dynamic>>[this],
    );
  }

  @override
  TemaHeisuca copyWith({Color? fundo, Color? superficie, Color? superficie2}) => TemaHeisuca(
    nome: nome,
    brilho: brilho,
    fundo: fundo ?? this.fundo,
    superficie: superficie ?? this.superficie,
    superficie2: superficie2 ?? this.superficie2,
    borda: borda,
    texto: texto,
    texto2: texto2,
    acento: acento,
    acentoSuave: acentoSuave,
    botaoFundo: botaoFundo,
    botaoTexto: botaoTexto,
    foco: foco,
    selo: selo,
    erro: erro,
    aviso: aviso,
    sucesso: sucesso,
  );

  /// Mistura para a troca de tema. O nome e o brilho mudam na metade do caminho.
  @override
  TemaHeisuca lerp(covariant TemaHeisuca? outro, double t) {
    if (outro == null) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return TemaHeisuca(
      nome: t < 0.5 ? nome : outro.nome,
      brilho: t < 0.5 ? brilho : outro.brilho,
      fundo: m(fundo, outro.fundo),
      superficie: m(superficie, outro.superficie),
      superficie2: m(superficie2, outro.superficie2),
      borda: m(borda, outro.borda),
      texto: m(texto, outro.texto),
      texto2: m(texto2, outro.texto2),
      acento: m(acento, outro.acento),
      acentoSuave: m(acentoSuave, outro.acentoSuave),
      botaoFundo: m(botaoFundo, outro.botaoFundo),
      botaoTexto: m(botaoTexto, outro.botaoTexto),
      foco: m(foco, outro.foco),
      selo: m(selo, outro.selo),
      erro: m(erro, outro.erro),
      aviso: m(aviso, outro.aviso),
      sucesso: m(sucesso, outro.sucesso),
    );
  }
}
