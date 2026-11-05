#!/bin/bash
# d77void: wmd77's /etc/xdg/wmd77/startup.sh, with polybar in place of the
# built-in bar and its bar.sh (see ~/.config/wmd77/config.toml).

conky -c ~/.conkyrc1 &
feh --bg-fill --randomize ~/Wallpaper/ &
synclient TapButton1=1 &
dunst &
udiskie -a &
xcompmgr -c -f -n &
xautolock -time 5 -locker slock &
redshift -l 41.16:-8.62 &
sxhkd -c ~/.config/sxhkd/sxhkdrc &
polybar wmd77 &
