#!/usr/bin/env python3
"""Servidor Jellyfin FALSO para desenvolver e testar o Heisuca Web sem acesso a um servidor de verdade.

Responde a parte da API que o site usa, com dados reais gravados do CGSERVER (gravar.py → dados/dados.json + img/ + video/).
Qualquer usuário e senha entram (a senha "errada" dá 401, para testar o erro). Toca o vídeo de teste de 90 s com
capítulos Prólogo/Abertura/Episódio/Créditos, 2 áudios e legendas VTT/ASS. Seerr falso em /__seerr/.

Uso:  python3 servidor.py [porta=8097]      e no site: endereço  http://127.0.0.1:8097
Os dados ficam no ramo `falso-dados`:  git fetch origin falso-dados && git archive origin/falso-dados | tar -x -C <raiz do repo>
"""
import json, mimetypes, os, re, sys, time, urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RAIZ = Path(__file__).resolve().parent / "dados"
D = json.load(open(RAIZ / "dados.json", encoding="utf-8"))
ITENS = D["itens"]; U = D["usuario"]; TOKEN = "token-falso"
dados_usuario = {}            # visto/favorito alterados na sessão (memória)
legendas_baixadas = set()     # itens com a "legenda baixada" pelo Buscar legendas
qc_polls = {}
TICKS = 10_000_000
CAPITULOS_TESTE = [{"Name": "Prologue", "StartPositionTicks": 0}, {"Name": "Opening", "StartPositionTicks": 8 * TICKS},
                   {"Name": "Episode", "StartPositionTicks": 38 * TICKS}, {"Name": "Credits", "StartPositionTicks": 80 * TICKS}]

def item(i, completo=True):
    x = dict(ITENS[i])
    if i in dados_usuario: x["UserData"] = {**x.get("UserData", {}), **dados_usuario[i]}
    if x.get("Type") in ("Episode", "Movie"):
        x["Chapters"] = CAPITULOS_TESTE     # combina com o vídeo de teste (o pular abertura dá para testar de verdade)
    if not completo: x.pop("People", None); x.pop("MediaStreams", None)
    return x

def lista(ids, inicio=0, limite=None, completo=False):
    ids = [i for i in ids if i in ITENS]
    fatia = ids[inicio:inicio + limite] if limite else ids[inicio:]
    return {"Items": [item(i, completo) for i in fatia], "TotalRecordCount": len(ids), "StartIndex": inicio}

def fluxos(i):
    s = [{"Index": 0, "Type": "Video", "Codec": "h264", "Width": 960, "Height": 540, "Profile": "High", "RealFrameRate": 24,
          "BitRate": 300000, "VideoRange": "SDR", "AspectRatio": "16:9", "DisplayTitle": "540p H264 SDR", "IsDefault": True},
         {"Index": 1, "Type": "Audio", "Codec": "aac", "Language": "por", "Channels": 2, "ChannelLayout": "stereo", "SampleRate": 44100,
          "DisplayTitle": "Português (Brasil) - AAC - Estéreo - Padrão", "Title": "Português (Brasil)", "IsDefault": True},
         {"Index": 2, "Type": "Audio", "Codec": "aac", "Language": "jpn", "Channels": 2, "ChannelLayout": "stereo", "SampleRate": 44100,
          "DisplayTitle": "Japonês - AAC - Estéreo", "Title": "Japonês"},
         {"Index": 3, "Type": "Subtitle", "Codec": "webvtt", "Language": "por", "DisplayTitle": "Português (Brasil) - VTT", "IsExternal": True,
          "IsTextSubtitleStream": True, "DeliveryMethod": "External", "DeliveryUrl": f"/Videos/{i}/x/Subtitles/3/0/Stream.vtt"},
         {"Index": 4, "Type": "Subtitle", "Codec": "ass", "Language": "por", "DisplayTitle": "Português (Brasil) [Full] - ASS", "IsExternal": True,
          "IsTextSubtitleStream": True, "DeliveryMethod": "External", "DeliveryUrl": f"/Videos/{i}/x/Subtitles/4/0/Stream.ass"}]
    if i in legendas_baixadas:
        s.append({"Index": 5, "Type": "Subtitle", "Codec": "subrip", "Language": "por", "DisplayTitle": "Português (Brasil) - Open Subtitles",
                  "IsExternal": True, "IsTextSubtitleStream": True, "DeliveryMethod": "External", "DeliveryUrl": f"/Videos/{i}/x/Subtitles/3/0/Stream.vtt"})
    return s

class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, f, *a):
        if os.environ.get("FALSO_LOG"): sys.stderr.write("%s %s\n" % (self.command, self.path))

    def cors(self):
        o = self.headers.get("Origin")
        self.send_header("Access-Control-Allow-Origin", o or "*")
        self.send_header("Access-Control-Allow-Credentials", "true")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Emby-Authorization, Range")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Expose-Headers", "Content-Range, Content-Length")

    def responder(self, corpo=None, status=200, tipo="application/json"):
        dados = b"" if corpo is None else (corpo if isinstance(corpo, bytes) else json.dumps(corpo, ensure_ascii=False).encode())
        self.send_response(status if (corpo is not None or status != 200) else 204)
        self.cors(); self.send_header("Content-Type", tipo); self.send_header("Content-Length", str(len(dados)))
        self.send_header("Cache-Control", "no-store" if tipo == "application/json" else "max-age=86400")
        self.end_headers(); self.wfile.write(dados)

    def arquivo(self, caminho: Path, tipo=None):
        if not caminho.exists(): return self.responder({"erro": "não gravado"}, 404)
        dados = caminho.read_bytes()
        tipo = tipo or ("image/png" if dados[:4] == b"\x89PNG" else mimetypes.guess_type(caminho.name)[0] or "application/octet-stream")
        rng = self.headers.get("Range")
        if rng and (m := re.match(r"bytes=(\d*)-(\d*)", rng)):
            ini = int(m.group(1) or 0); fim = int(m.group(2)) if m.group(2) else len(dados) - 1
            fim = min(fim, len(dados) - 1); parte = dados[ini:fim + 1]
            self.send_response(206); self.cors(); self.send_header("Content-Type", tipo); self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Range", f"bytes {ini}-{fim}/{len(dados)}"); self.send_header("Content-Length", str(len(parte)))
            self.end_headers(); self.wfile.write(parte); return
        self.send_response(200); self.cors(); self.send_header("Content-Type", tipo); self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(len(dados))); self.send_header("Cache-Control", "max-age=86400"); self.end_headers(); self.wfile.write(dados)

    def corpo(self):
        n = int(self.headers.get("Content-Length") or 0)
        b = self.rfile.read(n) if n else b""
        try: return json.loads(b) if b else {}
        except Exception: return {}

    def do_OPTIONS(self):
        self.send_response(204); self.cors(); self.send_header("Content-Length", "0"); self.end_headers()

    def do_GET(self): self.rota("GET")
    def do_POST(self): self.rota("POST")
    def do_DELETE(self): self.rota("DELETE")

    def rota(self, metodo):
        u = urllib.parse.urlparse(self.path); p = u.path; q = {k.lower(): v[0] for k, v in urllib.parse.parse_qs(u.query).items()}
        if metodo == "POST" or metodo == "DELETE": corpo = self.corpo()
        auth = U["Id"]
        # ---- público ----
        if p == "/System/Info/Public": return self.responder({"Id": D["servidor"]["Id"], "ServerName": D["servidor"]["ServerName"], "Version": D["servidor"]["Version"], "ProductName": "Jellyfin Server", "StartupWizardCompleted": True})
        if p == "/QuickConnect/Enabled": return self.responder(True)
        if p == "/QuickConnect/Initiate": qc_polls["s"] = 0; return self.responder({"Code": "482913", "Secret": "segredo-falso"})
        if p == "/QuickConnect/Connect":
            qc_polls["s"] = qc_polls.get("s", 0) + 1     # "autoriza" na 3ª consulta (≈ 7 s)
            return self.responder({"Authenticated": qc_polls["s"] >= 3, "Code": "482913", "Secret": "segredo-falso"})
        if p in ("/Users/AuthenticateByName", "/Users/AuthenticateWithQuickConnect"):
            nome = corpo.get("Username") or U["Name"]
            if corpo.get("Pw") == "errada": return self.responder({"erro": "senha"}, 401)
            return self.responder({"AccessToken": TOKEN, "ServerId": D["servidor"]["Id"], "User": {"Id": U["Id"], "Name": nome, "PrimaryImageTag": U.get("PrimaryImageTag"), "HasPassword": True}})
        if p == "/cgflix/emalta.json": return self.responder(D["emalta"])
        if p == "/cgflix/embreve.json": return self.responder(D["embreve"])
        # ---- imagens e vídeo ----
        if m := re.match(r"^/Items/([0-9a-f]{32})/Images/(\w+)(?:/\d+)?$", p): return self.arquivo(RAIZ / "img" / f"{m.group(1)}_{m.group(2)}.jpg")
        if m := re.match(r"^/Users/([0-9a-f]{32})/Images/Primary$", p):
            if metodo != "GET": return self.responder(None, 204)
            return self.arquivo(RAIZ / "img" / f"usuario_{m.group(1)}.jpg")
        if re.match(r"^/Videos/[0-9a-f]{32}/stream", p): return self.arquivo(RAIZ / "video" / "teste.mp4", "video/mp4")
        if m := re.match(r"^/Videos/.+/Subtitles/\d+/\d+/Stream\.(vtt|ass)$", p):
            return self.arquivo(RAIZ / "video" / f"teste.{m.group(1)}", "text/vtt" if m.group(1) == "vtt" else "text/x-ssa")
        # ---- Seerr falso ----
        if p.startswith("/__seerr/api/v1"):
            s = p[len("/__seerr/api/v1"):]
            if s == "/status": return self.responder({"version": "3.5.0-falso"})
            if s == "/auth/me": return self.responder({"id": 1, "jellyfinUserId": U["Id"]})
            if s == "/auth/jellyfin/quickconnect/initiate": return self.responder({"code": "112233", "secret": "s"})
            if s in ("/auth/jellyfin/quickconnect/authenticate", "/auth/logout"): return self.responder({"ok": True})
            if s == "/search":
                termo = q.get("query", "").lower()
                res = [{"id": 900 + n, "mediaType": t, "title": f"{termo.title()} {nome}" if t == "movie" else None, "name": f"{termo.title()} {nome}" if t == "tv" else None,
                        "releaseDate": f"{2000 + n}-05-01", "firstAirDate": f"{2000 + n}-05-01", "overview": "Título que o servidor ainda não tem (Seerr falso).",
                        "posterPath": None, "mediaInfo": {"status": [1, 2, 3, 1, 1][n]}} for n, (nome, t) in enumerate([("Cassino", "movie"), ("Contra Ataca", "movie"), ("A Série", "tv"), ("O Retorno", "movie"), ("Origens", "tv")])]
                return self.responder({"results": res if len(termo) >= 2 else []})
            if m := re.match(r"^/(movie|tv)/(\d+)$", s): return self.responder({"id": int(m.group(2)), "overview": "Sinopse do Seerr falso.", "seasons": [{"seasonNumber": n, "episodeCount": 10} for n in range(1, 4)] if m.group(1) == "tv" else None, "mediaInfo": {"seasons": [{"seasonNumber": 1, "status": 5}]}})
            if s == "/request" and metodo == "POST": return self.responder({"id": 77}, 201)
            if s == "/request": return self.responder({"results": [{"id": 77, "status": 2, "createdAt": "2026-10-18T12:00:00Z", "type": "movie", "media": {"tmdbId": 900, "status": 3, "mediaType": "movie"}}]})
            return self.responder({"erro": "seerr falso: rota não gravada"}, 404)
        if p == "/QuickConnect/Authorize": return self.responder(True)
        # ---- daqui para baixo precisa de token ----
        a = self.headers.get("Authorization", "") + self.headers.get("X-Emby-Authorization", "")
        if TOKEN not in a and q.get("api_key") != TOKEN: return self.responder({"erro": "sem token"}, 401)
        if p == f"/Users/{auth}" or p == "/Users/Me":
            return self.responder({"Id": U["Id"], "Name": U["Name"], "HasPassword": True, "PrimaryImageTag": U.get("PrimaryImageTag"), "Policy": {"IsAdministrator": False, "EnableSubtitleManagement": True}})
        if re.match(r"^/Users/[0-9a-f]{32}/Password$", p): return self.responder(None, 204)
        if p == "/UserViews": return self.responder(lista(D["views"]))
        if p == "/UserItems/Resume": return self.responder(lista(D["resume"], limite=int(q.get("limit", 20))))
        if p == "/Shows/NextUp":
            if sid := q.get("seriesid"):
                ids = [i for i in D["nextup"] + D["resume"] if ITENS[i].get("SeriesId") == sid]
                if not ids:
                    eps = [e for t in D["temporadas"].get(sid, []) for e in D["episodios"].get(t, [])]
                    ids = eps[:1]
                return self.responder(lista(ids[:1], completo=True))
            return self.responder(lista(D["nextup"], limite=int(q.get("limit", 20))))
        if p == "/Items/Latest": return self.responder(lista(D["latest"].get(q.get("parentid", ""), []), limite=int(q.get("limit", 20)))["Items"])
        if m := re.match(r"^/(UserPlayedItems|UserFavoriteItems)/([0-9a-f]{32})$", p):
            i = m.group(2); campo = "Played" if m.group(1) == "UserPlayedItems" else "IsFavorite"
            dados_usuario.setdefault(i, {})[campo] = metodo == "POST"
            return self.responder({**(ITENS.get(i, {}).get("UserData") or {}), **dados_usuario[i]})
        if p in ("/Sessions/Playing", "/Sessions/Playing/Progress", "/Sessions/Playing/Stopped", "/Videos/ActiveEncodings"): return self.responder(None, 204)
        if m := re.match(r"^/Items/([0-9a-f]{32})/PlaybackInfo$", p):
            i = m.group(1)
            fonte = {"Id": i, "Container": "mp4", "RunTimeTicks": 90 * TICKS, "SupportsDirectPlay": True, "SupportsDirectStream": True, "SupportsTranscoding": False,
                     "MediaStreams": fluxos(i), "DefaultAudioStreamIndex": 1, "DefaultSubtitleStreamIndex": -1, "Size": 4_300_000, "Bitrate": 380000}
            return self.responder({"PlaySessionId": f"sessao-{int(time.time())}", "MediaSources": [fonte]})
        if m := re.match(r"^/Items/([0-9a-f]{32})/RemoteSearch/Subtitles/(\w+)$", p):
            lingua = m.group(2)
            return self.responder([{"Id": f"os-{lingua}-{n}", "Name": f"{ITENS.get(m.group(1), {}).get('Name', 'Item')}.WEB-DL.{lingua}.{n}", "ProviderName": "Open Subtitles",
                                    "Format": "srt", "DownloadCount": 5000 - n * 900, "ThreeLetterISOLanguageName": lingua} for n in range(4)])
        if m := re.match(r"^/Items/([0-9a-f]{32})/RemoteSearch/Subtitles/.+$", p):
            legendas_baixadas.add(m.group(1)); return self.responder(None, 204)
        if m := re.match(r"^/Items/([0-9a-f]{32})$", p):
            return self.responder(item(m.group(1))) if m.group(1) in ITENS else self.responder({"erro": "item não gravado"}, 404)
        if m := re.match(r"^/Shows/([0-9a-f]{32})/Seasons$", p): return self.responder(lista(D["temporadas"].get(m.group(1), [])))
        if m := re.match(r"^/Shows/([0-9a-f]{32})/Episodes$", p):
            sid = m.group(1); temp = q.get("seasonid")
            eps = D["episodios"].get(temp, []) if temp else [e for t in D["temporadas"].get(sid, []) for e in D["episodios"].get(t, [])]
            if (ini := q.get("startitemid")) and ini in eps: eps = eps[eps.index(ini):]
            return self.responder(lista(eps, limite=int(q["limit"]) if "limit" in q else None, completo=True))
        if p == "/Items":
            inicio, limite = int(q.get("startindex", 0)), int(q.get("limit", 60))
            if "ids" in q: return self.responder(lista(q["ids"].split(","), completo=True))
            if termo := q.get("searchterm", "").lower():
                tipos = q.get("includeitemtypes", "Movie,Series").split(",")
                return self.responder(lista([i for i, x in ITENS.items() if x.get("Type") in tipos and termo in (x.get("Name") or "").lower()], limite=limite))
            if q.get("filters") == "IsFavorite":
                fav = D["favoritos"].get(q.get("parentid", ""), []) if "parentid" in q else [i for v in D["favoritos"].values() for i in v]
                fav = [i for i in fav if dados_usuario.get(i, {}).get("IsFavorite", True)] + [i for i, x in dados_usuario.items() if x.get("IsFavorite") and i not in fav and i in ITENS and ITENS[i].get("ParentId") == q.get("parentid")]
                return self.responder(lista(fav, inicio, limite))
            if pid := q.get("parentid"):
                return self.responder({**lista(D["biblioteca"].get(pid, []), inicio, limite), "TotalRecordCount": D["totais"].get(pid, 0)})
            if q.get("imagetypes"): return self.responder(lista(D["destaque"], limite=limite))
            return self.responder(lista([], 0))
        if m := re.match(r"^/HomeScreen/Section/(UpcomingShows|UpcomingMovies)$", p): return self.responder(D["upcoming"]["tv" if "Shows" in m.group(1) else "movie"])
        return self.responder({"erro": f"rota não gravada no servidor falso: {metodo} {p}"}, 404)

if __name__ == "__main__":
    porta = int(sys.argv[1]) if len(sys.argv) > 1 else 8097
    print(f"Jellyfin falso em http://127.0.0.1:{porta}  ({len(ITENS)} itens; qualquer usuário; senha 'errada' dá 401)")
    ThreadingHTTPServer(("0.0.0.0", porta), H).serve_forever()
