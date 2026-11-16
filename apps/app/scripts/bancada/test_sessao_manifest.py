"""A sessão do APK deve ser única e mediada pela Media3."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from heisuca_sessao_manifest import validar_sessao_manifest

class SessaoManifestTest(unittest.TestCase):
    def manifesto(self, nome='app.heisuca.sessao.HeisucaSessaoService', exportado='0xffffffff', tipo='0x2'):
        return f'''E: manifest
  E: uses-permission
    A: android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"
  E: application
    E: service
      A: android:name="{nome}"
      A: android:exported=(type 0x12){exportado}
      A: android:foregroundServiceType=(type 0x11){tipo}
      E: intent-filter
        E: action
          A: android:name="androidx.media3.session.MediaSessionService"
'''
    def test_aceita_uma_sessao_media3(self):
        validar_sessao_manifest(self.manifesto())
    def test_rejeita_servico_legado_ainda_mesclado(self):
        with self.assertRaises(AssertionError):
            validar_sessao_manifest(self.manifesto() + self.manifesto(nome='com.edde746.os_media_controls.MediaPlaybackService'))
    def test_rejeita_duas_instancias_de_servico(self):
        with self.assertRaises(AssertionError):
            validar_sessao_manifest(self.manifesto() + self.manifesto())
    def test_exige_tipo_foreground_e_endpoint_media3(self):
        for s in [self.manifesto(tipo='0x1'), self.manifesto(exportado='0x0'), self.manifesto().replace('androidx.media3.session.MediaSessionService','outra.acao')]:
            with self.subTest(manifesto=s), self.assertRaises(AssertionError):
                validar_sessao_manifest(s)
if __name__ == '__main__':
    unittest.main()
