#!/bin/sh

xrdb merge ~/.Xresources 
xbacklight -set 10 &
feh --bg-fill ~/Wallpaper/wall_macos3.jpg &
xset r rate 200 50 &
xcompmgr -c -f -n &
synclient TapButton1=1 &
synclient TapButton2=3 &
redshift -l 41.6:-8.62 &
udiskie -a &

dash /etc/xdg/chadwm/scripts/bar.sh &
while type chadwm >/dev/null; do chadwm && continue || break; done
