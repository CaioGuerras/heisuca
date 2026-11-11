"""Executa a instalação do workflow com comandos falsos; nunca usa rede ou apt real."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest


WORKFLOW = Path(__file__).resolve().parents[4] / '.github/workflows/heisuca-bancada-android.yml'


class EspelhosFfmpeg(unittest.TestCase):
    def executar(self, falha_update='', falha_install='', ffprobe=False):
        texto = WORKFLOW.read_text()
        bloco = texto[texto.index('          if ! command -v ffprobe'):texto.index('          mkdir -p .bancada/evidencias')]
        with tempfile.TemporaryDirectory() as pasta:
            raiz = Path(pasta)
            comandos = raiz / 'bin'
            comandos.mkdir()
            espelhos = raiz / 'apt-mirrors.txt'
            original = 'http://azure.archive.ubuntu.com/ubuntu\nhttp://security.ubuntu.com/ubuntu\n'
            espelhos.write_text(original)
            log = raiz / 'apt.log'
            limites = raiz / 'limites.log'
            for nome in ['cp', 'sed', 'tee', 'mktemp', 'cat']:
                (comandos / nome).symlink_to(shutil.which(nome))
            scripts = {
                'sudo': '#!/bin/bash\nexec "$@"\n',
                'timeout': '#!/bin/bash\nif [[ "$1" == --kill-after=5s ]]; then shift; fi\nprintf "%s\\n" "$1" >> "$APT_TEST_LIMITES"\nshift\nexec "$@"\n',
                'apt-get': '''#!/bin/bash
espelho=$(cat "$APT_TEST_ESPELHOS")
printf '%s|%s\\n' "$espelho" "$*" >> "$APT_TEST_LOG"
if [[ "$*" == *' update' ]]; then falhas=$APT_TEST_FALHA_UPDATE; else falhas=$APT_TEST_FALHA_INSTALL; fi
if [[ "$falhas" == ambos ]] || [[ "$falhas" == arquivo && "$espelho" == *'https://archive.ubuntu.com/'* ]]; then exit 1; fi
''',
            }
            if ffprobe:
                scripts['ffprobe'] = '#!/bin/bash\nexit 0\n'
            for nome, conteudo in scripts.items():
                arquivo = comandos / nome
                arquivo.write_text(conteudo)
                arquivo.chmod(0o755)
            ambiente = dict(os.environ, PATH=str(comandos), TMPDIR=str(raiz),
                            APT_TEST_ESPELHOS=str(espelhos), APT_TEST_LOG=str(log),
                            APT_TEST_LIMITES=str(limites), APT_TEST_FALHA_UPDATE=falha_update,
                            APT_TEST_FALHA_INSTALL=falha_install)
            script = textwrap.dedent(bloco).replace('/etc/apt/apt-mirrors.txt', str(espelhos))
            resultado = subprocess.run(['/bin/bash', '-euo', 'pipefail', '-c', script],
                                       env=ambiente, text=True, capture_output=True, timeout=5)
            return resultado, log.read_text() if log.exists() else '', espelhos.read_text(), original, (
                limites.read_text().splitlines() if limites.exists() else [])

    def test_primeiro_espelho_funciona_sem_consultar_reserva(self):
        resultado, log, atual, original, limites = self.executar()
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertEqual(log.count('|'), 2)
        self.assertNotIn('azure.archive', log)
        self.assertEqual(atual, original)
        self.assertEqual(limites, ['45s', '120s'])
        self.assertIn('APT::Update::Error-Mode=any', log)

    def test_falha_no_update_tenta_reserva_com_lista_recriada(self):
        resultado, log, atual, original, limites = self.executar(falha_update='arquivo')
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertEqual(log.count('|'), 3)
        self.assertIn('https://mirrors.kernel.org/ubuntu', log)
        self.assertEqual(atual, original)
        self.assertEqual(limites, ['45s', '45s', '120s'])

    def test_reserva_independente_usa_espelho_listado_pelo_ubuntu(self):
        resultado, log, atual, original, limites = self.executar(falha_update='arquivo')
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertIn('https://mirrors.kernel.org/ubuntu', log)
        self.assertEqual(atual, original)

    def test_falha_na_instalacao_tenta_reserva(self):
        resultado, log, atual, original, limites = self.executar(falha_install='arquivo')
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertEqual(log.count('|'), 4)
        self.assertEqual(atual, original)
        self.assertEqual(limites, ['45s', '120s', '45s', '120s'])

    def test_dois_updates_falham_e_nao_aprovam_instalacao(self):
        resultado, log, atual, original, limites = self.executar(falha_update='ambos')
        self.assertNotEqual(resultado.returncode, 0)
        self.assertEqual(log.count('|'), 2)
        self.assertNotIn(' install ', log)
        self.assertEqual(atual, original)
        self.assertEqual(limites, ['45s', '45s'])

    def test_duas_instalacoes_falham_e_o_passo_falha(self):
        resultado, log, atual, original, limites = self.executar(falha_install='ambos')
        self.assertNotEqual(resultado.returncode, 0)
        self.assertEqual(log.count('|'), 4)
        self.assertEqual(atual, original)
        self.assertEqual(limites, ['45s', '120s', '45s', '120s'])

    def test_ffprobe_existente_nao_consulta_rede(self):
        resultado, log, atual, original, limites = self.executar(ffprobe=True)
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertEqual(log, '')
        self.assertEqual(atual, original)
        self.assertEqual(limites, [])


if __name__ == '__main__':
    unittest.main()
