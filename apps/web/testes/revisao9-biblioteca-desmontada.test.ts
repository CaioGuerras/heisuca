import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bancada, nos, resolver } from './visual7-harness.ts';

// J9-08 (Branco 6, 08/11): abrir #/b sem id e sair antes da resposta das bibliotecas não pode trocar a URL da tela
// nova (history.replaceState) nem gravar estado do componente desmontado. Sem DOM nem rede.
const libs = [{ Id: 'A', Name: 'Filmes', CollectionType: 'movies' }, { Id: 'B', Name: 'Séries', CollectionType: 'tvshows' }];

for (const caso of ['desmontada', 'ativa', 'erro-desmontada']) {
  test(`Revisão9: Biblioteca sem id ${caso === 'ativa' ? 'ativa grava a última biblioteca na URL'
    : caso === 'desmontada' ? 'desmontada antes da resposta não mexe na URL nem no estado'
    : 'desmontada com erro não grava estado'}`, async () => {
    let responder!: (l: unknown) => void, falhar!: (e: unknown) => void;
    const resposta = new Promise((r, f) => { responder = r; falhar = f; });
    const trocas: string[] = [];
    const history = { state: { n: 1 }, replaceState: (_e: unknown, _t: string, url: string) => { trocas.push(url); } };
    const b = bancada('../src/telas/Biblioteca.tsx', 'Biblioteca', {
      '../api/servidor.ts': { bibliotecasDeVideo: () => resposta },
      '../rota': { ultimaBiblioteca: () => 'B', lembrarBiblioteca() {}, irAba() {}, irTitulo() {}, voltar() {} },
    }, { history });
    const props = { s: { token: 't1', nomeServidor: 'X' } };
    try {
      b.render('Biblioteca', props); b.efeitos();
      if (caso !== 'ativa') b.desmontar();
      if (caso === 'erro-desmontada') falhar(new Error('rede')); else responder(libs);
      await resolver();
      assert.deepEqual(trocas, caso === 'ativa' ? ['#/b/B'] : [], 'history.replaceState só na tela montada');
      // o botão do menu fica desabilitado enquanto não há bibliotecas no estado: prova que setLibs não rodou
      const v = b.render('Biblioteca', props);
      const menu = nos(v, 'button').find(n => n.props['aria-label'] === 'Trocar de biblioteca');
      assert.equal(menu.props.disabled, caso !== 'ativa', 'setLibs só na tela montada');
      // erro na tela desmontada também não grava libs=[] ("Nenhuma biblioteca neste servidor.")
      assert.equal(nos(v, 'p').some(n => n.props.class?.includes('biblioteca-vazio')), false, 'setLibs([]) só na tela montada');
    } finally { b.desmontar(); }
  });
}
