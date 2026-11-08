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
