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
