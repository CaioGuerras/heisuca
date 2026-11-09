import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { acaoDaTecla, ajustarVolume, alternarPip, sairDoPip, aplicarVelocidade, VELOCIDADES } from '../src/player/controles.ts';
const fonte = (nome: string) => readFileSync(new URL(`../src/${nome}`, import.meta.url), 'utf8');

test('1: PiP alterna e encerra somente a janela deste vídeo', async () => {
  let entrou = 0, saiu = 0;
  const v = { requestPictureInPicture: async () => { entrou++; } };
  const d = { pictureInPictureEnabled: true, pictureInPictureElement: null as unknown, exitPictureInPicture: async () => { saiu++; } };
  await alternarPip(d, v); assert.equal(entrou, 1);
  d.pictureInPictureElement = {}; await sairDoPip(d, v); assert.equal(saiu, 0);
  d.pictureInPictureElement = v; await alternarPip(d, v); assert.equal(saiu, 1);
  await sairDoPip(d, v); assert.equal(saiu, 2);
  d.pictureInPictureEnabled = false; d.pictureInPictureElement = null;
  await alternarPip(d, v); assert.equal(entrou, 1);
  assert.match(fonte('telas/Player.tsx'), /sairDoPip\(document, video.current\)/);
});

test('2: velocidades permitidas, inválida recusada e vídeo novo volta a 1', () => {
  assert.deepEqual(VELOCIDADES, [0.5, 0.75, 1, 1.25, 1.5, 2]);
  const v = { playbackRate: 1 }; aplicarVelocidade(v, 1.5); assert.equal(v.playbackRate, 1.5);
  aplicarVelocidade(v, 9); assert.equal(v.playbackRate, 1.5);
  aplicarVelocidade(v, 1); assert.equal(v.playbackRate, 1);
  assert.match(fonte('telas/Player.tsx'), /aplicarVelocidade\(video.current, 1\)/);
  assert.match(fonte('player/PainelFaixas.tsx'), /VELOCIDADES.map/);
});

test('3: novos atalhos e volume respeitam campos de texto e limites', () => {
  for (const [codigo, acao] of [[38, 'volumeMais'], [40, 'volumeMenos'], [67, 'legenda'], [74, 'recuar'], [76, 'avancar'], [80, 'pip']] as const) {
    assert.equal(acaoDaTecla(codigo, null), acao);
    for (const alvo of [{ tagName: 'INPUT', type: 'search' }, { tagName: 'TEXTAREA' }, { tagName: 'DIV', isContentEditable: true }, { tagName: 'SELECT' }])
      assert.equal(acaoDaTecla(codigo, alvo), null);
  }
  assert.equal(acaoDaTecla(80, { tagName: 'INPUT', type: 'range' }), 'pip');
  assert.equal(ajustarVolume(0.98, 1), 1); assert.equal(ajustarVolume(0.02, -1), 0);
  assert.equal(ajustarVolume(0.5, 1), 0.55);
});

test('4: prévia só existe durante ponteiro na barra, sem pré-carregamento de imagens', () => {
  const p = fonte('player/PreviaBarra.tsx');
  assert.match(p, /onPointerEnter/); assert.match(p, /onPointerLeave/);
  assert.match(p, /backgroundPosition/); assert.match(p, /previaImagem\(s, it, ponto.seg\)/);
  assert.doesNotMatch(p, /fetch\(|new Image|preload/);
});

test('5: fim de filme oferece voltar, repetir e no máximo seis recomendações', () => {
  const p = fonte('telas/Player.tsx');
  assert.match(p, /fim && it\?\.Type === 'Movie'/);
  assert.match(p, /Voltar ao título/); assert.match(p, /Assistir de novo/);
  assert.match(p, /limite=\{6\}/);
});
