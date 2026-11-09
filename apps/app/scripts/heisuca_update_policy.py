"""Contrato de permissões das variantes do Heisuca no APK efetivo."""
import re


def validar_permissao(badging: str, variante: str) -> None:
    assert variante in ("direct", "play"), "variante desconhecida"
    presente = re.search(r"(?m)^uses-permission(?:-sdk-\d+)?: name=['\"]android\.permission\.REQUEST_INSTALL_PACKAGES['\"]", badging) is not None
    assert presente == (variante == "direct"), "REQUEST_INSTALL_PACKAGES incompatível com a variante"


def validar_build(badging: str, esperado: int) -> None:
    real = re.search(r"versionCode='(\d+)'", badging)
    assert real and int(real.group(1)) == esperado, "versionCode diverge do build do feed/pubspec"
