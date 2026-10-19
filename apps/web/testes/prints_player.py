#!/usr/bin/env python3
"""Prints do PLAYER contra o servidor falso (sessão E, PLANO §13): celular deitado (915×412) e computador (1440×900).

Pré-requisitos: como em prints_falso.py (servidor falso em 8097 e o site em 5173).
Uso: python3 testes/prints_player.py [--saida testes/comparacoes/e] [--temas roxo,verde] [--chromium CAMINHO]
Tira, por perfil e tema: carregando, controles com "Pular abertura" em 0:10, painel aberto, busca de legendas,
legenda baixada ligada, "Pular créditos" e o cartão de próximo episódio. Confere também os atalhos de teclado (computador).
"""
import argparse, json, os, time
from playwright.sync_api import sync_playwright

a = argparse.ArgumentParser()
a.add_argument("--site", default="http://127.0.0.1:5173")
a.add_argument("--falso", default="http://127.0.0.1:8097")
a.add_argument("--saida", default="testes/comparacoes/e")
a.add_argument("--temas", default="roxo,verde")
a.add_argument("--perfis", default="cel,desk")
# Deadwood T1:E1…E4, um por rodada: o servidor falso lembra a legenda "baixada" por item (reinicie-o antes de rodar de novo)
a.add_argument("--itens", default="21c52267bb6330b33bee76498af2a7c9,4d3c95d9c1e4ce7654f59d824415a843,b63fd9d33e5508cd2c214c2c3136c934,da63f578ed7e2d4207f57d711d6273dc")
a.add_argument("--chromium", default=None)
o = a.parse_args()
os.makedirs(o.saida, exist_ok=True)

ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 915, "height": 412}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
          "desk": dict(viewport={"width": 1440, "height": 900}),
          "empe": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID)}
resumo = {}
itens = o.itens.split(",")

def ir(pg, seg, tocar=False):
    pg.evaluate(f"""(() => {{ const v = document.querySelector('.player video'); v.currentTime = {seg}; {'v.play()' if tocar else 'v.pause()'}; }})()""")
    time.sleep(0.8)

def mostrar(pg):
    pg.mouse.move(400, 200); pg.mouse.move(420, 210); time.sleep(0.3)

with sync_playwright() as p:
    b = p.chromium.launch(executable_path=o.chromium, args=["--autoplay-policy=no-user-gesture-required"]) if o.chromium \
        else p.chromium.launch(args=["--autoplay-policy=no-user-gesture-required"])
    for perfil in o.perfis.split(","):
        for tema in o.temas.split(","):
            ctx = b.new_context(**PERFIS[perfil], color_scheme="light" if tema == "verde" else "dark")
            ctx.add_init_script(f"""try {{ sessionStorage.setItem('heisuca.abriu','1'); localStorage.setItem('heisuca.tema','{tema}'); }} catch (e) {{}}""")
            pg = ctx.new_page(); erros = []; checagens = {}
            pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
            pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
            pg.goto(o.site + "/")
            pg.wait_for_selector(".entrada input[type=url]", timeout=15000)
            pg.fill(".entrada input[type=url]", o.falso)
            pg.wait_for_selector(".entrada-servidor", timeout=10000)
            pg.fill(".entrada input[autocomplete=username]", "caioguerras")
            pg.click(".entrada-botao")
            pg.wait_for_function("document.querySelector('.casca') && !document.querySelector('.transicao')", timeout=20000)
            pre = f"{o.saida}/{perfil}_{tema}"
            item = itens[len(resumo) % len(itens)]

            # 1. carregando: segura o vídeo até o print para ver o selo
            presos = []
            pg.route("**/Videos/*/stream*", lambda r: presos.append(r))
            pg.evaluate(f"location.hash = '#/ver/{item}'")
            pg.wait_for_selector(".player-carregando"); pg.wait_for_timeout(1300)
            pg.screenshot(path=f"{pre}_1_carregando.png")
            for r in presos:
                try: r.continue_()
                except Exception: pass      # o navegador já desistiu desse pedido
            pg.unroute("**/Videos/*/stream*")
            pg.wait_for_selector(".player:not(.esperando)", timeout=20000)
            time.sleep(1.5)

            # 2. controles com "Pular abertura" em 0:10
            ir(pg, 10); mostrar(pg)
            checagens["pular_abertura_em_10s"] = pg.locator(".player-pular").inner_text() if pg.locator(".player-pular").count() else None
            pg.screenshot(path=f"{pre}_2_controles.png")
            ir(pg, 5)
            checagens["sem_botao_no_prologo"] = pg.locator(".player-pular").count() == 0

            # 3. painel aberto
            ir(pg, 50); mostrar(pg)
            pg.click(".player-base [aria-label='Áudio e legendas']"); time.sleep(0.6)
            pg.screenshot(path=f"{pre}_3_painel.png")
            # rola a coluna de legendas no celular para o fim (Buscar legendas)
            # 4. busca de legendas
            pg.click(".painel-buscar"); time.sleep(1.0)
            pg.screenshot(path=f"{pre}_4_busca.png")
            # 5. baixa a primeira PT-BR: o painel fecha e a legenda nova liga
            pg.click(".painel-resultado >> nth=0"); time.sleep(1.5)
            checagens["painel_fechou_ao_baixar"] = pg.locator(".painel").count() == 0
            checagens["legenda_ligada"] = pg.evaluate("Array.from(document.querySelector('.player video').textTracks).filter(t => t.mode === 'showing').map(t => t.label)")
            ir(pg, 20, tocar=True); time.sleep(1.2); pg.evaluate("document.querySelector('.player video').pause()"); mostrar(pg)
            pg.screenshot(path=f"{pre}_5_legenda_baixada.png")
            # painel fecha tocando fora
            pg.click(".player-base [aria-label='Áudio e legendas']"); time.sleep(0.4)
            pg.mouse.click(8, PERFIS[perfil]["viewport"]["height"] // 2); time.sleep(0.4)
            checagens["painel_fecha_tocando_fora"] = pg.locator(".painel").count() == 0

            # 6. créditos (último capítulo, série com próximo) e fim
            ir(pg, 84); mostrar(pg)
            checagens["pular_creditos_em_84s"] = pg.locator(".player-pular").inner_text() if pg.locator(".player-pular").count() else None
            pg.screenshot(path=f"{pre}_6_creditos.png")
            ir(pg, 89.0, tocar=True); time.sleep(2.5)
            pg.screenshot(path=f"{pre}_7_fim.png")
            checagens["cartao_proximo"] = pg.locator(".player-proximo").count() == 1

            if perfil == "desk":
                # atalhos: espaço, K, ←/→, M, Esc
                ir(pg, 40); pg.mouse.move(700, 450)
                v = "document.querySelector('.player video')"
                pg.keyboard.press("Space"); time.sleep(0.4); t1 = pg.evaluate(f"!{v}.paused")
                pg.keyboard.press("k"); time.sleep(0.3); t2 = pg.evaluate(f"{v}.paused")
                antes = pg.evaluate(f"{v}.currentTime"); pg.keyboard.press("ArrowRight"); time.sleep(0.3); depois = pg.evaluate(f"{v}.currentTime")
                pg.keyboard.press("ArrowLeft"); time.sleep(0.3); volta = pg.evaluate(f"{v}.currentTime")
                pg.keyboard.press("m"); m1 = pg.evaluate(f"{v}.muted"); pg.keyboard.press("m"); m2 = pg.evaluate(f"{v}.muted")
                checagens["teclado"] = {"espaco_toca": t1, "k_pausa": t2, "direita_+10": round(depois - antes, 1), "esquerda_-10": round(volta - depois, 1),
                                        "m_mudo": m1 and not m2}
                pg.keyboard.press("Escape"); time.sleep(0.8)
                checagens["esc_volta"] = pg.evaluate("location.hash")
            resumo[f"{perfil}_{tema}"] = {"erros": erros, **checagens}
            ctx.close()
    b.close()
print(json.dumps(resumo, ensure_ascii=False, indent=1))
