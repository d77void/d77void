#!/bin/sh
# Run a command in a terminal emulator, whichever one is installed.
#
#   terminal.sh [--class CLASS] COMMAND [ARGS...]
#
# Uses $TERMINAL (a command name or absolute path) when it is set and found,
# otherwise the first available terminal from the list below. --class sets the
# window's app-id/class, so a compositor rule can match it (d77void floats
# "nmtui-float").
set -eu

class=
if [ "${1:-}" = "--class" ]; then
    class=$2
    shift 2
fi
[ "$#" -gt 0 ] || { echo "usage: terminal.sh [--class CLASS] COMMAND [ARGS...]" >&2; exit 2; }

term=
for candidate in ${TERMINAL:+"$TERMINAL"} alacritty kitty foot wezterm ghostty st xterm; do
    if command -v "$candidate" >/dev/null 2>&1; then
        term=$candidate
        break
    fi
done
[ -n "$term" ] || { echo "pmmac: no terminal emulator found" >&2; exit 1; }

case "${term##*/}" in
    wezterm) exec "$term" start ${class:+--class "$class"} -- "$@" ;;
    foot)    exec "$term" ${class:+--app-id "$class"} "$@" ;;
    ghostty) exec "$term" ${class:+"--class=$class"} -e "$@" ;;
    st)      exec "$term" ${class:+-c "$class"} -e "$@" ;;
    xterm)   exec "$term" ${class:+-class "$class"} -e "$@" ;;
    *)       exec "$term" ${class:+--class "$class"} -e "$@" ;;
esac
