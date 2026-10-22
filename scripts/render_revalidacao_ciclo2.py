#!/usr/bin/env python3
import base64
import json
import os
import re
import subprocess
from pathlib import Path

OUT_DIR = Path(
    "/home/caioguerras/cgmind/homes/gemini-04/.gemini/antigravity-cli/brain/510eaf64-dc4b-4f92-b4a4-afb9f3abf1b9/scratch"
)
OUT_DIR.mkdir(parents=True, exist_ok=True)

abertura_svg = Path(
    "/home/caioguerras/heisuca/apps/web/src/marca/abertura.svg"
).read_text()
kanji_paths = "".join(
    re.findall(
        r'<path transform="translate\(6\.38,[^"]+\) scale\(0\.05797\)"'
        r' d="[^"]+"/>',
        abertura_svg,
    )
)
palavra_path = re.search(
    r'<g class="palavra">(<path[^>]+/>)</g>', abertura_svg
).group(1)
kata_path = re.search(r'<g class="kata">(<path[^>]+/>)</g>', abertura_svg).group(
    1
)

W, H = 720, 1600  # Motorola Edge 60 Pro 20:9


def topbar_logo(selo_col, text_col, scale=0.38, cx=120, cy=64):
  return f"""
    <g transform="translate({cx}, {cy}) scale({scale}) translate(-320, -180)">
      <g transform="translate(114.22, 80.00)">
        <rect width="70.72" height="200" rx="4.64" fill="{selo_col}"/>
        <rect x="4.06" y="4.06" width="62.61" height="191.88" rx="2.32" fill="none" stroke="#FFF8F0" stroke-width="1.45"/>
        <g fill="#FFF8F0">{kanji_paths}</g>
      </g>
      <g fill="{text_col}">{palavra_path}</g>
    </g>
    """


def render_home(theme='shikkoku'):
  is_light = theme == 'hisui'
  bg = '#F7F3EC' if is_light else '#0B0910'
  surf = '#FFFFFF' if is_light else '#140F22'
  line = '#E2E8F0' if is_light else '#2E2248'
  text = '#134E4A' if is_light else '#F4F1FA'
  text2 = '#64748B' if is_light else '#A99FBB'
  accent = '#047857' if is_light else '#9D74FF'
  selo = '#047857' if is_light else '#7444E0'
  pill_col = (
      'rgba(4, 120, 87, 0.18)' if is_light else 'rgba(157, 116, 255, 0.24)'
  )

  # Backdrop gradient / illustration for Hero
  hero_grad = (
      f'<linearGradient id="hg_{theme}" x1="0" y1="0" x2="0" y2="1">'
      f'<stop offset="0%" stop-color="{"#86EFAC" if is_light else "#2E1065"}"'
      ' stop-opacity="0.8"/>'
      f'<stop offset="60%" stop-color="{"#BBF7D0" if is_light else "#1E1B4B"}"'
      ' stop-opacity="0.4"/>'
      f'<stop offset="100%" stop-color="{bg}"/>'
      '</linearGradient>'
  )

  return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
  <defs>{hero_grad}</defs>
  <rect width="{W}" height="{H}" fill="{bg}"/>

  <!-- Hero Art & Scrim -->
  <rect width="{W}" height="780" fill="url(#hg_{theme})"/>

  <!-- Status Bar -->
  <text x="56" y="58" font-family="sans-serif" font-weight="600" font-size="22" fill="{text}" opacity="0.8">01:58</text>
  <g transform="translate(605, 40)" fill="{text}" opacity="0.8">
    <rect x="0" y="6" width="6" height="12" rx="1.5"/>
    <rect x="9" y="3" width="6" height="15" rx="1.5"/>
    <rect x="18" y="0" width="6" height="18" rx="1.5"/>
    <rect x="32" y="2" width="26" height="14" rx="3" fill="none" stroke="{text}" stroke-width="2"/>
    <rect x="35" y="5" width="18" height="8" rx="1.5"/>
  </g>

  <!-- TopBar Oficial: Marca HEISUCA colada ao selo no canto superior esquerdo -->
  {topbar_logo(selo, text, scale=0.38, cx=110, cy=74)}

  <!-- Busca discreta à direita -->
  <g transform="translate(640, 92)" opacity="0.9">
    <circle cx="12" cy="12" r="9" fill="none" stroke="{text}" stroke-width="2.4"/>
    <path d="M19 19 L26 26" stroke="{text}" stroke-width="2.4" stroke-linecap="round"/>
  </g>

  <!-- Hero Info (ClearLogo, Nota, Metadados e Sinopse) -->
  <g transform="translate(48, 480)">
    <!-- ClearLogo Título -->
    <text x="0" y="70" font-family="sans-serif" font-weight="900" font-size="44" letter-spacing="2" fill="{text}">DUNA: PARTE 2</text>
    <!-- Metadados -->
    <g transform="translate(0, 110)">
      <circle cx="10" cy="-6" r="6" fill="#FBBF24"/>
      <text x="24" y="0" font-family="sans-serif" font-weight="700" font-size="20" fill="{text}">8.6</text>
      <text x="75" y="0" font-family="sans-serif" font-size="20" fill="{text2}">• 2024 • Ficção Científica • 4K HDR</text>
    </g>
    <!-- Sinopse -->
    <text x="0" y="150" font-family="sans-serif" font-size="19" fill="{text2}" opacity="0.9">Paul Atreides se une a Chani e aos Fremen em busca de vingança</text>
    <text x="0" y="178" font-family="sans-serif" font-size="19" fill="{text2}" opacity="0.9">contra os conspiradores que destruíram sua família.</text>
  </g>

  <!-- Fileira 1: Continuar assistindo (16:9 Widescreen) -->
  <g transform="translate(48, 760)">
    <text x="0" y="0" font-family="sans-serif" font-weight="800" font-size="24" fill="{text}">Continuar assistindo</text>
    <!-- Card 1 (16:9) -->
    <g transform="translate(0, 20)">
      <rect width="360" height="202" rx="20" fill="{surf}" stroke="{line}" stroke-width="1.2"/>
      <circle cx="180" cy="90" r="28" fill="{accent}" fill-opacity="0.9"/>
      <polygon points="174,78 192,90 174,102" fill="#FFFFFF"/>
      <rect x="0" y="194" width="240" height="8" rx="4" fill="{accent}"/>
      <text x="14" y="180" font-family="sans-serif" font-weight="700" font-size="18" fill="{text}">DanMachi: T4:E4</text>
    </g>
    <!-- Card 2 (16:9) -->
    <g transform="translate(380, 20)">
      <rect width="244" height="202" rx="20" fill="{surf}" stroke="{line}" stroke-width="1.2"/>
      <circle cx="122" cy="90" r="28" fill="{accent}" fill-opacity="0.9"/>
      <polygon points="116,78 134,90 116,102" fill="#FFFFFF"/>
      <rect x="0" y="194" width="160" height="8" rx="4" fill="{accent}"/>
      <text x="14" y="180" font-family="sans-serif" font-weight="700" font-size="18" fill="{text}">Dress-Up: T1:E1</text>
    </g>
  </g>

  <!-- Fileira 2: Em alta no Brasil (Top 10) -->
  <g transform="translate(48, 1050)">
    <text x="0" y="0" font-family="sans-serif" font-weight="800" font-size="24" fill="{text}">Em alta no Brasil</text>
    <rect x="220" y="-22" width="76" height="28" rx="6" fill="{accent}" fill-opacity="0.18"/>
    <text x="232" y="-3" font-family="sans-serif" font-weight="700" font-size="14" fill="{accent}">TOP 10</text>

    <!-- Pôster 1 com número vazado gigante -->
    <g transform="translate(0, 22)">
      <text x="0" y="240" font-family="sans-serif" font-weight="900" font-size="130" fill="none" stroke="{accent}" stroke-width="3">1</text>
      <rect x="80" y="0" width="170" height="255" rx="16" fill="{surf}" stroke="{line}" stroke-width="1.2"/>
      <text x="96" y="235" font-family="sans-serif" font-weight="600" font-size="17" fill="{text}">Cyberpunk</text>
    </g>
    <!-- Pôster 2 -->
    <g transform="translate(280, 22)">
      <text x="0" y="240" font-family="sans-serif" font-weight="900" font-size="130" fill="none" stroke="{accent}" stroke-width="3">2</text>
      <rect x="80" y="0" width="170" height="255" rx="16" fill="{surf}" stroke="{line}" stroke-width="1.2"/>
      <text x="96" y="235" font-family="sans-serif" font-weight="600" font-size="17" fill="{text}">Vision Quest</text>
    </g>
  </g>

  <!-- Ilha Flutuante de Navegação Inferior (Floating Island) -->
  <g transform="translate(60, 1480)">
    <rect width="600" height="82" rx="41" fill="{surf}" fill-opacity="0.88" stroke="{line}" stroke-width="1.2"/>
    <!-- Pílula ativa "Início" -->
    <rect x="18" y="12" width="128" height="58" rx="29" fill="{pill_col}"/>
    <!-- Itens: Início, Biblioteca, Buscar, Você -->
    <g transform="translate(82, 48)">
      <circle cx="0" cy="-6" r="10" fill="{accent}"/>
      <text x="0" y="16" text-anchor="middle" font-family="sans-serif" font-weight="700" font-size="14" fill="{accent}">Início</text>
    </g>
    <g transform="translate(230, 48)" opacity="0.75">
      <rect x="-10" y="-16" width="20" height="16" rx="3" fill="none" stroke="{text2}" stroke-width="2"/>
      <text x="0" y="16" text-anchor="middle" font-family="sans-serif" font-size="14" fill="{text2}">Biblioteca</text>
    </g>
    <g transform="translate(378, 48)" opacity="0.75">
      <circle cx="0" cy="-8" r="8" fill="none" stroke="{text2}" stroke-width="2"/>
      <text x="0" y="16" text-anchor="middle" font-family="sans-serif" font-size="14" fill="{text2}">Buscar</text>
    </g>
    <g transform="translate(526, 48)" opacity="0.75">
      <circle cx="0" cy="-12" r="6" fill="none" stroke="{text2}" stroke-width="2"/>
      <path d="M-9 2 c0 -6 18 -6 18 0" fill="none" stroke="{text2}" stroke-width="2"/>
      <text x="0" y="16" text-anchor="middle" font-family="sans-serif" font-size="14" fill="{text2}">Você</text>
    </g>
  </g>
</svg>"""


def render_details_sheet():
  bg = '#0B0910'
  surf = '#140F22'
  line = '#2E2248'
  text = '#F4F1FA'
  text2 = '#A99FBB'
  accent = '#9D74FF'

  return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
  <rect width="{W}" height="{H}" fill="{bg}"/>

  <!-- Scrim e Backdrop Widescreen -->
  <rect width="{W}" height="480" fill="#2E1065"/>
  <rect y="380" width="{W}" height="100" fill="url(#detailScrim)"/>
  <defs>
    <linearGradient id="detailScrim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#2E1065" stop-opacity="0"/>
      <stop offset="100%" stop-color="{bg}"/>
    </linearGradient>
  </defs>

  <!-- Pílula de Fechamento -->
  <rect x="330" y="24" width="60" height="6" rx="3" fill="#FFFFFF" opacity="0.4"/>

  <!-- Título e Metadados Nobres -->
  <g transform="translate(48, 380)">
    <text x="0" y="40" font-family="sans-serif" font-weight="900" font-size="38" fill="{text}">Duna: Parte 2</text>
    <g transform="translate(0, 78)">
      <rect x="0" y="-18" width="56" height="26" rx="6" fill="{surf}" stroke="{line}"/>
      <text x="10" y="0" font-family="sans-serif" font-weight="700" font-size="15" fill="{text}">2024</text>
      <rect x="66" y="-18" width="94" height="26" rx="6" fill="{surf}" stroke="{line}"/>
      <text x="76" y="0" font-family="sans-serif" font-weight="700" font-size="15" fill="{text}">DUBLADO</text>
      <rect x="170" y="-18" width="80" height="26" rx="6" fill="{surf}" stroke="{line}"/>
      <text x="180" y="0" font-family="sans-serif" font-weight="700" font-size="15" fill="{text}">4K HDR</text>
      <circle cx="270" cy="-6" r="6" fill="#FBBF24"/>
      <text x="284" y="0" font-family="sans-serif" font-weight="700" font-size="16" fill="{text}">8.6</text>
    </g>
  </g>

  <!-- Botão Largo de Vidro com Reprodução Imediata (Assistir Agora) -->
  <g transform="translate(48, 510)">
    <rect width="450" height="88" rx="22" fill="#7A40F2"/>
    <polygon points="170,30 196,44 170,58" fill="#FFFFFF"/>
    <text x="210" y="52" font-family="sans-serif" font-weight="800" font-size="24" fill="#FFFFFF">Assistir Agora</text>

    <!-- Botões Auxiliares (Favoritar, Baixar, Seerr) -->
    <rect x="470" y="0" width="88" height="88" rx="22" fill="{surf}" stroke="{line}"/>
    <circle cx="514" cy="44" r="16" fill="none" stroke="{text}" stroke-width="2.5"/>
    <rect x="578" y="0" width="46" height="88" rx="22" fill="{surf}" stroke="{line}"/>
    <path d="M601 32 V54 M594 47 L601 54 L608 47" fill="none" stroke="{text}" stroke-width="2.5"/>
  </g>

  <!-- Trilho de Episódios 16:9 / Capítulos -->
  <g transform="translate(48, 650)">
    <text x="0" y="0" font-family="sans-serif" font-weight="800" font-size="24" fill="{text}">Capítulos e Partes</text>
    <!-- Episódio 1 -->
    <g transform="translate(0, 24)">
      <rect width="624" height="110" rx="20" fill="{surf}" stroke="{line}"/>
      <rect x="14" y="14" width="146" height="82" rx="12" fill="#2E1065"/>
      <circle cx="87" cy="55" r="18" fill="{accent}"/>
      <polygon points="83,48 95,55 83,62" fill="#FFFFFF"/>
      <text x="180" y="46" font-family="sans-serif" font-weight="700" font-size="20" fill="{text}">1. O Começo em Arrakis</text>
      <text x="180" y="76" font-family="sans-serif" font-size="16" fill="{text2}">54 min • 4K HDR Atmos</text>
    </g>
    <!-- Episódio 2 -->
    <g transform="translate(0, 150)">
      <rect width="624" height="110" rx="20" fill="{surf}" stroke="{line}"/>
      <rect x="14" y="14" width="146" height="82" rx="12" fill="#2E1065"/>
      <circle cx="87" cy="55" r="18" fill="{accent}"/>
      <polygon points="83,48 95,55 83,62" fill="#FFFFFF"/>
      <text x="180" y="46" font-family="sans-serif" font-weight="700" font-size="20" fill="{text}">2. Os Vermes da Areia</text>
      <text x="180" y="76" font-family="sans-serif" font-size="16" fill="{text2}">61 min • 4K HDR Atmos</text>
    </g>
  </g>

  <!-- Modal Flutuante de Toque Longo (Esboço 04B) Sobreposto -->
  <rect width="{W}" height="{H}" fill="#000000" fill-opacity="0.55"/>
  <g transform="translate(100, 960)">
    <rect width="520" height="340" rx="26" fill="{surf}" stroke="{accent}" stroke-width="1.5"/>
    <text x="32" y="46" font-family="sans-serif" font-weight="800" font-size="22" fill="{text}">Menu de Toque Longo (500ms)</text>
    <g transform="translate(32, 70)">
      <!-- Linha 1 -->
      <rect y="0" width="456" height="54" rx="12" fill="rgba(255,255,255,0.04)"/>
      <text x="18" y="34" font-family="sans-serif" font-size="18" fill="{text}">Ir para o título</text>
      <path d="M420 22 L430 32 L420 42" fill="none" stroke="{accent}" stroke-width="2.5"/>
      <!-- Linha 2 -->
      <rect y="64" width="456" height="54" rx="12" fill="rgba(255,255,255,0.04)"/>
      <text x="18" y="98" font-family="sans-serif" font-size="18" fill="{text}">Marcar como visto</text>
      <circle cx="425" cy="91" r="7" fill="#34D399"/>
      <!-- Linha 3 -->
      <rect y="128" width="456" height="54" rx="12" fill="rgba(255,255,255,0.04)"/>
      <text x="18" y="162" font-family="sans-serif" font-size="18" fill="{text}">Favoritar</text>
      <path d="M420 162 C415 152 435 152 425 167 Z" fill="#F87171"/>
      <!-- Linha 4 -->
      <rect y="192" width="456" height="54" rx="12" fill="rgba(255,255,255,0.04)"/>
      <text x="18" y="226" font-family="sans-serif" font-size="18" fill="{text}">Baixar para o aparelho</text>
      <path d="M425 212 V226 M420 221 L425 226 L430 221" fill="none" stroke="#38BDF8" stroke-width="2.2"/>
    </g>
  </g>
</svg>"""


def render_settings():
  bg = '#0B0910'
  surf = '#140F22'
  line = '#2E2248'
  text = '#F4F1FA'
  text2 = '#A99FBB'
  accent = '#7A40F2'

  return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
  <rect width="{W}" height="{H}" fill="{bg}"/>

  <!-- Status Bar -->
  <text x="56" y="58" font-family="sans-serif" font-weight="600" font-size="22" fill="{text}" opacity="0.8">01:58</text>

  <!-- Topo -->
  <g transform="translate(48, 110)">
    <text x="0" y="0" font-family="sans-serif" font-weight="900" font-size="34" fill="{text}">Configurações</text>
    <rect x="520" y="-30" width="104" height="34" rx="8" fill="rgba(52, 211, 153, 0.15)" stroke="#34D399" stroke-width="0.8"/>
    <text x="536" y="-8" font-family="sans-serif" font-weight="800" font-size="13" fill="#34D399" letter-spacing="1">OTIMIZADO</text>
  </g>

  <!-- Card Aparelho Reconhecido -->
  <g transform="translate(48, 150)">
    <rect width="624" height="110" rx="22" fill="{surf}" stroke="{line}"/>
    <rect x="20" y="20" width="70" height="70" rx="16" fill="{accent}" fill-opacity="0.18"/>
    <rect x="42" y="36" width="26" height="38" rx="4" fill="none" stroke="{accent}" stroke-width="2.5"/>
    <text x="110" y="48" font-family="sans-serif" font-size="17" fill="{text2}">Aparelho Reconhecido</text>
    <text x="110" y="78" font-family="sans-serif" font-weight="800" font-size="22" fill="{text}">Motorola Edge 60 Pro</text>
    <text x="110" y="102" font-family="sans-serif" font-size="15" fill="{text2}">Snapdragon 7 Gen 3 • 12GB RAM • 144Hz pOLED</text>
  </g>

  <!-- Seletor de Abas (Geral vs Avançado) -->
  <g transform="translate(48, 280)">
    <rect width="624" height="64" rx="16" fill="rgba(255,255,255,0.04)"/>
    <rect x="8" y="8" width="300" height="48" rx="12" fill="{accent}"/>
    <text x="158" y="40" text-anchor="middle" font-family="sans-serif" font-weight="800" font-size="20" fill="#FFFFFF">Geral</text>
    <text x="466" y="40" text-anchor="middle" font-family="sans-serif" font-weight="600" font-size="20" fill="{text2}">Avançado</text>
  </g>

  <!-- Seção Aparência e Tema -->
  <g transform="translate(48, 380)">
    <text x="0" y="0" font-family="sans-serif" font-weight="800" font-size="21" fill="{accent}">Aparência e Tema</text>
    <!-- Card Shikkoku (Selecionado) -->
    <g transform="translate(0, 16)">
      <rect width="302" height="150" rx="20" fill="{surf}" stroke="#9D74FF" stroke-width="2.2"/>
      <rect x="14" y="14" width="274" height="66" rx="10" fill="#0B0910" stroke="rgba(255,255,255,0.1)"/>
      <rect x="30" y="32" width="28" height="28" rx="6" fill="#7444E0"/>
      <text x="44" y="52" text-anchor="middle" font-family="sans-serif" font-weight="bold" font-size="16" fill="#FFFFFF">炳</text>
      <text x="70" y="51" font-family="sans-serif" font-weight="800" font-size="15" letter-spacing="1" fill="#F4F1FA">HEISUCA</text>
      <text x="16" y="112" font-family="sans-serif" font-weight="800" font-size="19" fill="{text}">Shikkoku</text>
      <text x="16" y="134" font-family="sans-serif" font-size="15" fill="{text2}">Escuro OLED</text>
      <circle cx="270" cy="120" r="12" fill="#9D74FF"/>
      <path d="M265 120 L269 124 L276 116" fill="none" stroke="#FFFFFF" stroke-width="2"/>
    </g>
    <!-- Card Hisui -->
    <g transform="translate(322, 16)">
      <rect width="302" height="150" rx="20" fill="{surf}" stroke="{line}" stroke-width="0.8"/>
      <rect x="14" y="14" width="274" height="66" rx="10" fill="#F7F3EC" stroke="#CBD5E1"/>
      <rect x="30" y="32" width="28" height="28" rx="6" fill="#047857"/>
      <text x="44" y="52" text-anchor="middle" font-family="sans-serif" font-weight="bold" font-size="16" fill="#FFFFFF">炳</text>
      <text x="70" y="51" font-family="sans-serif" font-weight="800" font-size="15" letter-spacing="1" fill="#134E4A">HEISUCA</text>
      <text x="16" y="112" font-family="sans-serif" font-weight="800" font-size="19" fill="{text}">Hisui</text>
      <text x="16" y="134" font-family="sans-serif" font-size="15" fill="{text2}">Claro Esmeralda</text>
    </g>
  </g>

  <!-- Seção Reprodução e Vídeo -->
  <g transform="translate(48, 590)">
    <text x="0" y="0" font-family="sans-serif" font-weight="800" font-size="21" fill="{accent}">Reprodução e Vídeo</text>
    <!-- Item 1 -->
    <g transform="translate(0, 16)">
      <rect width="624" height="90" rx="18" fill="{surf}" stroke="{line}"/>
      <text x="20" y="38" font-family="sans-serif" font-weight="700" font-size="19" fill="{text}">Qualidade Original Direta</text>
      <text x="20" y="66" font-family="sans-serif" font-size="15" fill="{text2}">Priorizar Direct Play sem transcodificação</text>
      <!-- Switch ligado -->
      <rect x="540" y="28" width="60" height="34" rx="17" fill="{accent}"/>
      <circle cx="578" cy="45" r="13" fill="#FFFFFF"/>
    </g>
    <!-- Item 2 -->
    <g transform="translate(0, 120)">
      <rect width="624" height="90" rx="18" fill="{surf}" stroke="{line}"/>
      <text x="20" y="38" font-family="sans-serif" font-weight="700" font-size="19" fill="{text}">Pular Abertura Automático</text>
      <text x="20" y="66" font-family="sans-serif" font-size="15" fill="{text2}">Avança créditos iniciais instantaneamente</text>
      <rect x="540" y="28" width="60" height="34" rx="17" fill="{accent}"/>
      <circle cx="578" cy="45" r="13" fill="#FFFFFF"/>
    </g>
  </g>

  <!-- Seção Mini Player & Notificações -->
  <g transform="translate(48, 840)">
    <text x="0" y="0" font-family="sans-serif" font-weight="800" font-size="21" fill="{accent}">Área de Notificação &amp; Mini Player</text>
    <g transform="translate(0, 16)">
      <rect width="624" height="90" rx="18" fill="{surf}" stroke="{line}"/>
      <text x="20" y="38" font-family="sans-serif" font-weight="700" font-size="19" fill="{text}">Mini Player na Barra de Notificação</text>
      <text x="20" y="66" font-family="sans-serif" font-size="15" fill="{text2}">MediaSession nativa com controles de Play/Pausa e capa</text>
      <rect x="540" y="28" width="60" height="34" rx="17" fill="{accent}"/>
      <circle cx="578" cy="45" r="13" fill="#FFFFFF"/>
    </g>
  </g>
</svg>"""


screens = [
    (
        "c2_s1",
        render_home("shikkoku"),
        "1. Home Flagship (Shikkoku)",
        "TopBar com HEISUCA colado ao selo carmim;",
        "Continuar 16:9, Top 10 e Ilha Flutuante",
    ),
    (
        "c2_s2",
        render_home("hisui"),
        "2. Home Flagship (Hisui Claro)",
        "Selo verde jade oficial (#047857) e texto escuro;",
        "scrim claro de alto contraste e ilha adaptada",
    ),
    (
        "c2_s3",
        render_details_sheet(),
        "3. Ficha Técnica &amp; Toque Longo",
        "Botão 'Assistir' com disparo imediato da rota;",
        "Menu 500ms haptic sem fundos roxos no claro",
    ),
    (
        "c2_s4",
        render_settings(),
        "4. Configurações &amp; Reconhecimento",
        "Detecção de Snapdragon/12GB RAM/144Hz; seletor",
        "de tema integrado e abas Geral/Avançado",
    ),
]

cards_svg = []
for idx, (name, content_svg, title, l1, l2) in enumerate(screens):
  svg_p = OUT_DIR / f"{name}.svg"
  png_p = OUT_DIR / f"{name}.png"
  svg_p.write_text(content_svg)
  subprocess.run(
      ["rsvg-convert", "-w", str(W), "-h", str(H), str(svg_p), "-o", str(png_p)],
      check=True,
  )
  b64 = base64.b64encode(png_p.read_bytes()).decode()
  x = 48 + idx * (360 + 34)
  y = 120
  border_col = "#047857" if idx == 1 else "#7444E0"
  title_col = "#34D399" if idx == 1 else "#C084FC"
  cards_svg.append(f"""
    <g transform="translate({x}, {y})">
      <clipPath id="cp{idx}">
        <rect width="360" height="800" rx="26"/>
      </clipPath>
      <image href="data:image/png;base64,{b64}" width="360" height="800" clip-path="url(#cp{idx})"/>
      <rect width="360" height="800" rx="26" fill="none" stroke="{border_col}" stroke-width="2.5" stroke-opacity="0.85"/>
      <text x="4" y="834" font-family="sans-serif" font-weight="700" font-size="18" fill="{title_col}">{title}</text>
      <text x="4" y="860" font-family="sans-serif" font-weight="400" font-size="14.5" fill="#dcd7e8">{l1}</text>
      <text x="4" y="882" font-family="sans-serif" font-weight="400" font-size="14.5" fill="#dcd7e8">{l2}</text>
    </g>
    """)

board_svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1640 1060" width="1640" height="1060">
  <rect width="1640" height="1060" fill="#0B0910"/>
  <text x="48" y="52" font-family="sans-serif" font-weight="800" font-size="26" fill="#F4F1FA" letter-spacing="1">CICLO 2 — REVALIDAÇÃO COMPLETA: HOME, FICHA TÉCNICA, DETALHES E CONFIGURAÇÕES</text>
  <text x="48" y="84" font-family="sans-serif" font-weight="400" font-size="16.5" fill="#B4ACC6">Alinhamento rigoroso com os Esboços 03B, 04, 04B e 05 no Motorola Edge 60 Pro</text>
  {"".join(cards_svg)}
</svg>"""

board_svg_path = OUT_DIR / "heisuca_ciclo2_revalidacao.svg"
board_png_path = OUT_DIR / "heisuca_ciclo2_revalidacao_prancha.png"
board_svg_path.write_text(board_svg)
subprocess.run(
    [
        "rsvg-convert",
        "-w",
        "1640",
        "-h",
        "1060",
        str(board_svg_path),
        "-o",
        str(board_png_path),
    ],
    check=True,
)
print("Prancha Ciclo 2 gerada com sucesso:", board_png_path.stat().st_size)
