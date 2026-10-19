#!/usr/bin/env python3
"""Monta a comparação lado a lado: print nosso × print de referência (ref/), na mesma altura, com rótulo em cima.

Uso: lado_a_lado.py SAIDA.png NOSSO.png REF.png [REF2.png ...] [--altura 1100] [--rotulos "Heisuca,VidHub"]
Regra do PLANO §15: nenhuma tela vai ao Caio sem esta comparação.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

args = [a for a in sys.argv[1:]]
altura = 1100
rotulos = []
if "--altura" in args:
    i = args.index("--altura"); altura = int(args[i + 1]); del args[i:i + 2]
if "--rotulos" in args:
    i = args.index("--rotulos"); rotulos = args[i + 1].split(","); del args[i:i + 2]
saida, *fotos = args
imgs = []
for f in fotos:
    im = Image.open(f).convert("RGB")
    imgs.append(im.resize((round(im.width * altura / im.height), altura), Image.LANCZOS))
faixa, vao = 44, 24
L = sum(i.width for i in imgs) + vao * (len(imgs) + 1)
tela = Image.new("RGB", (L, altura + faixa + vao), (24, 24, 28))
d = ImageDraw.Draw(tela)
try:
    fonte = ImageFont.truetype("DejaVuSans-Bold.ttf", 22)
except (OSError, ImportError):
    fonte = ImageFont.load_default()
x = vao
for n, im in enumerate(imgs):
    tela.paste(im, (x, faixa))
    nome = rotulos[n] if n < len(rotulos) else fotos[n].rsplit("/", 1)[-1]
    d.text((x, 10), nome, fill=(235, 235, 240), font=fonte)
    x += im.width + vao
tela.save(saida, optimize=True)
print(saida, tela.size)
