## Hello

Thank you for trying d77void wmd77 edition.

This is a very special edition; not only d77void turns 1 year but also 
it ships my WM, developed with Penrose Libs and written in Rust.

Also, I swapped the usual apps nano and ranger for fresh and joshuto, using some new 
Rust apps.

## Side Note

The bar is ATG (At the Gates), a Quickshell shell for Xorg: launcher, workspaces,
weather, wallpaper picker, session menu and volume/brightness OSD. The screen is
locked with Amorphis, which amorphis-idle also starts after 5 minutes idle.

Your settings live in ~/.config/wmd77/ (config.toml and startup.sh) and
~/.config/amorphis/. Every wmd77 option, with comments, is in
/usr/share/wmd77/config.toml.example; Kantele also edits them from a GUI.

The keyboard layout is left as the X server sets it up. To change it, add a
[keyboard] section to ~/.config/wmd77/config.toml (for example layout = "pt")
and press super + shift + r.

If you want to dig more on the WM configurations, download a tarball from Github or clone the repository
https://github.com/dani-77/wmd77 and play with it.

## Installer

To install use Calamares from the menu.

## After Install

Don't forget to run d77-welcome after install.

I strongly advise you to uninstall Calamares using d77-welcome.

## Keybinds

By default:

super + return -> st (terminal)

super + d -> ATG launcher

super + r -> d77run

super + y -> wallpaper picker

super + x -> session menu

super + l or super + t -> lock (Amorphis)

super + j/k -> focus next/previous window

super + shift + j/k -> swap focused window

super + m -> change layout

super + q -> kill focused window

super + s -> scratchpad

super + shift + r -> reload the config

super + shift + q -> quit WM

Print -> scrot

Volume and brightness keys -> change the level and show the OSD

## Credits

- Huge thanks to [sminez](https://github.com/sminez) for the fantastic Penrose Library, examples and HowTo videos in Youtube.


Happy hacking!

