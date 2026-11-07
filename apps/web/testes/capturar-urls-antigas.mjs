// Rodar SOMENTE na base antiga (ff7e787), antes da refatoração. Entradas inteiramente fictícias.
import { readFile, writeFile } from 'node:fs/promises';
import * as jf from '../src/api/jellyfin.ts';
const s = { servidor: 'https://midia.example.invalid', token: 'credencial-ficticia', usuarioId: 'usuario-exemplo', nome: 'Teste' };
const i = { Id: 'item-opaco', Name: 'Exemplo', Type: 'Movie', ImageTags: { Primary: 'capa-opaca', Logo: 'logo-opaco' }, BackdropImageTags: ['fundo-opaco'] };
const f = { Id: 'fonte-opaca', Container: 'mp4', SupportsDirectPlay: true, SupportsDirectStream: true, SupportsTranscoding: true, MediaStreams: [] };
globalThis.localStorage = { getItem: () => 'aparelho-ficticio' };
let chamada;
globalThis.fetch = async url => { chamada = String(url); return new Response(JSON.stringify({ Items: [] })); };
const urls = {};
await jf.item(s, i.Id); urls.item = chamada;
await jf.episodios(s, 'serie-opaca', 'temporada-opaca'); urls.episodios = chamada;
urls.capa = jf.capa(s, i); urls.fundo = jf.fundo(s, i); urls.logo = jf.logo(s, i);
urls.urlDireta = jf.urlDireta(s, i.Id, f, 'sessao-opaca');
urls.legenda = jf.urlServidor(s, '/Videos/item-opaco/Subtitles/2/Stream.vtt');
urls.anexo = jf.urlServidor(s, '/Videos/item-opaco/Attachments/0?nome=fonte.ttf');
// Executa literalmente a expressão de URL do código antigo da Busca, sem transcrevê-la.
const busca = await readFile(new URL('../src/telas/Busca.tsx', import.meta.url), 'utf8');
const campos = busca.match(/const CAMPOS = ('[^']+');/)[1];
const expressao = busca.match(/obter<\{ Items: Item\[\] \}>\(s, ([\s\S]*?)\)\.then/)[1];
const caminho = new Function('s', 'b', 'q', `const CAMPOS = ${campos}; return ${expressao};`)(s, { Id: 'biblioteca-opaca' }, encodeURIComponent('ação & lua'));
await jf.obter(s, caminho); urls.buscar = chamada;
await writeFile(new URL('./urls-antigas.json', import.meta.url), JSON.stringify({ base: 'ff7e787', s, i, f, urls }, null, 2) + '\n');
console.log('URLs capturadas do código antigo:', Object.keys(urls).join(', '));
