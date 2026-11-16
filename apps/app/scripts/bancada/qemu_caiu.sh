#!/usr/bin/env bash
# Diz se a tentativa N da bancada caiu porque o qemu do emulador morreu por sinal (infraestrutura),
# e não por falha do app. Uso: qemu_caiu.sh N   (escreve caiu=true|false no GITHUB_OUTPUT)
#
# Critério: o systemd-coredump do runner tem pelo menos N cores do qemu-system. Falha do app (ANR, marco
# faltando, crash do Flutter) não gera core do qemu e NÃO ganha nova tentativa: segue vermelha.
# Com queda, as evidências da tentativa vão para .bancada/evidencias/tentativa-N/, para a próxima não misturar.
set -u
n="${1:?uso: qemu_caiu.sh N}"
# O systemd-coredump pode levar até 2 min para gravar o core do qemu (4 GiB de RAM do AVD).
for _ in $(seq 1 24); do pgrep -x systemd-coredum >/dev/null || break; sleep 5; done
cores=$(sudo coredumpctl list --no-pager --no-legend 2>/dev/null | grep -c 'qemu-system' || true)
echo "Cores do qemu no runner: ${cores:-0} (tentativa $n)"
if [ "${cores:-0}" -ge "$n" ]; then
  caiu=true
  sudo coredumpctl info --no-pager -1 2>/dev/null | grep -E '^ +(Signal|Executable):' || true
else
  caiu=false
fi
# Só arquiva quando haverá nova tentativa; sem queda, o relatório fica onde a classificação lê.
if [ "$caiu" = true ] && [ -d .bancada/evidencias ]; then
  mkdir -p ".bancada/tentativa-$n"
  find .bancada/evidencias -mindepth 1 -maxdepth 1 ! -name 'tentativa-*' -exec mv -t ".bancada/tentativa-$n" {} +
  mv ".bancada/tentativa-$n" ".bancada/evidencias/tentativa-$n"
fi
echo "caiu=$caiu" >> "${GITHUB_OUTPUT:-/dev/stdout}"
echo "Queda do qemu na tentativa $n: $caiu"
