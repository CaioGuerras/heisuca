"""Heisuca Web v2 — bancada de telas (roda no contêiner cgflix-bench-chrome da VPS, com --env-file .jf_teste.env).

Serve a build (dist/) num servidor local do próprio contêiner, entra num servidor Jellyfin de verdade (SERVIDOR, padrão
o CGSERVER) com a conta da bancada e tira os prints de cada passo no celular (412×915, o tamanho dos prints do Caio) e no
computador. Os prints voltam para a Whatbox e o testes/lado_a_lado.py monta a comparação com ref/.

Uso: python3 bancada_v2.py [cel|desk|tudo] [--tema verde]   (a build tem de estar em /w/heisuca_v2/dist)
"""
import functools, http.server, json, os, sys, threading, time
from playwright.sync_api import sync_playwright

DIST = os.environ.get("DIST", "/w/heisuca_v2/dist")
SAIDA = os.environ.get("SAIDA", "/w/shots/heisuca_v2")
SERVIDOR = os.environ.get("SERVIDOR", "netflix.docaio.com.br")
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
PORTA = 8790
os.makedirs(SAIDA, exist_ok=True)

class Silencioso(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(Silencioso, directory=DIST))
threading.Thread(target=srv.serve_forever, daemon=True).start()

ANDROID = ("Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) "
           "Chrome/141.0.0.0 Mobile Safari/537.36")
PERFIS = {
    "cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
    "desk": dict(viewport={"width": 1440, "height": 900}),
}
modo = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "tudo"
tema = sys.argv[sys.argv.index("--tema") + 1] if "--tema" in sys.argv else "roxo"
res = {}

def foto(pg, nome, perfil, inteira=False):
    pg.screenshot(path=f"{SAIDA}/{perfil}_{tema}_{nome}.png", full_page=inteira)

with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox"])
    for perfil in (["cel", "desk"] if modo == "tudo" else [modo]):
        ctx = b.new_context(**PERFIS[perfil], color_scheme="dark" if tema != "verde" else "light")
        ctx.add_init_script(f"try{{localStorage.setItem('heisuca.tema','{tema}')}}catch(e){{}}")
        pg = ctx.new_page(); erros = []; tempos = {}
        pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:240]))
        pg.on("pageerror", lambda e: erros.append(str(e)[:240]))
        t0 = time.time()
        pg.goto(f"http://127.0.0.1:{PORTA}/"); time.sleep(1.2); foto(pg, "1_abertura", perfil)
        pg.wait_for_selector(".entrada.pronta", timeout=10000); tempos["entrada"] = round(time.time() - t0, 2)
        time.sleep(0.4); foto(pg, "2_entrada", perfil)
        pg.fill(".entrada input[type=url]", SERVIDOR)
        pg.wait_for_selector(".entrada-servidor", timeout=15000)
        pg.fill(".entrada input[autocomplete=username]", U); pg.fill(".entrada input[type=password]", P)
        foto(pg, "3_entrada_preenchida", perfil)
        t1 = time.time(); pg.click(".entrada-botao")
        pg.wait_for_selector(".transicao", timeout=10000); time.sleep(1.4); foto(pg, "4_transicao", perfil)
        pg.wait_for_selector(".transicao", state="detached", timeout=15000); tempos["transicao"] = round(time.time() - t1, 2)
        time.sleep(1.2); foto(pg, "5_inicio", perfil)
        pg.mouse.wheel(0, 700); time.sleep(0.9); foto(pg, "6_inicio_rolada", perfil)
        pg.evaluate("scrollTo(0, 0)"); time.sleep(0.5)
        foto(pg, "7_inicio_inteira", perfil, inteira=True)
        if pg.query_selector(".ilha-eu"):
            pg.click(".ilha-eu"); time.sleep(0.6); foto(pg, "8_menu_usuario", perfil)
            pg.keyboard.press("Escape"); time.sleep(0.4)
        res[perfil] = {"tempos_s": tempos, "erros": erros,
                       "fileiras": pg.evaluate("[...document.querySelectorAll('.fileira h2')].map(h => h.textContent)"),
                       "semImagem": pg.evaluate("[...document.querySelectorAll('.img img')].filter(i => i.complete && !i.naturalWidth).length"),
                       "cores": pg.evaluate("(() => { const c = getComputedStyle(document.documentElement); return ['--hs-pagina','--hs-texto','--hs-texto-2'].map(v => v + ' ' + c.getPropertyValue(v).trim()); })()")}
        ctx.close()
    b.close()
srv.shutdown()
print(json.dumps(res, ensure_ascii=False, indent=1))
