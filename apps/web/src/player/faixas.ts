// Nomes das faixas de áudio e legenda como no painel do app completo (app_completo/…foto25): a língua em português na
// linha de cima e o detalhe (título da faixa · formato · canais) embaixo, em vez do DisplayTitle cru do servidor
// ("Português (Brasil) - Portuguese - AAC - Stereo - Padrão", reprovado em heisuca_reprovado/…foto20).
import type { Fluxo } from '../api/jellyfin';

// o Jellyfin manda ISO 639-2 (3 letras); o Intl entende melhor o código de 2 letras
const ISO: Record<string, string> = {
  por: 'pt', pob: 'pt-BR', eng: 'en', jpn: 'ja', spa: 'es', fre: 'fr', fra: 'fr', ger: 'de', deu: 'de', ita: 'it',
  ara: 'ar', kor: 'ko', chi: 'zh', zho: 'zh', rus: 'ru', pol: 'pl', tur: 'tr', hin: 'hi', tha: 'th', vie: 'vi', ind: 'id',
  dut: 'nl', nld: 'nl', swe: 'sv', nor: 'no', dan: 'da', fin: 'fi', heb: 'he', gre: 'el', ell: 'el', hun: 'hu', cze: 'cs',
  ces: 'cs', rum: 'ro', ron: 'ro', ukr: 'uk', may: 'ms', msa: 'ms', fil: 'fil', cat: 'ca', hrv: 'hr', srp: 'sr', bul: 'bg',
};
let nomes: Intl.DisplayNames | null = null;
export function nomeDaLingua(cod?: string): string {
  if (!cod || cod === 'und' || cod === 'mis' || cod === 'zxx') return '';
  try {
    nomes ??= new Intl.DisplayNames(['pt-BR'], { type: 'language' });
    const n = nomes.of(ISO[cod.toLowerCase()] || cod) || '';
    return n && n.toLowerCase() !== cod.toLowerCase() ? n[0].toUpperCase() + n.slice(1) : '';
  } catch { return ''; }
}

const FORMATO: Record<string, string> = { subrip: 'SRT', srt: 'SRT', webvtt: 'VTT', vtt: 'VTT', ass: 'ASS', ssa: 'SSA',
  pgssub: 'PGS', pgs: 'PGS', dvdsub: 'VobSub', dvbsub: 'DVB', mov_text: 'MP4', eac3: 'E-AC-3', ac3: 'AC-3', truehd: 'TrueHD',
  dts: 'DTS', aac: 'AAC', mp3: 'MP3', opus: 'Opus', flac: 'FLAC', vorbis: 'Vorbis' };
const formato = (c?: string) => (c ? FORMATO[c.toLowerCase()] || c.toUpperCase() : '');
const canais = (f: Fluxo) => f.Channels === 1 ? 'Mono' : f.Channels === 2 ? 'Estéreo' : f.Channels === 6 ? '5.1' : f.Channels === 8 ? '7.1'
  : f.Channels ? `${f.Channels} canais` : '';
// o começo do DisplayTitle é o título da faixa (ou a língua, quando a faixa não tem título)
const inicioDoNome = (f: Fluxo) => (f.DisplayTitle || '').split(' - ')[0].trim();

export function rotuloFaixa(f: Fluxo): { nome: string; detalhe: string } {
  const lingua = nomeDaLingua(f.Language);
  const titulo = (f.Title || inicioDoNome(f)).trim();
  if (f.Type === 'Audio') {
    const nome = titulo || lingua || `Faixa ${f.Index}`;
    return { nome, detalhe: [lingua && !nome.startsWith(lingua) ? lingua : '', formato(f.Codec), canais(f)].filter(Boolean).join(' · ') };
  }
  const nome = (lingua || titulo || `Legenda ${f.Index}`) + (f.IsForced ? ' (forçada)' : '');
  return { nome, detalhe: [titulo && titulo !== lingua ? titulo : '', formato(f.Codec)].filter(Boolean).join(' · ') };
}
