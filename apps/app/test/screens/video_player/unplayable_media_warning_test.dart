import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/i18n/strings.g.dart';
import 'package:heisuca/services/media_source_ranker.dart';
import 'package:heisuca/utils/dialogs.dart';
import 'package:heisuca/widgets/dialog_action_button.dart';

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return hostContext;
}

void main() {
  setUp(() {
    LocaleSettings.setLocale(AppLocale.pt);
  });

  group('Aviso de mídia não reproduzível (TV-1 G3 / Foco D-Pad)', () {
    testWidgets('mostra aviso com formato e botões padrão com foco inicial no primeiro botão', (tester) async {
      final hostContext = await _pumpHost(tester);
      final resultFuture = showUnplayableMediaDialog(
        hostContext,
        formatReason: 'HEVC 10-bit em 4K',
      );
      await tester.pumpAndSettle();

      // Title and reason
      expect(find.text(t.messages.unplayableMediaTitle), findsOneWidget);
      expect(find.text('HEVC 10-bit em 4K'), findsOneWidget);

      // Buttons
      expect(find.text(t.messages.unplayableMediaTryAnyway), findsOneWidget);
      expect(find.text(t.messages.unplayableMediaBack), findsOneWidget);

      // First button has autofocus
      final tryAnywayFinder = find.widgetWithText(DialogActionButton, t.messages.unplayableMediaTryAnyway);
      expect(tryAnywayFinder, findsOneWidget);
      final buttonWidget = tester.widget<DialogActionButton>(tryAnywayFinder);
      expect(buttonWidget.autofocus, isTrue);

      // Tapping 'Tentar assim mesmo' returns tryAnyway
      await tester.tap(tryAnywayFinder);
      await tester.pumpAndSettle();
      expect(await resultFuture, UnplayableMediaAction.tryAnyway);
    });

    testWidgets('mostra botão de versão alternativa quando disponível com foco no 1º botão', (tester) async {
      final hostContext = await _pumpHost(tester);
      final resultFuture = showUnplayableMediaDialog(
        hostContext,
        formatReason: 'HEVC 10-bit em 4K',
        alternativeResolution: '1080p',
      );
      await tester.pumpAndSettle();

      // First button is [Tocar versão 1080p] with autofocus
      final playVersionFinder = find.widgetWithText(
        DialogActionButton,
        t.messages.unplayableMediaPlayVersion(resolution: '1080p'),
      );
      expect(playVersionFinder, findsOneWidget);
      final buttonWidget = tester.widget<DialogActionButton>(playVersionFinder);
      expect(buttonWidget.autofocus, isTrue);

      // Tapping playVersion returns playVersion
      await tester.tap(playVersionFinder);
      await tester.pumpAndSettle();
      expect(await resultFuture, UnplayableMediaAction.playVersion);
    });

    test('formatMediaSourceReason formata codec, bit depth e resolução corretamente', () {
      final src4k10 = {
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'hevc', 'Profile': 'Main 10', 'BitDepth': 10, 'Width': 3840, 'Height': 2160},
        ],
      };
      expect(formatMediaSourceReason(src4k10), 'HEVC 10-bit em 4K');

      final srcAnime = {
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'h264', 'Profile': 'High 10', 'BitDepth': 10, 'Width': 1920, 'Height': 1080},
        ],
      };
      expect(formatMediaSourceReason(srcAnime), 'H.264 10-bit em 1080p');

      final srcAv1 = {
        'MediaStreams': [
          {'Type': 'Video', 'Codec': 'av1', 'Width': 3840, 'Height': 2160},
        ],
      };
      expect(formatMediaSourceReason(srcAv1), 'AV1 em 4K');
    });
  });
}
