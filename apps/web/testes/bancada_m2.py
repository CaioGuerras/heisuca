"""Heisuca M2: página do título (filme e série) e player (toca, relata progresso, menu, voltar). Conta da bancada."""
import json, os, time
from playwright.sync_api import sync_playwright
URL = "https://netflix.docaio.com.br/__heisuca/"
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
os.makedirs("/w/shots/heisuca", exist_ok=True)
TV = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 Chrome/76.0 Safari/537.36"
res = {}

def entrar(pg):
    pg.goto(URL); time.sleep(1.2); pg.keyboard.press("Enter"); time.sleep(.6)
    pg.wait_for_selector(".entrar-caixa", timeout=10000)
    pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P); pg.click("button.botao")
    pg.wait_for_selector(".cartao img", timeout=20000); time.sleep(1.5)

with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox", "--autoplay-policy=no-user-gesture-required"])
    for nome, vp, ua in [("desk", {"width": 1440, "height": 900}, None), ("cel", {"width": 390, "height": 844}, None), ("tv", {"width": 1920, "height": 1080}, TV)]:
        if os.environ.get("SO") and nome != os.environ["SO"]: continue
        ctx = b.new_context(viewport=vp, user_agent=ua) if ua else b.new_context(viewport=vp, is_mobile=nome == "cel", has_touch=nome == "cel")
        pg = ctx.new_page(); erros, api = [], []
        pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
        pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
        pg.on("response", lambda r: any(k in r.url for k in ("PlaybackInfo", "/Sessions/Playing", "/Videos/", "master.m3u8", "UserPlayedItems"))
              and api.append(f"{r.status} {r.request.method} {r.url.split('?')[0].split('.br')[-1][:70]}"))
        r = {}; res[nome] = r
        try:
          entrar(pg)
          # filme
          pg.locator(".fileira", has_text="Novidades em Filmes").locator(".cartao").first.click()
          pg.wait_for_selector(".titulo-info", timeout=15000); time.sleep(2)
          pg.screenshot(path=f"/w/shots/heisuca/m2_filme_{nome}.png")
          r["filme"] = pg.evaluate("() => ({nome: document.querySelector('.titulo-info h1, .titulo-logo')?.textContent || document.querySelector('.titulo-logo')?.alt, meta: document.querySelector('.titulo-meta')?.textContent, play: document.querySelector('.botao-play')?.textContent, foco: document.activeElement?.className})")
          if nome == "tv": pg.keyboard.press("Enter")
          else: pg.click(".botao-play")
          pg.wait_for_selector(".player video", timeout=10000); time.sleep(14)
          r["player"] = pg.evaluate("""() => { const v = document.querySelector('.player video');
              return {t: Math.round(v.currentTime), pausado: v.paused, pronto: v.readyState, w: v.videoWidth, selo: document.querySelector('.player-selo')?.textContent || 'Direto',
                      erro: document.querySelector('.player-erro')?.textContent || '', faixas: v.textTracks.length, menu: !!document.querySelector('[aria-label="Áudio e legendas"]')}; }""")
          if nome == "cel": pg.tap(".player video")
          else: pg.mouse.move(400, 400)
          time.sleep(.5)
          pg.screenshot(path=f"/w/shots/heisuca/m2_player_{nome}.png")
          if pg.locator('button[aria-label="Áudio e legendas"]').count():
              pg.click('button[aria-label="Áudio e legendas"]'); time.sleep(.6)
              pg.screenshot(path=f"/w/shots/heisuca/m2_menu_{nome}.png")
              r["menu"] = pg.evaluate("() => [...document.querySelectorAll('.player-menu .opcao')].map(o => o.textContent)")
              pg.keyboard.press("Escape"); time.sleep(.3)
          pg.keyboard.press("Escape"); time.sleep(2)
          r["voltou"] = pg.evaluate("() => !!document.querySelector('.titulo-info')")
          # série
          pg.keyboard.press("Escape"); time.sleep(1.5)
          pg.wait_for_selector(".fileira", timeout=10000)
          pg.locator(".fileira", has_text="Novidades em Séries").locator(".cartao").first.click()
          pg.wait_for_selector(".episodio", timeout=15000); time.sleep(2)
          if nome == "tv":
              for k in ["ArrowDown", "ArrowDown", "ArrowDown"]: pg.keyboard.press(k); time.sleep(.3)
          pg.screenshot(path=f"/w/shots/heisuca/m2_serie_{nome}.png")
          r["serie"] = pg.evaluate("() => ({nome: document.querySelector('.titulo-info h1')?.textContent || document.querySelector('.titulo-logo')?.alt, play: document.querySelector('.botao-play')?.textContent, temporadas: document.querySelectorAll('.temporadas-abas .aba').length, eps: document.querySelectorAll('.episodio').length, foco: document.activeElement?.className})")
        except Exception as ex:
          r["falha"] = str(ex)[:300]; pg.screenshot(path=f"/w/shots/heisuca/m2_falha_{nome}.png")
        r["erros"], r["api"] = erros, api[:14]
        ctx.close()
    b.close()
print(json.dumps(res, ensure_ascii=False, indent=1))
