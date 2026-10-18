"""Heisuca M2: retomar (?t=), HLS, legenda SRT por fora, trocar áudio, marcar/desmarcar assistido. Conta da bancada, desktop."""
import json, os, sys, time
from playwright.sync_api import sync_playwright
URL = "https://netflix.docaio.com.br/__heisuca/"
ID = sys.argv[1]
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
r = {}
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox", "--autoplay-policy=no-user-gesture-required"])
    pg = b.new_page(viewport={"width": 1440, "height": 900}); erros, api = [], []
    pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
    pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
    pg.on("response", lambda x: any(k in x.url for k in ("PlaybackInfo", "/Sessions/Playing", "master.m3u8", "Subtitles", "UserPlayedItems", "ActiveEncodings"))
          and api.append(f"{x.status} {x.request.method} {x.url.split('?')[0].split('.br')[-1][:80]}"))
    estado = lambda: pg.evaluate("""() => { const v = document.querySelector('.player video');
        const tt = [...v.textTracks].map(t => ({l: t.label, m: t.mode, cues: t.cues ? t.cues.length : null}));
        return {t: Math.round(v.currentTime), pausado: v.paused, w: v.videoWidth, selo: document.querySelector('.player-selo')?.textContent || 'Direto',
                erro: document.querySelector('.player-erro')?.textContent || '', faixas: tt,
                opcoes: [...document.querySelectorAll('.player-menu .opcao.ativa')].map(o => o.textContent)}; }""")
    try:
        pg.goto(URL); time.sleep(1.2); pg.keyboard.press("Enter"); time.sleep(.6)
        pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P); pg.click("button.botao")
        pg.wait_for_selector(".cartao img", timeout=20000)
        pg.evaluate(f"location.hash = '#/ver/{ID}?t=600000000'"); time.sleep(16)
        r["retomar"] = estado()
        pg.mouse.move(500, 400); pg.click('button[aria-label="Áudio e legendas"]'); time.sleep(.5)
        r["menu"] = pg.evaluate("() => [...document.querySelectorAll('.player-menu .opcao')].map(o => o.textContent)")
        pg.locator(".player-menu section", has_text="Legendas").locator(".opcao").nth(1).click(); time.sleep(5)
        r["legenda"] = estado()
        pg.mouse.move(520, 420); pg.click('button[aria-label="Áudio e legendas"]'); time.sleep(.5)
        pg.locator(".player-menu section", has_text="Áudio").locator(".opcao:not(.ativa)").first.click(); time.sleep(16)
        r["audio"] = estado()
        pg.mouse.move(500, 400); time.sleep(.3); pg.screenshot(path="/w/shots/heisuca/m2_trocas.png")
        pg.keyboard.press("Escape"); time.sleep(1.5)
        pg.evaluate(f"location.hash = '#/t/{ID}'"); pg.wait_for_selector(".titulo-info", timeout=10000); time.sleep(1.5)
        r["titulo_play"] = pg.locator(".botao-play").text_content()
        pg.click(".botao-sec"); time.sleep(1.5); r["marcou"] = pg.locator(".botao-sec").get_attribute("aria-pressed")
        pg.click(".botao-sec"); time.sleep(1.5); r["desmarcou"] = pg.locator(".botao-sec").get_attribute("aria-pressed")
    except Exception as ex:
        r["falha"] = str(ex)[:300]; pg.screenshot(path="/w/shots/heisuca/m2_trocas_falha.png")
    r["erros"], r["api"] = erros, api
    b.close()
print(json.dumps(r, ensure_ascii=False, indent=1))
