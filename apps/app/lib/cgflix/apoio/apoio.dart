// CGFLIX: "Apoie o CGFLIX" (gorjeta opcional; não destrava nada, sem anúncio, sem lembrete).
// A tela fala com uma interface [Apoio] para, quando o app for para a Play, entrar o Play Billing
// por `--dart-define=CGFLIX_APOIO=play` sem nenhum Pix no pacote da Play (a política da Play proíbe
// Pix ou link externo para coisa digital). O Billing ainda não existe: com `play`, o apoio some.
import 'package:flutter/material.dart';

import 'apoio_pix_view.dart';

/// Forma de apoio do pacote (Pix nos APKs nossos; Play Billing no futuro).
abstract interface class Apoio {
  /// Se a entrada "Apoie o CGFLIX" aparece (Configurações, menu do usuário e Sobre).
  bool get disponivel;

  /// Miolo da tela "Apoie o CGFLIX" (abaixo do texto de abertura).
  Widget conteudo(BuildContext context);
}

/// Sabor do apoio escolhido no build. Padrão `pix` (APK do GitHub e do nosso servidor).
const cgflixApoioSabor = String.fromEnvironment('CGFLIX_APOIO', defaultValue: 'pix');

/// Apoio deste pacote. Constante: com `play`, o compilador tira o Pix do pacote.
final Apoio cgflixApoio = cgflixApoioSabor == 'pix' ? const ApoioPixLivre() : const _SemApoio();

/// Testes trocam por um falso (ex.: para ver o menu sem o item).
Apoio? cgflixApoioDebugOverride;

Apoio get cgflixApoioAtual => cgflixApoioDebugOverride ?? cgflixApoio;

class _SemApoio implements Apoio {
  const _SemApoio();

  @override
  bool get disponivel => false;

  @override
  Widget conteudo(BuildContext context) => const SizedBox.shrink();
}
