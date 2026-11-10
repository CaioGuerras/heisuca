#!/usr/bin/env python3
"""Gera security/mobsf_aceitos.json a partir de um report_json do MobSF.

Uso: gerar_aceitos_mobsf.py REPORT.json [mapa.json [saida.json]]
O mapa (padrão: mobsf_motivos.json ao lado) é uma lista de {"casa": regex, "motivo": ...}
aplicada às chaves normalizadas do gate. Achado high sem regra casando NÃO é aceito
(é listado em stderr). Chaves de segredo são só hashes; nenhum valor é gravado.
"""
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import mobsf_gate  # noqa: E402


def gerar(relatorio, mapa):
    regras = [(re.compile(r["casa"]), r["motivo"]) for r in mapa]
    aceitos, sem_regra = [], []
    for chave, _ in sorted(mobsf_gate.coletar(relatorio)):
        for rx, motivo in regras:
            if rx.search(chave):
                aceitos.append({"chave": chave, "motivo": motivo})
                break
        else:
            sem_regra.append(chave)
    return aceitos, sem_regra


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    mapa_p = argv[2] if len(argv) > 2 else os.path.join(AQUI, "mobsf_motivos.json")
    saida = argv[3] if len(argv) > 3 else os.path.join(AQUI, "..", "..", "security", "mobsf_aceitos.json")
    aceitos, sem_regra = gerar(json.load(open(argv[1], encoding="utf-8")), json.load(open(mapa_p, encoding="utf-8")))
    with open(saida, "w", encoding="utf-8") as f:
        json.dump(aceitos, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"{len(aceitos)} aceitos gravados em {saida}; {len(sem_regra)} sem regra")
    for c in sem_regra:
        print("sem regra:", c, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
