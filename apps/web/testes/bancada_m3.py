"""Heisuca M3 (TV): foco inicial, fileiras por transform, voltar do título no mesmo cartão, Voltar na raiz.
Uso: python3 heisuca_m3.py [site|pacote]. "pacote" abre a build do .wgt (pasta /w/heisuca/tizen_dist) por file://,
como a TV abre o conteúdo local, e fala com o servidor por VITE_SERVIDOR (CORS)."""
import json, os, sys, time
from playwright.sync_api import sync_playwright
modo = sys.argv[1] if len(sys.argv) > 1 else "site"
URL = "https://netflix.docaio.com.br/__heisuca/" if modo == "site" else "file:///w/heisuca/tizen_dist/index.html"
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
UA = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 Chrome/76.0 Safari/537.36"
os.makedirs("/w/shots/heisuca", exist_ok=True)
ESTADO = """() => { const a = document.activeElement, r = a && a.getBoundingClientRect(), c = document.querySelector('.fileiras');
  const pista = document.querySelector('.fileiras-pista');
  return { foco: a && a.className, x: r && Math.round(r.left), y: r && Math.round(r.top - (c ? c.getBoundingClientRect().top : 0)),
    pista: pista && pista.style.transform, rolagem: [scrollY, c && c.scrollTop],
    trilhos: [...document.querySelectorAll('.fileira-trilho')].map(t => t.style.transform || '-'),
    destaque: document.querySelector('.destaque-texto h1')?.textContent, hash: location.hash }; }"""
res = {"modo": modo, "passos": []}
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox"])
    ctx = b.new_context(viewport={"width": 1920, "height": 1080}, user_agent=UA)
    pg = ctx.new_page(); erros = []
    pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
    pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
    pg.goto(URL); time.sleep(1.3)
    pg.keyboard.press("Enter")  # pula a abertura
    pg.wait_for_selector(".entrar-caixa", timeout=8000)
    pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P)
    pg.click("button.botao")
    pg.wait_for_selector(".cartao img", timeout=20000); time.sleep(2.5)
    def passo(nome, *teclas, espera=0.6):
        for t in teclas: pg.keyboard.press(t); time.sleep(0.25)
        time.sleep(espera)
        e = pg.evaluate(ESTADO); e["passo"] = nome; res["passos"].append(e); return e
    passo("inicial")
    passo("baixo", "ArrowDown")
    passo("direita x3", "ArrowRight", "ArrowRight", "ArrowRight")
    pg.screenshot(path=f"/w/shots/heisuca/m3_{modo}_fileira2.png")
    passo("baixo de novo", "ArrowDown")
    pg.screenshot(path=f"/w/shots/heisuca/m3_{modo}_fileira3.png")
    passo("cima", "ArrowUp")
    passo("abre título", "Enter", espera=2.5)
    pg.keyboard.press("Escape"); pg.wait_for_selector(".cartao:focus", timeout=20000)
    passo("Voltar do título", espera=1.2)
    passo("Voltar na raiz (vai ao começo)", "Escape")
    passo("Voltar na raiz de novo (fecharia o app)", "Escape")
    pg.screenshot(path=f"/w/shots/heisuca/m3_{modo}_inicio.png")
    res["erros"] = erros
    b.close()
print(json.dumps(res, ensure_ascii=False, indent=1))
