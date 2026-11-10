import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/utils/pointer_scroll_axis.dart';
import 'package:heisuca/utils/semantics_tree_gate.dart';

class _ComposedBinding extends AutomatedTestWidgetsFlutterBinding with PointerScrollAxisLock, SemanticsTreeGate {}

void main() {
  var calls = 0;
  final binding = HeisucaWidgetsBinding.ensureInitialized(createBinding: () { calls++; return _ComposedBinding(); });
  test('bootstrap conserva o binding composto e o cria uma única vez', () {
    expect(binding, isA<_ComposedBinding>());
    expect(binding, isA<PointerScrollAxisLock>());
    expect(binding, isA<SemanticsTreeGate>());
    expect(HeisucaWidgetsBinding.ensureInitialized(), same(binding));
    expect(WidgetsBinding.instance, same(binding));
    expect(calls, 1);
  });
}
