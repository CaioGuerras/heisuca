// P2: WCAG AA para os papéis de texto das três paletas aprovadas.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_palette.dart';

double contrast(Color a, Color b) {
  final blended = Color.alphaBlend(a, b);
  final x = blended.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final (name, s, p) in [
    ('Shikkoku', cgflixIsisScheme, CgflixPalette.isis),
    ('Hisui claro', cgflixHeitorScheme, CgflixPalette.heitor),
  ]) {
    final backgrounds = {
      'canvas': p.background,
      'superfície 1': p.surface,
      'superfície 2': s.surfaceContainerHigh,
      'superfície 3': s.surfaceContainerHighest,
    };
    for (final background in backgrounds.entries) {
      for (final (role, candidate) in [
        ('principal', p.text), ('secundário', p.textMuted),
        ('destaque', p.accent), ('erro', p.danger), ('sucesso', p.success),
      ]) {
        test('$name, $role em ${background.key}: papel de texto ≥ 4,5:1', () {
          final color = p.textOn(background.value, preferred: candidate);
          expect(contrast(color, background.value), greaterThanOrEqualTo(4.5));
          expect(color, anyOf(candidate, p.text));
          if (contrast(candidate, background.value) < 4.5) {
            expect(color, p.text, reason: 'cor de status não é texto universal');
          }
        });
      }
      test('$name: texto do Material em ${background.key} ≥ 4,5:1', () {
        expect(contrast(s.onSurface, background.value), greaterThanOrEqualTo(4.5));
        expect(contrast(s.onSurfaceVariant, background.value), greaterThanOrEqualTo(4.5));
      });
    }
    final pairs = {
      'botão': (s.onPrimary, s.primary),
      'botão secundário': (s.onSecondary, s.secondary),
      'botão terciário': (s.onTertiary, s.tertiary),
      'selo': (s.onPrimaryContainer, s.primaryContainer),
      'seleção': (s.onSecondaryContainer, s.secondaryContainer),
      'erro preenchido': (s.onError, s.error),
      'erro em cartão': (s.onErrorContainer, s.errorContainer),
      'inverso': (s.onInverseSurface, s.inverseSurface),
      'Assistir': (p.onAction, p.action),
      'ação secundária': (p.onSecondaryAction, p.secondaryAction),
      'selo da paleta': (p.onBadge, p.badge),
      'chip': (p.onGlass, p.chipSelected),
      'vidro': (p.onGlass, Color.alphaBlend(p.glass, p.background)),
      'botão sobre foto': (p.onPhotoButton, p.photoButton),
    };
    for (final pair in pairs.entries) {
      test('$name: ${pair.key} ≥ 4,5:1', () {
        expect(contrast(pair.value.$1, pair.value.$2), greaterThanOrEqualTo(4.5));
      });
    }
    test('$name: foco visível no canvas e cartão', () {
      for (final bg in [p.background, p.surface]) {
        expect(contrast(p.focusRing, bg), greaterThanOrEqualTo(3));
      }
    });
  }

  test('anel de foco (focusRing) ≥ 3:1 no canvas e na superfície das 4 paletas', () {
    for (final p in [CgflixPalette.isis, CgflixPalette.heitor,
        CgflixPalette.ichigo, CgflixPalette.sorairo]) {
      for (final bg in [p.background, p.surface]) {
        expect(contrast(p.focusRing, bg), greaterThanOrEqualTo(3), reason: '${p.variant}');
      }
    }
  });

  test('Hisui claro: verde suave é preenchimento de selo, nunca texto/ícone', () {
    const p = CgflixPalette.heitor;
    const pale = Color(0xFF8EB69B);
    expect(p.badge, pale);
    expect(p.onBadge, const Color(0xFF051F20));
    for (final fg in [p.text, p.textMuted, p.accent, p.accentSoft, p.success, p.danger, p.focusRing]) {
      expect(fg, isNot(pale));
    }
  });
}
