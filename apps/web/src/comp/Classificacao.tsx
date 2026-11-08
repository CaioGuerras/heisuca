import { faixaClassificacao } from '../dados/acabamento';
import './classificacao.css';

export function Classificacao({ valor }: { valor: string }) {
  const faixa = faixaClassificacao(valor);
  return <span class={`selo-idade${faixa ? ` idade-${faixa}` : ''}`}
    aria-label={`Classificação indicativa: ${faixa === 'L' ? 'livre' : faixa ? `${faixa} anos` : valor}`}>
    {faixa || valor}
  </span>;
}
