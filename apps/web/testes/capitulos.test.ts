// Teste da regra de Pular abertura/créditos (PLANO §13).  Rodar:  node --test testes/capitulos.test.ts   (Node ≥ 22.18)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { puloEm, tipoDoCapitulo } from '../src/player/capitulos.ts';

const T = 10_000_000;
const cap = (Name: string, seg: number) => ({ Name, StartPositionTicks: seg * T });

test('nomes reais do acervo viram abertura', () => {
  for (const n of ['Intro', 'INTRO', 'Opening', 'OP', 'op', 'OP 1', 'OP1', 'OP 01', 'Opening 2', 'Opening Credits',
    'opening credits', 'Title Sequence', 'Abertura', 'abertura 1', ' Intro ', 'Opening_Credits', 'OP #2'])
    assert.equal(tipoDoCapitulo(n), 'abertura', n);
});

test('nomes reais do acervo viram créditos', () => {
  for (const n of ['Credits', 'credits', 'End Credits', 'END CREDITS', 'ED', 'ed', 'ED 1', 'ED2', 'Ending', 'Ending 01',
    'Encerramento', 'encerramento 2', 'End-Credits', 'Créditos', 'Creditos finais'])
    assert.equal(tipoDoCapitulo(n), 'creditos', n);
});

test('o resto não é reconhecido (sem falso positivo)', () => {
  for (const n of ['Prologue', 'Prólogo', 'Episode', 'Chapter 1', 'Capítulo 2', 'Part A', 'Opening Scene', 'Edward',
    'Opera', 'Credits Scene?', 'Preview', 'Next Episode', 'Recap', '', undefined, null, '1'])
    assert.equal(tipoDoCapitulo(n), null, String(n));
});

// o vídeo de teste do servidor falso: Prólogo 0 s · Abertura 8 s · Episódio 38 s · Créditos 80 s (90 s no total)
const TESTE = [cap('Prologue', 0), cap('Opening', 8), cap('Episode', 38), cap('Credits', 80)];

test('vídeo de teste: botão só dentro do capítulo', () => {
  assert.equal(puloEm(TESTE, 0, true), null);
  assert.equal(puloEm(TESTE, 7.9, true), null);
  assert.deepEqual(puloEm(TESTE, 8, true), { tipo: 'abertura', ate: 38 });
  assert.deepEqual(puloEm(TESTE, 10, true), { tipo: 'abertura', ate: 38 });
  assert.deepEqual(puloEm(TESTE, 37.9, true), { tipo: 'abertura', ate: 38 });
  assert.equal(puloEm(TESTE, 38, true), null);
  assert.equal(puloEm(TESTE, 79, true), null);
});

test('créditos no último capítulo: próximo episódio, ou nada sem sucessor', () => {
  assert.deepEqual(puloEm(TESTE, 85, true), { tipo: 'creditos', ate: 'proximo' });
  assert.equal(puloEm(TESTE, 85, false), null);
});

test('filme: créditos no último capítulo encerram; no meio, pulam para o capítulo seguinte', () => {
  assert.deepEqual(puloEm(TESTE, 85, false, true), { tipo: 'creditos', ate: 'fim' });
  assert.deepEqual(puloEm(TESTE, 10, false, true), { tipo: 'abertura', ate: 38 });
  assert.equal(puloEm(TESTE, 50, false, true), null);
  const c = [cap('Intro', 0), cap('Chapter 2', 90), cap('End Credits', 1300), cap('Post-credits', 1400)];
  assert.deepEqual(puloEm(c, 1350, false, true), { tipo: 'creditos', ate: 1400 });
});

test('créditos no meio (cena pós-créditos) pulam para o capítulo seguinte', () => {
  const c = [cap('Intro', 0), cap('Chapter 2', 90), cap('End Credits', 1300), cap('Post-credits', 1400)];
  assert.deepEqual(puloEm(c, 1350, false), { tipo: 'creditos', ate: 1400 });
  assert.deepEqual(puloEm(c, 30, false), { tipo: 'abertura', ate: 90 });
});

test('capítulos fora de ordem e listas vazias', () => {
  const c = [cap('Episode', 38), cap('OP', 8), cap('Prologue', 0)];
  assert.deepEqual(puloEm(c, 9, false), { tipo: 'abertura', ate: 38 });
  assert.equal(puloEm([], 9, true), null);
  assert.equal(puloEm(undefined, 9, true), null);
  assert.equal(puloEm(c, NaN, true), null);
});
