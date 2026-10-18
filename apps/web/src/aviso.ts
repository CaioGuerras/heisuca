// erros do navegador vão para o log do nginx da VPS (GET /__heisuca/__erro?m=…, 404 de propósito), sem token
export function avisarErro(m: string) {
  const limpo = m.replace(/(api_key|ApiKey|Token)=[^&"\s]+/gi, '$1=…').slice(0, 300);
  new Image().src = `${import.meta.env.BASE_URL}__erro?m=${encodeURIComponent(limpo)}&h=${encodeURIComponent(location.hash)}`;
}
