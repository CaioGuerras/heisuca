#!/usr/bin/env python3
"""Gera os ícones do app Android do CGFLIX: Isis (`cgflix-brand/`) e Heitor (`cgflix-brand/heitor/`).

Desde a 1.5.0 o ícone acompanha o tema (dois `activity-alias` no manifesto): Isis = roxo (padrão),
Heitor = verde. Mesmo desenho e mesmo enquadramento; só as cores mudam. Para cada um, gera:
  - `drawable/ic_launcher_foreground.xml`: o emblema "C com play" do ícone adaptativo;
  - `drawable/ic_launcher_monochrome.xml`: a camada monocromática (ícones temáticos do Android 13+);
  - `mipmap-*/ic_launcher.png`: o ícone antigo (Android 7 e anteriores), de `cgflix-icone.svg`.
O fundo do adaptativo é a cor `ic_launcher_background` (#07060a) ou `ic_launcher_background_heitor`
(#f4fcee), em `values/colors.xml`. A camada monocromática é a mesma nos dois (o sistema pinta).
Os arquivos do Heitor levam o sufixo `_heitor` (`drawable/ic_launcher_foreground_heitor.xml`,
`mipmap-anydpi-v26/ic_launcher_heitor.xml`, `mipmap-*/ic_launcher_heitor.png`).

Medidas (ícone adaptativo: 108 dp, zona segura = círculo de 66 dp no centro). O emblema todo
(arco de raio 340 + metade do traço 64) cabe num círculo de raio ~405 em volta do centro do
desenho (1000 × 1000). A escala deixa esse círculo com 70% do diâmetro da zona segura, e nada
fica fora dela. Rodar da raiz do repositório (precisa de `cairosvg` e `pillow`):

    python3 cgflix-brand/gerar_icone_android.py
"""
import io
import math
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[1]
RES = RAIZ / "android" / "app" / "src" / "main" / "res"

ICONE_DP = 108
ZONA_SEGURA_DP = 66
FRACAO = 0.70
# Raio do emblema em volta do centro (500, 500): arco de 340 + metade do traço (128 / 2).
RAIO_EMBLEMA = math.hypot(760.9 - 500, 281 - 500) + 64
ESCALA = round((FRACAO * ZONA_SEGURA_DP / 2) / ICONE_DP * 1000 / RAIO_EMBLEMA, 3)

ARCO = "M760.9,281A340,340 0,1 0,760.9,719"
PLAY = "M452,368L452,632L668,500Z"

FRENTE_MODELO = """<?xml version="1.0" encoding="utf-8"?>
<!-- CGFLIX: emblema "C com play" (cgflix-brand/cgflix-emblema.svg) no ícone adaptativo, com
     ~{fracao}% da zona segura e nada fora dela. Tema {tema}. Gerado por cgflix-brand/gerar_icone_android.py. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="1000"
    android:viewportHeight="1000">
    <group android:scaleX="{escala}" android:scaleY="{escala}" android:pivotX="500" android:pivotY="500">
        <path
            android:pathData="{arco}"
            android:strokeWidth="128"
            android:strokeLineCap="round">
            <aapt:attr name="android:strokeColor">
                <gradient android:startX="160" android:startY="160" android:endX="840" android:endY="840" android:type="linear">
                    <item android:offset="0" android:color="{c0}"/>
                    <item android:offset="0.3" android:color="{c1}"/>
                    <item android:offset="0.7" android:color="{c2}"/>
                    <item android:offset="1" android:color="{c3}"/>
                </gradient>
            </aapt:attr>
        </path>
        <path
            android:pathData="{play}"
            android:fillColor="{p}"
            android:strokeColor="{p}"
            android:strokeWidth="54"
            android:strokeLineJoin="round"/>
    </group>
</vector>
"""

# (sufixo, pasta da marca, degradê do "C", cor do play, cor de fundo do adaptativo)
TEMAS = {
    "Isis": ("", RAIZ / "cgflix-brand", ("#f3e8ff", "#c084fc", "#9333ea", "#581c87"), "#ede9fe", "ic_launcher_background"),
    "Heitor": (
        "_heitor",
        RAIZ / "cgflix-brand" / "heitor",
        ("#8be3a1", "#34c759", "#1a9443", "#00531d"),
        "#1c261c",
        "ic_launcher_background_heitor",
    ),
}

ADAPTATIVO = """<?xml version="1.0" encoding="utf-8"?>
<!-- CGFLIX: ícone do tema {tema} (gerado por cgflix-brand/gerar_icone_android.py). -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/{fundo}"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground{sufixo}" />
  <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
"""

MONOCROMATICO = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- CGFLIX: camada monocromática (ícones temáticos do Android 13+): o mesmo emblema e a mesma
     escala da frente; o sistema pinta com a cor do papel de parede. Gerado por
     cgflix-brand/gerar_icone_android.py. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="1000"
    android:viewportHeight="1000">
    <group android:scaleX="{ESCALA}" android:scaleY="{ESCALA}" android:pivotX="500" android:pivotY="500">
        <path
            android:pathData="{ARCO}"
            android:strokeColor="#000000"
            android:strokeWidth="128"
            android:strokeLineCap="round"/>
        <path
            android:pathData="{PLAY}"
            android:fillColor="#000000"
            android:strokeColor="#000000"
            android:strokeWidth="54"
            android:strokeLineJoin="round"/>
    </group>
</vector>
"""

# Ícone antigo (48 dp) por densidade.
DENSIDADES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def main() -> None:
    (RES / "drawable" / "ic_launcher_monochrome.xml").write_text(MONOCROMATICO)
    print(f"escala do emblema: {ESCALA}")

    import cairosvg
    from PIL import Image

    for tema, (sufixo, pasta, arco, play, fundo) in TEMAS.items():
        frente = FRENTE_MODELO.format(
            fracao=round(FRACAO * 100), tema=tema, escala=ESCALA, arco=ARCO, play=PLAY,
            c0=arco[0], c1=arco[1], c2=arco[2], c3=arco[3], p=play,
        )
        (RES / "drawable" / f"ic_launcher_foreground{sufixo}.xml").write_text(frente)
        if sufixo:
            # O do Isis (ic_launcher.xml) é o original do Etapa 0; o do Heitor sai daqui.
            (RES / "mipmap-anydpi-v26" / f"ic_launcher{sufixo}.xml").write_text(
                ADAPTATIVO.format(tema=tema, fundo=fundo, sufixo=sufixo)
            )
        svg = (pasta / "cgflix-icone.svg").read_bytes()
        for nome, px in DENSIDADES.items():
            # Desenha grande e reduz (o brilho com desfoque fica mais limpo assim).
            grande = cairosvg.svg2png(bytestring=svg, output_width=px * 4, output_height=px * 4)
            img = Image.open(io.BytesIO(grande)).convert("RGBA").resize((px, px), Image.LANCZOS)
            img.save(RES / f"mipmap-{nome}" / f"ic_launcher{sufixo}.png", optimize=True)
            print(f"mipmap-{nome}/ic_launcher{sufixo}.png ({px} px)")


if __name__ == "__main__":
    main()
