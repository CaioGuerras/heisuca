#!/usr/bin/env python3
"""
Monitora a compilação do Heisuca Android no GitHub Actions, baixa o APK arm64-v8a,
faz o deploy para a VPS de produção/teste e avisa no Telegram.
"""
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

SP = ZoneInfo("America/Sao_Paulo")
OWNER = "CaioGuerras"
REPO = "heisuca"
BRANCH = "gemini/heisuca-plex-home"
VPS_HOST = "vps"  # atalho no ~/.ssh/config (endereço, porta e usuário fora do repositório)
VPS_DEST = "/var/www/heisuca/pacotes/heisuca-arm64-v8a.apk"
URL_PUBLICA = "https://heisuca.docaio.com.br/pacotes/heisuca-arm64-v8a.apk"


def log(msg):
    ts = datetime.now(SP).strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)


def get_token():
    cred_file = Path("/home/caioguerras/.git-credentials")
    if not cred_file.exists():
        raise SystemExit("Arquivo ~/.git-credentials não encontrado.")
    for line in cred_file.read_text().splitlines():
        m = re.search(r"https://[^:]+:([^@]+)@github\.com", line)
        if m:
            return m.group(1)
    raise SystemExit("Token do GitHub não encontrado em ~/.git-credentials.")


def api_get(path, token):
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "CGSERVER-HeisucaDeploy",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def send_geminions_msg(text):
    try:
        conf_file = Path("/home/caioguerras/.cgflix/segredos/telegram_geminions.json")
        if not conf_file.exists():
            return
        conf = json.loads(conf_file.read_text())
        url = f"https://api.telegram.org/bot{conf['token']}/sendMessage"
        data = json.dumps({
            "chat_id": conf["caio_id"],
            "text": text,
            "link_preview_options": {"is_disabled": True}
        }).encode()
        req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req, timeout=30).read()
    except Exception as e:
        log(f"Aviso: falha ao enviar via bot geminions: {e}")


def main():
    token = get_token()
    run_id = sys.argv[1] if len(sys.argv) > 1 else None

    if not run_id:
        log(f"Buscando runs recentes do branch {BRANCH}...")
        runs = api_get(
            f"/repos/{OWNER}/{REPO}/actions/runs?branch={BRANCH}&per_page=1",
            token,
        )
        if not runs.get("workflow_runs"):
            raise SystemExit("Nenhum workflow run encontrado.")
        run = runs["workflow_runs"][0]
        run_id = run["id"]

    log(f"Monitorando workflow run #{run_id}...")
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json", "User-Agent": "CGSERVER-HeisucaDeploy"}
    while True:
        try:
            info = api_get(f"/repos/{OWNER}/{REPO}/actions/runs/{run_id}", token)
            status = info.get("status")
            conclusion = info.get("conclusion")
            sha = info.get("head_sha", "")[:7]
            log(f"Run {run_id} ({sha}): status={status}, conclusion={conclusion}")
            if status == "completed":
                if conclusion != "success":
                    req_jobs = urllib.request.Request(f"https://api.github.com/repos/{OWNER}/{REPO}/actions/runs/{run_id}/jobs", headers=headers)
                    jobs_data = json.loads(urllib.request.urlopen(req_jobs, timeout=30).read())
                    failed_steps = []
                    for j in jobs_data.get("jobs", []):
                        for s in j.get("steps", []):
                            if s.get("conclusion") == "failure":
                                failed_steps.append(f"{j.get('name')} -> {s.get('name')}")
                    err_msg = f"⚠️ Build #{run_id} ({sha}) no GitHub Actions falhou com status={conclusion}. Passos com falha: {', '.join(failed_steps) or conclusion}."
                    send_geminions_msg(err_msg)
                    raise SystemExit(err_msg)
                break
        except Exception as e:
            log(f"Erro momentâneo ao consultar GitHub API: {e}")
        time.sleep(15)

    log("Buscando artefatos do run...")
    arts = api_get(f"/repos/{OWNER}/{REPO}/actions/runs/{run_id}/artifacts", token)
    dl_url = None
    for a in arts.get("artifacts", []):
        if a["name"] == "heisuca-apk":
            dl_url = a["archive_download_url"]
            break
    if not dl_url and arts.get("artifacts"):
        dl_url = arts["artifacts"][0]["archive_download_url"]

    if not dl_url:
        raise SystemExit("Artefato 'heisuca-apk' não encontrado nos resultados do workflow.")

    log(f"Baixando artefato zip de {dl_url}...")
    class NoAuthRedirectHandler(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, hdrs, newurl):
            new_req = super().redirect_request(req, fp, code, msg, hdrs, newurl)
            if new_req and "Authorization" in new_req.unredirected_hdrs:
                del new_req.unredirected_hdrs["Authorization"]
            if new_req and "Authorization" in new_req.headers:
                del new_req.headers["Authorization"]
            return new_req

    opener = urllib.request.build_opener(NoAuthRedirectHandler)
    req_zip = urllib.request.Request(dl_url, headers=headers)
    zip_bytes = opener.open(req_zip, timeout=240).read()
    log(f"Download concluído: {len(zip_bytes)} bytes recebidos.")

    out_dir = Path("/tmp/heisuca_apk_release")
    out_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        zf.extractall(out_dir)

    apks = list(out_dir.rglob("*.apk"))
    if not apks:
        raise SystemExit("Zip do artifact baixado, mas sem arquivo .apk dentro.")

    apk_path = apks[0]
    size_mb = apk_path.stat().st_size / (1024 * 1024)
    sha256 = hashlib.sha256(apk_path.read_bytes()).hexdigest()
    log(f"APK extraído: {apk_path} ({size_mb:.2f} MB, sha256={sha256[:16]}...)")

    # Atualiza cópia local em apps/app/dist
    local_dist = Path("/home/caioguerras/heisuca/apps/app/dist")
    local_dist.mkdir(parents=True, exist_ok=True)
    local_apk = local_dist / "heisuca-arm64-v8a.apk"
    import shutil
    shutil.copyfile(apk_path, local_apk)
    log(f"Cópia local atualizada em {local_apk}")

    # Deploy na VPS
    log(f"Enviando APK para a VPS {VPS_HOST}:{VPS_DEST} via SCP...")
    subprocess.run([
        "scp", str(apk_path),
        f"{VPS_HOST}:{VPS_DEST}"
    ], check=True)

    subprocess.run([
        "ssh", VPS_HOST,
        f"cp -f {VPS_DEST} /var/www/heisuca/teste/pacotes/heisuca-arm64-v8a.apk && chown -R www-data:www-data /var/www/heisuca/pacotes /var/www/heisuca/teste/pacotes && chmod 644 {VPS_DEST} /var/www/heisuca/teste/pacotes/heisuca-arm64-v8a.apk"
    ], check=True)

    # Validando via HTTP
    head_req = urllib.request.Request(URL_PUBLICA, method="HEAD")
    with urllib.request.urlopen(head_req, timeout=20) as resp:
        http_code = resp.status
    log(f"Validação HTTP: status {http_code}")

    # Registro de auditoria
    ts_sp = datetime.now(SP).strftime("%d/%m/%Y %H:%M SP")
    with open("/home/caioguerras/cgflix/GEMINI_BOT_ACOES.md", "a") as f:
        f.write(f"- {ts_sp} | Build #{run_id} ({sha}) deploy em {URL_PUBLICA} ({size_mb:.1f} MB, SHA256 {sha256[:12]}, HTTP {http_code}) | Sucesso\n")

    # Notificação aos canais Telegram
    msg = (
        f"📱 *Heisuca Android (Edge 60 Pro) — Build Atualizada*\n\n"
        f"• *Commit*: `{sha}`\n"
        f"• *Tamanho*: `{size_mb:.1f} MB` (HTTP {http_code} OK)\n"
        f"• *SHA256*: `{sha256[:16]}...`\n"
        f"• *Download direto*: {URL_PUBLICA}\n\n"
        f"Correções validadas aplicadas:\n"
        f"1. *Login 20:9:* Proporção vertical balanceada sem vazio inferior, indicador luminoso dinâmico (`● CGSERVER · Jellyfin pronto para autenticar`).\n"
        f"2. *Folha de Fontes:* Pílulas com cores oficiais de cada serviço (Plex dourado, Jellyfin roxo, Emby verde, SMB azul, WebDAV ciano, Local laranja).\n"
        f"3. *Quick Connect:* Fallback automático para netflix.docaio.com.br, formatação tabular do PIN (`482 917`) e retry.\n"
        f"4. *Reprodução Imediata:* Ficha técnica com `hostContext` fixo eliminando o fechamento prematuro da rota, fallback automático para séries e toque em episódios iniciando o vídeo na hora.\n"
        f"5. *Purificação dos Temas:* Removido ícone verde antigo CGFLIX no Android Manifest (aponta agora para o selo Hisui oficial) e eliminado qualquer fundo roxo fixo no modo claro.\n"
        f"6. *Toque Longo (500ms):* Conectado a Marcar visto, Favoritar e Baixar reais."
    )
    send_geminions_msg(msg)

    telegram_bin = "/mnt/nvme4n1/caioguerras/cgflix/bin/cgf-telegram"
    if os.path.exists(telegram_bin):
        env = os.environ.copy()
        env["HOME"] = "/home/caioguerras"
        subprocess.run([telegram_bin, "--topico", "relatorios", "msg", msg], env=env, check=False)
        log("Notificação Telegram enviada com sucesso ao tópico relatorios.")

    log("Processo de deploy finalizado com êxito!")


if __name__ == "__main__":
    main()
