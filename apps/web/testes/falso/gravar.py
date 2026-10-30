#!/usr/bin/env python3
"""Grava o "servidor falso" a partir do Jellyfin de verdade (roda SÓ na Whatbox, com a chave de admin; só leitura).

Saída em testes/falso/dados/ (dados.json + img/ + video/), publicada no ramo `falso-dados` (fora do histórico do site):
as sessões na nuvem baixam com  git archive  e sobem o servidor.py, sem precisar de acesso ao CGSERVER.

Conteúdo: a home do Caio (Continuar, Próximo, destaque, novidades, Em alta, Em breve, favoritos), as bibliotecas (60
primeiros em ordem alfabética) e os títulos que aparecem nos prints de referência (InuYasha, Deadwood, One Piece,
High School of the Dead, Aoashi, Masterplan, Meu Amigo Totoro), com temporadas, episódios, elenco e fluxos de mídia.
Limpeza: nenhum token, nenhum caminho de arquivo (chaves "Path"), nada do servidor além do nome.
"""
import importlib.machinery, importlib.util, json, os, subprocess, sys, urllib.parse, urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

H = Path.home()
ld = importlib.machinery.SourceFileLoader("a", str(H / "cgflix/arrs/bin/cgf-arrs"))
a = importlib.util.module_from_spec(importlib.util.spec_from_loader("a", ld)); ld.exec_module(a)
jf = a.Jellyfin(); B = "http://127.0.0.1:13168"
SAI = Path(__file__).resolve().parent / "dados"
(SAI / "img").mkdir(parents=True, exist_ok=True); (SAI / "video").mkdir(exist_ok=True)

def g(p):
    with urllib.request.urlopen(urllib.request.Request(B + p, headers={"Authorization": f'MediaBrowser Token="{jf._k}"'}), timeout=60) as r:
        return json.load(r)

def limpar(x):
    if isinstance(x, dict):
        return {k: limpar(v) for k, v in x.items() if k not in ("Path", "ServerId", "LockedFields", "ExternalUrls", "RemoteTrailers")}
    if isinstance(x, list):
        return [limpar(v) for v in x]
    return x

IMG = "enableImageTypes=Primary,Backdrop,Thumb,Logo&imageTypeLimit=1"
CAMPOS = ("fields=Overview,Genres,Taglines,Studios,People,Chapters,MediaStreams,ChildCount,PrimaryImageAspectRatio,ProductionYear,"
          "PremiereDate,EndDate,Status,OfficialRating,CommunityRating,ParentId&" + IMG)
usuario = next(u for u in g("/Users") if u["Name"].lower() == "caioguerras")
U = usuario["Id"]
itens, ids = {}, lambda lst: [i["Id"] for i in lst]
def guardar(lst):
    for i in lst: itens[i["Id"]] = i
    return ids(lst)

d = {"servidor": {"Id": "0123456789abcdef0123456789abcdef", "ServerName": "CGFLIX", "Version": g("/System/Info/Public")["Version"]},
     "usuario": {"Id": U, "Name": usuario["Name"], "PrimaryImageTag": usuario.get("PrimaryImageTag"), "HasPassword": True}}
views = [v for v in g(f"/UserViews?userId={U}")["Items"] if v.get("CollectionType") in ("movies", "tvshows", "boxsets", None)]
d["views"] = guardar(views)
d["resume"] = guardar(g(f"/UserItems/Resume?userId={U}&limit=20&mediaTypes=Video&{CAMPOS}")["Items"])
d["nextup"] = guardar(g(f"/Shows/NextUp?userId={U}&limit=20&enableResumable=false&enableRewatching=false&{CAMPOS}")["Items"])
d["destaque"] = guardar([i for i in g(f"/Items?userId={U}&recursive=true&includeItemTypes=Movie,Series&sortBy=DateCreated&sortOrder=Descending"
                        f"&imageTypes=Logo&limit=27&{CAMPOS}")["Items"] if i.get("BackdropImageTags") and i.get("ImageTags", {}).get("Logo")][:9])
d["latest"], d["favoritos"], d["biblioteca"], d["totais"] = {}, {}, {}, {}
for v in views:
    if v.get("CollectionType") != "boxsets":
        d["latest"][v["Id"]] = guardar(g(f"/Items/Latest?userId={U}&parentId={v['Id']}&limit=20&{CAMPOS}"))
    d["favoritos"][v["Id"]] = guardar(g(f"/Items?userId={U}&parentId={v['Id']}&recursive=true&filters=IsFavorite&includeItemTypes=Movie,Series,BoxSet"
                                      f"&sortBy=SortName&limit=30&{CAMPOS}")["Items"])
    r = g(f"/Items?userId={U}&parentId={v['Id']}&recursive=true&includeItemTypes=Movie,Series,BoxSet&sortBy=SortName&sortOrder=Ascending&limit=60&{CAMPOS}")
    d["biblioteca"][v["Id"]] = guardar(r["Items"]); d["totais"][v["Id"]] = r["TotalRecordCount"]

# Em alta e Em breve (o que o CGSERVER publica)
def publico(caminho):
    with urllib.request.urlopen(f"https://netflix.docaio.com.br{caminho}", timeout=30) as r:
        return json.load(r)
d["emalta"] = publico("/cgflix/emalta.json"); d["embreve"] = publico("/cgflix/embreve.json")
alta = [x["id"] for x in d["emalta"].get("itens", [])][:10]
if alta: guardar(g(f"/Items?userId={U}&ids={','.join(alta)}&{CAMPOS}")["Items"])
# Em breve: o plugin Home Screen Sections só aceita token de usuário (403 com a chave de admin); a seção é montada a
# partir do embreve.json (o mesmo mapa que o site usa), com datas fictícias nos próximos dias
import datetime
hoje = datetime.date.today()
def sec(mapa, campo):
    out = []
    for n, (chave, v) in enumerate(list(mapa.items())[:12]):
        p = {campo: chave}
        if campo == "SonarrSeriesId": p["EpisodeInfo"] = f"S01E{n + 1:02d} - Episódio"
        out.append({"Name": v.get("nome") or "", "SeriesName": v.get("nome") or "", "PremiereDate": f"{hoje + datetime.timedelta(days=n + 1)}T20:00:00Z", "ProviderIds": p})
    return {"Items": out}
d["upcoming"] = {"tv": sec(d["embreve"].get("s", {}), "SonarrSeriesId"), "movie": sec(d["embreve"].get("m", {}), "RadarrMovieId")}
jfs = [v["jf"] for m in (d["embreve"].get("s", {}), d["embreve"].get("m", {})) for v in list(m.values())[:12] if v.get("jf")]
if jfs: guardar(g(f"/Items?userId={U}&ids={','.join(jfs)}&{CAMPOS}")["Items"])

# títulos dos prints de referência: série inteira (temporadas; episódios das 2 primeiras e da atual)
d["temporadas"], d["episodios"] = {}, {}
FOCO = ["InuYasha", "Deadwood", "One Piece", "High School of the Dead", "Aoashi", "Masterplan", "Meu Amigo Totoro", "Black Clover", "American Hostage"]
for nome in FOCO:
    r = g(f"/Items?userId={U}&recursive=true&includeItemTypes=Series,Movie&searchTerm={urllib.parse.quote(nome)}&limit=1&{CAMPOS}")["Items"]
    if not r: print("não achei", nome); continue
    t = r[0]; guardar([t])
    if t["Type"] != "Series": continue
    temps = g(f"/Shows/{t['Id']}/Seasons?userId={U}&fields=ChildCount&{IMG}")["Items"]
    d["temporadas"][t["Id"]] = guardar(temps)
    atual = next((itens[i] for i in d["nextup"] + d["resume"] if itens[i].get("SeriesId") == t["Id"]), None)
    alvo = {x["Id"] for x in temps[:2]} | ({atual["SeasonId"]} if atual and atual.get("SeasonId") else set())
    for s in temps:
        if s["Id"] in alvo:
            d["episodios"][s["Id"]] = guardar(g(f"/Shows/{t['Id']}/Episodes?userId={U}&seasonId={s['Id']}&{CAMPOS}")["Items"])

# completa os campos dos itens que vieram de listas (busca de novo com tudo, em lotes)
faltam = list(itens)
for k in range(0, len(faltam), 60):
    for i in g(f"/Items?userId={U}&ids={','.join(faltam[k:k + 60])}&{CAMPOS}")["Items"]:
        itens[i["Id"]] = {**itens[i["Id"]], **i}
d["itens"] = limpar(itens)

# imagens (tamanhos do site; qualidade menor para caber no ramo)
pedidos = []
def img(item_id, tipo, tag, q, nome, idx=None):
    if tag: pedidos.append((f"/Items/{item_id}/Images/{tipo}{'' if idx is None else '/' + str(idx)}?{q}&tag={tag}", nome))
foco_ids = {i for i, x in itens.items() if x.get("Name") in FOCO or x.get("SeriesName") in FOCO}
com_fundo = set(d["destaque"]) | {i for i in foco_ids if itens[i]["Type"] in ("Series", "Movie")} | set(alta) | \
    {itens[i].get("SeriesId") or i for i in d["resume"] + d["nextup"]}
for i, x in itens.items():
    tags = x.get("ImageTags") or {}
    if x["Type"] in ("Episode",): img(i, "Primary", tags.get("Primary"), "fillWidth=400&quality=68", f"{i}_Primary")
    elif x["Type"] == "CollectionFolder" or i in d["views"]: img(i, "Primary", tags.get("Primary"), "fillWidth=640&quality=78", f"{i}_Primary")
    else: img(i, "Primary", tags.get("Primary"), "fillHeight=300&quality=70", f"{i}_Primary")
    # logo, fundo e miniatura 16:9 só de quem aparece grande (destaque, títulos dos prints, Continuar/Próximo, Em alta)
    if i in com_fundo:
        img(i, "Logo", tags.get("Logo"), "fillWidth=420&quality=80", f"{i}_Logo")
        if x.get("BackdropImageTags"): img(i, "Backdrop", x["BackdropImageTags"][0], "fillWidth=1280&quality=68", f"{i}_Backdrop", 0)
        if x["Type"] in ("Movie", "Series"): img(i, "Thumb", tags.get("Thumb"), "fillWidth=480&quality=68", f"{i}_Thumb")
    if i in foco_ids:
        for p in (x.get("People") or [])[:16]:
            if p.get("PrimaryImageTag"): pedidos.append((f"/Items/{p['Id']}/Images/Primary?fillWidth=200&quality=80&tag={p['PrimaryImageTag']}", f"{p['Id']}_Primary"))
for v in views:
    if v.get("ImageTags", {}).get("Primary"): img(v["Id"], "Primary", v["ImageTags"]["Primary"], "fillWidth=640&quality=80", f"{v['Id']}_Primary")
if usuario.get("PrimaryImageTag"):
    pedidos.append((f"/Users/{U}/Images/Primary?fillWidth=200&quality=85&tag={usuario['PrimaryImageTag']}", f"usuario_{U}"))

def baixar(p):
    caminho, nome = p; destino = SAI / "img" / f"{nome}.jpg"
    if destino.exists(): return 0
    try:
        with urllib.request.urlopen(urllib.request.Request(B + caminho, headers={"Authorization": f'MediaBrowser Token="{jf._k}"'}), timeout=60) as r:
            destino.write_bytes(r.read()); return 1
    except Exception: return 0
unicos = list(dict(pedidos).items())   # (caminho, nome) sem repetir
with ThreadPoolExecutor(6) as ex: n = sum(ex.map(baixar, unicos))
json.dump(d, open(SAI / "dados.json", "w", encoding="utf-8"), ensure_ascii=False)

# vídeo de teste: 90 s, 2 áudios (pt e ja), capítulos Prólogo/Abertura/Episódio/Créditos, legendas VTT e ASS
v = SAI / "video"
if not (v / "teste.mp4").exists():
    (v / "capitulos.txt").write_text(";FFMETADATA1\n" + "".join(
        f"[CHAPTER]\nTIMEBASE=1/1000\nSTART={a * 1000}\nEND={b * 1000}\ntitle={t}\n" for a, b, t in
        [(0, 8, "Prologue"), (8, 38, "Opening"), (38, 80, "Episode"), (80, 90, "Credits")]))
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=1280x720:rate=24:duration=90",
                    "-f", "lavfi", "-i", "sine=frequency=440:duration=90", "-f", "lavfi", "-i", "sine=frequency=660:duration=90",
                    "-i", str(v / "capitulos.txt"), "-map", "0:v", "-map", "1:a", "-map", "2:a", "-map_metadata", "3",
                    "-c:v", "libx264", "-preset", "veryfast", "-crf", "36", "-vf", "scale=960:540", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "64k",
                    "-metadata:s:a:0", "language=por", "-metadata:s:a:0", "title=Português (Brasil)",
                    "-metadata:s:a:1", "language=jpn", "-metadata:s:a:1", "title=Japonês",
                    "-movflags", "+faststart", str(v / "teste.mp4")], check=True)
    (v / "teste.vtt").write_text("WEBVTT\n\n" + "".join(f"00:00:{s:02d}.000 --> 00:00:{s + 3:02d}.000\nLegenda de teste aos {s} segundos.\n\n" for s in range(2, 88, 6)))
    (v / "teste.ass").write_text("[Script Info]\nScriptType: v4.00+\nPlayResX: 1280\nPlayResY: 720\n\n[V4+ Styles]\n"
        "Format: Name, Fontname, Fontsize, PrimaryColour, OutlineColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV\n"
        "Style: Default,Arial,48,&H00FFFFFF,&H00000000,&H64000000,0,0,1,3,1,2,40,40,40\n\n[Events]\n"
        "Format: Layer, Start, End, Style, Text\n" + "".join(f"Dialogue: 0,0:00:{s:02d}.00,0:00:{s + 3:02d}.00,Default,{{\\c&H66CCFF&}}Legenda ASS aos {s} s\n" for s in range(4, 88, 6)))
tam = sum(f.stat().st_size for f in SAI.rglob("*") if f.is_file())
print(f"itens: {len(itens)} | imagens novas: {n} de {len(pedidos)} | total: {tam / 1e6:.1f} MB")
