"""Valida a porta única de mídia no manifesto efetivamente empacotado."""
import re


def validar_sessao_manifest(manifest):
    assert 'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK' in manifest, 'permissão mediaPlayback ausente'
    assert 'android.permission.POST_PROMOTED_NOTIFICATIONS' not in manifest, 'Live Updates não se aplicam à mídia'
    assert 'com.edde746.os_media_controls' not in manifest, 'sessão legada ainda empacotada'
    lines = manifest.splitlines()
    blocks = []
    for index, line in enumerate(lines):
        match = re.match(r'(\s*)E: service(?:\s|$)', line)
        if match:
            indent = len(match[1])
            end = index + 1
            while end < len(lines):
                following = re.match(r'(\s*)E:', lines[end])
                if following and len(following[1]) <= indent:
                    break
                end += 1
            blocks.append('\n'.join(lines[index:end]))
    sessions = [b for b in blocks if 'app.heisuca.sessao.HeisucaSessaoService' in b]
    assert len(sessions) == 1, 'deve haver exatamente um serviço de sessão'
    service = sessions[0]
    assert re.search(r'android:foregroundServiceType.*0x2\b', service), 'sessão sem tipo mediaPlayback'
    # O endpoint Media3 recebe controllers do Android; a autorização acontece em onConnect.
    assert re.search(r'android:exported.*(?:0xffffffff\b|"true")', service), 'endpoint Media3 inacessível ao sistema'
    assert 'androidx.media3.session.MediaSessionService' in service, 'falta endpoint Media3'
