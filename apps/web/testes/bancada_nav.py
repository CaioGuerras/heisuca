"""Heisuca: navegação no modelo dos nossos apps (celular Android, computador e TV). Não faz pedido no Seerr: abre a folha e fecha.
Uso: python3 heisuca_nav.py [cel|desk|tv] [termo-que-não-temos]"""
import json, os, sys, time
from playwright.sync_api import sync_playwright
URL = "https://netflix.docaio.com.br/__heisuca/"
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
modo = sys.argv[1] if len(sys.argv) > 1 else "cel"
termo = sys.argv[2] if len(sys.argv) > 2 else "Duna"
CFG = {"cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.6, is_mobile=True, has_touch=True,
                   user_agent="Mozilla/5.0 (Linux; Android 15; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0 Mobile Safari/537.36"),
       "desk": dict(viewport={"width": 1440, "height": 900}),
       "tv": dict(viewport={"width": 1920, "height": 1080}, user_agent="Mozilla/5.0 (SMART-TV; Linux; Tizen 6.5) AppleWebKit/537.36 Chrome/85.0 Safari/537.36")}[modo]
D = f"/w/shots/heisuca/nav_{modo}"
os.makedirs("/w/shots/heisuca", exist_ok=True)
res = {"modo": modo}
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox"])
    ctx = b.new_context(**CFG); pg = ctx.new_page(); erros = []
    pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
    pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
    pg.goto(URL); time.sleep(1.2); pg.keyboard.press("Enter")
    pg.wait_for_selector(".entrar-caixa", timeout=8000)
    pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P); pg.click("button.botao")
    pg.wait_for_selector(".cartao img", timeout=20000); time.sleep(3.5)
    pg.screenshot(path=f"{D}_1inicio.png")
    res["inicio"] = pg.evaluate("""() => ({fileiras: [...document.querySelectorAll('.fileira h2')].map(h => h.textContent),
      atalhos: [...document.querySelectorAll('.atalho')].map(a => a.textContent), abasBaixo: getComputedStyle(document.querySelector('.abas-baixo')).display,
      linksTopo: getComputedStyle(document.querySelector('.topo-links')).display, menuAberto: !!document.querySelector('.menu-painel'),
      logo: !!document.querySelector('.destaque-logo'), top10: document.querySelectorAll('.cartao-numero').length})""")
    if modo == "cel":
        pg.mouse.wheel(0, 900); time.sleep(1.5); pg.screenshot(path=f"{D}_1inicio_rolado.png"); pg.mouse.wheel(0, -2000); time.sleep(.5)
    pg.click(".avatar-botao"); time.sleep(.8); pg.screenshot(path=f"{D}_2menu.png")
    res["menu"] = pg.evaluate("() => [...document.querySelectorAll('.menu-painel .menu-item span:not(.icone)')].map(s => s.textContent)")
    pg.keyboard.press("Escape"); time.sleep(.5)
    res["menuFechou"] = not pg.evaluate("() => !!document.querySelector('.menu-painel')")
    pg.click(".atalho"); pg.wait_for_selector(".grade .cartao img", timeout=15000); time.sleep(2)
    pg.screenshot(path=f"{D}_3biblioteca.png")
    res["biblioteca"] = pg.evaluate("() => ({titulo: document.querySelector('.pagina-titulo')?.textContent, cartoes: document.querySelectorAll('.grade .cartao').length})")
    pg.evaluate("location.hash = '#/busca'"); pg.wait_for_selector(".busca-caixa input", timeout=8000)
    pg.fill(".busca-caixa input", termo); time.sleep(5)
    pg.screenshot(path=f"{D}_4busca.png", full_page=True)
    res["busca"] = pg.evaluate("() => ({secoes: [...document.querySelectorAll('.pagina-sub')].map(h => h.textContent), cartoes: document.querySelectorAll('.grade .cartao').length, notas: [...document.querySelectorAll('.pagina-nota')].map(n => n.textContent)})")
    pedir = pg.query_selector(".pagina-sub + .grade .cartao:has(.cartao-selo:text-is('Pedir'))")
    if pedir:
        pedir.click(); time.sleep(3); pg.screenshot(path=f"{D}_5folha.png")
        res["folha"] = pg.evaluate("() => ({titulo: document.querySelector('.folha h2')?.textContent, botao: document.querySelector('.folha-pedir')?.textContent, temps: document.querySelectorAll('.folha-temp').length})")
        pg.keyboard.press("Escape"); time.sleep(.5)
    pg.evaluate("location.hash = '#/pedidos'"); time.sleep(5); pg.screenshot(path=f"{D}_6pedidos.png")
    res["pedidos"] = pg.evaluate("() => ({linhas: document.querySelectorAll('.pedido').length, notas: [...document.querySelectorAll('.pagina-nota')].map(n => n.textContent)})")
    pg.evaluate("location.hash = '#/fav'"); time.sleep(3)
    res["fav"] = pg.evaluate("() => document.querySelectorAll('.grade .cartao').length")
    res["erros"] = erros
    b.close()
print(json.dumps(res, ensure_ascii=False, indent=1))
