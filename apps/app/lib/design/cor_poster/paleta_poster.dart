/// Da cor de um pôster às cores de uma tela, sem depender do Flutter.
///
/// O pôster tinge fundo, halo e superfícies. Texto e acento continuam os do
/// tema: quando um pôster ameaça a leitura, quem cede é o fundo.
library;

import 'oklab.dart';

/// Como o tema recebe a cor do pôster.
enum TintaDoTema {
  /// Tema escuro: a cor do pôster entra escura.
  escura,

  /// Tema claro: a cor do pôster entra em pastel.
  pastel,

  /// Tema preto de tela OLED: cor bem escura e halo contido.
  oled,
}

/// As cores do tema que a paleta precisa conhecer (ARGB opacos).
class PapelDoTema {
  const PapelDoTema({
    required this.nome,
    required this.tinta,
    required this.fundo,
    required this.texto,
    required this.texto2,
    required this.acento,
  });

  final String nome;
  final TintaDoTema tinta;

  /// O papel: onde todo degradê termina.
  final int fundo;
  final int texto;
  final int texto2;
  final int acento;
}

/// Contraste mínimo do texto (WCAG AA) e do acento (elementos gráficos).
const double contrasteMinimoTexto = 4.5;
const double contrasteMinimoAcento = 3.0;

class _Receita {
  const _Receita({
    required this.lTopo,
    required this.cromaTopo,
    required this.tetoTopo,
    required this.lHalo,
    required this.cromaHalo,
    required this.tetoHalo,
    required this.lSuperficie,
    required this.lSuperficie2,
    required this.cromaSuperficie,
    required this.alcanceHalo,
    required this.limiteL,
  });

  /// Luminosidade Oklab e croma (fração da semente, com teto) de cada papel.
  final double lTopo, cromaTopo, tetoTopo;
  final double lHalo, cromaHalo, tetoHalo;
  final double lSuperficie, lSuperficie2, cromaSuperficie;

  /// Até que fração da altura da tela o halo chega.
  final double alcanceHalo;

  /// Até onde a correção de contraste pode levar a luminosidade.
  final double limiteL;

  static const escura = _Receita(
    lTopo: 0.22,
    cromaTopo: 0.60,
    tetoTopo: 0.065,
    lHalo: 0.30,
    cromaHalo: 0.85,
    tetoHalo: 0.095,
    lSuperficie: 0.265,
    lSuperficie2: 0.31,
    cromaSuperficie: 0.80,
    alcanceHalo: 0.70,
    limiteL: 0.0,
  );
  static const pastel = _Receita(
    lTopo: 0.955,
    cromaTopo: 0.45,
    tetoTopo: 0.040,
    lHalo: 0.925,
    cromaHalo: 0.75,
    tetoHalo: 0.065,
    lSuperficie: 0.985,
    lSuperficie2: 0.925,
    cromaSuperficie: 0.45,
    alcanceHalo: 0.70,
    limiteL: 1.0,
  );
  static const oled = _Receita(
    lTopo: 0.13,
    cromaTopo: 0.50,
    tetoTopo: 0.045,
    lHalo: 0.17,
    cromaHalo: 0.70,
    tetoHalo: 0.060,
    lSuperficie: 0.175,
    lSuperficie2: 0.22,
    cromaSuperficie: 0.70,
    alcanceHalo: 0.45,
    limiteL: 0.0,
  );

  static _Receita de(TintaDoTema tinta) => switch (tinta) {
    TintaDoTema.escura => escura,
    TintaDoTema.pastel => pastel,
    TintaDoTema.oled => oled,
  };
}

double _degrauSuave(double de, double ate, double x) {
  final t = ((x - de) / (ate - de)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Faixa mostarda/oliva (matiz 70–115°): em pastel ou escura, essa cor parece
/// suja. Dentro da faixa o croma cai pela metade; a borda de 12° é suave para
/// dois pôsteres vizinhos no matiz não darem telas muito diferentes.
double fatorMostarda(double matiz) {
  const inicio = 70.0, fim = 115.0, borda = 12.0;
  final dentro = _degrauSuave(inicio - borda, inicio, matiz) * (1 - _degrauSuave(fim, fim + borda, matiz));
  return 1 - 0.5 * dentro;
}

/// Quanto da cor do pôster entra: pôster quase cinza não tem matiz confiável,
/// então a tela fica com o tom do próprio papel do tema.
double _forcaDaTinta(double croma) => _degrauSuave(0.008, 0.040, croma);

/// As cores de uma tela tingida por um pôster, para um tema.
class PaletaPoster {
  const PaletaPoster({
    required this.semente,
    required this.fundoTopo,
    required this.fundoFim,
    required this.halo,
    required this.superficie,
    required this.superficie2,
    required this.alcanceHalo,
  });

  /// A cor tirada do pôster, sem ajuste.
  final int semente;

  /// Fundo no alto da tela.
  final int fundoTopo;

  /// Fim do degradê: sempre o papel do tema, sem diferença de 1 bit.
  final int fundoFim;

  /// Luz atrás da arte.
  final int halo;

  /// Cartões e barras sobre o fundo tingido.
  final int superficie;

  /// Superfície de segundo nível (campo, item pressionado).
  final int superficie2;

  /// Até que fração da altura da tela o halo chega (menor no tema OLED).
  final double alcanceHalo;

  /// Paradas do fundo, do topo até o papel, interpoladas em Oklab.
  List<int> degrade({int paradas = 7}) => degradeOklab(fundoTopo, fundoFim, paradas: paradas);

  /// A paleta do tema sem pôster: tudo no tom do papel.
  factory PaletaPoster.neutra(PapelDoTema tema) => PaletaPoster.de(semente: tema.fundo, tema: tema);

  factory PaletaPoster.de({required int semente, required PapelDoTema tema}) {
    final receita = _Receita.de(tema.tinta);
    final cor = Oklab.deArgb(semente);
    final papel = Oklab.deArgb(tema.fundo);
    final croma = cor.croma * fatorMostarda(cor.matiz);
    final forca = _forcaDaTinta(cor.croma);

    int papelTingido(double l, double fracao, double teto) {
      final tinta = Oklab.deLch(l, (croma * fracao).clamp(0.0, teto), cor.matiz);
      // Mistura em Oklab com o papel do tema (não com cinza em sRGB).
      final base = papel.comL(l).mistura(tinta, forca);
      return _garantirLeitura(base, tema, receita.limiteL);
    }

    return PaletaPoster(
      semente: semente | 0xFF000000,
      fundoTopo: papelTingido(receita.lTopo, receita.cromaTopo, receita.tetoTopo),
      fundoFim: tema.fundo,
      halo: papelTingido(receita.lHalo, receita.cromaHalo, receita.tetoHalo),
      superficie: papelTingido(receita.lSuperficie, receita.cromaTopo * receita.cromaSuperficie, receita.tetoTopo),
      superficie2: papelTingido(receita.lSuperficie2, receita.cromaTopo * receita.cromaSuperficie, receita.tetoTopo),
      alcanceHalo: receita.alcanceHalo,
    );
  }
}

/// `true` quando texto, texto secundário e acento do [tema] se leem sobre [fundo].
bool leituraGarantida(int fundo, PapelDoTema tema) =>
    contraste(tema.texto, fundo) >= contrasteMinimoTexto &&
    contraste(tema.texto2, fundo) >= contrasteMinimoTexto &&
    contraste(tema.acento, fundo) >= contrasteMinimoAcento;

/// Corrige o fundo até o tema se ler sobre ele: primeiro afasta a luminosidade
/// do texto, em passos pequenos; no limite, tira croma.
int _garantirLeitura(Oklab fundo, PapelDoTema tema, double limiteL) {
  var cor = fundo.noSrgb();
  final passo = limiteL >= cor.l ? 0.004 : -0.004;
  for (var i = 0; i < 400; i++) {
    final argb = cor.paraArgb();
    if (leituraGarantida(argb, tema)) return argb;
    final proximoL = cor.l + passo;
    if ((passo > 0 && proximoL <= limiteL) || (passo < 0 && proximoL >= limiteL)) {
      cor = cor.comL(proximoL).noSrgb();
    } else if (cor.croma > 0.001) {
      cor = cor.comCroma(cor.croma * 0.85);
    } else {
      break;
    }
  }
  return tema.fundo;
}
