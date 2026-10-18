import { render } from 'preact';
import { App } from './app';
import { ligarFoco } from './foco';
import { ligarVoltar } from './rota';
import './marca/base.css';
import './marca/temas/shikkoku.css';
import './marca/temas/hisui.css';
import './marca/temas/ichigo.css';
import './marca/temas/sorairo.css';
import './marca/temas/shinju.css';
import './estilo.css';

const tema = new URLSearchParams(location.search).get('tema') || localStorage.getItem('heisuca.tema') || 'shikkoku';
document.documentElement.dataset.tema = tema;
if (/Tizen|Web0S|SMART-TV/i.test(navigator.userAgent)) document.documentElement.classList.add('tv');
ligarFoco();
ligarVoltar();

// erros do navegador vão para o log do nginx da VPS (GET /__heisuca/__erro?m=…, 404 de propósito), sem token
function avisarErro(m: string) {
  const limpo = m.replace(/(api_key|ApiKey|Token)=[^&"\s]+/gi, '$1=…').slice(0, 300);
  new Image().src = `${import.meta.env.BASE_URL}__erro?m=${encodeURIComponent(limpo)}&h=${encodeURIComponent(location.hash)}`;
}
addEventListener('error', e => avisarErro(`${e.message} @${e.filename?.split('/').pop()}:${e.lineno}`));
addEventListener('unhandledrejection', e => avisarErro(`promessa: ${e.reason instanceof Error ? e.reason.message : String(e.reason)}`));
render(<App />, document.getElementById('app')!);
