# Identidade do Heisuca (09/11/2026): material para os apps

Aprovada pelo dono em 09/11. Fonte única: tokens DTCG (gerados; não editar à mão). O site já está em produção com ela.

## Ideia
A tela é o suporte, o filme é a obra, o Heisuca é o carimbo vermelho no canto. A interface quase não tem cor;
a cor vem do pôster e do vídeo. Nenhuma área grande colorida fora da arte.

## Os três temas (um nome = os mesmos valores em todos os apps)
| | Shikkoku 漆黒 (escuro, padrão) | Hisui 翡翠 (claro) | Sumi 墨 (preto OLED) |
|---|---|---|---|
| Fundo | `#0F0D13` | `#F8F6EF` | `#000000` |
| Superfícies | `#1A181F` / `#26242C` | `#FEFDFA` / `#EEEBE3` | `#100F0E` / `#1D1C1A` |
| Texto 1 / 2 | `#EAE8EE` / `#ABA7B2` | `#1A201C` / `#545E57` | `#DBD9D5` / `#96938E` |
| Acento | `#B8ADDE` | `#276C4F` | `#DCB875` |
| Selo 朱 | `#C84127` | `#C3381C` | `#C84127` |

Valores completos (borda, foco, erro, aviso, sucesso, botão, acento suave): `dart/temas/tema_*.dart`.
Base (espaços, raios, tempos, curvas, fontes): `dart/heisuca_base.dart`.

## Regras
- Botão principal ("Assistir") **neutro**: `temaCorBotaoFundo` / `temaCorBotaoTexto` (claro sobre escuro e vice-versa).
- Acento só em coisa pequena: aba ativa, barra de progresso, chave ligada, link, chip selecionado.
- Selo 朱 só no logo, no ícone e na abertura. Nunca em botão nem em fundo.
- Player sempre nos neutros do Sumi, em qualquer tema.
- Fontes: Inter em tudo; Sora só no logotipo HEISUCA; Shippori Mincho só no japonês; Fredoka só no kids.
- Kids não é tema: Ichigo e Sorairo trocam só o acento, sobre Hisui de dia e Shikkoku à noite (`tema_ichigo*`, `tema_sorairo*`).
- Shinju foi aposentado. Matinê e Projetor (nomes antigos do site) = Hisui e Sumi.
- Android TV: só Shikkoku e Sumi (sem Hisui, sem paleta azul própria). Celular: Automático segue o sistema
  (escuro → Shikkoku, claro → Hisui); Sumi é manual.
- Foco na TV: escala 1,06 + anel claro de 3 px (`temaCorFoco`).

## Ícones (`android/`)
`res/` segue a estrutura do Android: ícone adaptativo por tema (`mipmap-anydpi-v26/ic_launcher{_tema}.xml` +
`drawable/ic_launcher_foreground{_tema}.xml` + `values/ic_launcher_background{_tema}.xml`), monocromático, notificação,
`splash_selo.xml`, PNG legados e o banner da Android TV. `play_store_512{_tema}.png` = loja.
Os XML foram conferidos por renderização, não num build real.
