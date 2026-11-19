#!/usr/bin/env bash
set -euo pipefail
# Private Fedora container only; unprivileged fixture user.
export RUNNER_TEMP=/tmp/heisuca-fedora
export XDG_RUNTIME_DIR="$RUNNER_TEMP/runtime"
export XDG_DATA_HOME="$RUNNER_TEMP/data"
export XDG_CONFIG_HOME="$RUNNER_TEMP/config"
export XDG_CACHE_HOME="$RUNNER_TEMP/cache"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
chmod 700 "$XDG_RUNTIME_DIR"
export DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1
Xvfb "$DISPLAY" -screen 0 1600x1000x24 -nolisten tcp -ac >"$RUNNER_TEMP/xvfb.log" 2>&1 &
xvfb_pid=$!
weston_pid=
trap '[[ -z "$weston_pid" ]] || kill "$weston_pid" 2>/dev/null || true; kill "$xvfb_pid" 2>/dev/null || true' EXIT
for unused in {1..60}; do [[ -S /tmp/.X11-unix/X99 ]] && break; sleep .25; done
[[ -S /tmp/.X11-unix/X99 ]]
weston --backend=x11-backend.so --renderer=pixman --socket=heisuca-wayland --width=1600 --height=1000 --idle-time=0 --log="$RUNNER_TEMP/weston.log" &
weston_pid=$!
for unused in {1..60}; do [[ -S "$XDG_RUNTIME_DIR/heisuca-wayland" ]] && break; sleep .25; done
[[ -S "$XDG_RUNTIME_DIR/heisuca-wayland" ]]
export WAYLAND_DISPLAY=heisuca-wayland GDK_BACKEND=wayland
printf 'heisuca-fedora-fixture-only' | gnome-keyring-daemon --unlock --components=secrets >/dev/null
pulseaudio --start --exit-idle-time=-1
python3 tool/desktop/capture-native-linux.py --binary /usr/bin/heisuca --output dist/fedora-evidence/installed
printf 'preservar perfil Fedora' > "$XDG_DATA_HOME/app.heisuca.player.desktop/fedora-user-fixture.txt"
