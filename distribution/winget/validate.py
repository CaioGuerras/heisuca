#!/usr/bin/env python3
import json, re, sys, urllib.parse, urllib.request
from pathlib import Path
import jsonschema, yaml

ALLOWED_HOSTS = {"aka.ms", "raw.githubusercontent.com"}
PKG_ID = "Heisuca.Heisuca"
PRODUCT_CODE = "{ddf45e29-4518-4c70-a963-998f215557d8}_is1"
SCHEMA_VER = "1.12.0"

def check_url(url: str) -> None:
    p = urllib.parse.urlparse(url)
    if p.scheme != "https" or p.hostname not in ALLOWED_HOSTS:
        raise ValueError(f"Dominio/esquema nao permitido para JSON Schema: {url}")
    if p.hostname == "raw.githubusercontent.com" and not p.path.lower().startswith("/microsoft/"):
        raise ValueError(f"Caminho GitHub fora da org microsoft: {url}")

def fetch_schema(mtype: str) -> dict:
    url = f"https://aka.ms/winget-manifest.{mtype}.{SCHEMA_VER}.schema.json"
    check_url(url)
    req = urllib.request.Request(url, headers={"User-Agent": "heisuca-winget-validate/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        check_url(resp.geturl())
        return json.loads(resp.read().decode("utf-8"))

def find_manifest_dir(arg: str | None) -> Path:
    if arg:
        return Path(arg).resolve()
    root = Path(__file__).resolve().parent / "manifests/h/Heisuca/Heisuca"
    for yml in sorted(root.glob("*/*.yaml")):
        doc = yaml.safe_load(yml.read_text(encoding="utf-8")) or {}
        if doc.get("ManifestType") == "version":
            return yml.parent.resolve()
    raise FileNotFoundError("Nenhum manifesto ManifestType=version encontrado.")

def main() -> int:
    mdir = find_manifest_dir(sys.argv[1] if len(sys.argv) > 1 else None)
    by_type: dict[str, list[tuple[Path, dict]]] = {}
    for yml in sorted(mdir.glob("*.yaml")):
        doc = yaml.safe_load(yml.read_text(encoding="utf-8"))
        if not isinstance(doc, dict) or "ManifestType" not in doc:
            raise ValueError(f"Arquivo YAML invalido: {yml}")
        by_type.setdefault(str(doc["ManifestType"]), []).append((yml, doc))
    if len(by_type.get("version", [])) != 1:
        raise ValueError("Exatamente um arquivo ManifestType=version e obrigatorio.")
    version = str(by_type["version"][0][1]["PackageVersion"])
    if mdir.parts[-5:] != ("manifests", "h", "Heisuca", "Heisuca", version):
        raise ValueError(f"Caminho {mdir} inconsistente com PackageVersion={version}")
    for mtype in ("version", "installer", "defaultLocale", "locale"):
        if mtype not in by_type:
            raise ValueError(f"ManifestType ausente: {mtype}")
        schema = fetch_schema(mtype)
        for yml, doc in by_type[mtype]:
            jsonschema.validate(instance=doc, schema=schema)
            if doc.get("PackageIdentifier") != PKG_ID or str(doc.get("PackageVersion")) != version:
                raise ValueError(f"Identificador ou versao divergente em {yml.name}")
            if str(doc.get("ManifestVersion")) != SCHEMA_VER:
                raise ValueError(f"ManifestVersion diferente de {SCHEMA_VER} em {yml.name}")
    inst = by_type["installer"][0][1]
    arp = (inst.get("AppsAndFeaturesEntries") or [{}])[0]
    if inst.get("InstallerType") != "inno" or inst.get("Scope") != "user":
        raise ValueError("InstallerType deve ser inno e Scope deve ser user.")
    if str(arp.get("DisplayVersion")) != version or arp.get("ProductCode") != PRODUCT_CODE or arp.get("Publisher") != "Heisuca":
        raise ValueError("AppsAndFeaturesEntries inconsistente.")
    exp_url = f"https://heisuca.docaio.com.br/pacotes/windows/{version}/heisuca-windows-installer.exe"
    for item in inst.get("Installers", []):
        sha = str(item.get("InstallerSha256", ""))
        if item.get("InstallerUrl") != exp_url:
            raise ValueError(f"URL inesperada: {item.get('InstallerUrl')}")
        if not re.fullmatch(r"[0-9a-fA-F]{64}", sha) or int(sha, 16) == 0 or sha.lower().startswith("24ead"):
            raise ValueError(f"SHA256 invalido (placeholder zero ou hash legado 2.0.45): {sha}")
    print(f"OK: {PKG_ID} {version} validado com sucesso.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
