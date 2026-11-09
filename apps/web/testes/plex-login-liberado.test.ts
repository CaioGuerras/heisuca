import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ErroEntradaPlex, passoSeguinte } from '../src/api/fluxo-plex.ts';
import { bancada, nos, texto } from './visual7-harness.ts';

// 09/11: a conta Plex do Caio tem nome exibido ("title") diferente do login; a build de teste recusava.
test('Plex: nome exibido diferente, login liberado → entra', async () => {
  let conexoes = 0;
  const b = bancada('../src/telas/Entrada.tsx', 'PainelPlex', {
    '../api/servidor.ts': { entradaJellyfin: {}, ErroEntradaPlex, passoSeguinte, cancelada: () => false,
      autorizarPlex: async () => ({ conta: { id: 'u', nome: 'Caio G.', login: 'CaioGuerras' }, servidores: [{ name: 'Servidor', clientIdentifier: 's' }] }),
      conectarPlex: async () => { conexoes++; return { nome: 'Caio G.' }; } },
  }, { AbortController }, fonte => fonte.replaceAll('import.meta.env.VITE_SO_USUARIO', JSON.stringify('caioguerras')));
  let recebido: unknown[] = [];
  const props = { terminou: async (...a: unknown[]) => { recebido = a; return true; }, topo: null, aviso: null };
  try {
    const v = b.render('PainelPlex', props); b.efeitos();
    await nos(v, 'button').find(n => texto(n) === 'Entrar com Plex').props.onClick();
    assert.equal(conexoes, 1);
    assert.equal(recebido[2], true, 'a conferência já feita pelo login não pode ser refeita pelo nome exibido');
  } finally { b.desmontar(); }
});
