import { render } from 'preact';
import { App } from './app';
import { avisarErro } from './aviso';
import { ligarTema } from './tema';
import './marca/base.css';
import './marca/temas/shikkoku.css';
import './marca/temas/hisui.css';
import './estilo/base.css';

// navegador sem o mínimo: o index.html já mostrou "use o app"; o app não sobe por cima
if (!(window as unknown as { heisucaSemSuporte?: boolean }).heisucaSemSuporte) {
  ligarTema();
  addEventListener('error', e => avisarErro(`${e.message} @${e.filename?.split('/').pop()}:${e.lineno}`));
  addEventListener('unhandledrejection', e => avisarErro(`promessa: ${e.reason instanceof Error ? e.reason.message : String(e.reason)}`));
  render(<App />, document.getElementById('app')!);
}
