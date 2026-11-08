import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as conta from '../src/dados/conta.ts';
import { bancada, nos, resolver } from './visual7-harness.ts';

for (const fase of ['envio', 'releitura', 'ativa']) {
  test(`Revisão9: foto da conta ${fase === 'ativa' ? 'ativa atualiza a sessão' : `desmontada durante ${fase} não restaura sessão antiga`}`, async () => {
    let concluirEnvio!: () => void, concluirLeitura!: (u: unknown) => void;
    const envio = new Promise<void>(r => { concluirEnvio = r; });
    const leitura = new Promise(r => { concluirLeitura = r; });
    const mudancas: any[] = [];
    const b = bancada('../src/telas/Paginas.tsx', 'Conta', {
      '../api/servidor.ts': { pode: (_s: unknown, c: string) => c === 'foto', fotoUsuario: () => '',
        trocarFoto: () => envio, euMesmo: () => leitura },
      '../dados/conta.ts': conta, '../comp/Aviso': { avisar() {} },
    });
    try {
      const v = b.render('Conta', { s: { servidor: 'A', usuarioId: 'u', nome: 'Teste' }, aoMudar: (s: any) => mudancas.push(s) });
      b.efeitos();
      nos(v, 'input').find(n => n.props.type === 'file').props.onChange({ target: {
        files: [{ type: 'image/png', size: 100 }], value: 'foto.png',
      } });
      if (fase === 'envio') b.desmontar();
      concluirEnvio(); await resolver();
      if (fase === 'releitura') b.desmontar();
      concluirLeitura({ PrimaryImageTag: 'foto-nova' }); await resolver();
      assert.equal(mudancas.length, fase === 'ativa' ? 1 : 0, 'aoMudar escreve na sessão global do App');
      if (fase === 'ativa') assert.equal(mudancas[0].fotoTag, 'foto-nova');
    } finally { b.desmontar(); }
  });
}
