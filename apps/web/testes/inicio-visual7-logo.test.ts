import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bancada, texto } from './visual7-harness.ts';

test('Home: logo válida aparece; falha da imagem retorna ao nome real do título', () => {
  const b = bancada('../src/telas/Inicio.tsx', 'MarcaDestaque', { '../api/servidor.ts': { logo: () => 'logo.svg' } });
  const props = { s: {}, i: { Id: '1', Name: 'Título do servidor' } };
  let v = b.render('MarcaDestaque', props);
  assert.equal(v.type, 'img');
  assert.equal(v.props.alt, props.i.Name);
  v.props.onError();
  v = b.render('MarcaDestaque', props);
  assert.equal(v.type, 'span');
  assert.equal(v.props.class, 'destaque-nome');
  assert.equal(texto(v), props.i.Name);
});

test('Home: sem URL da logo, o nome aparece imediatamente, sem imagem quebrada', () => {
  const b = bancada('../src/telas/Inicio.tsx', 'MarcaDestaque', { '../api/servidor.ts': { logo: () => '' } });
  const v = b.render('MarcaDestaque', { s: {}, i: { Name: 'Sem logo' } });
  assert.equal(v.type, 'span');
  assert.equal(texto(v), 'Sem logo');
});
