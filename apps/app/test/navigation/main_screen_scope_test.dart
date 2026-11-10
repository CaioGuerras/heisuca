import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/navigation/main_screen_scope.dart';

void main() {
  testWidgets('focusSidebarOf invokes the scope callback', (tester) async {
    var focusCalls = 0;
    late BuildContext childContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MainScreenFocusScope(
          focusSidebar: () => focusCalls++,
          sideNavigationWidth: 0,
          child: Builder(
            builder: (context) {
              childContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    MainScreenFocusScope.focusSidebarOf(childContext);

    expect(focusCalls, 1);
  });

  testWidgets('goHomeOf chama a ação do escopo e diz se havia uma', (tester) async {
    var homeCalls = 0;
    late BuildContext comAcao;
    late BuildContext semAcao;

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MainScreenFocusScope(
              focusSidebar: () {},
              sideNavigationWidth: 0,
              goHome: () => homeCalls++,
              child: Builder(
                builder: (context) {
                  comAcao = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
            MainScreenFocusScope(
              focusSidebar: () {},
              sideNavigationWidth: 0,
              child: Builder(
                builder: (context) {
                  semAcao = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(MainScreenFocusScope.goHomeOf(comAcao), isTrue);
    expect(homeCalls, 1);
    // Sem goHome (fora da TV), a Busca segue para a barra lateral.
    expect(MainScreenFocusScope.goHomeOf(semAcao), isFalse);
  });

  testWidgets('focusSidebarOf is a no-op without a scope', (tester) async {
    late BuildContext childContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            childContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(() => MainScreenFocusScope.focusSidebarOf(childContext), returnsNormally);
  });

  testWidgets('focusSidebarOf does not register an inherited dependency', (tester) async {
    var sideNavigationWidth = 0.0;
    var childBuilds = 0;
    var focusCalls = 0;
    late StateSetter rebuildScope;
    final child = Builder(
      builder: (context) {
        childBuilds++;
        MainScreenFocusScope.focusSidebarOf(context);
        return const SizedBox.shrink();
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuildScope = setState;
            return MainScreenFocusScope(
              focusSidebar: () => focusCalls++,
              sideNavigationWidth: sideNavigationWidth,
              child: child,
            );
          },
        ),
      ),
    );

    expect(childBuilds, 1);
    expect(focusCalls, 1);

    rebuildScope(() => sideNavigationWidth = 100);
    await tester.pump();

    expect(childBuilds, 1);
    expect(focusCalls, 1);
  });
}
