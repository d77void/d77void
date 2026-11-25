#!/bin/bash
# d77void: wmd77 session startup with the ATG bar.

synclient TapButton1=1 &
dunst &
udiskie -a &
xcompmgr -c -f -n &
amorphis-idle &
redshift -P -l 41.16:-8.62 &
QT_QPA_PLATFORM=xcb XDG_CONFIG_DIRS="/usr/share:${XDG_CONFIG_DIRS:-/etc/xdg}" qs -n -d -c atg
