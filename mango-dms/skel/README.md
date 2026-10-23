## Hello

Thank you for trying d77void Mango DMS edition.

This ISO uses MangoWC together with Dux Shell (dms, formerly DankMaterialShell) as the shell.

To install use Calamares from the menu.

## Keybinds

super + t / super + return -> terminal

super + space -> app launcher

super + comma -> settings

super + a -> control center

super + d -> dash

super + m -> media

super + n -> notepad

super + ctrl + n -> notifications

super + v -> clipboard

ctrl + alt + m / ctrl + alt + delete -> task manager

super + o -> d77run

super + y -> wallpaper picker

super + x -> powermenu

super + shift + c -> color picker

super + alt + n -> night mode

super + alt + l -> lock screen

super + q -> close window

print -> region screenshot

ctrl + print -> full screen screenshot

alt + print -> window screenshot

super + shift + / -> keybinds cheat sheet

alt + tab -> overview

super + s -> scratchpad

super + shift + e -> quit mango

## Mango tweaks

The d77void additions (autostart programs, extra window rules and binds) live in ~/.config/mango/d77.conf. Add your own changes there: `dms setup` rewrites ~/.config/mango/config.conf (keeping a .backup copy) but never touches that file. If they stop applying after running `dms setup`, add `source=./d77.conf` back at the end of ~/.config/mango/config.conf.

The files inside ~/.config/mango/dms/ belong to DMS and are regenerated from its settings; change gaps, borders, colors, input and monitors from the DMS settings instead.

Have fun!
