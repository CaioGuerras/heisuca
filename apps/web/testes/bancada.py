"""Heisuca, build de teste: abertura, login (conta da bancada), início no desktop, celular e TV (setas)."""
import json, os, time
from playwright.sync_api import sync_playwright
URL = "https://netflix.docaio.com.br/__heisuca/"
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
os.makedirs("/w/shots/heisuca", exist_ok=True)
res = {}
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox"])
    for nome, vp, ua in [("desk", {"width": 1440, "height": 900}, None),
                         ("cel", {"width": 390, "height": 844}, None),
                         ("tv", {"width": 1920, "height": 1080}, "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 Chrome/76.0 Safari/537.36")]:
        ctx = b.new_context(viewport=vp, user_agent=ua) if ua else b.new_context(viewport=vp)
        pg = ctx.new_page(); erros = []
        pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
        pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
        pg.goto(URL); time.sleep(1.3)
        if nome == "desk": pg.screenshot(path="/w/shots/heisuca/abertura.png")
        pg.wait_for_selector(".entrar-caixa", timeout=8000)
        pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P)
        if nome == "desk": pg.screenshot(path="/w/shots/heisuca/entrar.png")
        pg.click("button.botao")
        pg.wait_for_selector(".cartao img", timeout=15000); time.sleep(2.5)
        if nome == "tv":
            pg.keyboard.press("ArrowDown"); pg.keyboard.press("ArrowDown")
            for _ in range(3): pg.keyboard.press("ArrowRight")
            pg.keyboard.press("ArrowDown"); time.sleep(1.2)
        pg.screenshot(path=f"/w/shots/heisuca/inicio_{nome}.png")
        res[nome] = pg.evaluate("""() => ({fileiras: [...document.querySelectorAll('.fileira h2')].map(h => h.textContent),
            cartoes: document.querySelectorAll('.cartao').length, foco: document.activeElement && document.activeElement.className,
            destaque: document.querySelector('.destaque-texto h1')?.textContent,
            semImagem: [...document.querySelectorAll('.cartao img')].filter(i => i.complete && !i.naturalWidth).length})""")
        res[nome]["erros"] = erros
        ctx.close()
    b.close()
print(json.dumps(res, ensure_ascii=False, indent=1))
