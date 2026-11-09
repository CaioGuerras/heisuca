import { render } from 'preact';
import '@fontsource-variable/fraunces/opsz.css';
import '@fontsource-variable/fraunces/opsz-italic.css';
import '@fontsource-variable/inter/opsz.css';
import './estilo/tokens.css';
import './estilo/base.css';
import { App } from './app';

render(<App />, document.getElementById('app')!);
