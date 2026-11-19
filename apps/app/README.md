# Heisuca

Player para bibliotecas Jellyfin e Plex. Uma experiência de cinema no celular, na TV e no computador, com controle de áudio, legendas e progresso de reprodução.

O Heisuca não fornece conteúdo ou contas. Conecte o servidor ao qual você já tem acesso.

## Baixar

Os downloads e os requisitos atualizados ficam em [heisuca.docaio.com.br](https://heisuca.docaio.com.br/).

- **Android:** Google Play ou APK; celular e tablet.
- **Android TV e Google TV:** APK para TV, com navegação por controle remoto.
- **Fire TV:** APK Universal, em aparelhos com Fire OS 6 ou mais recente. Modelos com Vega OS não instalam este APK.
- **Windows x64:** instalador e ZIP sem instalação, em teste.
- **Linux x64 com Wayland:** DEB para Ubuntu 24.04+, RPM validado no Fedora 45 e tar.gz validado no Ubuntu, em teste.
- **iPhone, iPad e Mac:** use o site no navegador; ainda não há app nativo disponível para baixar.
- **Samsung e LG:** ainda não há app disponível para download.

## Desenvolvimento

Este diretório contém a base Flutter. Os pontos de entrada e os fluxos de compilação variam por plataforma; veja os workflows do repositório e as instruções em [../../AGENTS.md](../../AGENTS.md).

O desktop usa uma entrada própria em `lib/desktop/`. Empacotamento e verificações ficam em `tool/desktop/`.

## Créditos e licença

O Heisuca deriva do [Plezy](https://github.com/edde746/plezy), de edde746 e colaboradores, e mantém seus avisos de autoria e a licença **GNU GPL-3.0**. Consulte [LICENSE](LICENSE) e as licenças das dependências distribuídas com o app.

Construído com Flutter e componentes de reprodução como mpv, libass e Media3, conforme a plataforma.
