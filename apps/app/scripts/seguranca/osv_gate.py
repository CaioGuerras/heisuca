#!/usr/bin/env python3
"""Portão do osv-scanner.

Uso: osv_gate.py RELATORIO.json [aceitos.json [FERRAMENTAS.json]]
     osv_gate.py --filtrar-runtime gradle.lockfile SAIDA   (só o que entra no APK)

RELATORIO = pubspec.lock + gradle.lockfile filtrado para releaseRuntimeClasspath (decide o portão).
FERRAMENTAS = varredura do gradle.lockfile completo; o que não está no RELATORIO é só informativo
("ferramentas de build, não vão no APK") e nunca muda o estado.

CVSS >= 7 = vermelho, salvo {"id","pacote","motivo"} em security/osv_aceitos.json = ATENÇÃO.
Demais (e gravidade desconhecida) = ATENÇÃO, só listada. Bloqueia só com SEGURANCA_MODO=bloquear.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from comum import escrever_resumo, estado_final, sair  # noqa: E402


def aceitos_osv(caminho):
    try:
        dados = json.load(open(caminho, encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return {(i["id"], i["pacote"]): i["motivo"] for i in dados
            if isinstance(i, dict) and i.get("id") and i.get("pacote") and str(i.get("motivo", "")).strip()}


def filtrar_runtime(texto, config="releaseRuntimeClasspath"):
    """Mantém cabeçalho/comentários e só as linhas grupo:artefato:versão=cfg1,cfg2 cuja
    lista de configurações contém `config`. A linha `empty=` (sem pacote) é descartada."""
    saida = []
    for linha in texto.splitlines():
        if linha.startswith("#") or not linha.strip():
            saida.append(linha)
            continue
        coord, _, cfgs = linha.partition("=")
        if coord.strip() == "empty":
            continue
        if config in [c.strip() for c in cfgs.split(",")]:
            saida.append(linha)
    return "\n".join(saida) + "\n"


def nota(grupo_scores):
    notas = []
    for s in grupo_scores:
        try:
            notas.append(float(s))
        except (TypeError, ValueError):
            pass
    return max(notas) if notas else None


def coletar(rel):
    """Lista de dicts {id, pacote, versao, ecossistema, nota, arquivo}."""
    achados = []
    for res in (rel.get("results") or []) if isinstance(rel, dict) else []:
        arquivo = (res.get("source") or {}).get("path", "?")
        for pkg in res.get("packages") or []:
            p = pkg.get("package") or {}
            # Nota por grupo (max_severity já vem calculada pelo osv-scanner); id -> nota.
            por_id = {}
            for g in pkg.get("groups") or []:
                n = nota([g.get("max_severity")])
                for i in g.get("ids") or []:
                    por_id[i] = n
            for v in pkg.get("vulnerabilities") or []:
                vid = v.get("id")
                achados.append({"id": vid, "pacote": p.get("name"), "versao": p.get("version"),
                                "ecossistema": p.get("ecosystem"), "nota": por_id.get(vid), "arquivo": arquivo})
    return achados


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    if argv[1] == "--filtrar-runtime":
        with open(argv[2], encoding="utf-8") as f:
            texto = filtrar_runtime(f.read())
        with open(argv[3], "w", encoding="utf-8") as f:
            f.write(texto)
        print(f"{argv[3]}: {sum(1 for l in texto.splitlines() if l and not l.startswith('#'))} dependências de runtime")
        return 0
    modo = os.environ.get("SEGURANCA_MODO", "relatorio").strip().lower()
    aceitos = aceitos_osv(argv[2] if len(argv) > 2 else "security/osv_aceitos.json")
    try:
        rel = json.load(open(argv[1], encoding="utf-8"))
    except (OSError, ValueError):
        escrever_resumo("### OSV: vermelho\n\nRelatório ausente ou ilegível; a varredura não terminou.\n")
        sair("vermelho", modo == "bloquear")
        return 0
    achados = coletar(rel)
    ver, ate = [], []
    for a in achados:
        if (a["id"], a["pacote"]) in aceitos or a["nota"] is None or a["nota"] < 7:
            ate.append(a)
        else:
            ver.append(a)
    estado = estado_final(ver, ate)
    # Ferramentas de build: tudo do lockfile completo que não está no de runtime. Informativo.
    ferramentas = []
    if len(argv) > 3:
        try:
            ja = {(a["id"], a["pacote"]) for a in achados}
            ferramentas = [a for a in coletar(json.load(open(argv[3], encoding="utf-8")))
                           if (a["id"], a["pacote"]) not in ja]
        except (OSError, ValueError):
            print("::warning::Relatório das ferramentas de build ausente; seção omitida.")
    # Aceito com nota alta é ATENÇÃO; baixo/desconhecido também. Só vermelho bloqueia.
    out = [f"### OSV: {estado} (modo {modo})", "",
           f"Avisos: {len(achados)}; CVSS >= 7 fora da lista de aceitos: {len(ver)}; demais: {len(ate)}.", ""]
    for titulo, lista in (("Vermelho (CVSS >= 7)", ver), ("ATENÇÃO", ate)):
        if lista:
            out += [f"**{titulo}**", "", "| Aviso | Pacote | Versão | CVSS | Arquivo |", "|---|---|---|---|---|"]
            for a in sorted(lista, key=lambda x: -(x["nota"] or 0))[:80]:
                nt = "?" if a["nota"] is None else a["nota"]
                acc = " (aceito)" if (a["id"], a["pacote"]) in aceitos else ""
                out.append(f"| `{a['id']}`{acc} | `{a['pacote']}` | `{a['versao']}` | {nt} | `{a['arquivo']}` |")
            out.append("")
    if ferramentas:
        out += [f"**Ferramentas de build (não vão no APK), informativo: {len(ferramentas)} aviso(s)**", "",
                "| Aviso | Pacote | Versão | CVSS |", "|---|---|---|---|"]
        for a in sorted(ferramentas, key=lambda x: -(x["nota"] or 0))[:40]:
            nt = "?" if a["nota"] is None else a["nota"]
            out.append(f"| `{a['id']}` | `{a['pacote']}` | `{a['versao']}` | {nt} |")
        out.append("")
    escrever_resumo("\n".join(out))
    sair(estado, modo == "bloquear")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
