#!/usr/bin/env python3
"""Aplica a variante 1 aprovada, com geometria oficial e recursos Android reproduzíveis."""
import argparse
import base64
from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg

APP = Path(__file__).resolve().parents[2]
REPO = APP.parent.parent
RES = APP / 'android/app/src/main/res'
SVG = 'http://www.w3.org/2000/svg'
ANDROID = 'http://schemas.android.com/apk/res/android'
AAPT = 'http://schemas.android.com/aapt'
ET.register_namespace('android', ANDROID)
ET.register_namespace('aapt', AAPT)
ET.register_namespace('', SVG)
THEMES = ['shikkoku', 'hisui', 'ichigo', 'sorairo', 'shinju']
DENSITIES = {'mdpi': (48, 24), 'hdpi': (72, 36), 'xhdpi': (96, 48), 'xxhdpi': (144, 72), 'xxxhdpi': (192, 96)}
reference = ET.parse(REPO / 'docs/icone_variantes_2026-10-24/01_relevo.svg').getroot()


def paths(root):
    return root.findall(f'{{{SVG}}}path')


def mix(color, other, amount):
    a = [int(color[i:i+2], 16) for i in (1, 3, 5)]
    b = [int(other[i:i+2], 16) for i in (1, 3, 5)]
    return '#' + ''.join(f'{round(x * (1-amount) + y * amount):02X}' for x, y in zip(a, b))


def artwork(theme):
    base = ET.parse(APP / f'assets/heisuca/icone_{theme}.svg').getroot()
    assert [p.get('d') for p in paths(base)] == [p.get('d') for p in paths(reference)], 'Geometria divergiu da marca aprovada'
    if theme == 'shikkoku':
        return deepcopy(reference)
    bg, seal, _, _ = paths(base)
    background, accent = bg.get('fill'), seal.get('fill')
    definitions = deepcopy(reference.find(f'{{{SVG}}}defs'))
    for gradient in definitions:
        if gradient.get('id') == 'seal':
            colors = [mix(accent, '#FFFFFF', .20), accent, mix(accent, '#000000', .22)]
        else:
            light = sum(int(background[i:i+2], 16) for i in (1, 3, 5)) / 3 > 220
            colors = [background, mix(background, accent, .035)] if light else [mix(background, accent, .15), mix(background, '#000000', .35)]
        for stop, color in zip(gradient, colors):
            stop.set('stop-color', color)
    base.insert(0, definitions)
    bg.set('fill', 'url(#bg)')
    seal.set('fill', 'url(#seal)')
    return base


def vector():
    return ET.Element('vector', {f'{{{ANDROID}}}width': '108dp', f'{{{ANDROID}}}height': '108dp',
        f'{{{ANDROID}}}viewportWidth': '108', f'{{{ANDROID}}}viewportHeight': '108'})


def gradient(parent, colors, start, end):
    attr = ET.SubElement(parent, f'{{{AAPT}}}attr', {'name': 'android:fillColor'})
    g = ET.SubElement(attr, 'gradient', {f'{{{ANDROID}}}type': 'linear',
        f'{{{ANDROID}}}startX': str(start[0]), f'{{{ANDROID}}}startY': str(start[1]),
        f'{{{ANDROID}}}endX': str(end[0]), f'{{{ANDROID}}}endY': str(end[1])})
    for offset, color in colors:
        ET.SubElement(g, 'item', {f'{{{ANDROID}}}offset': offset, f'{{{ANDROID}}}color': color})


def resources(art):
    definitions = {g.get('id'): [(s.get('offset', '0'), s.get('stop-color')) for s in g] for g in art.find(f'{{{SVG}}}defs')}
    background = vector()
    p = ET.SubElement(background, 'path', {f'{{{ANDROID}}}pathData': 'M0,0H108V108H0Z'})
    gradient(p, definitions['bg'], (18, 18), (75.6, 90))
    foreground = vector()
    root = ET.SubElement(foreground, 'group', {f'{{{ANDROID}}}translateX': '18', f'{{{ANDROID}}}translateY': '18',
        f'{{{ANDROID}}}scaleX': '0.0703125', f'{{{ANDROID}}}scaleY': '0.0703125'})
    for source in paths(art)[1:]:
        group = root
        if source.get('transform'):
            # Mesma transformação do SVG oficial: translate(302, 671.6) scale(.42).
            assert source.get('transform') == 'translate(302.00,671.60) scale(0.42000)'
            group = ET.SubElement(root, 'group', {f'{{{ANDROID}}}translateX': '302', f'{{{ANDROID}}}translateY': '671.6',
                f'{{{ANDROID}}}scaleX': '.42', f'{{{ANDROID}}}scaleY': '.42'})
        attrs = {f'{{{ANDROID}}}pathData': source.get('d')}
        fill = source.get('fill')
        if not fill.startswith('url'):
            attrs[f'{{{ANDROID}}}fillColor'] = '#00000000' if fill == 'none' else fill
        for svg_name, android_name in [('stroke', 'strokeColor'), ('stroke-width', 'strokeWidth')]:
            if source.get(svg_name): attrs[f'{{{ANDROID}}}{android_name}'] = source.get(svg_name)
        p = ET.SubElement(group, 'path', attrs)
        if fill == 'url(#seal)': gradient(p, definitions['seal'], (212, 212), (632, 812))
    return foreground, background


def xml(root):
    ET.indent(root, space='  ')
    return b'<?xml version="1.0" encoding="utf-8"?>\n' + ET.tostring(root, encoding='utf-8') + b'\n'


def vector_svg(data):
    source = ET.fromstring(data)
    root = ET.Element(f'{{{SVG}}}svg', {'viewBox': f'0 0 {source.get("{"+ANDROID+"}viewportWidth")} {source.get("{"+ANDROID+"}viewportHeight")}'})
    def copy(node, dest):
        for child in node:
            if child.tag == 'group':
                attrs = {k.split('}')[-1]: v for k,v in child.attrib.items()}
                g = ET.SubElement(dest, f'{{{SVG}}}g', {'transform': f'translate({attrs.get("translateX",0)},{attrs.get("translateY",0)}) scale({attrs.get("scaleX",1)},{attrs.get("scaleY",1)})'})
                copy(child, g)
            elif child.tag == 'path':
                attrs = {k.split('}')[-1]: v for k,v in child.attrib.items()}
                fill = attrs.get('fillColor', 'none')
                opacity = '1'
                if len(fill) == 9 and fill.startswith('#'):
                    opacity = str(int(fill[1:3], 16) / 255)
                    fill = '#' + fill[3:]
                p = ET.SubElement(dest, f'{{{SVG}}}path', {'d': attrs['pathData'], 'fill': fill, 'fill-opacity': opacity})
                for key, value in [('strokeColor', 'stroke'), ('strokeWidth', 'stroke-width')]:
                    if key in attrs: p.set(value, attrs[key])
                for attr in child:
                    g = attr.find('gradient')
                    if g is None: continue
                    name = f'g{len(list(root.iter()))}'
                    defs = ET.SubElement(root, f'{{{SVG}}}defs')
                    colors = {k.split('}')[-1]: v for k,v in g.attrib.items()}
                    grad = ET.SubElement(defs, f'{{{SVG}}}linearGradient', {'id':name, 'gradientUnits':'userSpaceOnUse',
                        'x1':colors['startX'],'y1':colors['startY'],'x2':colors['endX'],'y2':colors['endY']})
                    for stop in g:
                        ET.SubElement(grad, f'{{{SVG}}}stop', {'offset':stop.get(f'{{{ANDROID}}}offset'), 'stop-color':stop.get(f'{{{ANDROID}}}color')})
                    p.set('fill', f'url(#{name})')
    copy(source, root)
    return ET.tostring(root)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--verify', action='store_true', help='Confere os arquivos sem escrever')
    args = parser.parse_args()
    outputs = {}
    preview = []
    mono = (REPO / 'docs/marca/android/ic_launcher_monochrome.xml').read_bytes()
    notification = (REPO / 'docs/marca/android/ic_stat_heisuca.xml').read_bytes()
    outputs['drawable/ic_launcher_monochrome.xml'] = mono
    outputs['drawable/ic_stat_heisuca.xml'] = notification
    for theme in THEMES:
        art = artwork(theme)
        suffix = '' if theme == 'shikkoku' else '_'+theme
        foreground, background = resources(art)
        fg, bg = xml(foreground), xml(background)
        outputs[f'drawable/ic_launcher_foreground{suffix}.xml'] = fg
        outputs[f'drawable/ic_launcher_background{suffix}.xml'] = bg
        outputs[f'mipmap-anydpi-v26/ic_launcher{suffix}.xml'] = xml(ET.fromstring(
            f'<adaptive-icon xmlns:android="{ANDROID}"><background android:drawable="@drawable/ic_launcher_background{suffix}"/>'
            f'<foreground android:drawable="@drawable/ic_launcher_foreground{suffix}"/>'
            '<monochrome android:drawable="@drawable/ic_launcher_monochrome"/></adaptive-icon>'))
        for density, (launcher_size, notification_size) in DENSITIES.items():
            png = cairosvg.svg2png(bytestring=ET.tostring(art), output_width=launcher_size, output_height=launcher_size)
            for ending in ['', '_round']:
                outputs[f'mipmap-{density}/ic_launcher{suffix}{ending}.png'] = png
            # A notificação mede 24 dp em todas as densidades: sempre a geometria gótica pequena.
            small = cairosvg.svg2png(bytestring=vector_svg(notification), output_width=notification_size, output_height=notification_size)
            outputs[f'drawable-{density}/ic_stat_heisuca.png'] = small
            outputs[f'drawable-{density}/ic_stat_notification.png'] = small
            size = launcher_size * 108 // 48
            outputs[f'mipmap-{density}/ic_launcher_monochrome.png'] = cairosvg.svg2png(bytestring=vector_svg(mono), output_width=size, output_height=size)
        preview.append((theme, art, fg, bg))
    # Heitor é o nome técnico antigo do alias Hisui: mantém a compatibilidade.
    for name, data in list(outputs.items()):
        if '_hisui' in name: outputs[name.replace('_hisui','_heitor')] = data
    for name, data in outputs.items():
        target = RES / name
        if args.verify:
            assert target.read_bytes() == data, f'Recurso desatualizado: {name}'
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    if not args.verify:
        sheet = ET.Element(f'{{{SVG}}}svg', {'width':'640','height':'360','viewBox':'0 0 640 360'})
        ET.SubElement(sheet, f'{{{SVG}}}rect', {'width':'640','height':'360','fill':'#25212D'})
        for col, label in enumerate(['SVG 48 px', 'Android 48 px', 'Mono 48 px', 'Aviso 24 px']):
            ET.SubElement(sheet, f'{{{SVG}}}text', {'x':str(120+col*110),'y':'14','fill':'white','font-size':'11'}).text=label
        for index, (theme, art, fg, bg) in enumerate(preview):
            y = 28 + index * 64
            ET.SubElement(sheet, f'{{{SVG}}}text', {'x':'12','y':str(y+30),'fill':'white','font-size':'14'}).text=theme
            combined = ET.Element(f'{{{SVG}}}svg', {'viewBox':'18 18 72 72'})
            clip = ET.SubElement(ET.SubElement(combined, f'{{{SVG}}}defs'), f'{{{SVG}}}clipPath', {'id':'android-mask'})
            ET.SubElement(clip, f'{{{SVG}}}circle', {'cx':'54','cy':'54','r':'36'})
            group = ET.SubElement(combined, f'{{{SVG}}}g', {'clip-path':'url(#android-mask)'})
            for layer in [vector_svg(bg), vector_svg(fg)]:
                for child in ET.fromstring(layer): group.append(child)
            for col, data in enumerate([ET.tostring(art), ET.tostring(combined), vector_svg(mono), vector_svg(notification)]):
                root = ET.fromstring(data)
                if col in [1, 2]:
                    root.set('viewBox','0 0 72 72')
                    crop = ET.Element(f'{{{SVG}}}g', {'transform':'translate(-18,-18)'})
                    for child in list(root):
                        root.remove(child)
                        crop.append(child)
                    root.append(crop)
                size = '24' if col == 3 else '48'
                root.set('width', size)
                root.set('height', size)
                encoded = base64.b64encode(ET.tostring(root)).decode()
                ET.SubElement(sheet, f'{{{SVG}}}image', {'x':str(120+col*110),'y':str(y+(12 if col == 3 else 0)),
                    'width':size,'height':size,'href':'data:image/svg+xml;base64,'+encoded})
        out = REPO / 'docs/evidencias/j_icones_48px.png'
        out.with_suffix('.svg').write_bytes(ET.tostring(sheet))
        cairosvg.svg2png(bytestring=ET.tostring(sheet), write_to=str(out))
    print(f'{len(outputs)} recursos Heisuca {"conferidos" if args.verify else "gerados"}; selo oficial preservado.')


if __name__ == '__main__': main()
