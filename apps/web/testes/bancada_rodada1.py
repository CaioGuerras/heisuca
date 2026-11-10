#!/usr/bin/env python3
# Bancada focada da rodada 1 (recomendações 2, 3, 17, 19, 20 e 21 de PERGUNTAS_RODADA1.md + cor do selo).
# Serve DIST localmente; só leitura no servidor (posição salva e capítulos são simulados na resposta, nada grava no Jellyfin).
import functools, http.server, json, os, sys, threading, time
from playwright.sync_api import sync_playwright

DIST = os.environ.get("DIST", "/novo"); SAIDA = os.environ.get("SAIDA", "/w/shots/site_novo")
SERVIDOR = os.environ.get("SERVIDOR", "netflix.docaio.com.br"); U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
PORTA = 8792; BASE = f"http://127.0.0.1:{PORTA}/"
PERFIS = {
    "desk": {"viewport": {"width": 1440, "height": 900}},
    "cel": {"viewport": {"width": 915, "height": 412}, "is_mobile": True, "has_touch": True,
            "user_agent": "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0 Mobile Safari/537.36"},
}


class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass


srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(H, directory=DIST))
threading.Thread(target=srv.serve_forever, daemon=True).start()
JS_API = """async ({caminho}) => { const s = JSON.parse(localStorage.getItem('heisuca.sessao'));
  const h = { Authorization: `MediaBrowser Client="Heisuca", Device="Bancada", DeviceId="bancada", Version="0", Token="${s.token}"` };
  return fetch(`${s.servidor}${caminho.replaceAll('{u}', s.usuarioId)}`, { headers: h }).then(x => x.json()); }"""


def login(pg):
    pg.goto(BASE); pg.wait_for_selector(".entrada input[type=url]", timeout=30000)
    pg.fill(".entrada input[type=url]", SERVIDOR); pg.wait_for_selector(".entrada-servidor", timeout=15000)
    pg.fill(".entrada input[autocomplete=username]", U); pg.fill(".entrada input[type=password]", P); pg.click(".entrada-botao")
    pg.wait_for_selector(".transicao", timeout=30000); pg.wait_for_selector(".transicao", state="detached", timeout=30000)


def api(pg, caminho): return pg.evaluate(JS_API, {"caminho": caminho})


def selo(ctx):
    pg = ctx.new_page(); t0 = time.time(); pg.goto(BASE); cor = None; nasceu = sumiu = None
    for _ in range(600):
        e = pg.evaluate("""() => { const f = document.querySelector('.selo-fundo'); const t = document.querySelector('.transicao');
          return { cor: f ? getComputedStyle(f).fill : null, t: !!t }; }""")
        cor = cor or e["cor"]
        if e["t"] and nasceu is None: nasceu = time.time() - t0
        if nasceu is not None and not e["t"]: sumiu = time.time() - t0; break
        time.sleep(0.02)
    pg.close()
    return {"cor": cor, "transicao_comeca_s": round(nasceu or -1, 2), "home_s": round(sumiu or -1, 2)}


def forma(ctx):
    # 1 s antes do fim da transição: a máscara no CSS em uso diz se é círculo ou retângulo
    pg = ctx.new_page(); pg.goto(BASE); ultimo = None
    for _ in range(600):
        e = pg.evaluate("""() => { const t = document.querySelector('.transicao'); if (!t) return null;
          const vis = [...t.querySelectorAll('*')].map(x => { const c = getComputedStyle(x); return c.clipPath; }).filter(x => x && x !== 'none');
          const r = [...t.querySelectorAll('*')].map(x => getComputedStyle(x).borderRadius).filter(x => x && x !== '0px');
          return { clip: vis[0] || null, raio: r[0] || null, an: t.getAnimations({ subtree: true }).map(a => a.effect.getKeyframes().map(k => k.clipPath || '').filter(Boolean).join(' > ').slice(0, 90)).filter(Boolean)[0] || null }; }""")
        if e and (e["an"] or e["clip"]): ultimo = e
        if ultimo and e is None: break
        time.sleep(0.02)
    pg.close(); return ultimo


res = {}; falhas = []
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox", "--autoplay-policy=no-user-gesture-required"])
    for perfil, cfg in PERFIS.items():
        ctx = b.new_context(**cfg); pg = ctx.new_page(); erros = []
        pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
        pg.add_init_script("try{sessionStorage.setItem('heisuca.abriu','1')}catch(e){}")
        login(pg); r = {}
        r["selo"] = selo(ctx); r["forma"] = forma(ctx)
        # 17: episódio sem posição (Reproduzir) e o mesmo com posição simulada na resposta (Continuar)
        sid = api(pg, "/Items?userId={u}&recursive=true&includeItemTypes=Series&searchTerm=Aoashi&limit=1")["Items"][0]["Id"]
        pg.goto(BASE + f"#/t/{sid}"); pg.wait_for_function("[...document.querySelectorAll('button')].some(x => /^\\s*\\S*\\s*(Continuar|Reproduzir)/.test(x.textContent))", timeout=45000); time.sleep(1.5)
        r["rotulo_real"] = pg.evaluate("[...document.querySelectorAll('button')].map(x => x.textContent.trim()).filter(x => /(Continuar|Reproduzir)/.test(x))[0] || null")

        def com_posicao(rota):
            resp = rota.fetch()
            try: d = resp.json()
            except Exception: return rota.fulfill(response=resp)
            def marca(x):
                if isinstance(x, dict):
                    if x.get("Type") == "Episode": x.setdefault("UserData", {})["PlaybackPositionTicks"] = 3000000000
                    for v in x.values(): marca(v)
                elif isinstance(x, list):
                    for v in x: marca(v)
            marca(d); rota.fulfill(response=resp, json=d)
        ctx.route("**/Shows/**", com_posicao); ctx.route("**/Items**", com_posicao)
        pg2 = ctx.new_page(); pg2.add_init_script("try{sessionStorage.setItem('heisuca.abriu','1')}catch(e){}"); pg2.goto(BASE + f"#/t/{sid}"); pg2.wait_for_function("[...document.querySelectorAll('button')].some(x => /^\\s*\\S*\\s*(Continuar|Reproduzir)/.test(x.textContent))", timeout=45000); time.sleep(2.5)
        r["rotulo_com_posicao"] = pg2.evaluate("[...document.querySelectorAll('button')].map(x => x.textContent.trim()).filter(x => /(Continuar|Reproduzir)/.test(x))[0] || null")
        pg2.close(); ctx.unroute("**/Shows/**"); ctx.unroute("**/Items**")

        # 19: contagem do fim e Cancelar
        ep = api(pg, f"/Shows/{sid}/Episodes?userId={{u}}&limit=1")["Items"][0]
        pg.goto(BASE + f"#/ver/{ep['Id']}"); pg.wait_for_function("(() => { const v = document.querySelector('video'); return v && v.videoWidth > 0 })()", timeout=60000)
        # 21: volume
        time.sleep(1); pg.mouse.move(400, 200); time.sleep(.4)
        r["volume_visivel"] = pg.evaluate("(() => { const x = document.querySelector('.player-vol'); return !!x && x.getBoundingClientRect().width > 0 && getComputedStyle(x).display !== 'none' })()")
        if perfil == "desk":
            pg.evaluate("(() => { const x = document.querySelector('.player-vol'); const s = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set; s.call(x, '0.4'); x.dispatchEvent(new Event('input', { bubbles: true })); })()")
            time.sleep(.3); r["volume_aplicado"] = pg.evaluate("document.querySelector('video').volume")
        # o fim real: dispara 'ended' no elemento (buscar no fim do HLS transcodificado depende do servidor)
        pg.evaluate("document.querySelector('video').dispatchEvent(new Event('ended'))")
        try:
            pg.wait_for_selector(".player-cancelar", timeout=8000)
            a = pg.inner_text(".player-proximo small"); time.sleep(2.2); c = pg.inner_text(".player-proximo small")
            pg.screenshot(path=f"{SAIDA}/rodada1_contagem_{perfil}.png")
            pg.click(".player-cancelar"); time.sleep(1.5)
            r["contagem"] = {"antes": a, "depois": c, "cancelar_some": pg.query_selector(".player-cancelar") is None, "fixo": pg.inner_text(".player-proximo small")}
        except Exception as e: r["contagem"] = {"erro": str(e)[:160]}

        # 20: filme, "Pular créditos" encerra e volta ao título (tipo e capítulo simulados na resposta)
        pg.goto(BASE + "#/"); time.sleep(1.5)
        filme = ep  # arquivo já aquecido; filme de sorteio pode dormir no Drive e o que se testa aqui é a regra do botão

        def com_creditos(rota):
            resp = rota.fetch()
            try: d = resp.json()
            except Exception: return rota.fulfill(response=resp)
            if isinstance(d, dict) and d.get("Id") == filme["Id"]:
                d["Type"] = "Movie"; d["Chapters"] = [{"Name": "Filme", "StartPositionTicks": 0}, {"Name": "Credits", "StartPositionTicks": 20000000}]
            rota.fulfill(response=resp, json=d)
        ctx.route(f"**/Items/{filme['Id']}**", com_creditos)
        pg.goto(BASE + f"#/ver/{filme['Id']}"); pg.wait_for_function("(() => { const v = document.querySelector('video'); return v && v.videoWidth > 0 && v.currentTime > 2.2 })()", timeout=60000)
        try:
            pg.wait_for_selector(".player-pular", timeout=8000); txt = pg.inner_text(".player-pular"); pg.click(".player-pular"); time.sleep(2)
            r["pular_filme"] = {"botao": txt, "hash": pg.evaluate("location.hash"), "video_saiu": pg.query_selector("video") is None}
        except Exception as e: r["pular_filme"] = {"erro": str(e)[:160]}
        r["erros"] = erros; res[perfil] = r
        ctx.unroute_all(behavior="ignoreErrors")
        # a sessão de teste não fica aberta no Jellyfin (nem o token válido)
        pg.evaluate(JS_API.replace("{ headers: h }).then(x => x.json())", "{ method: 'POST', headers: h }).then(x => x.status)"), {"caminho": "/Sessions/Logout"})
        ctx.close()
    b.close()
srv.shutdown()
print(json.dumps(res, ensure_ascii=False, indent=1))
