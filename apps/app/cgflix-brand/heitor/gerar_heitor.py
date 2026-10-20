#!/usr/bin/env python3
"""Gera a marca Heitor (tema claro, verde) a partir da marca Isis em `cgflix-brand/`.

O desenho é o mesmo: só troca as cores (tabela TROCA da ordem do tema Heitor). Também gera
`assets/cgflix_emblema_heitor.svg` (sem o filtro de brilho, que o flutter_svg não desenha) e,
se o cairosvg estiver instalado, o PNG 512 do ícone. Rodar da raiz do repositório:

    python3 cgflix-brand/heitor/gerar_heitor.py
"""
import pathlib
import sys

TROCA = {
    "#f3e8ff": "#8be3a1", "#c084fc": "#34c759", "#9333ea": "#1a9443", "#581c87": "#00531d",
    'stop-color="#ffffff"/><stop offset=".55" stop-color="#ede9fe"/><stop offset="1" stop-color="#c4b5fd"':
        'stop-color="#2b3a2a"/><stop offset=".55" stop-color="#1c261c"/><stop offset="1" stop-color="#161d16"',
    'flood-color="#a855f7" flood-opacity=".6"': 'flood-color="#34c759" flood-opacity=".28"',
    'stop-color="#1e1030"': 'stop-color="#ffffff"', 'stop-color="#07060a"': 'stop-color="#e2ebde"',
}

RAIZ = pathlib.Path(__file__).resolve().parents[2]
ISIS = RAIZ / "cgflix-brand"
HEITOR = ISIS / "heitor"


def trocar(svg: str) -> str:
    # As chaves longas primeiro: o degradê do play contém cores que não podem ser trocadas sozinhas.
    for antes in sorted(TROCA, key=len, reverse=True):
        svg = svg.replace(antes, TROCA[antes])
    return svg


def main() -> int:
    for origem in sorted(ISIS.glob("*.svg")):
        (HEITOR / origem.name).write_text(trocar(origem.read_text()))
        print("heitor/" + origem.name)
    # Emblema do app (Flutter): igual ao assets/cgflix_emblema.svg da Isis, sem o filtro.
    emblema = trocar((RAIZ / "assets" / "cgflix_emblema.svg").read_text())
    (RAIZ / "assets" / "cgflix_emblema_heitor.svg").write_text(emblema)
    print("assets/cgflix_emblema_heitor.svg")
    restos = [c for c in ("#a855f7", "#9333ea", "#c084fc", "#ede9fe", "#c4b5fd", "#581c87")
              for f in HEITOR.glob("*.svg") if c in f.read_text()]
    if restos:
        print("sobrou roxo:", sorted(set(restos)), file=sys.stderr)
        return 1
    try:
        import cairosvg  # opcional
    except ImportError:
        print("(sem cairosvg: PNG não gerado)")
        return 0
    cairosvg.svg2png(url=str(HEITOR / "cgflix-icone.svg"), write_to=str(HEITOR / "cgflix-icone-512.png"),
                     output_width=512, output_height=512)
    print("heitor/cgflix-icone-512.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
