## Hello

Thank you for trying d77void niri pmMac edition.

This ISO uses niri together with pmMac, a Quickshell desktop shell with a
dock, a top bar, application search, a control center, a wallpaper picker and
a lock screen.

To install use Calamares from the menu.

## Keybinds

super + t -> terminal (Alacritty)

super + space or super + ctrl + space -> application search

super + o -> run dialog (d77run)

super + a or super + ctrl + shift + c -> control center

super + y or super + ctrl + w -> wallpaper picker

super + x or super + ctrl + s -> session menu

super + alt + l -> lock screen

super + d, super + tab or super + ctrl + o -> overview

super + q -> close window

super + shift + e -> logout

super + shift + / -> show all keybinds

print -> region screenshot

ctrl + print -> full screen screenshot

alt + print -> window screenshot

volume/brightness keys -> handled by pmMac

## Dock

Click a dock icon to launch or focus the app; click the focused app again to
hide its windows. Right-click an icon to pick a window or pin/unpin the app.

## niri and pmMac tweaks

Autostart, keyboard layout and outputs live in ~/.config/niri/config.kdl; the
d77void key bindings, layout and input settings in ~/.config/niri/pmmac/.
pmMac's own shortcuts come from /usr/share/quickshell/pmmac/niri-pmmac.kdl,
included at the end of config.kdl.

Wallpapers are picked from ~/Wallpaper; the first login starts with
wall_macos2.jpg. Dock pins, the wallpaper folder,
opacity, blur and dock behaviour are set in
/usr/share/quickshell/pmmac/Settings.qml.
