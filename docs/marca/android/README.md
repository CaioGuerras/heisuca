# Fontes monocromáticas Android

Vetores oficiais já usados pelo app, trazidos para cá como entrada estável do
novo gerador. Não foram redesenhados: `ic_launcher_monochrome.xml` vem do selo
mincho com moldura; `ic_stat_heisuca.xml` vem do 炳 gótico pequeno, sem moldura.
O segundo mede 24 dp, em todas as densidades; o primeiro respeita a zona segura
do adaptive icon. O sistema pinta o monocromático do launcher.

Gerar: `bash apps/app/scripts/codegen/generate_android_icons.sh`.
Conferir sem escrever: o mesmo comando com `--verify`.
Dependência de desenvolvimento usada nesta rodada: CairoSVG 2.9.1 (fora do app).
O gerador usa exclusivamente esses vetores, os `assets/heisuca/icone_*.svg` e a
variante aprovada em `docs/icone_variantes_2026-10-24/01_relevo.svg`.

Shikkoku mantém os gradientes exatos aprovados. Os demais temas mantêm suas cores
centrais e a geometria: brilho de 20% de branco e sombra de 22% de preto no selo;
fundo escuro recebe 15% da cor do selo e sombra de 35%; fundo claro fica branco
até um tom de 3,5% da cor do selo. A moldura e a tinta do kanji são as originais.
Heitor é conservado como nome técnico de compatibilidade para os recursos Hisui.
O applicationId, os aliases habilitados e o mecanismo de troca não mudaram.

`docs/evidencias/j_icones_48px.{svg,png}` é uma prévia local, não captura de celular:
SVG aprovado/derivado, composição do XML efetivo sob máscara circular Android,
monocromático e notificação. As três primeiras colunas medem 48 px; a última, 24 px.
O XML também foi aceito por `aapt2 compile`; instalação/launcher real ficam para
conferência em aparelho. Não confundir prévia rasterizada com aprovação física.
