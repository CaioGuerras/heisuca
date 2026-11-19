#!/usr/bin/env bash
set -euo pipefail
# Runs only in the isolated CI desktop, inside Xvfb and a private D-Bus session.
export XDG_RUNTIME_DIR="${RUNNER_TEMP:?}/heisuca-runtime"
export XDG_DATA_HOME="$RUNNER_TEMP/heisuca-data"
export XDG_CONFIG_HOME="$RUNNER_TEMP/heisuca-config"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
chmod 700 "$XDG_RUNTIME_DIR"
export LIBGL_ALWAYS_SOFTWARE=1
weston --backend=x11-backend.so --renderer=pixman --socket=heisuca-wayland --width=1280 --height=800 --idle-time=0 --log="$RUNNER_TEMP/weston.log" &
weston_pid=$!
trap 'kill "$weston_pid" 2>/dev/null || true' EXIT
for unused in {1..60}; do [[ -S "$XDG_RUNTIME_DIR/heisuca-wayland" ]] && break; sleep .5; done
[[ -S "$XDG_RUNTIME_DIR/heisuca-wayland" ]]
export WAYLAND_DISPLAY=heisuca-wayland
export GDK_BACKEND=wayland
printf 'heisuca-ci-fixture-only' | gnome-keyring-daemon --unlock --components=secrets >/dev/null
pulseaudio --start --exit-idle-time=-1
flutter test --no-pub integration_test/desktop_linux_playback_test.dart -d linux
unset LD_LIBRARY_PATH
python3 tool/desktop/capture-native-linux.py --binary "${HEISUCA_LINUX_BUNDLE:?}"/heisuca --output dist/linux-evidence/unpacked
python3 linux/packaging/build-heisuca.py --bundle "${HEISUCA_LINUX_BUNDLE:?}" --output dist/linux
sudo dpkg -i dist/linux/heisuca-linux-x64.deb
sudo dpkg -i dist/linux/heisuca-linux-x64.deb
sentinel="$XDG_DATA_HOME/heisuca-user-fixture.txt"
printf 'preservar dados do usuario' > "$sentinel"
python3 tool/desktop/capture-native-linux.py --binary /usr/bin/heisuca --output dist/linux-evidence/installed
sudo dpkg --remove heisuca
test -s "$sentinel"
printf '{"installed":true,"reinstalled":true,"uninstalled":true,"userDataPreserved":true}\n' > dist/linux-evidence/installation.json
