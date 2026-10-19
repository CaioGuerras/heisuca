"""Benchmark de Comparação: CGFLIX Web (jellyfin-web oficial modificado) vs Heisuca Web (escrito do zero)

Executado via Playwright no container de bancada cgflix-bench-chrome na VPS.
Mede tempos reais de:
1. Cold Start e tamanho de transferência de rede
2. DOMContentLoaded e Load event
3. Tempo do submit de login até a Home pronta (10+ pôsteres renderizados)
4. Tamanho da árvore DOM e consumo de memória JS Heap
5. Quantidade de requisições de rede
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

URL_BASE = "https://netflix.docaio.com.br"
U = os.environ.get("JF_USER", "caioguerras")
P = os.environ.get("JF_PIN", "")

def medir_cgflix(ctx):
    pg = ctx.new_page()
    rede = {"bytes": 0, "reqs": 0}
    erros = []
    pg.on("requestfinished", lambda req: (
        rede.update({"reqs": rede["reqs"] + 1, "bytes": rede["bytes"] + (req.response().headers.get("content-length") and int(req.response().headers["content-length"]) or 0)})
        if req.response() else None
    ))
    pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:150]))

    t0 = time.time()
    pg.goto(f"{URL_BASE}/web/index.html#/login", wait_until="networkidle", timeout=60000)
    tempo_login_tela = round((time.time() - t0) * 1000)

    perf = pg.evaluate("""() => {
        const n = performance.getEntriesByType('navigation')[0] || {};
        return {
            ttfb: Math.round(n.responseStart || 0),
            dcl: Math.round(n.domContentLoadedEventEnd || 0),
            load: Math.round(n.loadEventEnd || 0)
        };
    }""")

    # Preenche login manual
    pg.evaluate("() => { const b = [...document.querySelectorAll('.btnManual')].find(e => e.offsetParent); if (b) b.click(); }")
    pg.wait_for_selector("#txtManualName", state="visible", timeout=20000)
    pg.fill("#txtManualName", U)
    pg.fill("#txtManualPassword", P)

    t_submit = time.time()
    pg.press("#txtManualPassword", "Enter")
    pg.wait_for_url("**/home**", timeout=45000)
    pg.wait_for_function("() => [...document.querySelectorAll('.cardImageContainer')].filter(e => getComputedStyle(e).backgroundImage.startsWith('url')).length >= 10", timeout=45000)
    tempo_home = round((time.time() - t_submit) * 1000)

    dom_nodes = pg.evaluate("() => document.querySelectorAll('*').length")
    js_heap = pg.evaluate("() => window.performance && window.performance.memory ? Math.round(window.performance.memory.usedJSHeapSize / (1024 * 1024) * 10) / 10 : null")

    pg.close()
    return {
        "app": "CGFLIX Web (jellyfin-web)",
        "ttfb_ms": perf["ttfb"],
        "dcl_ms": perf["dcl"],
        "load_ms": perf["load"],
        "tempo_ate_login_ms": tempo_login_tela,
        "tempo_login_ate_home_ms": tempo_home,
        "dom_elementos_count": dom_nodes,
        "js_heap_mb": js_heap,
        "requisicoes_feitas": rede["reqs"],
        "kb_transferidos": round(rede["bytes"] / 1024),
        "erros_console": len(erros)
    }

def medir_heisuca(ctx):
    pg = ctx.new_page()
    rede = {"bytes": 0, "reqs": 0}
    erros = []
    pg.on("requestfinished", lambda req: (
        rede.update({"reqs": rede["reqs"] + 1, "bytes": rede["bytes"] + (req.response().headers.get("content-length") and int(req.response().headers["content-length"]) or 0)})
        if req.response() else None
    ))
    pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:150]))

    t0 = time.time()
    pg.goto(f"{URL_BASE}/__heisuca/", wait_until="networkidle", timeout=60000)
    # pula abertura se houver
    time.sleep(1.2)
    pg.keyboard.press("Enter")
    pg.wait_for_selector(".entrar-caixa", timeout=15000)
    tempo_login_tela = round((time.time() - t0) * 1000)

    perf = pg.evaluate("""() => {
        const n = performance.getEntriesByType('navigation')[0] || {};
        return {
            ttfb: Math.round(n.responseStart || 0),
            dcl: Math.round(n.domContentLoadedEventEnd || 0),
            load: Math.round(n.loadEventEnd || 0)
        };
    }""")

    pg.fill("input[autocomplete=username]", U)
    pg.fill("input[type=password]", P)

    t_submit = time.time()
    pg.click("button.botao")
    pg.wait_for_selector(".cartao img", timeout=30000)
    # Espera ao menos 10 capas renderizadas
    pg.wait_for_function("() => [...document.querySelectorAll('.cartao img')].filter(i => i.complete && i.naturalWidth > 0).length >= 10", timeout=30000)
    tempo_home = round((time.time() - t_submit) * 1000)

    dom_nodes = pg.evaluate("() => document.querySelectorAll('*').length")
    js_heap = pg.evaluate("() => window.performance && window.performance.memory ? Math.round(window.performance.memory.usedJSHeapSize / (1024 * 1024) * 10) / 10 : null")

    pg.close()
    return {
        "app": "Heisuca Web (Novo Site)",
        "ttfb_ms": perf["ttfb"],
        "dcl_ms": perf["dcl"],
        "load_ms": perf["load"],
        "tempo_ate_login_ms": tempo_login_tela,
        "tempo_login_ate_home_ms": tempo_home,
        "dom_elementos_count": dom_nodes,
        "js_heap_mb": js_heap,
        "requisicoes_feitas": rede["reqs"],
        "kb_transferidos": round(rede["bytes"] / 1024),
        "erros_console": len(erros)
    }

def main():
    print("Iniciando benchmark de disputa (CGFLIX Web vs Heisuca Web)...")
    res = {}
    with sync_playwright() as p:
        b = p.chromium.launch(channel="chrome", args=["--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"])
        
        # Teste 1: CGFLIX Web
        ctx1 = b.new_context(viewport={"width": 1440, "height": 900}, device_scale_factor=1.0)
        res["cgflix"] = medir_cgflix(ctx1)
        ctx1.close()
        
        time.sleep(2)
        
        # Teste 2: Heisuca Web
        ctx2 = b.new_context(viewport={"width": 1440, "height": 900}, device_scale_factor=1.0)
        res["heisuca"] = medir_heisuca(ctx2)
        ctx2.close()
        
        b.close()

    print(json.dumps(res, ensure_ascii=False, indent=2))
    with open("/w/out/benchmark_disputa.json", "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    main()
