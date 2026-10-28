import json
import os
import subprocess
import sys
import tempfile
import unittest

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import mobsf_gate  # noqa: E402

RELATORIO = {
    "manifest_analysis": {"manifest_findings": [
        {"rule": "android_allow_backup", "title": "Backup ligado", "severity": "high"},
        {"rule": "x_info", "title": "info", "severity": "info"}]},
    "network_security": {"network_findings": [{"severity": "high", "scope": ["*"], "description": "cleartext"}]},
    "code_analysis": {"findings": {
        "android_logging": {"metadata": {"severity": "high", "description": "log"}},
        "android_ok": {"metadata": {"severity": "secure"}}}},
    "binary_analysis": [{"name": "lib/a.so", "nx": {"severity": "high", "description": "sem NX"},
                         "pie": {"severity": "info"}}],
    "secrets": ["chave=SEGREDO_NUNCA_NO_RESUMO"],
}


class TesteGate(unittest.TestCase):
    def test_coleta_so_high(self):
        chaves = {c for c, _ in mobsf_gate.coletar(RELATORIO)}
        self.assertIn("manifest_analysis:android_allow_backup", chaves)
        self.assertIn("code_analysis:android_logging", chaves)
        self.assertIn("binary_analysis:lib/a.so:nx", chaves)
        self.assertNotIn("code_analysis:android_ok", chaves)
        self.assertNotIn("manifest_analysis:x_info", chaves)
        self.assertEqual(sum(c.startswith("secrets:") for c in chaves), 1)

    def test_chaves_ausentes_nao_quebram(self):
        self.assertEqual(mobsf_gate.coletar({}), [])
        self.assertEqual(mobsf_gate.coletar({"manifest_analysis": None, "binary_analysis": "x", "secrets": None}), [])
        self.assertEqual(mobsf_gate.coletar([]), [])

    def rodar(self, modo, aceitos):
        with tempfile.TemporaryDirectory() as d:
            rel, ac, resumo = (os.path.join(d, n) for n in ("r.json", "a.json", "s.md"))
            json.dump(RELATORIO, open(rel, "w"))
            json.dump(aceitos, open(ac, "w"))
            env = dict(os.environ, MOBSF_MODO=modo, GITHUB_STEP_SUMMARY=resumo)
            p = subprocess.run([sys.executable, "-I", os.path.join(AQUI, "mobsf_gate.py"), rel, ac],
                               env=env, capture_output=True, text=True)
            return p.returncode, open(resumo).read()

    def test_modos(self):
        rc, resumo = self.rodar("relatorio", [])
        self.assertEqual(rc, 0)
        self.assertIn("vermelho", resumo)
        self.assertNotIn("SEGREDO_NUNCA_NO_RESUMO", resumo)
        self.assertEqual(self.rodar("bloquear", [])[0], 1)

    def test_aceitos_viram_atencao(self):
        _, resumo = self.rodar("bloquear", [])
        chaves = [l.split("`")[1] for l in resumo.splitlines() if l.startswith("| vermelho")]
        rc, resumo = self.rodar("bloquear", [{"chave": c, "motivo": "teste"} for c in chaves])
        self.assertEqual(rc, 0)
        self.assertIn("MobSF: ATENÇÃO", resumo)

    def test_aceito_sem_motivo_e_ignorado(self):
        rc, _ = self.rodar("bloquear", [{"chave": "manifest_analysis:android_allow_backup"}])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
