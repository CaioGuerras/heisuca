import json
import os
import subprocess
import sys
import tempfile
import unittest

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import osv_gate  # noqa: E402

LOCK = """# This is a Gradle generated file for dependency locking.
# Manual edits can break the build and are not advised.
# This file is expected to be part of source control.
com.a:runtime:1.0=compileClasspath,releaseRuntimeClasspath,debugRuntimeClasspath
org.bouncycastle:bcprov:1.0=lintClassPath
io.netty:netty:4.0=kotlinCompilerClasspath,releaseRuntimeClasspathCopy
com.b:solo:2.0=releaseRuntimeClasspath
empty=annotationProcessor
"""


def relatorio(pacote, vid, nota):
    return {"results": [{"source": {"path": "x"}, "packages": [
        {"package": {"name": pacote, "version": "1", "ecosystem": "Maven"},
         "vulnerabilities": [{"id": vid}], "groups": [{"ids": [vid], "max_severity": str(nota)}]}]}]}


class TesteOsv(unittest.TestCase):
    def test_filtro_runtime(self):
        out = osv_gate.filtrar_runtime(LOCK)
        linhas = out.splitlines()
        self.assertEqual(linhas[:3], LOCK.splitlines()[:3])  # cabeçalho preservado
        self.assertIn("com.a:runtime:1.0=compileClasspath,releaseRuntimeClasspath,debugRuntimeClasspath", linhas)
        self.assertIn("com.b:solo:2.0=releaseRuntimeClasspath", linhas)
        self.assertNotIn("bcprov", out)
        self.assertNotIn("netty", out)  # releaseRuntimeClasspathCopy não é a config exata
        self.assertNotIn("empty=", out)

    def rodar(self, runtime, ferramentas):
        with tempfile.TemporaryDirectory() as d:
            r, f, s = (os.path.join(d, n) for n in ("r.json", "f.json", "s.md"))
            json.dump(runtime, open(r, "w"))
            json.dump(ferramentas, open(f, "w"))
            env = dict(os.environ, SEGURANCA_MODO="bloquear", GITHUB_STEP_SUMMARY=s)
            p = subprocess.run([sys.executable, os.path.join(AQUI, "osv_gate.py"), r, "/inexistente", f],
                               env=env, capture_output=True, text=True)
            return p.returncode, open(s).read()

    def test_ferramentas_so_informativo(self):
        rc, resumo = self.rodar(relatorio("lib", "A-1", 3.0), relatorio("bcprov", "B-1", 9.8))
        self.assertEqual(rc, 0)
        self.assertIn("OSV: ATENÇÃO", resumo)
        self.assertIn("não vão no APK", resumo)
        self.assertIn("B-1", resumo)

    def test_runtime_alto_bloqueia(self):
        rc, _ = self.rodar(relatorio("lib", "A-1", 9.0), relatorio("lib", "A-1", 9.0))
        self.assertEqual(rc, 1)

    def test_ferramenta_repetida_do_runtime_nao_duplica(self):
        _, resumo = self.rodar(relatorio("lib", "A-1", 3.0), relatorio("lib", "A-1", 3.0))
        self.assertNotIn("não vão no APK", resumo)


if __name__ == "__main__":
    unittest.main()
