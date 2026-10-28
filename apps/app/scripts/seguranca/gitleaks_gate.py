#!/usr/bin/env python3
"""Portão do gitleaks. Uso: gitleaks_gate.py HISTORICO.json ARVORE.json [aceitos.json]

Árvore atual com achado = vermelho (sempre bloqueia). Histórico: vermelho, salvo
fingerprint listada em security/gitleaks_aceitos.json = ATENÇÃO (bloqueia só com
SEGURANCA_MODO=bloquear). Relatórios já vêm redigidos (--redact); nada secreto é impresso.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from comum import ler_aceitos, escrever_resumo, sair  # noqa: E402


def carregar(caminho):
    try:
        with open(caminho, encoding="utf-8") as f:
            dados = json.load(f)
        return dados if isinstance(dados, list) else []
    except (OSError, ValueError):
        return None


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    modo = os.environ.get("SEGURANCA_MODO", "relatorio").strip().lower()
    aceitos = ler_aceitos(argv[3] if len(argv) > 3 else "security/gitleaks_aceitos.json", "fingerprint")
    hist, arvore = carregar(argv[1]), carregar(argv[2])
    if hist is None or arvore is None:
        escrever_resumo("### Gitleaks: vermelho\n\nRelatório ausente ou ilegível; a varredura não terminou.\n")
        sair("vermelho", True)
        return 0

    def linha(a):
        return f"| `{a.get('RuleID')}` | `{a.get('File')}:{a.get('StartLine')}` | `{str(a.get('Commit', ''))[:8]}` | `{a.get('Fingerprint')}` |"

    hist_ver = [a for a in hist if a.get("Fingerprint") not in aceitos]
    hist_ace = [a for a in hist if a.get("Fingerprint") in aceitos]
    # Achado na árvore atual também aparece no histórico: só a árvore decide o bloqueio duro.
    if arvore:
        estado = "vermelho"
    elif hist_ver:
        estado = "vermelho"
    elif hist_ace:
        estado = "ATENÇÃO"
    else:
        estado = "verde"
    out = [f"### Gitleaks: {estado}", "",
           f"Árvore atual: {len(arvore)} achado(s). Histórico: {len(hist_ver)} fora da lista de aceitos, {len(hist_ace)} aceito(s).", ""]
    for titulo, lista in (("Árvore atual (vermelho)", arvore), ("Histórico (vermelho)", hist_ver), ("Histórico aceito (ATENÇÃO)", hist_ace)):
        if lista:
            out += [f"**{titulo}**", "", "| Regra | Local | Commit | Fingerprint |", "|---|---|---|---|"]
            out += [linha(a) for a in lista[:50]] + [""]
    escrever_resumo("\n".join(out))
    if arvore:
        sair("vermelho", True)
    else:
        sair(estado, modo == "bloquear")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
