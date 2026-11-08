// Minha conta (PLANO §10): regras da troca de senha e da foto, sem DOM e sem rede (testável no node).
// Senha vazia é permitida: a "Senha atual" fica vazia quando a conta não tem senha (muitas contas começam assim), e a
// "Nova senha" vazia, com a atual digitada, tira a senha da conta (o Jellyfin aceita; a tela pede confirmação antes).
export type Senhas = { atual: string; nova: string; confirma: string };
export type CampoSenha = keyof Senhas;
export type Validacao = { ok: true; semSenha: boolean } | { ok: false; campo: CampoSenha; texto: string };

// temSenha: o que o servidor diz (HasPassword); undefined = não sabemos
export function validarSenha(v: Senhas, temSenha?: boolean): Validacao {
  if (v.nova !== v.confirma) return { ok: false, campo: 'confirma', texto: 'As duas senhas novas não são iguais.' };
  if (!v.nova && (temSenha === false || !v.atual)) return { ok: false, campo: 'nova', texto: 'Digite a nova senha.' };
  if (v.nova && v.nova === v.atual) return { ok: false, campo: 'nova', texto: 'A nova senha é igual à atual.' };
  return { ok: true, semSenha: !v.nova };
}

// erro da troca (a API lança Error("<caminho>: <status>"); falha de rede = TypeError do fetch)
export function erroDaSenha(x: unknown): { campo?: CampoSenha; texto: string } {
  const m = x instanceof Error ? x.message : String(x);
  if (/: 40[03]$/.test(m)) return { campo: 'atual', texto: 'Senha atual incorreta.' };
  if (m === 'sessão vencida') return { texto: 'Sua sessão venceu. Entre de novo para trocar a senha.' };
  if (x instanceof TypeError) return { texto: 'Sem conexão com o servidor. Confira a internet e tente de novo.' };
  return { texto: 'Não deu para trocar a senha agora. Tente de novo.' };
}

export const sucessoDaSenha = (semSenha: boolean) => semSenha
  ? 'Senha removida. A conta agora entra sem senha, em todos os aparelhos.'
  : 'Senha trocada. Nos outros aparelhos, entre de novo com a senha nova.';

export const TIPOS_FOTO = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
export const MAX_FOTO = 10 * 1024 * 1024;
export function validarFoto(f: { type: string; size: number }): string | null {
  if (!TIPOS_FOTO.includes(f.type)) return 'Escolha uma imagem JPG, PNG, WebP ou GIF.';
  if (f.size > MAX_FOTO) return 'Imagem grande demais: o máximo é 10 MB.';
  if (f.size <= 0) return 'Esse arquivo está vazio. Escolha outra imagem.';
  return null;
}
