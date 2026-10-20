"""Heisuca Web v2 — passa por todas as telas com o servidor de verdade (contêiner cgflix-bench-chrome, --env-file .jf_teste.env).
Para cada tela: print, erros de console e se a tela tem conteúdo (não ficou em branco). Uso: python3 bancada_rotas_v2.py [cel|desk]"""
import functools, http.server, json, os, sys, threading, time
from playwright.sync_api import sync_playwright
DIST = os.environ.get("DIST", "/w/heisuca_v2/dist"); SAIDA = os.environ.get("SAIDA", "/w/shots/heisuca_v2/rotas")
SERVIDOR = os.environ.get("SERVIDOR", "netflix.docaio.com.br"); U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
os.makedirs(SAIDA, exist_ok=True); PORTA = 8792
class S(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(S, directory=DIST)); threading.Thread(target=srv.serve_forever, daemon=True).start()
ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID), "desk": dict(viewport={"width": 1440, "height": 900})}
perfil = sys.argv[1] if len(sys.argv) > 1 else "cel"
res = {}
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox"]); ctx = b.new_context(**PERFIS[perfil])
    ctx.add_init_script("try{sessionStorage.setItem('heisuca.abriu','1')}catch(e){}")
    pg = ctx.new_page(); erros = []
    pg.on("console", lambda m: m.type == "error" and "__seerr" not in m.text and "ERR_FAILED" not in m.text and erros.append(m.text[:200]))
    pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
    pg.goto(f"http://127.0.0.1:{PORTA}/"); pg.wait_for_selector(".entrada input[type=url]", timeout=15000)
    pg.fill(".entrada input[type=url]", SERVIDOR); pg.wait_for_selector(".entrada-servidor", timeout=15000)
    pg.fill(".entrada input[autocomplete=username]", U); pg.fill(".entrada input[type=password]", P); pg.click(".entrada-botao")
    pg.wait_for_selector(".transicao", timeout=20000); pg.wait_for_selector(".transicao", state="detached", timeout=20000)
    ids = pg.evaluate("""async () => { const s = JSON.parse(localStorage.getItem('heisuca.sessao'));
      const h = { Authorization: `MediaBrowser Client="Heisuca", Device="Bancada", DeviceId="bancada", Version="0", Token="${s.token}"` };
      const j = u => fetch(s.servidor + u, { headers: h }).then(x => x.json());
      const serie = (await j(`/Items?userId=${s.usuarioId}&recursive=true&includeItemTypes=Series&searchTerm=Deadwood&limit=1`)).Items[0];
      const filme = (await j(`/Items?userId=${s.usuarioId}&recursive=true&includeItemTypes=Movie&limit=1&sortBy=DateCreated&sortOrder=Descending`)).Items[0];
      const lib = (await j(`/UserViews?userId=${s.usuarioId}`)).Items[0];
      return { serie: serie && serie.Id, filme: filme && filme.Id, lib: lib && lib.Id }; }""")
    rotas = [("titulo_serie", f"#/t/{ids['serie']}"), ("titulo_filme", f"#/t/{ids['filme']}"), ("biblioteca", f"#/b/{ids['lib']}"), ("favoritos", "#/fav"),
             ("busca", "#/busca"), ("conta", "#/conta"), ("ajuda", "#/ajuda"), ("apps", "#/apps"), ("sobre", "#/sobre"), ("apoiar", "#/apoiar")]
    for nome, h in rotas:
        antes = len(erros); pg.evaluate(f"location.hash = '{h}'"); time.sleep(2.6)
        if nome == "busca":
            pg.fill("input[type=search], .busca input", "dead"); time.sleep(2.2)
        texto = pg.evaluate("document.querySelector('#app').innerText.trim().length")
        pg.screenshot(path=f"{SAIDA}/{perfil}_{nome}.png")
        res[nome] = {"texto": texto, "erros": erros[antes:]}
    ctx.close(); b.close()
srv.shutdown(); print(json.dumps(res, ensure_ascii=False, indent=1))
