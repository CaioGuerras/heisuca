"""Mede apenas vídeo no PNG nativo; interface clara não comprova um quadro."""
import math
import struct
import subprocess


def _numero(value, *, positivo=False):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise RuntimeError('Geometria do vídeo ausente ou inválida.')
    if (positivo and value <= 0) or (not positivo and value < 0):
        raise RuntimeError('Geometria do vídeo ausente ou inválida.')
    return value


def _retangulo(data):
    x, y = _numero(data['x']), _numero(data['y'])
    return (x, y, x + _numero(data['largura'], positivo=True),
            y + _numero(data['altura'], positivo=True))


def _intersecao(a, b):
    x, y, right, bottom = max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3])
    return (x, y, right, bottom) if right > x and bottom > y else None


def _subtrair(area, exclusion):
    overlap = _intersecao(area, exclusion)
    if overlap is None:
        return [area]
    x, y, right, bottom = area
    left, top, end, base = overlap
    return [rect for rect in [(x, y, right, top), (x, base, right, bottom),
                              (x, top, left, base), (end, top, right, base)]
            if rect[2] > rect[0] and rect[3] > rect[1]]


def _area(geometry, width, height):
    try:
        window, source = geometry['janela'], geometry['video']
        if (_numero(window['largura'], positivo=True), _numero(window['altura'], positivo=True)) != (width, height):
            raise RuntimeError('Geometria do vídeo não corresponde à captura nativa.')
        surface = _retangulo(geometry['superficie'])
        sw, sh = surface[2] - surface[0], surface[3] - surface[1]
        vw, vh = _numero(source['largura'], positivo=True), _numero(source['altura'], positivo=True)
        mode, zoom = source['modo'], _numero(source['zoom'], positivo=True)
        if mode == 'esticar':
            rw, rh = sw * zoom, sh * zoom
        elif mode in ('conter', 'cobrir'):
            scale = (min if mode == 'conter' else max)(sw / vw, sh / vh) * zoom
            rw, rh = vw * scale, vh * scale
        else:
            raise RuntimeError('Modo de proporção do vídeo desconhecido.')
        left, top = surface[0] + (sw - rw) / 2, surface[1] + (sh - rh) / 2
        video = (left, top, left + rw, top + rh)
        if not all(math.isfinite(value) for value in video):
            raise RuntimeError('Geometria do vídeo ausente ou inválida.')
        bars = geometry['barrasSistema']
        safe = (_numero(bars['esquerda']), _numero(bars['topo']),
                width - _numero(bars['direita']), height - _numero(bars['base']))
        visible = _intersecao(surface, safe)
        visible = _intersecao(video, visible) if visible else None
        if visible is None:
            raise RuntimeError('Área do vídeo não pode ser medida.')
        # Arredonda para dentro: nenhuma borda do letterbox entra na amostra.
        area = (math.ceil(visible[0]), math.ceil(visible[1]), math.floor(visible[2]), math.floor(visible[3]))
        if area[2] <= area[0] or area[3] <= area[1]:
            raise RuntimeError('Área do vídeo não pode ser medida.')
        regions = [area]
        exclusions = geometry['exclusoesHud']
        if not isinstance(exclusions, list) or len(exclusions) > 64 or type(geometry['hudOculto']) is not bool:
            raise RuntimeError('Geometria do HUD ausente ou inválida.')
        if geometry['hudOculto'] is not True and not exclusions:
            raise RuntimeError('HUD visível sem área de exclusão conhecida.')
        for exclusion in exclusions:
            rect = _retangulo(exclusion)
            rect = (math.floor(rect[0]), math.floor(rect[1]), math.ceil(rect[2]), math.ceil(rect[3]))
            regions = [piece for region in regions for piece in _subtrair(region, rect)]
        if not regions:
            raise RuntimeError('Área do vídeo não pode ser medida sem o HUD.')
        return regions, video
    except (KeyError, TypeError, AttributeError) as error:
        raise RuntimeError('Geometria do vídeo ausente ou inválida.') from error


def analisar(png, geometria=None):
    if len(png) < 24 or not png.startswith(b'\x89PNG\r\n\x1a\n'):
        raise RuntimeError('Não foi possível ler os pixels da captura nativa.')
    width, height = struct.unpack('>II', png[16:24])
    if not (0 < width <= 8192 and 0 < height <= 8192):
        raise RuntimeError('Dimensões dos pixels da captura nativa inválidas.')
    regions, video = _area(geometria, width, height)
    result = subprocess.run(['ffmpeg', '-v', 'error', '-threads', '1', '-i', 'pipe:0',
                             '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'],
                            input=png, capture_output=True, timeout=30)
    if result.returncode or len(result.stdout) != width * height * 3:
        raise RuntimeError('Não foi possível ler os pixels da captura nativa.')
    pixels, light, maximum = 0, 0, 0
    rgb = result.stdout
    for left, top, right, bottom in regions:
        pixels += (right - left) * (bottom - top)
        for y in range(top, bottom):
            for offset in range((y * width + left) * 3, (y * width + right) * 3, 3):
                red, green, blue = rgb[offset:offset + 3]
                maximum = max(maximum, red, green, blue)
                # Luma Rec.709 em RGB de 8 bits; 16 não é contado como claro.
                light += 2126 * red + 7152 * green + 722 * blue > 16 * 10000
    return {'imagem': 'sim' if light * 100 >= pixels * 2 else 'não',
            'metodo': 'adb exec-out screencap -p; RGB24 por ffmpeg; vídeo pela geometria real, sem barras/HUD',
            'maiorCanalRGB': maximum,
            'areaMedida': {'pixels': pixels, 'retangulos': [
                {'x': x, 'y': y, 'largura': right - x, 'altura': bottom - y} for x, y, right, bottom in regions]},
            'retanguloVideo': {'x': video[0], 'y': video[1], 'largura': video[2] - video[0], 'altura': video[3] - video[1]},
            'geometriaVideo': geometria, 'pixelsNaoEscuros': light, 'fracaoNaoEscura': light / pixels,
            'lumaMinima': 16, 'fracaoMinima': 0.02,
            'criterio': 'luma > 16 em pelo menos 2% da área útil do vídeo, excluindo barras do sistema, HUD e letterbox'}
