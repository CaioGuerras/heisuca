import { test } from 'node:test';
import assert from 'node:assert/strict';
import { selosDeMidia } from '../src/dados/selos.ts';
import type { Fluxo } from '../src/api/tipos.ts';
import { progressoAssistido } from '../src/dados/progresso.ts';
const fluxo = (Type: string, dados: Partial<Fluxo> = {}): Fluxo => ({ Index: 0, Type, ...dados });

test('progresso prefere percentual explícito e limita metadados fora da faixa', () => {
  assert.equal(progressoAssistido({ PlayedPercentage: 0, PlaybackPositionTicks: 50 }, 100), 0);
  assert.equal(progressoAssistido({ PlayedPercentage: 37, PlaybackPositionTicks: 50 }, 100), 37);
  assert.equal(progressoAssistido({ PlayedPercentage: -10 }), 0);
  assert.equal(progressoAssistido({ PlayedPercentage: 150 }), 100);
  assert.equal(progressoAssistido({ Played: true, PlayedPercentage: 5 }), 100);
});
test('progresso só usa ticks com duração válida e tolera valores não finitos', () => {
  assert.equal(progressoAssistido(undefined), 0);
  assert.equal(progressoAssistido({ PlaybackPositionTicks: 25 }, 100), 25);
  assert.equal(progressoAssistido({ PlaybackPositionTicks: 25 }), 0);
  assert.equal(progressoAssistido({ PlaybackPositionTicks: 25 }, 0), 0);
  assert.equal(progressoAssistido({ PlaybackPositionTicks: 25 }, -10), 0);
  assert.equal(progressoAssistido({ PlayedPercentage: NaN, PlaybackPositionTicks: 25 }, 100), 25);
  assert.equal(progressoAssistido({ PlayedPercentage: Infinity, PlaybackPositionTicks: Infinity }, 100), 0);
});

test('selos omitem dados ausentes, legendas parciais e idiomas desconhecidos', () => {
  assert.deepEqual(selosDeMidia([]), []);
  assert.deepEqual(selosDeMidia([fluxo('Audio'), fluxo('Subtitle', { Language: 'por', IsForced: true }),
    fluxo('Video', { Width: 1920, VideoRange: 'SDR' })]), []);
  assert.deepEqual(selosDeMidia([fluxo('Audio', { Language: 'jpn' }), fluxo('Subtitle', { Language: 'eng' }),
    fluxo('Video', { VideoRangeType: 'Unknown' })]), []);
});
test('selos usam áudio/legenda em português e vídeo 4K HDR sem duplicar', () => {
  assert.deepEqual(selosDeMidia([fluxo('Audio', { Language: 'por' }), fluxo('Audio', { Language: 'pt-BR' }),
    fluxo('Subtitle', { Language: 'pt_br' }), fluxo('Video', { Width: 3840, Height: 1608, VideoRangeType: 'HDR10Plus' })]),
    ['Dublado', 'Legendado', '4K', 'HDR']);
});
test('faixas Dolby Vision/HLG e fallback VideoRange são reconhecidos sem inferir HDR de codec ou profundidade', () => {
  for (const VideoRangeType of ['DOVIWithHDR10', 'Dolby Vision', 'HLG']) {
    assert.deepEqual(selosDeMidia([fluxo('Video', { VideoRangeType })]), ['HDR']);
  }
  assert.deepEqual(selosDeMidia([fluxo('Video', { Height: 2160, VideoRangeType: 'Unknown', VideoRange: 'HDR' })]), ['4K', 'HDR']);
  assert.deepEqual(selosDeMidia([fluxo('Video', { Codec: 'hevc', BitDepth: 10 })]), []);
});
