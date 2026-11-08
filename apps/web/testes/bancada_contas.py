"""Heisuca Web — bancada do lado da conta (Visão, noite 07→08/11). Roda no contêiner cgflix-bench-chrome da VPS:
  docker run --rm --network host -v /root/cgflix-bench:/w -w /w/noite --env-file .jf_teste.env \
    -e DIST=/w/noite/contas/dist -e SAIDA=/w/noite/shots/contas cgflix-bench-chrome:latest python3 contas/bancada_contas.py
Entra com a conta da bancada e fotografa: menu do usuário (aberto, foco, Esc, reduzir movimento), Minha conta (com erro de
validação local, sem enviar nada ao servidor), Como usar, Baixar os apps, Sobre; em 412 px (cel), 360 px e 1440 px, Roxo e
Verde. Mede rolagem lateral e contraste AA do texto. Fecha a tela §3.4 com um navegador "capado" (sem IntersectionObserver).
NUNCA salva senha nem foto: a conta é compartilhada.
"""
import functools, http.server, json, os, threading, time
from playwright.sync_api import sync_playwright

DIST = os.environ.get("DIST", "/w/noite/contas/dist")
SAIDA = os.environ.get("SAIDA", "/w/noite/shots/contas")
SERVIDOR = os.environ.get("SERVIDOR", "netflix.docaio.com.br")
U, P = os.environ["JF_USER"], os.environ.get("JF_PIN", "")
PORTA = 8791
os.makedirs(SAIDA, exist_ok=True)

class Silencioso(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORTA), functools.partial(Silencioso, directory=DIST))
threading.Thread(target=srv.serve_forever, daemon=True).start()
URL = f"http://127.0.0.1:{PORTA}/"

ANDROID = ("Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) "
           "Chrome/141.0.0.0 Mobile Safari/537.36")
PERFIS = {
    "cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
    "c360": dict(viewport={"width": 360, "height": 780}, device_scale_factor=2, is_mobile=True, has_touch=True, user_agent=ANDROID),
    "desk": dict(viewport={"width": 1440, "height": 900}),
}

# contraste AA de todo nó de texto visível em .pagina-corpo (fundo = primeira cor opaca subindo na árvore)
CONTRASTE = r"""(() => {
  const rgb = s => (s.match(/[\d.]+/g) || []).map(Number);
  const lum = ([r, g, b]) => { const f = c => { c /= 255; return c <= .03928 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4); }; return .2126 * f(r) + .7152 * f(g) + .0722 * f(b); };
  // fundo efetivo: compõe as camadas translúcidas (ex.: pílula clara a 86 %) sobre a primeira opaca abaixo delas
  const fundo = el => { const camadas = [];
    for (let e = el; e; e = e.parentElement) { const c = rgb(getComputedStyle(e).backgroundColor); if (c.length < 3) continue;
      const a = c[3] === undefined ? 1 : c[3]; if (a === 0) continue; camadas.push([c[0], c[1], c[2], a]); if (a >= 1) break; }
    let base = camadas.length && camadas[camadas.length - 1][3] >= 1 ? camadas.pop().slice(0, 3) : rgb(getComputedStyle(document.documentElement).backgroundColor).slice(0, 3);
    if (base.length < 3) base = [0, 0, 0];
    while (camadas.length) { const [r, g, b, a] = camadas.pop(); base = [r * a + base[0] * (1 - a), g * a + base[1] * (1 - a), b * a + base[2] * (1 - a)]; }
    return base; };
  const ruins = []; let min = 99, n = 0;
  const w = document.createTreeWalker(document.querySelector('.pagina') || document.body, NodeFilter.SHOW_TEXT);
  while (w.nextNode()) { const t = w.currentNode, el = t.parentElement; if (!t.textContent.trim() || !el) continue;
    const r = el.getBoundingClientRect(); if (!r.width || !r.height || el.closest('[hidden],.visualmente-oculto,.icone')) continue;
    const cs = getComputedStyle(el); if (cs.visibility === 'hidden' || +cs.opacity === 0) continue;
    const a = lum(rgb(cs.color)), b = lum(fundo(el)), k = (Math.max(a, b) + .05) / (Math.min(a, b) + .05);
    const grande = parseFloat(cs.fontSize) >= 24 || (parseFloat(cs.fontSize) >= 18.66 && +cs.fontWeight >= 700);
    n++; min = Math.min(min, k); if (k < (grande ? 3 : 4.5)) ruins.push(`${t.textContent.trim().slice(0, 40)} = ${k.toFixed(2)}`); }
  return { textos: n, minimo: +min.toFixed(2), abaixo_AA: ruins.slice(0, 12) };
})()"""
LATERAL = "document.documentElement.scrollWidth - innerWidth"

res = {}
def foto(pg, nome, inteira=False):
    pg.screenshot(path=f"{SAIDA}/{nome}.png", full_page=inteira)

def entrar(pg):
    pg.goto(URL); pg.wait_for_selector(".entrada.pronta", timeout=15000)
    pg.fill(".entrada input[type=url]", SERVIDOR); pg.wait_for_selector(".entrada-servidor", timeout=15000)
    pg.fill(".entrada input[autocomplete=username]", U); pg.fill(".entrada input[type=password]", P)
    pg.click(".entrada-botao")
    try:
        pg.wait_for_selector(".transicao", timeout=15000)
        pg.wait_for_selector(".transicao", state="detached", timeout=20000)
        pg.wait_for_selector(".ilha-eu", timeout=15000); time.sleep(0.8)
    except Exception:
        foto(pg, "ERRO_entrar"); print("ERRO_entrar:", pg.evaluate("document.body.innerText.slice(0, 400)")); raise

def pagina(pg, rota, espera=".pagina-corpo"):
    pg.evaluate(f"location.hash = '{rota}'"); pg.wait_for_selector(espera, timeout=10000); time.sleep(0.9)

with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", args=["--no-sandbox"])
    for tema in ("roxo", "verde"):
        for perfil in ("cel", "c360", "desk"):
            if tema == "verde" and perfil == "c360": continue
            chave = f"{perfil}_{tema}"; r = res[chave] = {"erros": []}
            ctx = b.new_context(**PERFIS[perfil], color_scheme="light" if tema == "verde" else "dark")
            ctx.add_init_script(f"try{{localStorage.setItem('heisuca.tema','{tema}');sessionStorage.setItem('heisuca.abriu','1')}}catch(e){{}}")
            pg = ctx.new_page()
            pg.on("console", lambda m, r=r: m.type == "error" and r["erros"].append(m.text[:200]))
            pg.on("pageerror", lambda e, r=r: r["erros"].append(str(e)[:200]))
            entrar(pg)
            # menu do usuário: abre da foto, origem da animação, foco preso, Esc devolve o foco
            pg.click(".ilha-eu"); time.sleep(0.08); foto(pg, f"{chave}_menu_abrindo"); time.sleep(0.5); foto(pg, f"{chave}_menu")
            r["menu"] = pg.evaluate("""(() => { const f = document.querySelector('.folha.mu'), cs = getComputedStyle(f);
              return { itens: [...f.querySelectorAll('.mu-item strong')].map(x => x.textContent), origem: f.style.transformOrigin,
                duracao: cs.animationDuration, foco: document.activeElement.className }; })()""")
            for _ in range(12): pg.keyboard.press("Tab")
            r["menu"]["foco_apos_12_tabs_dentro"] = pg.evaluate("!!document.activeElement.closest('.folha.mu')")
            pg.keyboard.press("ArrowDown"); r["menu"]["seta"] = pg.evaluate("document.activeElement.textContent.trim().slice(0, 30)")
            pg.keyboard.press("Escape"); time.sleep(0.5)
            r["menu"]["foco_apos_esc"] = pg.evaluate("document.activeElement.className")
            r["menu"]["fechado"] = pg.evaluate("!document.querySelector('.folha.mu')")
            for rota, nome in (("#/conta", "conta"), ("#/ajuda", "ajuda"), ("#/apps", "apps"), ("#/sobre", "sobre")):
                pagina(pg, rota)
                if nome == "ajuda": pg.wait_for_selector(".ajuda-passo", timeout=8000); time.sleep(0.8)
                foto(pg, f"{chave}_{nome}"); foto(pg, f"{chave}_{nome}_inteira", inteira=True)
                r[nome] = {"lateral_px": pg.evaluate(LATERAL), "contraste": pg.evaluate(CONTRASTE)}
                if nome == "conta" and perfil != "desk":
                    # validação local (nada vai ao servidor): senhas diferentes e nova vazia com a atual digitada
                    campos = pg.query_selector_all(".campo-senha input")
                    if len(campos) == 3:
                        campos[0].fill("atual-falsa"); campos[1].fill("nova-1"); campos[2].fill("nova-2")
                        pg.click(".olho, .campo-olho"); pg.click(".conta-salvar"); time.sleep(0.3)
                        r[nome]["erro_iguais"] = pg.evaluate("[...document.querySelectorAll('.campo-erro')].map(e => e.textContent)")
                        foto(pg, f"{chave}_conta_erro", inteira=True)
                        campos[1].fill(""); campos[2].fill(""); pg.click(".conta-salvar"); time.sleep(0.3)
                        r[nome]["aviso_sem_senha"] = pg.evaluate("(document.querySelector('.conta-alerta')||{}).textContent || ''")
                        r[nome]["botao"] = pg.evaluate("document.querySelector('.conta-salvar').textContent")
                        foto(pg, f"{chave}_conta_sem_senha", inteira=True)
                    else: r[nome]["campos"] = len(campos)
                if nome == "ajuda" and perfil == "cel":
                    pg.click(".ajuda-passo:first-child .ajuda-feito"); time.sleep(0.6)
                    r[nome]["apos_marcar"] = pg.evaluate("document.querySelector('.ajuda-progresso').getAttribute('aria-label')")
                    foto(pg, f"{chave}_ajuda_marcado")
                    pg.click(".ajuda-passo:first-child .ajuda-feito"); time.sleep(0.3)  # desfaz
            ctx.close()
    # reduzir movimento: o balão abre sem animação
    ctx = b.new_context(**PERFIS["cel"], reduced_motion="reduce", color_scheme="dark")
    ctx.add_init_script("try{sessionStorage.setItem('heisuca.abriu','1')}catch(e){}")
    pg = ctx.new_page(); entrar(pg); pg.click(".ilha-eu"); time.sleep(0.05)
    res["reduzir_movimento"] = pg.evaluate("(() => { const f = document.querySelector('.folha.mu'); return { animacao: getComputedStyle(f).animationName, opacidade: getComputedStyle(f).opacity }; })()")
    foto(pg, "reduzir_movimento_menu_50ms"); ctx.close()
    # §3.4: navegador sem IntersectionObserver e sem variáveis de CSS (como uma TV capada), com UA de computador
    for nome, script in (("sem_io", "delete window.IntersectionObserver;"),
                         ("sem_var_css", "const s0 = CSS.supports.bind(CSS); CSS.supports = (a, b) => String(a).startsWith('--') ? false : s0(a, b);")):
        ctx = b.new_context(viewport={"width": 1280, "height": 720})
        ctx.add_init_script(script)
        pg = ctx.new_page(); erros = []; pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
        pg.goto(URL); time.sleep(1.5); foto(pg, f"tv_{nome}")
        info = pg.evaluate("(() => { const m = document.querySelector('main.sem-suporte'); return m ? { texto: m.innerText, faltando: m.dataset.faltando } : null; })()")
        if info: pg.click("main.sem-suporte a"); time.sleep(0.4); foto(pg, f"tv_{nome}_apps"); info["apps"] = pg.evaluate("document.querySelector('main.sem-suporte').innerText")
        res[f"tv_{nome}"] = {"tela": info, "erros": erros}
        ctx.close()
    # controle: navegador completo segue para a abertura normal
    ctx = b.new_context(viewport={"width": 1280, "height": 720}); pg = ctx.new_page(); pg.goto(URL); time.sleep(0.8)
    res["tv_controle"] = pg.evaluate("({ abertura: !!document.querySelector('main.abertura'), semSuporte: !!document.querySelector('main.sem-suporte') })")
    ctx.close()
    b.close()
srv.shutdown()
print(json.dumps(res, ensure_ascii=False, indent=1))
