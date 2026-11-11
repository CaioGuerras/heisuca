"""A ferramenta precisa embarcar também as classes auxiliares geradas pelo javac."""
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import compilar_ui


class CompilacaoUi(unittest.TestCase):
    def test_dex_inclui_classe_principal_e_auxiliares(self):
        with tempfile.TemporaryDirectory() as pasta:
            raiz = Path(pasta)
            android = raiz / 'sdk/platforms/android-35/android.jar'
            android.parent.mkdir(parents=True)
            android.touch()
            d8 = raiz / 'sdk/build-tools/35.0.0/d8'
            d8.parent.mkdir(parents=True)
            d8.touch()
            nomes = ['HeisucaPipClose.class', 'HeisucaPipClose$Leitura.class', 'HeisucaPipClose$Tempos.class']
            def compilar(argumentos, **opcoes):
                if argumentos[0] == 'javac':
                    for nome in nomes:
                        Path('.bancada/ui', nome).touch()
            anterior = Path.cwd()
            try:
                os.chdir(raiz)
                with patch.dict(os.environ, ANDROID_HOME=str(raiz / 'sdk')), patch('compilar_ui.subprocess.run', side_effect=compilar) as executar:
                    compilar_ui.main()
                comando = next(c.args[0] for c in executar.call_args_list if c.args[0][0] == str(d8))
                self.assertEqual({Path(a).name for a in comando if a.endswith('.class')}, set(nomes))
            finally:
                os.chdir(anterior)
