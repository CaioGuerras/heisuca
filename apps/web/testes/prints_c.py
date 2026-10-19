#!/usr/bin/env python3
"""Prints da sessão C (Título e Biblioteca) contra o servidor FALSO, com ações por cena (rolar, clicar).

Uso: python3 testes/prints_c.py [--site http://127.0.0.1:5173] [--saida testes/comparacoes/c/brutos] [--so nome1,nome2]
     [--temas roxo,verde] [--perfis cel,desk] [--chromium CAMINHO]
Cenas: lista CENAS abaixo (nome, rota, ações). Ações: ("rolar", px) · ("clicar", seletor) · ("esperar", s) · ("tecla", nome).
Sai <perfil>_<tema>_<cena>.png e um resumo com os erros de console de cada contexto.
"""
import argparse, json, os, time
from playwright.sync_api import sync_playwright

DEADWOOD, ONEPIECE, HSOTD = "6338069512c6b504f35fcbad739639f7", "781959f63b29a341944248b6d4936e49", "424e882405bf7ddc65ffe3acbc70c9f7"
INUYASHA, AOASHI, MASTERPLAN = "ab2bf5e7ad98bf78bd48c6fa1c7fd037", "85103948cf4bc28a34256b6b38c8b896", "ab05a17a4c806920bebc1b563e118078"
ALIEN, ANIMES = "2239e1d833e90e0c6d4140d6b38e3eee", "ca0de50d2c11073f53df7c82dc3fe2a4"
CENAS = [
    ("deadwood_topo", f"#/t/{DEADWOOD}", []),
    ("deadwood_rolado", f"#/t/{DEADWOOD}", [("rolar", 620)]),
    ("deadwood_baixo", f"#/t/{DEADWOOD}", [("rolar", 99999)]),
    ("deadwood_temporada", f"#/t/{DEADWOOD}", [("rolar", 420), ("clicar", ".titulo-temp")]),
    ("deadwood_vertudo", f"#/t/{DEADWOOD}", [("rolar", 420), ("clicar", ".titulo-eps .fileira-tudo")]),
    ("onepiece_temporada", f"#/t/{ONEPIECE}", [("rolar", 420), ("clicar", ".titulo-temp")]),
    ("onepiece_topo", f"#/t/{ONEPIECE}", []),
    ("hsotd_topo", f"#/t/{HSOTD}", []),
    ("hsotd_rolado", f"#/t/{HSOTD}", [("rolar", 900)]),
    ("inuyasha_topo", f"#/t/{INUYASHA}", []),
    ("aoashi_topo", f"#/t/{AOASHI}", []),
    ("masterplan_topo", f"#/t/{MASTERPLAN}", []),
    ("masterplan_baixo", f"#/t/{MASTERPLAN}", [("rolar", 99999)]),
    ("alien_topo", f"#/t/{ALIEN}", []),
    ("biblioteca", f"#/b/{ANIMES}", []),
    ("biblioteca_menu", f"#/b/{ANIMES}", [("clicar", ".biblioteca-topo .redondo:last-child")]),
    ("biblioteca_trocar", f"#/b/{ANIMES}", [("clicar", ".biblioteca-topo .redondo:last-child"), ("clicar", ".biblioteca-servidor"), ("esperar", 0.6)]),
    ("biblioteca_rolada", f"#/b/{ANIMES}", [("rolar", 99999), ("esperar", 1.5), ("rolar", 99999)]),
    ("biblioteca_sem_id", "#/b", []),
]

a = argparse.ArgumentParser()
a.add_argument("--site", default="http://127.0.0.1:5173")
a.add_argument("--falso", default="http://127.0.0.1:8097")
a.add_argument("--saida", default="testes/comparacoes/c/brutos")
a.add_argument("--so", default="")
a.add_argument("--temas", default="roxo,verde")
a.add_argument("--perfis", default="cel,desk")
a.add_argument("--chromium", default=None)
o = a.parse_args()
os.makedirs(o.saida, exist_ok=True)
so = set(filter(None, o.so.split(",")))

ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
          "desk": dict(viewport={"width": 1440, "height": 900})}
resumo = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=o.chromium) if o.chromium else p.chromium.launch()
    for perfil in o.perfis.split(","):
        for tema in o.temas.split(","):
            ctx = b.new_context(**PERFIS[perfil], color_scheme="light" if tema == "verde" else "dark")
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
            try: pg.wait_for_selector(".transicao", state="attached", timeout=5000)
            except Exception: pass
            pg.wait_for_selector(".transicao", state="detached", timeout=20000); time.sleep(0.5)
            for nome, rota, acoes in CENAS:
                if so and nome not in so: continue
                pg.evaluate("location.hash = '#/fav'"); time.sleep(0.3)
                pg.evaluate(f"location.hash = {json.dumps(rota)}"); time.sleep(1.8)
                for acao, arg in acoes:
                    if acao == "rolar": pg.evaluate(f"scrollTo(0, Math.min({arg}, document.documentElement.scrollHeight))"); time.sleep(0.9)
                    elif acao == "clicar":
                        try: pg.click(arg, timeout=5000)
                        except Exception as e: erros.append(f"{nome}: não deu para clicar em {arg}")
                        time.sleep(0.9)
                    elif acao == "esperar": time.sleep(arg)
                    elif acao == "tecla": pg.keyboard.press(arg); time.sleep(0.5)
                pg.screenshot(path=f"{o.saida}/{perfil}_{tema}_{nome}.png")
                pg.keyboard.press("Escape"); time.sleep(0.3)
            resumo[f"{perfil}_{tema}"] = {"erros": erros}
            ctx.close()
    b.close()
print(json.dumps(resumo, ensure_ascii=False, indent=1))
