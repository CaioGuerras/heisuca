// Perfil do aparelho para o PlaybackInfo: o que este navegador toca sem conversão (perguntado ao próprio <video>).
// Regra: tocar direto sempre que der; converter só o necessário (áudio antes do vídeo) e sempre em HLS.

const v = document.createElement('video');
const toca = (tipo: string) => !!v.canPlayType && v.canPlayType(tipo).replace('no', '') !== '';
const mse = (tipo: string) => {
  const M = (window as unknown as { MediaSource?: { isTypeSupported(t: string): boolean } }).MediaSource;
  return !!M && M.isTypeSupported(tipo);
};
const ok = (tipo: string) => toca(tipo) || mse(tipo);

// ASS desenhada no navegador (JASSUB: WebAssembly + worker de módulo, Chrome 80+/Safari 15+). Sem isso, o servidor grava.
function workerDeModulo(): boolean {
  let ok = false;
  try { new Worker('data:,', { get type() { ok = true; return 'module'; } } as WorkerOptions).terminate(); } catch { /* só testa */ }
  return ok;
}
export const assNoNavegador = typeof WebAssembly === 'object' && typeof Worker === 'function' && workerDeModulo();

// MKV que tocou só o áudio: lembrado por aparelho (o player marca; o perfil deixa de pedir MKV direto)
const SEM_MKV = 'hs-sem-mkv', TRINTA_DIAS = 30 * 86_400_000;
export function marcarMkvFalhou() { try { localStorage.setItem(SEM_MKV, String(Date.now())); } catch { /* modo privado */ } }
function mkvFalhou(): boolean {
  try { return Date.now() - Number(localStorage.getItem(SEM_MKV) || 0) < TRINTA_DIAS; } catch { return false; }
}

export function perfilDoAparelho() {
  const video = ['h264'];
  if (ok('video/mp4; codecs="hvc1.1.6.L120.90"') || ok('video/mp4; codecs="hev1.1.6.L120.90"')) video.push('hevc');
  if (ok('video/mp4; codecs="av01.0.08M.08"')) video.push('av1');
  if (ok('video/webm; codecs="vp9"')) video.push('vp9');

  const audio = ['aac', 'mp3'];
  if (ok('audio/mp4; codecs="opus"') || ok('audio/webm; codecs="opus"')) audio.push('opus');
  if (ok('audio/mp4; codecs="flac"')) audio.push('flac');
  if (ok('audio/mp4; codecs="ac-3"')) audio.push('ac3');
  if (ok('audio/mp4; codecs="ec-3"')) audio.push('eac3');

  // MKV: só onde o navegador diz que toca (Chrome/Edge novos dizem; o Chromium 128 não), mais as TVs Samsung/LG, como no
  // jellyfin-web. Aparelho que já abriu MKV sem mostrar o vídeo (Chrome do Android, 18/10) fica 30 dias sem.
  const mkv = !mkvFalhou() && (toca('video/x-matroska') || /Tizen|Web0S/.test(navigator.userAgent));
  const recipientes = ['mp4', 'm4v', ...(mkv ? ['mkv'] : []), ...(video.includes('vp9') ? ['webm'] : [])];
  // HLS em fMP4: o Jellyfin só remonta HEVC nesse formato (em .ts converteria o vídeo inteiro)
  const hlsVideo = video.filter(c => c === 'h264' || c === 'hevc');
  const hlsAudio = ['aac', ...audio.filter(c => c !== 'aac' && c !== 'flac')];

  return {
    Name: 'Heisuca',
    MaxStreamingBitrate: 140_000_000,
    MaxStaticBitrate: 140_000_000,
    MusicStreamingTranscodingBitrate: 384_000,
    DirectPlayProfiles: [
      { Type: 'Video', Container: recipientes.join(','), VideoCodec: video.join(','), AudioCodec: audio.join(',') },
      { Type: 'Audio', Container: 'mp3,aac,m4a,flac,ogg,opus,webm' },
    ],
    TranscodingProfiles: [
      { Type: 'Video', Container: 'mp4', Protocol: 'hls', Context: 'Streaming', VideoCodec: hlsVideo.join(','),
        AudioCodec: hlsAudio.join(','), MaxAudioChannels: '6', BreakOnNonKeyFrames: true, MinSegments: 1 },
      { Type: 'Audio', Container: 'aac', Protocol: 'hls', Context: 'Streaming', AudioCodec: 'aac', MaxAudioChannels: '2' },
    ],
    ContainerProfiles: [],
    CodecProfiles: [],
    // texto vira WebVTT por fora (sem converter o vídeo); imagem (PGS/VobSub) precisa ser gravada no vídeo
    SubtitleProfiles: [
      { Format: 'vtt', Method: 'External' },
      ...(assNoNavegador ? [{ Format: 'ass', Method: 'External' }, { Format: 'ssa', Method: 'External' }] : []),
      { Format: 'pgssub', Method: 'Encode' },
      { Format: 'dvdsub', Method: 'Encode' },
      { Format: 'dvbsub', Method: 'Encode' },
    ],
  };
}

export const hlsNativo = () => toca('application/vnd.apple.mpegurl');
