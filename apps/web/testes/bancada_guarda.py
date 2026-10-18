"""Heisuca: guarda de vídeo sem quadros (18/10). uso: bancada_guarda.py ID canal(chrome|chromium) falsear(0|1)
falsear=1 finge que o navegador não mostra quadro nenhum (getVideoPlaybackQuality = 0): a guarda tem de cair no HLS."""
import json, os, sys, time
from playwright.sync_api import sync_playwright
URL = "https://netflix.docaio.com.br/__heisuca/"
ID, CANAL, FALSO = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
FINGE = "HTMLVideoElement.prototype.getVideoPlaybackQuality = function () { return {totalVideoFrames: 0, droppedVideoFrames: 0}; };"
r = {"canal": CANAL, "falsear": FALSO}
with sync_playwright() as p:
    kw = {"args": ["--no-sandbox", "--autoplay-policy=no-user-gesture-required"]}
    b = p.chromium.launch(channel="chrome", **kw) if CANAL == "chrome" else p.chromium.launch(**kw)
    ctx = b.new_context(viewport={"width": 1440, "height": 900})
    if FALSO: ctx.add_init_script(FINGE)
    pg = ctx.new_page(); erros, api = [], []
    pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
    pg.on("response", lambda x: any(k in x.url for k in ("PlaybackInfo", "/stream?", "master.m3u8", "__erro", "Stream.ass"))
          and api.append(f"{x.status} {x.request.method} {x.url.split('?')[0].split('.br')[-1][:70]}"))
    estado = lambda: pg.evaluate("""() => { const v = document.querySelector('.player video'); const q = v.getVideoPlaybackQuality();
        return {t: Math.round(v.currentTime), pausado: v.paused, w: v.videoWidth, quadros: q.totalVideoFrames, src: v.currentSrc.slice(0, 20),
                selo: document.querySelector('.player-selo')?.textContent || 'Direto', erro: document.querySelector('.player-erro')?.textContent || '',
                semMkv: localStorage.getItem('hs-sem-mkv')}; }""")
    try:
        pg.goto(URL); time.sleep(1.2); pg.keyboard.press("Enter"); time.sleep(.6)
        pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P); pg.click("button.botao")
        pg.wait_for_selector(".cartao img", timeout=20000)
        pg.evaluate(f"location.hash = '#/ver/{ID}?t=600000000'")
        time.sleep(5); r["5s"] = estado(); time.sleep(13); r["18s"] = estado()
        pg.screenshot(path=f"/w/shots/heisuca/guarda_{CANAL}_{int(FALSO)}.png")
        pg.keyboard.press("Escape"); time.sleep(3)
    except Exception as e: r["falha"] = str(e)[:300]
    r["api"] = api; r["erros"] = erros
    b.close()
print(json.dumps(r, ensure_ascii=False, indent=1))
