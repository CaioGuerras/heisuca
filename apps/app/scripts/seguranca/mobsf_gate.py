#!/usr/bin/env python3
"""Portão do MobSF: classifica achados de severidade "high" do report_json.

Uso: mobsf_gate.py RELATORIO.json [aceitos.json]
Modo: MOBSF_MODO=relatorio (padrão; não falha) ou bloquear (falha se vermelho).
Chave do achado: "<secao>:<id>" (ver tabela do resumo). Aceito com motivo = ATENÇÃO.
"""
import hashlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from comum import ler_aceitos, escrever_resumo, estado_final, sair  # noqa: E402


def _alto(valor):
    return str(valor or "").strip().lower() == "high"


def _curto(texto, n=110):
    texto = " ".join(str(texto or "").split())
    return texto if len(texto) <= n else texto[: n - 1] + "…"


def _dicts(valor):
    if isinstance(valor, dict):
        return list(valor.items())
    return []


def _lista(valor):
    return valor if isinstance(valor, list) else []


def normalizar_chave(chave):
    """O MobSF repete os binários em apktool_out/lib/... e lib/...: a chave ignora o prefixo."""
    return chave.replace(":apktool_out/", ":", 1)


def coletar(rel):
    """Devolve lista de (chave, descrição) de achados high, chaves normalizadas e sem duplicatas."""
    unicos = {}
    for chave, desc in _coletar_bruto(rel):
        unicos.setdefault(normalizar_chave(chave), desc)
    return list(unicos.items())


def _coletar_bruto(rel):
    achados = []
    if not isinstance(rel, dict):
        return achados

    # Manifesto: manifest_analysis.manifest_findings[] (v4) ou lista direta (v3).
    ma = rel.get("manifest_analysis")
    itens = ma.get("manifest_findings") if isinstance(ma, dict) else ma
    for i in _lista(itens):
        if isinstance(i, dict) and _alto(i.get("severity")):
            ident = i.get("rule") or i.get("name") or i.get("title") or "?"
            achados.append((f"manifest_analysis:{ident}", i.get("title") or i.get("description")))

    # Rede: network_security.network_findings[]
    ns = rel.get("network_security")
    itens = ns.get("network_findings") if isinstance(ns, dict) else ns
    for i in _lista(itens):
        if isinstance(i, dict) and _alto(i.get("severity")):
            escopo = ",".join(map(str, i.get("scope") or [])) if isinstance(i.get("scope"), list) else i.get("scope")
            ident = hashlib.sha1(f"{escopo}|{i.get('description')}".encode()).hexdigest()[:10]
            achados.append((f"network_security:{ident}", i.get("description")))

    # Código e API: {findings: {regra: {metadata: {severity, description}}}}
    for secao in ("code_analysis", "android_api"):
        bloco = rel.get(secao)
        regras = bloco.get("findings") if isinstance(bloco, dict) and "findings" in bloco else bloco
        for regra, dados in _dicts(regras):
            meta = dados.get("metadata", dados) if isinstance(dados, dict) else {}
            if isinstance(meta, dict) and _alto(meta.get("severity")):
                achados.append((f"{secao}:{regra}", meta.get("description") or meta.get("cwe")))

    # Binários: lista de {name, <checagem>: {severity, description}} (ou dict por biblioteca).
    bin_ = rel.get("binary_analysis")
    por_lib = bin_ if isinstance(bin_, list) else [dict(v, name=k) for k, v in _dicts(bin_) if isinstance(v, dict)]
    for lib in por_lib:
        if not isinstance(lib, dict):
            continue
        for chk, dados in lib.items():
            if isinstance(dados, dict) and _alto(dados.get("severity")):
                achados.append((f"binary_analysis:{lib.get('name', '?')}:{chk}", dados.get("description")))

    # Certificado: certificate_findings[] = [severidade, descrição, título] ou dicts.
    ca = rel.get("certificate_analysis")
    for i in _lista(ca.get("certificate_findings") if isinstance(ca, dict) else None):
        if isinstance(i, (list, tuple)) and len(i) >= 3 and _alto(i[0]):
            achados.append((f"certificate_analysis:{i[2]}", i[1]))
        elif isinstance(i, dict) and _alto(i.get("severity")):
            achados.append((f"certificate_analysis:{i.get('title', '?')}", i.get("description")))

    # Comportamento: {hash: {metadata: {severity, label}}}
    for ident, dados in _dicts(rel.get("behaviour")):
        meta = dados.get("metadata") if isinstance(dados, dict) else None
        if isinstance(meta, dict) and _alto(meta.get("severity")):
            achados.append((f"behaviour:{ident}", meta.get("label")))

    # Segredos: lista de textos sem severidade; tudo é tratado como high.
    # A chave usa só o hash; o texto NUNCA vai ao resumo.
    segredos = rel.get("secrets")
    for s in _lista(segredos) if not isinstance(segredos, dict) else list(segredos.values()):
        h = hashlib.sha1(str(s).encode()).hexdigest()[:12]
        achados.append((f"secrets:{h}", "possível segredo (conteúdo omitido)"))
    return achados


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    modo = os.environ.get("MOBSF_MODO", "relatorio").strip().lower()
    aceitos = ler_aceitos(argv[2] if len(argv) > 2 else "security/mobsf_aceitos.json", "chave")
    try:
        with open(argv[1], encoding="utf-8") as f:
            rel = json.load(f)
    except (OSError, ValueError) as e:
        escrever_resumo(f"### MobSF: vermelho\n\nRelatório ilegível ({type(e).__name__}).\n")
        sair("vermelho", modo == "bloquear")
        return 0

    achados = coletar(rel)
    vermelhos = [(c, d) for c, d in achados if c not in aceitos]
    aceitos_achados = [(c, d) for c, d in achados if c in aceitos]
    estado = estado_final(vermelhos, aceitos_achados)

    linhas = [f"### MobSF: {estado} (modo {modo})", "",
              f"Achados high: {len(achados)}; fora da lista de aceitos: {len(vermelhos)}; aceitos: {len(aceitos_achados)}.", ""]
    if achados:
        linhas += ["| Estado | Chave | Descrição / motivo |", "|---|---|---|"]
        for c, d in sorted(vermelhos):
            linhas.append(f"| vermelho | `{c}` | {_curto(d).replace('|', '/')} |")
        for c, d in sorted(aceitos_achados):
            linhas.append(f"| ATENÇÃO | `{c}` | aceito: {_curto(aceitos[c]).replace('|', '/')} |")
        linhas.append("")
        linhas.append("Para aceitar um achado, acrescente `{\"chave\": ..., \"motivo\": ...}` em apps/app/security/mobsf_aceitos.json.")
    escrever_resumo("\n".join(linhas) + "\n")
    sair(estado, modo == "bloquear")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
