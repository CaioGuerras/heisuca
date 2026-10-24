"""Renderiza a geometria oficial do selo 炳; não altera recursos do aplicativo."""
from pathlib import Path
import xml.etree.ElementTree as ET
import cairosvg

HERE = Path(__file__).resolve().parent
BASE = HERE.parent.parent / 'apps/app/assets/heisuca/icone_shikkoku.svg'
root = ET.fromstring(BASE.read_text())
paths = list(root)
background, seal, border, glyph = [ET.tostring(p, encoding='unicode') for p in paths]
# As curvas do kanji e sua transformação são preservadas literalmente do SVG oficial.
def svg(body, defs=''):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 1024 1024"><defs>{defs}</defs>{body}</svg>'

def recolor(element, old, new):
    return element.replace(old, new)

defs = '<linearGradient id="bg" x2="0.8" y2="1"><stop stop-color="#312047"/><stop offset="1" stop-color="#100d19"/></linearGradient><linearGradient id="seal" x2="0.7" y2="1"><stop stop-color="#9368ef"/><stop offset="0.5" stop-color="#7444E0"/><stop offset="1" stop-color="#542aaf"/></linearGradient>'
relief = svg(recolor(background, '#1A1424', 'url(#bg)') + recolor(seal, '#7444E0', 'url(#seal)') + border + glyph, defs)
lines = ''.join(f'<path d="M50 {y} Q512 {y-18} 974 {y+5}" fill="none" stroke="#c4b5e0" stroke-opacity="0.035" stroke-width="2"/>' for y in range(80, 970, 13))
lacquer = svg(background + lines + seal + border + glyph)
mono = svg(recolor(background, '#1A1424', '#cbbdde') + recolor(seal, '#7444E0', '#483654') + recolor(border, '#FFF8F0', '#f5e9ff') + recolor(glyph, '#FFF8F0', '#f5e9ff'))
variants = [('01_relevo', 'Relevo e gradiente', relief), ('02_laca', 'Textura de laca', lacquer), ('03_monocromatico', 'Temático Android 13', mono)]
for name, title, data in variants:
    (HERE / f'{name}.svg').write_text(data)
    cairosvg.svg2png(bytestring=data.encode(), write_to=str(HERE / f'{name}_512.png'), output_width=512, output_height=512)

parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1120" viewBox="0 0 1500 1120"><rect width="1500" height="1120" fill="#0e0b16"/><text x="750" y="60" text-anchor="middle" fill="#fff8f0" font-family="sans-serif" font-size="30">Heisuca · variantes para escolha</text>']
for index, (name, title, data) in enumerate(variants):
    x = 110 + index * 460
    inner = data[data.index('>')+1:data.rindex('</svg>')]
    # IDs isolados por telefone para que os gradientes não se misturem.
    inner = inner.replace('id="bg"', f'id="bg{index}"').replace('url(#bg)', f'url(#bg{index})').replace('id="seal"', f'id="seal{index}"').replace('url(#seal)', f'url(#seal{index})')
    parts.append(f'<g transform="translate({x},110)"><rect width="360" height="830" rx="40" fill="#09080d" stroke="#72677f" stroke-width="3"/><rect x="12" y="12" width="336" height="806" rx="30" fill="#252035"/><path d="M12 400Q180 130 348 400V780H12Z" fill="#3e2b56"/><text x="32" y="52" fill="white" font-family="sans-serif" font-size="18">09:41</text><rect x="145" y="22" width="70" height="14" rx="7" fill="#09080d"/><text x="180" y="155" text-anchor="middle" fill="#fff8f0" font-family="sans-serif" font-size="46">Sábado</text><text x="180" y="190" text-anchor="middle" fill="#d5c8e5" font-family="sans-serif" font-size="17">24 de outubro</text>')
    for j, label in enumerate(['Fotos', 'Agenda', 'Arquivos']):
        xx = 34 + j * 108
        parts.append(f'<rect x="{xx}" y="440" width="70" height="70" rx="20" fill="{["#a6bbdc","#b2cfb2","#d5c2a5"][j]}"/><circle cx="{xx+35}" cy="475" r="12" fill="#252035"/><text x="{xx+35}" y="537" text-anchor="middle" fill="white" font-family="sans-serif" font-size="14">{label}</text>')
    parts.append(f'<svg x="124" y="590" width="112" height="112" viewBox="0 0 1024 1024">{inner}</svg><text x="180" y="732" text-anchor="middle" fill="white" font-family="sans-serif" font-size="17">Heisuca</text><rect x="130" y="797" width="100" height="5" rx="3" fill="#ede5f3"/></g><text x="{x+180}" y="1000" text-anchor="middle" fill="#fff8f0" font-family="sans-serif" font-size="24">{index+1}. {title}</text>')
parts.append('<text x="750" y="1070" text-anchor="middle" fill="#bcb0c9" font-family="sans-serif" font-size="18">Simulação de tela inicial Android · nenhuma variante foi instalada</text></svg>')
mock = ''.join(parts)
(HERE / 'mockup_android.svg').write_text(mock)
cairosvg.svg2png(bytestring=mock.encode(), write_to=str(HERE / 'mockup_android.png'))
