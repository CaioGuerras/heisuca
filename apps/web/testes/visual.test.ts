import { test } from 'node:test';
import assert from 'node:assert/strict';
import { selosDeMidia } from '../src/dados/selos.ts';
import type { Fluxo } from '../src/api/tipos.ts';
const fluxo = (Type: string, dados: Partial<Fluxo> = {}): Fluxo => ({ Index: 0, Type, ...dados });

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
