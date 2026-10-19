// "Instalar o site como app" (PLANO §11 e §12): o Chrome/Edge avisam cedo (beforeinstallprompt) que dá para instalar.
// Este módulo é carregado já na abertura para não perder o aviso; as páginas (carregadas sob demanda) leem daqui.
type AvisoInstalar = Event & { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> };
let aviso: AvisoInstalar | null = null;
const ouvintes = new Set<() => void>();
const avisarTodos = () => ouvintes.forEach(f => f());
addEventListener('beforeinstallprompt', e => { e.preventDefault(); aviso = e as AvisoInstalar; avisarTodos(); });
addEventListener('appinstalled', () => { aviso = null; avisarTodos(); });

export const podeInstalar = () => !!aviso;
export const jaInstalado = () => matchMedia('(display-mode: standalone)').matches || (navigator as { standalone?: boolean }).standalone === true;
export const aoMudarInstalar = (f: () => void) => { ouvintes.add(f); return () => { ouvintes.delete(f); }; };
// abre a pergunta do navegador; true se a pessoa instalou
export async function instalar(): Promise<boolean> {
  const a = aviso;
  if (!a) return false;
  await a.prompt();
  const r = await a.userChoice;
  aviso = null; avisarTodos();
  return r.outcome === 'accepted';
}
