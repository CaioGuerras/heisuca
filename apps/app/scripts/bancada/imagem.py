"""Mede o PNG nativo, sem depender da flag de primeiro quadro do player."""
import subprocess


def analisar(png):
    result = subprocess.run(['ffmpeg', '-v', 'error', '-threads', '1', '-i', 'pipe:0',
                             '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'],
                            input=png, capture_output=True, timeout=30)
    if result.returncode or not result.stdout:
        raise RuntimeError('Não foi possível ler os pixels da captura nativa.')
    maximum = max(result.stdout)
    return {'imagem': 'não' if maximum == 0 else 'sim',
            'metodo': 'adb exec-out screencap -p; PNG original decodificado por ffmpeg em RGB24',
            'maiorCanalRGB': maximum,
            'criterio': 'ausência total de pixels não pretos; pixels de interface não comprovam conteúdo de vídeo'}
