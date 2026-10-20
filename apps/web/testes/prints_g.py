#!/usr/bin/env python3
"""Prints da sessão G: Info mídia do Título (celular 412×915 e computador 1440×900, Roxo e Verde), contra o servidor FALSO.

Uso: python3 testes/prints_g.py [--site http://127.0.0.1:5173] [--saida testes/comparacoes/g/brutos (PNG; converta para JPEG antes de juntar)] [--prefixo depois]
Para cada filme da lista, rola até o "Info mídia" e tira o print da tela; também confere se algum <dd> está vazio
ou fora da tela (o defeito do Caio em 20/10: rótulos sem valor no celular).
"""
import argparse, json, os, time
from playwright.sync_api import sync_playwright

FILMES = {"amorsemfim": "21b3b1d813cc43752cfdda361bb475f3",      # dois AAC 2.0 (o caso do "Max & Companhia": MP4 h264/aac 2.0)
          "masterplan": "ab05a17a4c806920bebc1b563e118078",      # dois E-AC-3 5.1
          "aliens": "0060a8fea9e85757c6204c99058bbfeb"}          # quatro áudios
a = argparse.ArgumentParser()
a.add_argument("--site", default="http://127.0.0.1:5173")
a.add_argument("--falso", default="http://127.0.0.1:8097")
a.add_argument("--saida", default="testes/comparacoes/g/brutos (PNG; converta para JPEG antes de juntar)")
a.add_argument("--prefixo", default="depois")
a.add_argument("--chromium", default=None)
o = a.parse_args()
os.makedirs(o.saida, exist_ok=True)
ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
          "desk": dict(viewport={"width": 1440, "height": 900})}
CONFERE = """() => { const w = innerWidth, r = [];
  document.querySelectorAll('.titulo-midia-cartao').forEach(c => { const b = c.getBoundingClientRect();
    if (b.right > w + 1 || b.left < -1) r.push('cartão fora da tela: ' + c.querySelector('h3').textContent);
    c.querySelectorAll('dl > div').forEach(l => { const dd = l.querySelector('dd'), x = dd.getBoundingClientRect();
      if (!dd.textContent.trim()) r.push('valor vazio: ' + l.querySelector('dt').textContent);
      if (x.right > w + 1) r.push('valor fora da tela: ' + l.querySelector('dt').textContent); }); });
  const m = document.querySelector('.titulo-midia'); if (m && m.scrollWidth > m.clientWidth + 1) r.push('rolagem lateral no Info mídia');
  if (document.documentElement.scrollWidth > w + 1) r.push('rolagem lateral na página');
  return r; }"""
resumo = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=o.chromium) if o.chromium else p.chromium.launch()
    for perfil in ("cel", "desk"):
        for tema in ("roxo", "verde"):
            ctx = b.new_context(**PERFIS[perfil], color_scheme="light" if tema == "verde" else "dark")
            ctx.add_init_script(f"try {{ sessionStorage.setItem('heisuca.abriu','1'); localStorage.setItem('heisuca.tema','{tema}'); }} catch (e) {{}}")
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
            for nome, id_ in FILMES.items():
                pg.evaluate("location.hash = '#/fav'"); time.sleep(0.3)
                pg.evaluate(f"location.hash = '#/t/{id_}'"); time.sleep(1.8)
                pg.evaluate("document.querySelector('.titulo-midia')?.closest('section')?.scrollIntoView({block: 'center'})"); time.sleep(0.9)
                problemas = pg.evaluate(CONFERE)
                if problemas: erros.append(f"{nome}: {problemas}")
                pg.screenshot(path=f"{o.saida}/{o.prefixo}_{perfil}_{tema}_{nome}.png")
            resumo[f"{perfil}_{tema}"] = erros
            ctx.close()
    b.close()
print(json.dumps(resumo, ensure_ascii=False, indent=1))
