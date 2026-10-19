"""Heisuca Web v2 — bancada do PLAYER com o servidor de verdade (contêiner cgflix-bench-chrome, --env-file .jf_teste.env).

Entra com a conta da bancada, acha um episódio (BUSCA, padrão "Aoashi") e toca no Chrome (canal chrome: tem H.264).
Confere: método (direto ou HLS pelo servidor), quadros de vídeo saindo (videoWidth e totalVideoFrames), o tempo andando,
erros no console, e que ao sair o vídeo para. Uma tela por vez (o servidor limita 2 telas por conta).

Uso: python3 bancada_player_v2.py [cel|desk|tudo] [--busca "Aoashi"]
"""
import functools, http.server, json, os, sys, threading, time
from playwright.sync_api import sync_playwright

DIST = os.environ.get("DIST", "/w/heisuca_v2/dist"); SAIDA = os.environ.get("SAIDA", "/w/shots/heisuca_v2")
SERVIDOR = os.environ.get("SERVIDOR", "netflix.docaio.com.br"); U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
BUSCA = sys.argv[sys.argv.index("--busca") + 1] if "--busca" in sys.argv else "Aoashi"
PORTA = 8791
os.makedirs(SAIDA, exist_ok=True)
class Silencioso(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(Silencioso, directory=DIST))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 915, "height": 412}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
          "desk": dict(viewport={"width": 1440, "height": 900})}
modo = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "tudo"
res = {}
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox", "--autoplay-policy=no-user-gesture-required"])
    for perfil in (["desk", "cel"] if modo == "tudo" else [modo]):
        ctx = b.new_context(**PERFIS[perfil])
        ctx.add_init_script("try{sessionStorage.setItem('heisuca.abriu','1')}catch(e){}")
        pg = ctx.new_page(); erros = []; pedidos = []
        pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:240]))
        pg.on("pageerror", lambda e: erros.append(str(e)[:240]))
        pg.on("request", lambda r: ("PlaybackInfo" in r.url or ".m3u8" in r.url or "/stream" in r.url) and pedidos.append(r.url.split("?")[0][-70:]))
        pg.goto(f"http://127.0.0.1:{PORTA}/")
        pg.wait_for_selector(".entrada input[type=url]", timeout=15000)
        pg.fill(".entrada input[type=url]", SERVIDOR); pg.wait_for_selector(".entrada-servidor", timeout=15000)
        pg.fill(".entrada input[autocomplete=username]", U); pg.fill(".entrada input[type=password]", P); pg.click(".entrada-botao")
        pg.wait_for_selector(".transicao", timeout=20000); pg.wait_for_selector(".transicao", state="detached", timeout=20000)
        ep = pg.evaluate("""async (busca) => {
          const s = JSON.parse(localStorage.getItem('heisuca.sessao')); const h = { Authorization: `MediaBrowser Client="Heisuca", Device="Bancada", DeviceId="bancada", Version="0", Token="${s.token}"` };
          const r = await fetch(`${s.servidor}/Items?userId=${s.usuarioId}&recursive=true&includeItemTypes=Series&searchTerm=${encodeURIComponent(busca)}&limit=1`, { headers: h }).then(x => x.json());
          const e = await fetch(`${s.servidor}/Shows/${r.Items[0].Id}/Episodes?userId=${s.usuarioId}&limit=1`, { headers: h }).then(x => x.json());
          return { id: e.Items[0].Id, nome: `${e.Items[0].SeriesName} ${e.Items[0].Name}` };
        }""", BUSCA)
        t0 = time.time(); pg.evaluate(f"location.hash = '#/ver/{ep['id']}'")
        # espera o 1º quadro
        ok = False
        for _ in range(40):
            time.sleep(0.5)
            q = pg.evaluate("(() => { const v = document.querySelector('video'); return v ? { w: v.videoWidth, t: v.currentTime, q: v.getVideoPlaybackQuality?.().totalVideoFrames || 0, src: (v.currentSrc || '').slice(0, 5) } : null })()")
            if q and q["w"] > 0 and q["q"] > 5: ok = True; break
        primeiro = round(time.time() - t0, 1)
        time.sleep(4)
        q2 = pg.evaluate("(() => { const v = document.querySelector('video'); return { w: v.videoWidth, h: v.videoHeight, t: Math.round(v.currentTime*10)/10, q: v.getVideoPlaybackQuality?.().totalVideoFrames || 0, perdidos: v.getVideoPlaybackQuality?.().droppedVideoFrames || 0, src: (v.currentSrc || '').slice(0, 5), pausado: v.paused } })()")
        # legenda de texto por fora (<track>): liga a 1ª e confere se as falas carregaram (site e servidor em endereços diferentes)
        leg = pg.evaluate("""async () => { const v = document.querySelector('video'); const t = [...v.textTracks];
          if (!t.length) return { faixas: 0 }; t.forEach((x, i) => x.mode = i ? 'disabled' : 'showing');
          await new Promise(r => setTimeout(r, 6000));
          const el = [...document.querySelectorAll('track')].map(x => ({ estado: x.readyState, modo: x.track.mode, falas: x.track.cues ? x.track.cues.length : null, host: (x.src || '').split('/')[2] }));
          return { faixas: t.length, rotulo: t[0].label, falas: t[0].cues ? t[0].cues.length : null, modo: t[0].mode, elementos: el, crossorigin: v.crossOrigin }; }""")
        pg.mouse.move(400, 200); time.sleep(0.3); pg.screenshot(path=f"{SAIDA}/player_{perfil}.png")
        pg.evaluate("location.hash = ''"); time.sleep(2.5)
        parou = pg.evaluate("!document.querySelector('video')")
        res[perfil] = {"episodio": ep["nome"], "tocou": ok, "primeiro_quadro_s": primeiro, "depois_4s": q2, "metodo": "HLS (servidor)" if q2["src"] == "blob:" else "direto",
                       "parou_ao_sair": parou, "legenda_texto": leg, "pedidos": pedidos[:6], "erros": erros}
        ctx.close(); time.sleep(3)
    b.close()
srv.shutdown()
print(json.dumps(res, ensure_ascii=False, indent=1))
