# Repositórios Linux Heisuca (Beta Desktop)

Repositórios oficiais de teste do **Heisuca** para desktop Linux em sessão **Wayland** nativa:
- **Ubuntu 24.04+ (`amd64` / Wayland)**
- **Fedora 45 (`x86_64` / Wayland)**

> **Aviso:** As versões desktop são builds **Beta** de teste. Sessões X11 não reproduzem vídeo nesta versão.

Chave pública: `8825EE297E38A4521A638568DB6342368211E128`.

[Guia de instalação](https://heisuca.docaio.com.br/linux/).

## Instalação no Cliente

### Ubuntu 24.04+ (APT / Deb822)
```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://heisuca.docaio.com.br/pacotes/repos/apt/heisuca-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/heisuca-archive-keyring.gpg >/dev/null
sudo chmod 0644 /etc/apt/keyrings/heisuca-archive-keyring.gpg
curl -fsSL https://heisuca.docaio.com.br/pacotes/repos/apt/heisuca.sources \
  | sudo tee /etc/apt/sources.list.d/heisuca.sources >/dev/null
sudo apt-get update
sudo apt-get install -y heisuca
```

### Fedora 45 (DNF5 / RPM)
```bash
sudo rpm --import https://heisuca.docaio.com.br/pacotes/repos/rpm/RPM-GPG-KEY-heisuca.asc
sudo curl -fsSL https://heisuca.docaio.com.br/pacotes/repos/rpm/heisuca.repo \
  -o /etc/yum.repos.d/heisuca.repo
sudo dnf install -y heisuca
```

## Geração Offline e Renovação de Metadados (90 dias)

Construção completa validando SHA-256 dos pacotes e os 161 ELFs de `provenance.json`:
```bash
python3 distribution/repos/build_repos.py \
  --deb /caminho/heisuca-linux-x64.deb \
  --deb-sha256 /caminho/heisuca-linux-x64.deb.sha256 \
  --rpm /caminho/heisuca-linux-x64.rpm \
  --rpm-sha256 /caminho/heisuca-linux-x64.rpm.sha256 \
  --provenance /caminho/provenance.json \
  --output /caminho/saida-repos \
  --gpg-home /caminho/gnupghome-externo \
  --key-id "<FINGERPRINT_RSA4096>"
```

Renovação exclusiva de índices (`Valid-Until` de 90 dias, mantendo `pool/` e histórico `by-hash/`):
```bash
python3 distribution/repos/build_repos.py \
  --refresh-metadata \
  --output /caminho/saida-repos \
  --gpg-home /caminho/gnupghome-externo \
  --key-id "<FINGERPRINT_RSA4096>"
```

## Roteiro de Aceitação em Contêineres (HTTPS + Assinaturas + Upgrade)

### 1. Ubuntu 24.04 (`ubuntu:24.04`)
```bash
apt-get update && apt-get install -y curl ca-certificates gnupg
curl -fsSLO https://heisuca.docaio.com.br/pacotes/linux/teste-46df8e02/heisuca-linux-x64.deb
apt-get install -y ./heisuca-linux-x64.deb
mkdir -p ~/.local/share/app.heisuca.player.desktop
echo '{"profile":"ok"}' > ~/.local/share/app.heisuca.player.desktop/sentinel.json
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://heisuca.docaio.com.br/pacotes/repos/apt/heisuca-archive-keyring.gpg \
  -o /etc/apt/keyrings/heisuca-archive-keyring.gpg
curl -fsSL https://heisuca.docaio.com.br/pacotes/repos/apt/heisuca.sources \
  -o /etc/apt/sources.list.d/heisuca.sources
apt-get update && apt-get install -y --only-upgrade heisuca
dpkg-query -W -f='${Version}\n' heisuca | grep -qx '2.0.45-2'
test -f ~/.local/share/app.heisuca.player.desktop/sentinel.json
```

### 2. Fedora 45 (`fedora:45`)
```bash
dnf install -y curl ca-certificates gnupg2 rpm
curl -fsSLO https://heisuca.docaio.com.br/pacotes/linux/teste-e3a2f56a/heisuca-linux-x64.rpm
dnf install -y ./heisuca-linux-x64.rpm
mkdir -p ~/.local/share/app.heisuca.player.desktop
echo '{"profile":"ok"}' > ~/.local/share/app.heisuca.player.desktop/sentinel.json
rpm --import https://heisuca.docaio.com.br/pacotes/repos/rpm/RPM-GPG-KEY-heisuca.asc
curl -fsSL https://heisuca.docaio.com.br/pacotes/repos/rpm/heisuca.repo -o /etc/yum.repos.d/heisuca.repo
dnf upgrade -y heisuca
rpm -q heisuca | grep -qx 'heisuca-2.0.45-2.fc45.x86_64'
test -f ~/.local/share/app.heisuca.player.desktop/sentinel.json
```

## Publicação e manutenção

`refresh-published.sh` renova os índices semanalmente na VPS; a chave dedicada permanece fora da pasta pública. Publica por troca atômica de symlink e preserva os snapshots anteriores. O crontab anterior fica em `/root/heisuca-package-repository/backups/`. Nunca exportar a chave privada. A chave pública inicial vence em novembro de 2028 e precisa ser renovada antes disso.
