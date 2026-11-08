import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bancada, nos } from './visual7-harness.ts';

function seletor(largo: boolean) {
  const Folha = () => null, escolhas: string[] = [];
  let mudou: (() => void) | undefined;
  const media = { matches: largo, addEventListener: (_: string, f: () => void) => { mudou = f; },
    removeEventListener: (_: string, f: () => void) => { if (mudou === f) mudou = undefined; } };
  const b = bancada('../src/telas/Titulo.tsx', 'SeletorTemporadas', { '../comp/Folha': { Folha } }, { matchMedia: () => media });
  const props = { temps: [{ Id: 't1', Name: 'Temporada 1' }, { Id: 't2', Name: 'Temporada 2', ChildCount: 12 }],
    selecionada: 't1', selecionar: (id: string) => escolhas.push(id) };
  const render = () => b.render('SeletorTemporadas', props);
  return { b, props, escolhas, render, folha: (v: any) => nos(v, Folha)[0],
    redimensionar(matches: boolean) { media.matches = matches; mudou?.(); },
    get escutando() { return !!mudou; } };
}

test('Temporadas: celular usa folha; computador usa balão com a âncora real do botão', () => {
  for (const largo of [false, true]) {
    const s = seletor(largo);
    let v = s.render();
    const botao = nos(v, 'button')[0], ancora = { getBoundingClientRect: () => ({ left: 20, top: 100 }) };
    botao.ref.current = ancora;
    assert.equal(s.folha(v).props.aberta, false);
    botao.props.onClick();
    v = s.render();
    assert.equal(s.folha(v).props.aberta, true);
    assert.equal(s.folha(v).props.variante, largo ? 'balao' : 'folha');
    assert.equal(s.folha(v).props.ancora, ancora);
  }
});

test('Temporadas: escolher muda só a seleção e fecha a caixa; fechar sem escolha preserva seleção', () => {
  const s = seletor(true);
  let v = s.render();
  nos(v, 'button')[0].props.onClick();
  v = s.render();
  const opcoes = nos(v, 'button').filter(n => n.props.class === 'opcao-linha');
  assert.equal(opcoes[0].props['aria-current'], 'true');
  opcoes[1].props.onClick();
  assert.deepEqual(s.escolhas, ['t2']);
  assert.equal(s.folha(s.render()).props.aberta, false);
  s.folha(v).props.fechar();
  assert.deepEqual(s.escolhas, ['t2']);
});

test('Temporadas: acompanha mudança de largura e remove listener ao desmontar', () => {
  const s = seletor(false);
  s.render(); s.b.efeitos();
  assert.equal(s.escutando, true);
  s.redimensionar(true);
  assert.equal(s.folha(s.render()).props.variante, 'balao');
  s.redimensionar(false);
  assert.equal(s.folha(s.render()).props.variante, 'folha');
  s.b.desmontar();
  assert.equal(s.escutando, false);
});

test('Temporadas: uma temporada mantém o seletor desabilitado', () => {
  const s = seletor(false);
  s.props.temps = s.props.temps.slice(0, 1);
  assert.equal(nos(s.render(), 'button')[0].props.disabled, true);
});
