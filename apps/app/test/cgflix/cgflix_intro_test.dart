import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/cgflix/cgflix_intro.dart';

void main() {
  test('pula a animação em aberturas seguidas (< 30 s)', () {
    const now = 1000000;
    expect(cgflixShouldAnimateIntro(lastOpenMs: null, nowMs: now), isTrue);
    expect(cgflixShouldAnimateIntro(lastOpenMs: now - 10000, nowMs: now), isFalse);
    expect(cgflixShouldAnimateIntro(lastOpenMs: now - 30000, nowMs: now), isTrue);
    // Relógio voltou para trás: anima (não dá para confiar no intervalo).
    expect(cgflixShouldAnimateIntro(lastOpenMs: now + 5000, nowMs: now), isTrue);
  });

  test('duração entre 1,2 e 1,6 s', () {
    expect(cgflixIntroDuration.inMilliseconds, inInclusiveRange(1200, 1600));
  });

  testWidgets('a abertura anima até o fim e libera a troca de tela', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ColoredBox(
          color: Color(0xFF07060A),
          child: Center(child: CgflixIntroEmblem(size: 288)),
        ),
      ),
    );
    var finished = false;
    unawaited(CgflixIntro.finished().then((_) => finished = true));
    for (var ms = 0; ms <= 1500; ms += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
