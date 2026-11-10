"""O CI deve recusar a permissão de instalar na Play e exigi-la na direta."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from heisuca_update_policy import validar_permissao, validar_build


class VariantesAtualizadorTest(unittest.TestCase):
    permissao = "uses-permission: name='android.permission.REQUEST_INSTALL_PACKAGES'\n"

    def test_direta_exige_permissao(self):
        validar_permissao(self.permissao, "direct")
        with self.assertRaises(AssertionError):
            validar_permissao("uses-permission: name='android.permission.INTERNET'", "direct")

    def test_play_recusa_permissao(self):
        validar_permissao("", "play")
        with self.assertRaises(AssertionError):
            validar_permissao(self.permissao, "play")

    def test_variante_desconhecida_falha_fechada(self):
        with self.assertRaises(AssertionError):
            validar_permissao(self.permissao, "outra")

    def test_build_do_feed_precisa_ser_igual_ao_version_code(self):
        validar_build("package: name='app.heisuca.player.teste.home' versionCode='2042'", 2042)
        with self.assertRaises(AssertionError):
            validar_build("package: name='app.heisuca.player.teste.home' versionCode='4042'", 2042)


if __name__ == "__main__":
    unittest.main()
