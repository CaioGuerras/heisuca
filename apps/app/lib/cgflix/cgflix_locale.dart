// CGFLIX (1.5.0, acabamento): o upstream não carregava as traduções do próprio Material, então
// a dica "Back" da seta de voltar, o menu "Copy/Paste" dos campos e o "Dismiss" do leitor de
// tela saíam em inglês. Aqui o Material segue o idioma escolhido no app (slang).
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../i18n/strings.g.dart';

/// Idioma do Material = o do app (precisa de um TranslationProvider acima de [context]).
Locale cgflixMaterialLocale(BuildContext context) => TranslationProvider.of(context).flutterLocale;

List<Locale> get cgflixSupportedLocales => AppLocaleUtils.supportedLocales;

const cgflixLocalizationsDelegates = GlobalMaterialLocalizations.delegates;

/// Abas do seletor de cor (o FlexColorPicker vinha com "Primary" e "Wheel" em inglês).
const cgflixColorPickerLabels = <ColorPickerType, String>{
  ColorPickerType.primary: 'Cores',
  ColorPickerType.wheel: 'Personalizada',
};

/// Refino 2: o que o leitor de tela diz numa opção de lista com texto extra ("Isis, escuro, roxo").
/// Sem extra, `null` (o próprio texto).
String? cgflixOptionSemantics(String title, String? hint) => hint == null ? null : '$title, $hint';
