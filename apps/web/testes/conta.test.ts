// Lado da conta: menu do usuário (§9), Minha conta (§10), Como usar (§11). Só lógica pura, sem DOM e sem rede.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { gruposMenu, proximoFoco } from '../src/dados/menu.ts';

test('menu: ordem do §9 com Como usar no topo enquanto houver passo sem marcar', () => {
  assert.deepEqual(gruposMenu(false), [['ajuda'], ['tema', 'apps', 'sobre'], ['apoiar'], ['servidor', 'sair']]);
});
test('menu: com tudo marcado o Como usar sai do menu e não sobra grupo vazio', () => {
  const g = gruposMenu(true);
  assert.deepEqual(g, [['tema', 'apps', 'sobre'], ['apoiar'], ['servidor', 'sair']]);
  assert.ok(g.every(x => x.length > 0));
  const todos = g.flat(); assert.equal(todos[todos.length - 1], 'sair');
});
test('menu: setas circulam, Home/End vão às pontas, outras teclas não são tratadas', () => {
  assert.equal(proximoFoco(0, 5, 'ArrowDown'), 1);
  assert.equal(proximoFoco(4, 5, 'ArrowDown'), 0);
  assert.equal(proximoFoco(0, 5, 'ArrowUp'), 4);
  assert.equal(proximoFoco(-1, 5, 'ArrowDown'), 0);
  assert.equal(proximoFoco(-1, 5, 'ArrowUp'), 4);
  assert.equal(proximoFoco(2, 5, 'Home'), 0);
  assert.equal(proximoFoco(2, 5, 'End'), 4);
  assert.equal(proximoFoco(2, 5, 'Tab'), -1);
  assert.equal(proximoFoco(0, 0, 'ArrowDown'), -1);
});

import { erroDaSenha, sucessoDaSenha, validarFoto, validarSenha } from '../src/dados/conta.ts';
const sv = (atual: string, nova: string, confirma = nova) => ({ atual, nova, confirma });

test('senha: as duas novas precisam ser iguais', () => {
  assert.deepEqual(validarSenha(sv('a', 'x', 'y')), { ok: false, campo: 'confirma', texto: 'As duas senhas novas não são iguais.' });
});
test('senha: atual vazia é permitida (conta sem senha) e a troca normal passa', () => {
  assert.deepEqual(validarSenha(sv('', 'nova')), { ok: true, semSenha: false });
  assert.deepEqual(validarSenha(sv('', 'nova'), false), { ok: true, semSenha: false });
  assert.deepEqual(validarSenha(sv('velha', 'nova'), true), { ok: true, semSenha: false });
});
test('senha: nova vazia com a atual digitada tira a senha; sem nada digitado pede a nova', () => {
  assert.deepEqual(validarSenha(sv('velha', '')), { ok: true, semSenha: true });
  const r = validarSenha(sv('', ''));
  assert.equal(r.ok, false); assert.equal(!r.ok && r.campo, 'nova');
  const semSenhaJa = validarSenha(sv('', ''), false);
  assert.equal(semSenhaJa.ok, false);
});
test('senha: nova igual à atual é recusada', () => {
  const r = validarSenha(sv('igual', 'igual'));
  assert.equal(r.ok, false); assert.equal(!r.ok && r.texto, 'A nova senha é igual à atual.');
});
test('senha: erros do servidor viram mensagem clara em PT-BR', () => {
  assert.deepEqual(erroDaSenha(new Error('/Users/u1/Password: 403')), { campo: 'atual', texto: 'Senha atual incorreta.' });
  assert.deepEqual(erroDaSenha(new Error('/Users/u1/Password: 400')), { campo: 'atual', texto: 'Senha atual incorreta.' });
  assert.match(erroDaSenha(new TypeError('Failed to fetch')).texto, /Sem conexão/);
  assert.match(erroDaSenha(new Error('sessão vencida')).texto, /sessão venceu/);
  assert.match(erroDaSenha(new Error('/Users/u1/Password: 500')).texto, /Tente de novo/);
  assert.equal(erroDaSenha(new Error('/Users/u1/Password: 500')).campo, undefined);
  assert.match(sucessoDaSenha(false), /outros aparelhos/);
  assert.match(sucessoDaSenha(true), /sem senha/);
});
test('foto: só imagem, até 10 MB, não vazia', () => {
  assert.equal(validarFoto({ type: 'image/png', size: 1000 }), null);
  assert.equal(validarFoto({ type: 'image/webp', size: 10 * 1024 * 1024 }), null);
  assert.match(validarFoto({ type: 'image/heic', size: 1000 })!, /JPG, PNG/);
  assert.match(validarFoto({ type: 'application/pdf', size: 1000 })!, /JPG, PNG/);
  assert.match(validarFoto({ type: 'image/jpeg', size: 10 * 1024 * 1024 + 1 })!, /10 MB/);
  assert.match(validarFoto({ type: 'image/jpeg', size: 0 })!, /vazio/);
});

import { alternarFeito, lerFeitos, passosDaConta, progresso } from '../src/dados/passos.ts';

test('como usar: passos por capacidade (Plex sem senha/foto; pedir só com Seerr)', () => {
  assert.deepEqual(passosDaConta({ senha: true, foto: true, seerr: true }), ['entrar', 'senha', 'foto', 'instalar', 'pedir']);
  assert.deepEqual(passosDaConta({ senha: true, foto: true, seerr: false }), ['entrar', 'senha', 'foto', 'instalar']);
  assert.deepEqual(passosDaConta({ senha: false, foto: false, seerr: false }), ['entrar', 'instalar']);
});
test('como usar: o que está guardado no aparelho é lido sem quebrar', () => {
  assert.deepEqual(lerFeitos('["entrar","foto","entrar",3,null]'), ['entrar', 'foto']);
  for (const lixo of [null, '', '{', '{"a":1}', '"texto"', '42']) assert.deepEqual(lerFeitos(lixo), []);
});
test('como usar: marcar e desmarcar; progresso ignora id que não vale mais', () => {
  assert.deepEqual(alternarFeito(['entrar'], 'foto'), ['entrar', 'foto']);
  assert.deepEqual(alternarFeito(['entrar', 'foto'], 'entrar'), ['foto']);
  const ids = ['entrar', 'senha', 'foto', 'instalar'];
  assert.deepEqual(progresso(ids, ['entrar', 'pedir']), { feitos: 1, total: 4, pct: 25, completo: false, proximo: 'senha' });
  assert.deepEqual(progresso(ids, [...ids, 'pedir']), { feitos: 4, total: 4, pct: 100, completo: true, proximo: null });
  assert.equal(progresso([], []).completo, false);
});

import { readFileSync } from 'node:fs';
test('sobre: slogan, GPL-3.0 com o link do código, Locadora só pelo nome e dedicatória sem nomes da família', () => {
  const fonte = readFileSync(new URL('../src/telas/Paginas.tsx', import.meta.url), 'utf8');
  const sobre = fonte.slice(fonte.indexOf('export function Sobre'), fonte.indexOf('// ---------------------------------------------------------------- Meus pedidos'));
  assert.match(sobre, /Nada entre você e o filme\./);
  assert.match(sobre, /GPL-3\.0/);
  assert.match(fonte, /const CODIGO = 'https:\/\/github\.com\/CaioGuerras\/heisuca'/);
  assert.match(sobre, /<h3>Locadora<\/h3>/);
  assert.doesNotMatch(sobre, /locadora\.cc|href="[^"]*locadora/i);
  assert.match(sobre, /Para a família, que sempre se reuniu diante da tela\./);
  assert.doesNotMatch(sobre, /Isis|Heitor|Caio|Guerras/);
});

import { recursosFaltando, type Ambiente } from '../src/dados/suporte.ts';
const fn = () => undefined;
const cssQue = (nao: string[] = []) => ({ supports: (p: string) => !nao.includes(p) });
const moderno = (): Ambiente => ({ fetch: fn, Promise: fn, IntersectionObserver: fn, ResizeObserver: fn, AbortController: fn,
  URLSearchParams: fn, requestAnimationFrame: fn, matchMedia: fn, CSS: cssQue() });

test('§3.4: navegador com tudo segue para o site normal (nenhum recurso faltando)', () => {
  assert.deepEqual(recursosFaltando(moderno()), []);
});
test('§3.4: falta de fetch, Promise ou IntersectionObserver aparece pelo nome do recurso', () => {
  for (const k of ['fetch', 'Promise', 'IntersectionObserver'] as const) {
    const w = moderno(); delete w[k];
    assert.deepEqual(recursosFaltando(w), [k]);
  }
  assert.deepEqual(recursosFaltando({ ...moderno(), fetch: 'não é função' }), ['fetch']);
});
test('§3.4: CSS sem variáveis, sem CSS.supports ou com supports que lança conta como faltando', () => {
  assert.deepEqual(recursosFaltando({ ...moderno(), CSS: cssQue(['--hs-teste']) }), ['CSS custom properties']);
  assert.deepEqual(recursosFaltando({ ...moderno(), CSS: cssQue(['aspect-ratio']) }), ['aspect-ratio']);
  assert.equal(recursosFaltando({ ...moderno(), CSS: undefined }).length, 4);
  assert.equal(recursosFaltando({ ...moderno(), CSS: { supports: () => { throw new Error('x'); } } }).length, 4);
});
test('§3.4: o teste não olha nome de aparelho (userAgent de TV com tudo = site normal)', () => {
  const w = { ...moderno(), navigator: { userAgent: 'Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 Chrome/85' } } as Ambiente;
  assert.deepEqual(recursosFaltando(w), []);
  assert.equal(recursosFaltando({}).length, 12);
  const fonte = readFileSync(new URL('../src/dados/suporte.ts', import.meta.url), 'utf8');
  assert.doesNotMatch(fonte, /userAgent|Tizen|webOS|SmartTV/);
});
