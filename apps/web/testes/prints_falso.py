#!/usr/bin/env python3
"""Prints do site contra o servidor FALSO, no tamanho do celular do Caio (412×915, 2,625x) e no computador (1440×900).

Pré-requisitos: servidor falso rodando (python3 testes/falso/servidor.py 8097) e o site em `npm run dev` (5173) ou
`npx vite preview --port 4173`. Playwright para Python (pip install playwright pillow); na nuvem o Chromium já está em
/opt/pw-browsers (use --chromium /opt/pw-browsers/chromium-*/chrome-linux/chrome se a versão do pacote não achar sozinha).

Uso:
  python3 testes/prints_falso.py --site http://127.0.0.1:5173 --rotas "#/,#/t/<id>,#/fav" [--temas roxo,verde] [--perfis cel,desk]
         [--saida testes/comparacoes/x] [--antes "js para rodar antes do print"] [--rolar 700] [--chromium CAMINHO]
Cada print sai como <perfil>_<tema>_<n>.png na pasta de saída. Depois: testes/lado_a_lado.py para comparar com plano/ref.
"""
import argparse, json, os, time
from playwright.sync_api import sync_playwright

a = argparse.ArgumentParser()
a.add_argument("--site", default="http://127.0.0.1:5173")
a.add_argument("--falso", default="http://127.0.0.1:8097")
a.add_argument("--rotas", default="#/")
a.add_argument("--temas", default="roxo,verde")
a.add_argument("--perfis", default="cel,desk")
a.add_argument("--saida", default="testes/comparacoes/prints")
a.add_argument("--antes", default="")
a.add_argument("--rolar", type=int, default=0)
a.add_argument("--espera", type=float, default=1.6)
a.add_argument("--chromium", default=None)
o = a.parse_args()
os.makedirs(o.saida, exist_ok=True)

ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
          "desk": dict(viewport={"width": 1440, "height": 900})}
resumo = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=o.chromium) if o.chromium else p.chromium.launch()
    for perfil in o.perfis.split(","):
        for tema in o.temas.split(","):
            ctx = b.new_context(**PERFIS[perfil], color_scheme="light" if tema == "verde" else "dark")
            # pula a abertura e entra direto (abertura e entrada têm print próprio da sessão A)
            ctx.add_init_script(f"""try {{ sessionStorage.setItem('heisuca.abriu','1'); localStorage.setItem('heisuca.tema','{tema}'); }} catch (e) {{}}""")
            pg = ctx.new_page(); erros = []
            pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
            pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
            pg.goto(o.site + "/")
            pg.wait_for_selector(".entrada input[type=url]", timeout=15000)
            pg.fill(".entrada input[type=url]", o.falso)
            pg.wait_for_selector(".entrada-servidor", timeout=10000)
            pg.fill(".entrada input[autocomplete=username]", "caioguerras")
            pg.click(".entrada-botao")
            pg.wait_for_selector(".transicao", timeout=20000); pg.wait_for_selector(".transicao", state="detached", timeout=20000)
            for n, rota in enumerate(o.rotas.split(",")):
                pg.evaluate(f"location.hash = {json.dumps(rota)}"); time.sleep(o.espera)
                if o.antes: pg.evaluate(o.antes); time.sleep(0.8)
                if o.rolar: pg.mouse.wheel(0, o.rolar); time.sleep(0.9)
                pg.screenshot(path=f"{o.saida}/{perfil}_{tema}_{n}.png")
            resumo[f"{perfil}_{tema}"] = {"erros": erros}
            ctx.close()
    b.close()
print(json.dumps(resumo, ensure_ascii=False, indent=1))
