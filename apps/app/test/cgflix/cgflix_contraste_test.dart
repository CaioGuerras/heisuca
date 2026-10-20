// Tema Heitor (versão 1.4.0): contraste medido dos pares principais do esquema e da paleta.
// Regra (WCAG 2.1): texto ≥ 4,5:1; bordas, ícones e controles ≥ 3:1.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_palette.dart';

/// Luminância relativa (WCAG) de uma cor opaca.
double _luminance(Color c) {
  double channel(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Contraste entre [a] e [b]; uma cor translúcida é misturada antes sobre [b].
double contrast(Color a, Color b) {
  final top = Color.alphaBlend(a, b);
  final l1 = _luminance(top), l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  const s = cgflixHeitorScheme;
  const p = CgflixPalette.heitor;

  test('a conta confere com a tabela oficial (onSurface 16,4:1, primary ≥ 6,1:1)', () {
    expect(contrast(s.onSurface, s.surface), closeTo(16.4, 0.2));
    expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(6.1));
    expect(contrast(s.onSurfaceVariant, s.surface), closeTo(8.9, 0.2));
  });

  final texto = <String, (Color, Color)>{
    'texto principal no fundo': (s.onSurface, s.surface),
    'texto principal no cartão': (s.onSurface, s.surfaceContainerLowest),
    'texto principal na barra/campo': (s.onSurface, s.surfaceContainerHigh),
    'texto secundário no fundo': (s.onSurfaceVariant, s.surface),
    'texto secundário no cartão': (s.onSurfaceVariant, s.surfaceContainerLowest),
    'texto secundário na barra/campo': (s.onSurfaceVariant, s.surfaceContainerHigh),
    'botão principal (onPrimary/primary)': (s.onPrimary, s.primary),
    'link/aba ativa (primary no fundo)': (s.primary, s.surface),
    'selo (onPrimaryContainer/primaryContainer)': (s.onPrimaryContainer, s.primaryContainer),
    'item ativo da navegação': (s.onSecondaryContainer, s.secondaryContainer),
    'selo "Novo" (tertiary no fundo)': (s.tertiary, s.surface),
    'erro no fundo': (s.error, s.surface),
    'texto do erro (onError/error)': (s.onError, s.error),
    'paleta: botão "Assistir"': (p.onAction, p.action),
    'paleta: "Mais informações"': (p.onSecondaryAction, p.secondaryAction),
    'paleta: chip ativo': (p.onGlass, p.chipSelected),
    'paleta: chip sobre o fundo (vidro)': (p.onGlass, Color.alphaBlend(p.glass, s.surface)),
    'paleta: selo Dublado/Legendado': (p.onBadge, p.badge),
    'paleta: texto apagado': (p.textMuted, p.background),
    'paleta: destaque suave (gêneros)': (p.accentSoft, p.surface),
    'paleta: pedido disponível (sucesso)': (p.success, p.surface),
    'paleta: pedido recusado (perigo)': (p.danger, p.surface),
    'paleta: texto sobre o fim do véu do destaque': (s.onSurface, Color.alphaBlend(p.heroVeil[3], Colors.black)),
  };
  for (final e in texto.entries) {
    test('texto ≥ 4,5:1 — ${e.key}', () {
      final (fg, bg) = e.value;
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '${e.key}: ${contrast(fg, bg).toStringAsFixed(2)}');
    });
  }

  final bordas = <String, (Color, Color)>{
    'borda de campo (outline) no fundo': (s.outline, s.surface),
    'borda de campo (outline) no cartão': (s.outline, s.surfaceContainerLowest),
    'borda do vidro dos chips': (p.glassBorder, s.surface),
    'anel de foco no fundo': (p.focusRing, s.surface),
    'anel de foco no cartão': (p.focusRing, s.surfaceContainerLowest),
    'ícone ativo (primary) na barra': (s.primary, s.surfaceContainer),
    'ícone inativo na barra': (s.onSurfaceVariant, s.surfaceContainer),
    'borda do chip ativo': (p.chipSelectedBorder, s.surface),
    'contorno do número do Top 10': (p.rankStroke, s.surface),
    'coração roxo da dedicatória': (CgflixPalette.isis.accent, s.surface),
    'coração verde da dedicatória': (p.dedication, s.surface),
  };
  for (final e in bordas.entries) {
    test('borda/ícone ≥ 3:1 — ${e.key}', () {
      final (fg, bg) = e.value;
      expect(contrast(fg, bg), greaterThanOrEqualTo(3.0), reason: '${e.key}: ${contrast(fg, bg).toStringAsFixed(2)}');
    });
  }

  test('Isis continua com fundo preto puro (OLED)', () {
    expect(cgflixIsisScheme.surfaceContainerLowest, const Color(0xFF000000));
    expect(CgflixPalette.isis.background, const Color(0xFF000000));
    expect(contrast(CgflixPalette.isis.onAction, CgflixPalette.isis.action), greaterThanOrEqualTo(4.5));
  });

  test('Isis (1.5.0): erro legível no preto e borda dos botões visível', () {
    const i = cgflixIsisScheme;
    for (final bg in [i.surface, i.surfaceContainerLowest]) {
      expect(contrast(i.error, bg), greaterThanOrEqualTo(4.5));
      expect(contrast(Color.alphaBlend(i.outline, bg), bg), greaterThanOrEqualTo(3.0));
    }
    expect(contrast(i.onError, i.error), greaterThanOrEqualTo(4.5));
  });

  test('rosa do Apoie (#ec4899) como ícone ≥ 3:1 nos dois temas', () {
    const rosa = Color(0xFFEC4899);
    expect(contrast(rosa, cgflixIsisScheme.surface), greaterThanOrEqualTo(3.0));
    expect(contrast(rosa, cgflixHeitorScheme.surface), greaterThanOrEqualTo(3.0));
  });
}
