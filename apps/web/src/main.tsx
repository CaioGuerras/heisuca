import { render } from 'preact';
import { App } from './app';
import { ligarFoco } from './foco';
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
render(<App />, document.getElementById('app')!);
