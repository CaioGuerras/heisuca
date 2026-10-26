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

W, H = 720, 1600  # 20:9 Motorola Edge 60 Pro ratio


def logo_group(selo_color, text_color, scale=1.05, cx=360, cy=330):
  return f"""
    <g transform="translate({cx}, {cy}) scale({scale}) translate(-320, -180)">
      <g transform="translate(114.22, 80.00)">
        <rect width="70.72" height="200" rx="4.64" fill="{selo_color}"/>
        <rect x="4.06" y="4.06" width="62.61" height="191.88" rx="2.32" fill="none" stroke="#FFF8F0" stroke-width="1.45"/>
        <g fill="#FFF8F0">{kanji_paths}</g>
      </g>
      <g fill="{text_color}">{palavra_path}</g>
      <g fill="{text_color}" opacity="0.65">{kata_path}</g>
    </g>
    <text x="{cx}" y="{cy + 75}" text-anchor="middle" font-family="sans-serif" font-size="20" font-weight="500" fill="{text_color}" opacity="0.55">Nada entre você e o filme.</text>
    """


def render_screen(theme='shikkoku', mode='login'):
  if theme == 'shikkoku':
    bg = '#0B0910'
    surf = '#181324'
    line = '#2E2248'
    text = '#F4F1FA'
    text2 = '#A99FBB'
    accent = '#9D74FF'
    btn_grad1 = '#7444E0'
    btn_grad2 = '#9D74FF'
    selo = '#7444E0'
    sheet_bg = '#140F22'
    sheet_card = '#1E1730'
    sheet_line = '#2E2248'
    qr_col = '#9D74FF'
  else:
    bg = '#F7F3EC'
    surf = '#FFFFFF'
    line = '#E2E8F0'
    text = '#134E4A'
    text2 = '#64748B'
    accent = '#047857'
    btn_grad1 = '#059669'
    btn_grad2 = '#047857'
    selo = '#047857'
    sheet_bg = '#F7F3EC'
    sheet_card = '#FFFFFF'
    sheet_line = '#E2E8F0'
    qr_col = '#047857'

  # QR Code icon on top right
  top_qr = f"""
    <!-- Conexão Rápida no canto superior direito -->
    <g transform="translate(630, 95)" opacity="0.95">
      <rect x="0" y="0" width="40" height="40" rx="10" fill="{surf}" stroke="{line}" stroke-width="1.2"/>
      <path d="M10 10 h7 v7 h-7 z M23 10 h7 v7 h-7 z M10 23 h7 v7 h-7 z" fill="{qr_col}"/>
      <rect x="23" y="23" width="7" height="7" fill="{qr_col}"/>
    </g>
    """

  # Form fields: clean without prefilled server address
  val_server = (
      'https://netflix.docaio.com.br' if mode == 'preenchido' else ''
  )
  hint_server = 'https://seuservidor.com' if not val_server else ''
  status_server = (
      'Procurando servidor…'
      if mode == 'preenchido'
      else ''
  )
  dot_col = '#94A3B8'  # Esboço estático: não comprova conexão.
  val_user = 'caio' if mode == 'preenchido' else ''
  hint_user = 'Nome de usuário' if not val_user else ''
  val_pass = '••••••••••' if mode == 'preenchido' else ''
  hint_pass = '••••••••' if not val_pass else ''

  form_svg = f"""
    <!-- Bloco de Campos Verticais Proporcionais em 20:9 -->
    <g transform="translate(60, 560)">
      <!-- Rótulo SERVIDOR -->
      <text x="4" y="0" font-family="sans-serif" font-weight="700" font-size="16" letter-spacing="1" fill="{accent}">SERVIDOR</text>
      <!-- Campo 1 -->
      <rect x="0" y="14" width="600" height="88" rx="22" fill="{surf}" stroke="{line}" stroke-width="1.4"/>
      <circle cx="42" cy="58" r="14" fill="none" stroke="{text2}" stroke-width="2"/>
      <text x="76" y="66" font-family="sans-serif" font-size="24" fill="{text}">{val_server}</text>
      {f'<text x="76" y="66" font-family="sans-serif" font-size="24" fill="{text2}" opacity="0.6">{hint_server}</text>' if hint_server else ''}

      <!-- Esboço: só mostra a procura; não simula resposta on-line -->
      <circle cx="10" cy="124" r="{5 if status_server else 0}" fill="{dot_col}"/>
      <text x="24" y="129" font-family="sans-serif" font-weight="500" font-size="18" fill="{text2}">{status_server}</text>

      <!-- Rótulo USUÁRIO -->
      <text x="4" y="174" font-family="sans-serif" font-weight="700" font-size="16" letter-spacing="1" fill="{accent}">USUÁRIO</text>
      <!-- Campo 2 -->
      <rect x="0" y="188" width="600" height="88" rx="22" fill="{surf}" stroke="{accent if mode=='preenchido' else line}" stroke-width="{2.0 if mode=='preenchido' else 1.4}"/>
      <circle cx="42" cy="232" r="10" fill="none" stroke="{text2}" stroke-width="2"/>
      <path d="M30 248 c0 -8 24 -8 24 0" fill="none" stroke="{text2}" stroke-width="2"/>
      <text x="76" y="240" font-family="sans-serif" font-size="24" fill="{text}">{val_user}</text>
      {f'<text x="76" y="240" font-family="sans-serif" font-size="24" fill="{text2}" opacity="0.6">{hint_user}</text>' if hint_user else ''}

      <!-- Rótulo SENHA -->
      <text x="4" y="318" font-family="sans-serif" font-weight="700" font-size="16" letter-spacing="1" fill="{accent}">SENHA</text>
      <!-- Campo 3 -->
      <rect x="0" y="332" width="600" height="88" rx="22" fill="{surf}" stroke="{line}" stroke-width="1.4"/>
      <rect x="34" y="374" width="16" height="14" rx="3" fill="none" stroke="{text2}" stroke-width="2"/>
      <path d="M37 374 v-5 a5 5 0 0 1 10 0 v5" fill="none" stroke="{text2}" stroke-width="2"/>
      <text x="76" y="384" font-family="sans-serif" font-size="24" fill="{text}">{val_pass}</text>
      {f'<text x="76" y="384" font-family="sans-serif" font-size="24" fill="{text2}" opacity="0.6">{hint_pass}</text>' if hint_pass else ''}

      <!-- Botão Primário: Iniciar sessão -->
      <defs>
        <linearGradient id="btnGrad_{theme}" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stop-color="{btn_grad1}"/>
          <stop offset="100%" stop-color="{btn_grad2}"/>
        </linearGradient>
      </defs>
      <rect x="0" y="468" width="600" height="96" rx="48" fill="url(#btnGrad_{theme})"/>
      <text x="300" y="528" text-anchor="middle" font-family="sans-serif" font-weight="700" font-size="28" fill="#FFFFFF" letter-spacing="0.5">Iniciar sessão</text>

      <!-- Botão Discreto: + Outros servidores e pastas locais -->
      <g transform="translate(300, 640)">
        <circle cx="-135" cy="-8" r="12" fill="none" stroke="{text2}" stroke-width="2"/>
        <path d="M-135 -14 v12 M-141 -8 h12" fill="none" stroke="{text2}" stroke-width="2"/>
        <text x="-112" y="0" font-family="sans-serif" font-weight="500" font-size="22" fill="{text2}">Outros servidores e pastas locais</text>
      </g>
    </g>
    """

  # Sheet 1: Fontes e Servidores
  sheet_sources_svg = ''
  if mode == 'sheet_sources':
    sources = [
        (
            '#E5A00D',
            'Plex Media Server',
            'Entrar com conta Plex (PIN ou navegador)',
        ),
        (
            '#AA5CC3',
            'Servidor Jellyfin',
            'Streaming direto de alta fidelidade com perfis',
        ),
        (
            '#52B54B',
            'Servidor Emby',
            'Conexão direta a biblioteca ou servidor Emby',
        ),
        ('#3B82F6', 'Rede Local (SMB / Samba)', 'Compartilhamento no Wi-Fi, PC ou NAS'),
        (
            '#0EA5E9',
            'Servidor WebDAV / Nuvem',
            'Streaming direto de nuvens privadas compatíveis',
        ),
        (
            '#F97316',
            'Arquivos do Aparelho',
            'Vídeos salvos no armazenamento interno ou SD',
        ),
    ]
    rows = []
    for idx, (bcol, stitle, sdesc) in enumerate(sources):
      ry = 170 + idx * 115
      rows.append(f"""
        <g transform="translate(48, {ry})">
          <rect width="624" height="96" rx="22" fill="{sheet_card}" stroke="{sheet_line}" stroke-width="1.2"/>
          <!-- Badge com cor oficial da marca -->
          <rect x="18" y="16" width="64" height="64" rx="18" fill="{bcol}" fill-opacity="0.18"/>
          <circle cx="50" cy="48" r="14" fill="{bcol}"/>
          <text x="100" y="44" font-family="sans-serif" font-weight="700" font-size="23" fill="{text}">{stitle}</text>
          <text x="100" y="70" font-family="sans-serif" font-weight="400" font-size="17" fill="{text2}">{sdesc}</text>
          <path d="M590 40 L600 48 L590 56" fill="none" stroke="{text2}" stroke-width="2.5" stroke-linecap="round"/>
        </g>
        """)

    sheet_sources_svg = f"""
      <!-- Véu escuro de fundo -->
      <rect width="{W}" height="{H}" fill="#000000" fill-opacity="0.65"/>
      <!-- Folha Inferior deslizante -->
      <g transform="translate(0, 680)">
        <path d="M0 40 Q0 0 40 0 L680 0 Q720 0 720 40 L720 920 L0 920 Z" fill="{sheet_bg}"/>
        <rect x="330" y="18" width="60" height="6" rx="3" fill="{text2}" opacity="0.4"/>
        <text x="48" y="76" font-family="sans-serif" font-weight="800" font-size="28" fill="{text}">Fontes e Servidores</text>
        <text x="48" y="112" font-family="sans-serif" font-weight="400" font-size="19" fill="{text2}">Escolha o protocolo para adicionar uma nova biblioteca</text>
        <!-- Fechar X -->
        <g transform="translate(650, 68)" opacity="0.7">
          <path d="M-8 -8 L8 8 M8 -8 L-8 8" stroke="{text2}" stroke-width="2.6" stroke-linecap="round"/>
        </g>
        {"".join(rows)}
      </g>
      """

  # Sheet 2: Quick Connect
  sheet_qc_svg = ''
  if mode == 'sheet_qc':
    sheet_qc_svg = f"""
      <!-- Véu escuro de fundo -->
      <rect width="{W}" height="{H}" fill="#000000" fill-opacity="0.75"/>
      <!-- Folha Quick Connect -->
      <g transform="translate(0, 920)">
        <path d="M0 40 Q0 0 40 0 L680 0 Q720 0 720 40 L720 680 L0 680 Z" fill="{sheet_bg}"/>
        <rect x="330" y="18" width="60" height="6" rx="3" fill="{text2}" opacity="0.4"/>
        <text x="360" y="80" text-anchor="middle" font-family="sans-serif" font-weight="800" font-size="28" fill="{text}">Conexão Rápida Heisuca</text>
        <text x="360" y="116" text-anchor="middle" font-family="sans-serif" font-weight="400" font-size="19" fill="{text2}">Acesse sua conta sem precisar digitar sua senha</text>

        <!-- Caixa luminosa do código tabular -->
        <g transform="translate(180, 160)">
          <rect width="360" height="110" rx="26" fill="{surf}" stroke="{accent}" stroke-width="2"/>
          <text x="180" y="74" text-anchor="middle" font-family="monospace" font-weight="800" font-size="48" letter-spacing="8" fill="{accent}">482 917</text>
        </g>

        <!-- Instruções claras -->
        <g transform="translate(70, 310)">
          <text x="0" y="0" font-family="sans-serif" font-size="18.5" fill="{text}" opacity="0.9">1. No seu computador ou celular, abra o Jellyfin no navegador</text>
          <text x="0" y="32" font-family="sans-serif" font-size="18.5" fill="{text}" opacity="0.9">2. Vá em Configurações &gt; Conexão Rápida</text>
          <text x="0" y="64" font-family="sans-serif" font-size="18.5" fill="{text}" opacity="0.9">3. Digite o código acima para autorizar o Heisuca</text>
        </g>

        <!-- Indicador de escuta -->
        <g transform="translate(360, 440)">
          <circle cx="-100" cy="-6" r="6" fill="{accent}"/>
          <text x="-80" y="0" font-family="sans-serif" font-size="18" fill="{text2}">Aguardando aprovação em tempo real...</text>
        </g>

        <!-- Botão Cancelar -->
        <rect x="60" y="490" width="600" height="84" rx="20" fill="{surf}" stroke="{line}" stroke-width="1.4"/>
        <text x="360" y="543" text-anchor="middle" font-family="sans-serif" font-weight="600" font-size="24" fill="{text2}">Cancelar</text>
      </g>
      """

  return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
  <rect width="{W}" height="{H}" fill="{bg}"/>

  <!-- Status Bar 20:9 -->
  <text x="56" y="58" font-family="sans-serif" font-weight="600" font-size="22" fill="{text}" opacity="0.75">01:45</text>
  <g transform="translate(605, 40)" fill="{text}" opacity="0.75">
    <rect x="0" y="6" width="6" height="12" rx="1.5"/>
    <rect x="9" y="3" width="6" height="15" rx="1.5"/>
    <rect x="18" y="0" width="6" height="18" rx="1.5"/>
    <rect x="32" y="2" width="26" height="14" rx="3" fill="none" stroke="{text}" stroke-width="2"/>
    <rect x="35" y="5" width="18" height="8" rx="1.5"/>
  </g>

  {top_qr}

  <!-- Logo Heisuca centralizada verticalmente -->
  {logo_group(selo, text, scale=1.05, cx=360, cy=330)}

  {form_svg}
  {sheet_sources_svg}
  {sheet_qc_svg}
</svg>"""


screens = [
    (
        "s1_limpa",
        "shikkoku",
        "login",
        "1. Entrada Limpa (Shikkoku)",
        "Proporção 20:9 balanceada, sem vazio inferior;",
        "botão discreto de outras fontes no rodapé",
    ),
    (
        "s2_sources",
        "shikkoku",
        "sheet_sources",
        "2. Folha Fontes e Servidores",
        "Cores oficiais de cada protocolo (Plex dourado,",
        "Jellyfin roxo, Emby verde, SMB azul, WebDAV ciano)",
    ),
    (
        "s3_qc",
        "shikkoku",
        "sheet_qc",
        "3. Conexão Rápida (Quick Connect)",
        "Acionada no ícone discreto superior; PIN tabular",
        "com fallback automático e aprovação contínua",
    ),
    (
        "s4_hisui",
        "hisui",
        "login",
        "4. Tema Claro (Hisui Verde)",
        "Selo carmim sobre fundo jade e superfícies alvas;",
        "zero fundos roxos indesejados no modo claro",
    ),
]

cards_svg = []
for idx, (name, th, md, title, l1, l2) in enumerate(screens):
  svg_p = OUT_DIR / f"{name}.svg"
  png_p = OUT_DIR / f"{name}.png"
  svg_p.write_text(render_screen(th, md))
  subprocess.run(
      ["rsvg-convert", "-w", str(W), "-h", str(H), str(svg_p), "-o", str(png_p)],
      check=True,
  )
  b64 = base64.b64encode(png_p.read_bytes()).decode()
  x = 48 + idx * (360 + 34)
  y = 120
  border_col = "#047857" if th == "hisui" else "#7444E0"
  title_col = "#34D399" if th == "hisui" else "#C084FC"
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
  <text x="48" y="52" font-family="sans-serif" font-weight="800" font-size="26" fill="#F4F1FA" letter-spacing="1">REVALIDAÇÃO — TELA DE ENTRADA E LOGIN HEISUCA MOBILE (MOTOROLA EDGE 60 PRO)</text>
  <text x="48" y="84" font-family="sans-serif" font-weight="400" font-size="16.5" fill="#B4ACC6">Alinhamento rigoroso com as instruções do Caio: botão discreto inferior, Quick Connect no topo e folha com cores oficiais</text>
  {"".join(cards_svg)}
</svg>"""

board_svg_path = OUT_DIR / "heisuca_login_revalidacao.svg"
board_png_path = OUT_DIR / "heisuca_login_revalidacao_prancha.png"
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
print("Prancha de Revalidação do Login gerada:", board_png_path.stat().st_size)
