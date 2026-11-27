#!/bin/bash
# d77void: wmd77 session startup with the ATG bar.

# Tap to click with either touchpad driver: synaptics (synclient) or libinput.
synclient TapButton1=1 2>/dev/null ||
	for id in $(xinput list --id-only 2>/dev/null); do
		xinput list-props "$id" 2>/dev/null | grep -q "libinput Tapping Enabled (" &&
			xinput set-prop "$id" "libinput Tapping Enabled" 1
	done
dunst &
udiskie -a &
xcompmgr -c -f -n &
amorphis-idle &
redshift -P -l 41.16:-8.62 &
~/.auto.sh &
QT_QPA_PLATFORM=xcb XDG_CONFIG_DIRS="/usr/share:${XDG_CONFIG_DIRS:-/etc/xdg}" qs -n -d -c atg
