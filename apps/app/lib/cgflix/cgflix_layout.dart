// Medidas que dependem do tamanho da tela (Etapa 1D: paisagem). Funções puras, testáveis,
// para nenhuma tela do CGFLIX fazer conta de altura por conta própria.
import 'package:flutter/widgets.dart';

/// Celular deitado (ou janela mais larga que alta).
bool cgflixIsLandscape(Size size) => size.width > size.height;

/// Altura do destaque da Início.
///
/// Em pé: ~1,15 × a largura, entre 360 dp e 68% da altura. Deitado: quase a altura toda
/// (sobra a próxima linha espiando embaixo), nunca menos que o necessário para logo +
/// botões. Até a 1C era `clamp(360, altura * 0.68)`: deitado, 68% da altura fica abaixo de
/// 360 e o `clamp` lança exceção — a Início inteira virava a caixa preta de erro.
double cgflixHeroHeight(Size size) {
  if (cgflixIsLandscape(size)) {
    return (size.height * 0.82).clamp(240.0, 520.0);
  }
  final upper = size.height * 0.68;
  return (size.width * 1.15).clamp(360.0, upper < 360.0 ? 360.0 : upper);
}

/// Destaque baixo (paisagem): logo menor e texto alinhado à esquerda.
bool cgflixHeroCompact(Size size) => cgflixIsLandscape(size) && size.height < 600;
