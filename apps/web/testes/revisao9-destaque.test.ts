import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bancada, nos, resolver } from './visual7-harness.ts';

test('Revisão9: escolher novamente o destaque atual cancela uma troca ainda decodificando', async () => {
  let decodificar!: () => void;
  const dados = { destaque: [{ Id: 'a', Name: 'A' }, { Id: 'b', Name: 'B' }], retomar: [], proximos: [], continuar: [],
    emAlta: { titulo: '', itens: [] }, bibliotecas: [], porBiblioteca: [], emBreve: { tv: [], movie: [] } };
  const b = bancada('../src/telas/Inicio.tsx', 'Inicio', {
    '../api/servidor.ts': { fundo: (_s: unknown, i: any) => i.Id, logo: () => '', hashDe: () => '' },
    '../cor/paleta': { usePaleta() {} },
    '../comp/Cartoes': { anos: () => '', nota: () => '' },
    '../anim/rolagem.ts': { lembranca: () => undefined, lembrar() {} },
    '../dados/inicio': { prepararInicio: async () => dados, carregarSecundario: async () => ({}), hashDoDestaque: () => '' },
  }, {
    Image: class { decode() { return new Promise<void>(r => { decodificar = r; }); } },
    innerWidth: 1000, devicePixelRatio: 1, document: { hidden: false },
    matchMedia: () => ({ matches: false }), setInterval: () => 1, clearInterval() {},
  });
  const props = { s: { token: 'ficticio' }, pedir() {} };
  try {
    b.render('Inicio', props); b.efeitos(); await resolver();
    let v = b.render('Inicio', props); b.efeitos();
    const botao = (rotulo: string) => nos(v, 'button').find(n => n.props['aria-label'] === rotulo);
    const troca = botao('2: B').props.onClick();
    botao('1: A').props.onClick();
    decodificar(); await troca;
    v = b.render('Inicio', props);
    assert.equal(botao('1: A').props['aria-pressed'], true);
    assert.equal(botao('2: B').props['aria-pressed'], false);
  } finally { b.desmontar(); }
});
