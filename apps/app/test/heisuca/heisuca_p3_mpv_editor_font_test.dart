import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/cgflix/cgflix_theme.dart';
import 'package:heisuca/screens/settings/mpv_config_line_editor.dart';
import 'package:heisuca/screens/settings/mpv_config_screen.dart';

void main() {
  test('P3 estilo do editor mpv usa família monoespaçada com reservas', () {
    expect(mpvEditorStyle.fontFamily, cgflixMonoFamily);
    expect(mpvEditorStyle.fontFamily, isNot('Inter'));
    expect(mpvEditorStyle.fontFamilyFallback, containsAll(['RobotoMono', 'Courier']));
  });

  testWidgets('P3 editor por linhas do mpv renderiza em monoespaçada', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: cgflixAppTheme(), home: Scaffold(
      body: MpvConfigLineEditor(text: 'hwdec=auto', onChanged: (_) {}, style: mpvEditorStyle))));
    await tester.pump();
    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    expect(fields, isNotEmpty);
    for (final f in fields) {
      expect(f.style.fontFamily, cgflixMonoFamily);
    }
  });
}
