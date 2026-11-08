import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bancada, nos, resolver, texto } from './visual7-harness.ts';

const s = { tipo: 'jellyfin', token: 'teste', servidor: 'local', usuarioId: 'u' };
const biblioteca = (Id: string) => ({ Id, Name: `Biblioteca ${Id}`, Type: 'CollectionFolder' });
const itens = (n: number, prefixo = 'a') => Array.from({ length: n }, (_, k) => ({ Id: `${prefixo}${k}`, Name: `${prefixo}${k}`, Type: 'Movie' }));
const pagina = (n: number, total = n, prefixo = 'a') => ({ Items: itens(n, prefixo), TotalRecordCount: total });
function pendente() {
  let ok!: (v: any) => void, falhar!: (e: Error) => void;
  const promessa = new Promise((a, b) => { ok = a; falhar = b; });
  return { promessa, ok, falhar };
}
function tela(api: any) {
  const Fileira = () => null, CartaoPoster = () => null, removidos = new Set<string>();
  const chamadas: { servidor: string; id: string; limite: number }[] = [];
  const b = bancada('../src/telas/Favoritos.tsx', 'Favoritos', {
    '../api/servidor.ts': { bibliotecasDeVideo: api.libs || (async () => [biblioteca('A'), biblioteca('B')]),
      favoritos: (sessao: any, id: string, limite: number) => { chamadas.push({ servidor: sessao.servidor, id, limite }); return api.favoritos(id, limite, sessao); },
      hashDe: () => '' },
    '../cor/paleta': { usePaleta() {}, fundoDesfocado: () => '' },
    '../comp/Cartoes': { CartaoPoster }, '../comp/Fileira': { Fileira },
    '../estado/usuario': { useMudancas() {}, dadosDe: (_: any, i: any) => ({ IsFavorite: !removidos.has(i.Id) }) },
  }, { scrollY: 0, addEventListener() {}, removeEventListener() {} });
  let sessao = s;
  const render = () => b.render('Favoritos', { s: sessao });
  return { b, chamadas, render, removidos,
    fileiras: (v: any) => nos(v, Fileira), cartoes: (v: any) => nos(v, CartaoPoster),
    sessao(nova: any) { sessao = nova; } };
}

test('Favoritos: Ver tudo usa o total real, bloqueia duplicação e mantém bibliotecas separadas', async () => {
  const todos = pendente();
  const t = tela({ favoritos: async (id: string, limite: number) => id === 'B' ? pagina(1, 1, 'b') : limite === 60 ? pagina(60, 62) : todos.promessa });
  t.render(); t.b.efeitos(); await resolver();
  let v = t.render();
  const secoes = t.fileiras(v);
  assert.deepEqual(secoes.map(n => n.props.titulo), ['Biblioteca A', 'Biblioteca B']);
  const abrir = secoes[0].props.verTudo;
  abrir(); abrir();
  assert.deepEqual(t.chamadas.map(c => [c.id, c.limite]), [['A', 60], ['B', 60], ['A', 62]]);
  // Dois cliques também recolhem a grade; reabrir durante a consulta não a duplica.
  t.fileiras(t.render())[0].props.verTudo();
  v = t.render();
  assert.match(texto(v), /Carregando favoritos/);
  assert.equal(t.cartoes(v).length, 61, 'não some nenhum cartão enquanto carrega');
  todos.ok(pagina(62)); await resolver();
  v = t.render();
  assert.equal(t.cartoes(v).length, 63);
  assert.ok(!texto(v).includes('Carregando favoritos'));
  nos(v, 'button').find(n => texto(n) === 'Mostrar menos').props.onClick();
  v = t.render();
  t.fileiras(v)[0].props.verTudo();
  assert.equal(t.chamadas.length, 3, 'reabrir dados completos não refaz a consulta');
});

test('Favoritos: falha em Ver tudo conserva os 60 e permite repetir até receber os demais', async () => {
  let falhar = true;
  const t = tela({ favoritos: async (id: string, limite: number) => {
    if (id === 'B') return pagina(0);
    if (limite > 60 && falhar) throw new Error('offline');
    return limite === 60 ? pagina(60, 65) : pagina(65);
  } });
  t.render(); t.b.efeitos(); await resolver();
  t.fileiras(t.render())[0].props.verTudo(); await resolver();
  let v = t.render();
  assert.equal(t.cartoes(v).length, 60);
  assert.match(texto(v), /Não deu para carregar os favoritos de Biblioteca A/);
  falhar = false;
  nos(v, 'button').find(n => texto(n) === 'Tentar de novo').props.onClick(); await resolver();
  v = t.render();
  assert.equal(t.cartoes(v).length, 65);
  assert.ok(!texto(v).includes('Não deu'));
});

test('Favoritos: servidor que limita resposta informa a quantidade, sem fingir Ver tudo completo', async () => {
  const t = tela({ favoritos: async (id: string) => id === 'B' ? pagina(0) : pagina(60, 90) });
  t.render(); t.b.efeitos(); await resolver();
  t.fileiras(t.render())[0].props.verTudo(); await resolver();
  const v = t.render();
  assert.match(texto(v), /Mostrando 60 de 90 favoritos/);
  assert.ok(nos(v, 'button').some(n => texto(n) === 'Tentar carregar todos'));
});

test('Favoritos: erro de uma biblioteca não vira vazio e não esconde a outra; repetir recupera', async () => {
  let falhar = true;
  const t = tela({ favoritos: async (id: string) => {
    if (id === 'A' && falhar) throw new Error('offline');
    return pagina(1, 1, id);
  } });
  t.render(); t.b.efeitos(); await resolver();
  let v = t.render();
  assert.match(texto(v), /Não deu para carregar os favoritos de Biblioteca A/);
  assert.ok(!texto(v).includes('Toque em ♡'));
  assert.equal(t.cartoes(v).length, 1);
  falhar = false;
  nos(v, 'button').find(n => texto(n) === 'Tentar de novo').props.onClick(); await resolver();
  v = t.render();
  assert.equal(t.cartoes(v).length, 2);
  assert.ok(!texto(v).includes('Não deu'));
});

test('Favoritos: erro ao listar bibliotecas tem repetição própria e vazio só após resposta válida', async () => {
  let falhar = true;
  const t = tela({ libs: async () => { if (falhar) throw new Error('offline'); return []; }, favoritos: async () => pagina(0) });
  t.render(); t.b.efeitos(); await resolver();
  let v = t.render();
  assert.match(texto(v), /Não deu para carregar os favoritos/);
  assert.ok(!texto(v).includes('Toque em ♡'));
  falhar = false;
  nos(v, 'button').find(n => texto(n) === 'Tentar de novo').props.onClick();
  t.render(); t.b.efeitos(); await resolver();
  v = t.render();
  assert.match(texto(v), /Toque em ♡/);
  assert.ok(!texto(v).includes('Não deu'));
});

test('Favoritos: resposta antiga de Ver tudo não vaza após troca de servidor com o mesmo token', async () => {
  const antiga = pendente();
  const t = tela({ libs: async () => [biblioteca('A')], favoritos: async (_: string, limite: number, sessao: any) => {
    if (sessao.servidor !== 'local') return pagina(1, 1, 'novo');
    return limite === 60 ? pagina(60, 61) : antiga.promessa;
  } });
  t.render(); t.b.efeitos(); await resolver();
  t.fileiras(t.render())[0].props.verTudo();
  t.sessao({ ...s, servidor: 'outro' });
  t.render(); t.b.efeitos(); await resolver();
  antiga.ok(pagina(61)); await resolver();
  const v = t.render();
  assert.equal(t.cartoes(v).length, 1);
  assert.equal(t.cartoes(v)[0].props.i.Id, 'novo0');
  assert.ok(!texto(v).includes('Carregando favoritos'));
});

test('Favoritos: desfavoritar localmente continua removendo o cartão sem misturar as bibliotecas', async () => {
  const t = tela({ favoritos: async (id: string) => pagina(1, 1, id) });
  t.render(); t.b.efeitos(); await resolver();
  assert.equal(t.cartoes(t.render()).length, 2);
  t.removidos.add('A0');
  let v = t.render();
  assert.equal(t.cartoes(v).length, 1);
  assert.deepEqual(t.fileiras(v).map(n => n.props.titulo), ['Biblioteca B']);
  t.removidos.add('B0');
  v = t.render();
  assert.match(texto(v), /Toque em ♡/);
});

test('Favoritos: remover um favorito da grade completa não cria falsa paginação nem consulta extra', async () => {
  const t = tela({ favoritos: async (id: string) => pagina(2, 2, id) });
  t.render(); t.b.efeitos(); await resolver();
  t.fileiras(t.render())[0].props.verTudo();
  t.removidos.add('A0');
  let v = t.render();
  assert.equal(t.cartoes(v).length, 3);
  assert.ok(!texto(v).includes('Mostrando'));
  nos(v, 'button').find(n => texto(n) === 'Mostrar menos').props.onClick();
  v = t.render();
  t.fileiras(v)[0].props.verTudo();
  assert.equal(t.chamadas.length, 2);
});
