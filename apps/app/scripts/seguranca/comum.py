"""Utilidades comuns dos portões de segurança (gitleaks, osv, MobSF)."""
import json
import os
import sys


def ler_aceitos(caminho, campo):
    """Lê a lista de aceitos: [{campo: ..., "motivo": ...}]. Entrada sem motivo é ignorada."""
    try:
        with open(caminho, encoding="utf-8") as f:
            dados = json.load(f)
    except FileNotFoundError:
        return {}
    aceitos = {}
    for item in dados if isinstance(dados, list) else []:
        if isinstance(item, dict) and item.get(campo) and str(item.get("motivo", "")).strip():
            aceitos[str(item[campo])] = str(item["motivo"])
    return aceitos


def escrever_resumo(texto):
    print(texto)
    destino = os.environ.get("GITHUB_STEP_SUMMARY")
    if destino:
        with open(destino, "a", encoding="utf-8") as f:
            f.write(texto + "\n")


def estado_final(vermelhos, atencao):
    if vermelhos:
        return "vermelho"
    return "ATENÇÃO" if atencao else "verde"


def sair(estado, bloqueia):
    if estado == "ATENÇÃO":
        print("::warning::Portão de segurança em ATENÇÃO; veja o resumo.")
    if estado == "vermelho":
        if bloqueia:
            print("::error::Portão de segurança vermelho.")
            sys.exit(1)
        print("::warning::Portão vermelho, mas o modo é relatório (não bloqueia).")
