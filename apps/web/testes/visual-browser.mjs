// Bancada opcional: preview local, Playwright existente e fixtures; toda rede externa é bloqueada.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright-core');
const origin = process.env.VISUAL_URL || 'http://127.0.0.1:18107';
const out = process.env.VISUAL_OUT || '/tmp/jocasta-visual';
await mkdir(out, { recursive: true });
const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
const filme = n => ({ Id: String(n), Name: n === 1 ? 'Além do horizonte' : `A viagem ${n}`, Type: 'Movie',
  ProductionYear: 2026, OfficialRating: 'BR-12', CommunityRating: 8.6, Genres: ['Aventura', 'Drama'],
  Overview: 'Uma viagem pelas montanhas revela encontros inesperados e histórias que merecem ser lembradas.',
  ImageTags: { Primary: 'p', Logo: 'l', Thumb: 't' }, BackdropImageTags: ['b'],
  ImageBlurHashes: { Primary: { p: hash }, Backdrop: { b: hash } }, RunTimeTicks: 72000000000,
  UserData: { IsFavorite: true, PlaybackPositionTicks: 1200000000 },
  MediaStreams: [{ Index: 0, Type: 'Video', Width: 3840, Height: 1608, Codec: 'hevc', VideoRangeType: 'HDR10' },
    { Index: 1, Type: 'Audio', Language: 'por', Codec: 'aac', Channels: 2 },
    { Index: 2, Type: 'Subtitle', Language: 'por', IsForced: false }] });
const catalogo = Array.from({ length: 65 }, (_, n) => filme(n + 1));
const libs = [{ Id: 'filmes', Name: 'Filmes de aventura e histórias para toda a família', CollectionType: 'movies' }];
const arte = '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800"><defs><linearGradient id="c" x2="0" y2="1"><stop stop-color="#93adb8"/><stop offset="1" stop-color="#233f45"/></linearGradient></defs><path fill="url(#c)" d="M0 0h1200v800H0z"/><circle fill="#eed9ba" cx="850" cy="210" r="80"/><path fill="#516b70" d="M0 600L280 190l260 400 210-220 450 400v30H0z"/><path fill="#29474d" d="M0 700l450-310 420 410H0z"/></svg>';
const logo = '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="160"><text x="300" y="100" text-anchor="middle" fill="white" font-family="serif" font-size="55">ALÉM DO HORIZONTE</text></svg>';
const browser = await chromium.launch({ headless: true, executablePath: process.env.CHROMIUM_PATH, args: ['--no-sandbox'] });
const resultados = [];
try {
  for (const tema of ['roxo', 'verde']) for (const width of [360, 1440]) {
    const context = await browser.newContext({ viewport: { width, height: 900 }, deviceScaleFactor: 1, locale: 'pt-BR' });
    const erros = [], externas = [];
    await context.addInitScript(({ origin, tema }) => {
      localStorage.setItem('heisuca.tema', tema);
      localStorage.setItem('heisuca.sessao', JSON.stringify({ tipo: 'jellyfin', servidor: origin + '/mock',
        token: 'fixture-sem-credencial', usuarioId: 'teste', nome: 'Bancada', nomeServidor: 'Biblioteca de demonstração' }));
      sessionStorage.setItem('heisuca.abriu', '1');
    }, { origin, tema });
    await context.route('**/*', async route => {
      const url = new URL(route.request().url());
      if (url.origin !== origin && !['data:', 'blob:'].includes(url.protocol)) { externas.push(url.origin); return route.abort(); }
      if (!url.pathname.startsWith('/mock')) return route.continue();
      const p = url.pathname.slice(5), q = url.searchParams, json = obj => route.fulfill({ json: obj });
      if (p.includes('/Images/')) return route.fulfill({ contentType: 'image/svg+xml', body: p.includes('/Logo') ? logo : arte });
      if (p === '/UserViews') return json({ Items: libs });
      if (p === '/UserItems/Resume') return json({ Items: catalogo.slice(0, 4) });
      if (p === '/Shows/NextUp') return json({ Items: [] });
      if (p === '/Items/Latest') return json(catalogo.slice(0, 20));
      if (/^\/Items\/\d+$/.test(p)) return json(filme(Number(p.split('/')[2])));
      if (p === '/Items') {
        const start = Number(q.get('startIndex') || 0);
        const Items = q.has('imageTypes') ? catalogo.slice(0, 9) : q.has('searchTerm') ? catalogo.slice(0, 3) : catalogo.slice(start, start + Number(q.get('limit') || 20));
        return json({ Items, TotalRecordCount: catalogo.length });
      }
      if (p === '/cgflix/embreve.json') return json({ s: {}, m: {} });
      return json({ Items: [] });
    });
    const page = await context.newPage(); page.on('pageerror', e => erros.push(e.message));
    await page.goto(origin, { waitUntil: 'networkidle' });
    await page.locator('.destaque-texto').waitFor();
    await page.evaluate(() => document.fonts.ready);
    const verificar = async tela => {
      await page.waitForTimeout(650);
      const medida = await page.evaluate(() => ({ largura: innerWidth, conteudo: document.documentElement.scrollWidth }));
      await page.screenshot({ path: `${out}/${tema}-${width}-${tela}.png` });
      if (medida.conteudo > width) console.log(await page.evaluate(() => [...document.querySelectorAll('body *')].map(el => ({ tag: el.tagName, classe: el.getAttribute('class'), left: el.getBoundingClientRect().left, right: el.getBoundingClientRect().right })).filter(r => r.right > innerWidth + 1 && r.left < innerWidth)));
      assert.ok(medida.conteudo <= width, `${tela}: rolagem lateral ${JSON.stringify(medida)}`);
      const contraste = await page.evaluate(() => {
        const css = getComputedStyle(document.documentElement);
        const rgb = nome => css.getPropertyValue(nome).match(/[\d.]+/g).slice(0, 3).map(Number);
        const lum = valores => valores.map(v => v / 255).map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4).reduce((a, v, n) => a + v * [.2126, .7152, .0722][n], 0);
        const bg = lum(rgb('--hs-pagina'));
        return ['--hs-texto', '--hs-texto-2'].map(nome => { const fg = lum(rgb(nome)); return (Math.max(bg, fg) + .05) / (Math.min(bg, fg) + .05); });
      });
      assert.ok(contraste.every(n => n >= 4.5), `${tela}: contraste ${contraste}`);
      resultados.push({ tema, width, tela, ...medida, contraste });
      console.log(`OK ${tema} ${width} ${tela}`);
    };
    await verificar('home');
    const sobreArte = await page.evaluate(() => ['.cartao-nota', '.cartao-tempo', '.cartao-play'].map(seletor => {
      const el = document.querySelector(seletor);
      if (!el) return null;
      const css = getComputedStyle(el), numeros = valor => valor.match(/[\d.]+/g).map(Number);
      const cor = numeros(css.color), bg = numeros(css.backgroundColor), alpha = bg[3] === undefined ? 1 : bg[3];
      const lum = rgb => rgb.slice(0, 3).map(v => v / 255).map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4).reduce((a, v, n) => a + v * [.2126, .7152, .0722][n], 0);
      const fg = lum(cor), fundo = lum(bg.slice(0, 3).map(v => v * alpha + 255 * (1 - alpha)));
      return { seletor, contraste: (Math.max(fg, fundo) + .05) / (Math.min(fg, fundo) + .05), minimo: seletor === '.cartao-play' ? 3 : 4.5 };
    }).filter(Boolean));
    assert.ok(sobreArte.every(c => c.contraste >= c.minimo), JSON.stringify(sobreArte));
    resultados[resultados.length - 1].sobreArte = sobreArte;
    const contrastePonto = await page.locator('.destaque-pontos button').nth(1).evaluate(el => {
      const css = getComputedStyle(el, '::after'), raiz = getComputedStyle(document.documentElement);
      const rgb = valor => valor.match(/[\d.]+/g).slice(0, 3).map(Number), bg = rgb(raiz.getPropertyValue('--hs-pagina'));
      const alpha = Number(css.opacity), fg = rgb(css.backgroundColor).map((v, n) => v * alpha + bg[n] * (1 - alpha));
      const lum = c => c.map(v => v / 255).map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4).reduce((a, v, n) => a + v * [.2126, .7152, .0722][n], 0);
      return (Math.max(lum(fg), lum(bg)) + .05) / (Math.min(lum(fg), lum(bg)) + .05);
    });
    assert.ok(contrastePonto >= 3, `Indicador: contraste ${contrastePonto}`);
    resultados[resultados.length - 1].contrastePonto = contrastePonto;
    await page.mouse.move(width - 1, 880);
    const primeiro = page.locator('.destaque-pontos button').first(); await primeiro.focus();
    assert.notEqual(await primeiro.evaluate(el => getComputedStyle(el).outlineStyle), 'none');
    if (tema === 'roxo' && width === 360) {
      await page.waitForTimeout(8200); assert.equal(await primeiro.getAttribute('aria-pressed'), 'true');
      await page.emulateMedia({ reducedMotion: 'reduce' }); await primeiro.blur();
      await page.waitForTimeout(8200); assert.equal(await primeiro.getAttribute('aria-pressed'), 'true');
      await page.emulateMedia({ reducedMotion: 'no-preference' });
    }
    if (tema === 'roxo' && width === 360) {
      await page.evaluate(() => {
        const original = HTMLImageElement.prototype.decode;
        let bloqueado = false;
        HTMLImageElement.prototype.decode = function () {
          if (!bloqueado && this.src.includes('/2/Images/Backdrop')) {
            bloqueado = true;
            return new Promise(resolve => { window.liberarArteTeste = resolve; });
          }
          return original.call(this);
        };
      });
      await page.locator('.destaque-pontos button').nth(1).click();
      await page.waitForFunction(() => !!window.liberarArteTeste);
      assert.equal(await primeiro.getAttribute('aria-pressed'), 'true');
      await page.evaluate(() => window.liberarArteTeste());
    } else await page.locator('.destaque-pontos button').nth(1).click();
    await page.waitForFunction(() => document.querySelectorAll('.destaque-pontos button')[1]?.getAttribute('aria-pressed') === 'true');
    await page.goto(origin + '/#/t/1'); await page.locator('.titulo-selos').waitFor();
    assert.deepEqual(await page.locator('.titulo-selos li').allTextContents(), ['Dublado', 'Legendado', '4K', 'HDR']);
    await verificar('titulo');
    await page.goto(origin + '/#/b/filmes'); await page.locator('.biblioteca-grade button.cartao-poster').first().waitFor();
    await page.waitForFunction(() => document.querySelector('.biblioteca-grade')?.getAttribute('aria-busy') === 'false');
    const carregados = await page.locator('.biblioteca-grade button.cartao-poster').count();
    assert.ok(carregados >= 60 && carregados <= 65);
    if (width === 360) assert.equal(await page.locator('.biblioteca-grade').evaluate(el => getComputedStyle(el).gridTemplateColumns.split(' ').length), 3);
    await verificar('biblioteca');
    await page.goto(origin + '/#/fav'); await page.locator('.favoritos .cartao').first().waitFor(); await verificar('favoritos');
    await page.goto(origin + '/#/busca'); await page.locator('.busca-inicial').waitFor(); await verificar('busca-inicial');
    await page.locator('input[type="search"]').fill('viagem'); await page.locator('button.busca-item').first().waitFor(); await verificar('busca');
    const busca = page.locator('button.busca-item').first(); await page.keyboard.press('Tab'); await busca.focus();
    assert.notEqual(await busca.evaluate(el => getComputedStyle(el).outlineStyle), 'none');
    assert.deepEqual(erros, []); assert.deepEqual(externas, []);
    await context.close();
  }
} finally { await browser.close(); }
await writeFile(`${out}/resultado.json`, JSON.stringify(resultados, null, 2) + '\n');
console.log(JSON.stringify({ cenarios: resultados.length, falhas: 0, resultados }, null, 2));
