import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/desktop_root.dart';
import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';
import 'package:heisuca/desktop/ui/desktop_library_screen.dart';

void main() {
  testWidgets('entrada real abre bibliotecas sem exigir conta para arquivos', (tester) async {
    await tester.pumpWidget(DesktopRoot(vault: MemoryDesktopConnectionVault()));
    await tester.pumpAndSettle();
    expect(find.text('Abrir arquivo'), findsOneWidget);
    expect(find.text('Bibliotecas'), findsOneWidget);
    await tester.tap(find.text('Bibliotecas'));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopLibraryScreen), findsOneWidget);
    expect(find.text('Conectar Plex'), findsWidgets);
    expect(find.text('Conectar Jellyfin'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopLibraryScreen), findsNothing);
    expect(find.text('Abrir arquivo'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
