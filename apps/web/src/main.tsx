import { render } from 'preact';
import { App } from './app';
import { ligarFoco } from './foco';
import { ligarVoltar } from './rota';
import { avisarErro } from './aviso';
import { ligarTV } from './tv';
import './marca/base.css';
import './marca/temas/shikkoku.css';
import './marca/temas/hisui.css';
import './marca/temas/ichigo.css';
import './marca/temas/sorairo.css';
import './marca/temas/shinju.css';
import './estilo.css';

const tema = new URLSearchParams(location.search).get('tema') || localStorage.getItem('heisuca.tema') || 'shikkoku';
document.documentElement.dataset.tema = tema;
ligarTV();
ligarFoco();
ligarVoltar();

addEventListener('error', e => avisarErro(`${e.message} @${e.filename?.split('/').pop()}:${e.lineno}`));
addEventListener('unhandledrejection', e => avisarErro(`promessa: ${e.reason instanceof Error ? e.reason.message : String(e.reason)}`));
render(<App />, document.getElementById('app')!);
