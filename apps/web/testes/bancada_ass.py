"""Heisuca: legenda ASS pelo JASSUB (sem conversão no servidor). Uso: bancada_ass.py <id> [segundos]. Conta da bancada."""
import json, os, sys, time
from playwright.sync_api import sync_playwright
URL = "https://netflix.docaio.com.br/__heisuca/"; ID = sys.argv[1]; T = int(sys.argv[2]) if len(sys.argv) > 2 else 300
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
r, erros, rede = {}, [], []
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox", "--autoplay-policy=no-user-gesture-required"])
    pg = b.new_page(viewport={"width": 1440, "height": 810})
    pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
    pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
    pg.on("response", lambda x: any(k in x.url for k in (".wasm", "Subtitles", "Attachments", "master.m3u8", "jassub"))
          and rede.append(f"{x.status} {x.headers.get('content-type','')[:24]} {x.url.split('?')[0].split('/')[-1][:40]}"))
    try:
        pg.goto(URL); time.sleep(1.2); pg.keyboard.press("Enter"); time.sleep(.6)
        pg.fill("input[autocomplete=username]", U); pg.fill("input[type=password]", P); pg.click("button.botao")
        pg.wait_for_selector(".cartao img", timeout=20000)
        pg.evaluate(f"location.hash = '#/ver/{ID}?t={T * 10_000_000}'"); time.sleep(8)
        pg.mouse.move(500, 400); pg.click('button[aria-label="Áudio e legendas"]'); time.sleep(.4)
        pg.locator(".player-menu section", has_text="Legendas").locator(".opcao", has_text="ASS").first.click()
        time.sleep(14)
        r["estado"] = pg.evaluate("""() => { const v = document.querySelector('.player video'); const c = document.querySelector('.player canvas');
            let tinta = null;
            if (c) { try { const g = document.createElement('canvas'); g.width = c.width; g.height = c.height; const x = g.getContext('2d'); x.drawImage(c, 0, 0);
                     const d = x.getImageData(0, 0, g.width, g.height).data; tinta = 0; for (let i = 3; i < d.length; i += 4) if (d[i]) tinta++; } catch (e) { tinta = String(e); } }
            return {t: Math.round(v.currentTime), pausado: v.paused, selo: document.querySelector('.player-selo')?.textContent || 'Direto',
                    canvas: c ? [c.width, c.height] : null, pixelsDesenhados: tinta}; }""")
        pg.screenshot(path="/w/shots/heisuca/ass.png")
    except Exception as ex:
        r["falha"] = str(ex)[:300]; pg.screenshot(path="/w/shots/heisuca/ass_falha.png")
    r["erros"], r["rede"] = erros, rede[:15]
    b.close()
print(json.dumps(r, ensure_ascii=False, indent=1))
