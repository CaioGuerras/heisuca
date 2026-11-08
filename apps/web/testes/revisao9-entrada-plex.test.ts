import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ErroEntradaPlex, passoSeguinte } from '../src/api/fluxo-plex.ts';
import { bancada, nos, texto } from './visual7-harness.ts';

for (const nome of ['liberado', 'outra-pessoa']) {
  test(`Revisão9: entrada Plex ${nome === 'liberado' ? 'liberada conecta' : 'restrita não grava sessão antes de recusar'}`, async () => {
    let conexoes = 0, saidas = 0;
    const b = bancada('../src/telas/Entrada.tsx', 'PainelPlex', {
      '../api/servidor.ts': { entradaJellyfin: {}, ErroEntradaPlex, passoSeguinte, cancelada: () => false,
        autorizarPlex: async () => ({ conta: { id: 'u', nome }, servidores: [{ name: 'Servidor', clientIdentifier: 's' }] }),
        conectarPlex: async () => { conexoes++; return { nome }; } },
    }, { AbortController }, fonte => fonte.replaceAll('import.meta.env.VITE_SO_USUARIO', JSON.stringify('liberado')));
    const props = { terminou: async () => { saidas++; return nome === 'liberado'; }, topo: null, aviso: null };
    try {
      const v = b.render('PainelPlex', props); b.efeitos();
      await nos(v, 'button').find(n => texto(n) === 'Entrar com Plex').props.onClick();
      const permitido = nome === 'liberado';
      assert.equal(conexoes, permitido ? 1 : 0, 'conectarPlex persiste a sessão antes de terminou');
      assert.equal(saidas, permitido ? 1 : 0);
      if (!permitido) assert.match(texto(b.render('PainelPlex', props)), /Esta versão de teste ainda não está aberta/);
    } finally { b.desmontar(); }
  });
}
