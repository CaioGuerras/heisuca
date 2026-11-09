"""O roteiro só aprova atualização confirmada no Android, nunca só por texto da tela."""
import hashlib
import tempfile
from pathlib import Path
import unittest
from atualizador import montar_feed, confirmar_build, achar_rotulo, configuracoes_abertas, instalador_aberto


class AtualizadorBancadaTest(unittest.TestCase):
    def test_feed_calcula_tamanho_e_hash_do_arquivo_real(self):
        pasta = Path(tempfile.mkdtemp(prefix="heisuca-feed-sintetico-"))
        apk = pasta / "app.apk"
        apk.write_bytes(b"APK sintetico, sem dados de usuario")
        feed = montar_feed(apk, 2043, "a" * 64, "https://10.0.2.2:8443")
        self.assertEqual(feed["build"], 2043)
        self.assertEqual(feed["apks"][0]["bytes"], apk.stat().st_size)
        self.assertEqual(feed["apks"][0]["sha256"], hashlib.sha256(apk.read_bytes()).hexdigest())
        self.assertEqual(feed["apks"][0]["url"], "https://10.0.2.2:8443/upgrade.apk")

    def test_fixture_nao_cria_feed_http_nem_de_producao(self):
        for origem in ["http://10.0.2.2:8443", "https://producao.example", "https://senha@localhost"]:
            with self.assertRaises(ValueError):
                montar_feed(Path("ausente.apk"), 2043, "a" * 64, origem)

    def test_so_aprova_version_code_novo_confirmado_pelo_android(self):
        confirmar_build("versionCode=2043 minSdk=25 targetSdk=36", 2043)
        for dump in ["versionCode=2042 minSdk=25", "Instalação concluída", "versionCode=4043"]:
            with self.assertRaises(AssertionError):
                confirmar_build(dump, 2043)

    def test_rotulo_considera_semantica_e_texto_sem_acionar_outro_botao(self):
        xml = '<hierarchy><node text="Cancelar"/><node content-desc="Instalar" focused="true" bounds="[1,2][30,40]"/></hierarchy>'
        self.assertEqual(achar_rotulo(xml, "Instalar")["bounds"], "[1,2][30,40]")
        self.assertIsNone(achar_rotulo(xml, "Baixar"))

    def test_janela_em_segundo_plano_nao_aprova_permissao_nem_confirmacao(self):
        fundo = 'Window com.android.tv.settings\nWindow com.google.android.packageinstaller\nmCurrentFocus=Window{123 app.heisuca.player.teste.home/app.heisuca.MainActivity}'
        self.assertFalse(configuracoes_abertas(fundo))
        self.assertFalse(instalador_aberto(fundo))
        self.assertTrue(configuracoes_abertas('mCurrentFocus=Window{123 com.android.tv.settings/.MainSettings}'))
        self.assertTrue(instalador_aberto('mCurrentFocus=Window{123 com.google.android.packageinstaller/.InstallActivity}'))


if __name__ == "__main__":
    unittest.main()
