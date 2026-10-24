# Heisuca: kit de ícones (18/10/2026)

Gerado por `logo/gerador/icones.py` (rodar com `~/TMP/venv_fontes/bin/python`, que tem fonttools e skia-pathops). As cores vêm
dos tokens (`tokens/temas/*.tokens.json`), então trocar uma cor lá e rodar de novo atualiza tudo. Conferência visual:
**`FOLHA_ICONES.png`**. Os XML do Android estão renderizados de volta na folha a partir do próprio XML (`folha_icones.py`).

Base: o selo 炳 aprovado (esboço C, selo na cor do tema), com o selo ocupando 58,6 % do ícone, como na `FOLHA_C_TEMAS`.
Regra de tamanho óptico do `logo/LOGO.md`: **≥ 48 px → mincho com moldura**; **≤ 32 px → gótico 900 sem moldura**.

## O que tem e onde usar

| Pasta | Arquivos | Observação |
|---|---|---|
| `android/res/mipmap-anydpi-v26/` | `ic_launcher{_tema}.xml` | Ícone adaptativo: fundo (cor da superfície) + primeiro plano (XML) + monocromático. No círculo de 66 dp da zona segura o selo cabe inteiro (diagonal 59,7 dp) [V] |
| `android/res/drawable/` | `ic_launcher_foreground{_tema}.xml`, `ic_launcher_monochrome.xml`, `ic_stat_heisuca.xml`, `splash_selo.xml` | Monocromático (Android 13+, o sistema pinta) e notificação são um *path* só, com o 炳 recortado por operação booleana (skia-pathops), sem máscara, que o VectorDrawable não tem |
| `android/res/mipmap-*dpi/` | `ic_launcher{_tema}.png`, `…_round.png` | Legado (< Android 8), 48 a 192 px |
| `android/res/drawable-*dpi/` | `ic_stat_heisuca.png`, `banner.png` | Notificação 24–96 px; banner da Android TV 320×180 (xhdpi) e 640×360 |
| `android/` | `play_store_512{_tema}.png` | Loja: quadrado sangrado, a Google aplica a máscara |
| `ios/` | `AppIcon-{tema}-1024.png`, `AppIcon-dark-1024.png`, `AppIcon-tinted-1024.png` | Sangrado, sem alfa (a App Store recusa). Escuro e tingido do iOS 18. **Shinju** é o tema do iOS; os outros entram como ícones alternativos |
| `web/` | `favicon.svg`, `favicon.ico` (16/32/48), `apple-touch-icon.png`, `icon-192/512.png`, `icon-maskable-512.png`, `manifest_icones.json` | Maskable com o selo em 52 % (cabe no círculo de 80 %) |
| `tv/` | `tizen_icon_512x423.png`, `webos_icon_80.png`, `webos_largeIcon_130.png`, `webos_splash_1920x1080.png` | Samsung e LG (o site vira o app das TVs) |
| `svg/` | fontes vetoriais por tema, mono, banner e abertura da TV | Para materiais e para refazer qualquer PNG |

Temas: o padrão é **Shikkoku** (sem sufixo); `_hisui`, `_ichigo`, `_sorairo` e `_shinju` são ícones alternativos (no Android,
por `activity-alias`; no iOS, por `alternateIcons`). Se o Caio quiser que o ícone acompanhe o tema escolhido no app, já está pronto.

## Ícones de interface: Material Symbols × Lucide

Comparação em **`FOLHA_ICONES_UI.png`** (18 ícones do player, adulto e kids, 36 e 24 px). Pacotes conferidos no npm em 18/10:
`@material-symbols/svg-300` 0.48.0 (Apache-2.0) e `lucide-static` 1.59.0 (ISC) [V].

| | Material Symbols | Lucide |
|---|---|---|
| Visual | Fino no peso 300, discreto; tem `replay_10`/`forward_10` com o número | Traço mais elegante e uniforme no site; sem ícone de "10 s" (usa seta genérica) |
| Kids | **Rounded 500 cheio** fica ótimo com a Fredoka (linha D da folha) | Só traço; mais grosso não vira "cheio" |
| Plataformas | Pacote oficial para Flutter e Compose, fonte variável (peso, preenchimento) | Sem pacote oficial para Compose [I] |
| Estado selecionado | Troca vazio → cheio na mesma família | Precisa de outro desenho |

**Recomendação [I]: Material Symbols Rounded**, peso 300 no adulto e 500 cheio no kids (e cheio também para o item
selecionado). É uma família só para os quatro apps. **[C] Caio:** confirmar (BASE_MARCA §8, item 4).

## Pendências

- O primeiro app nativo confere os XML num build real (aqui não há SDK do Android; a prova atual é a renderização de volta).
- Animar o ícone da abertura do Android 12 (`AnimatedVectorDrawable`, o mesmo carimbo de `animacoes/`) quando o app existir.
