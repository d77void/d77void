# pmMac

pmMac is a desktop shell for Niri and Quickshell. It adds a live dock, a top bar, application search, a control center, a wallpaper picker, and a Wayland lock screen.

## Quick install on Niri

### 1. Install the dependencies

| Feature | What to install |
| --- | --- |
| Desktop shell and application launcher | Niri 26.04 or later, Quickshell 0.3.2 or later with its Wayland, Networking and Qt Quick modules, Python 3, and GTK's `gtk-launch` |
| Installer and icons | GNU Make, Bash, curl, tar, coreutils, and `gtk-update-icon-cache` |
| Niri keyboard shortcuts | [qsd77](https://github.com/dani-77/qsd77) on the Niri session's `PATH` |
| Wallpaper and matching colors | `awww` and `awww-daemon`, and Matugen 4 |
| Control center and power actions | PipeWire for audio, UPower for battery, NetworkManager for the graphical network panel, power-profiles-daemon for power modes, `brightnessctl` for brightness, and elogind or systemd-logind for session power actions |
| Terminal applications | A terminal emulator: `$TERMINAL`, or the first of Alacritty, kitty, foot, WezTerm, Ghostty, st and xterm |
| Lock screen | Quickshell with PAM support and the `/etc/pam.d/amorphis` policy from [Amorphis](https://github.com/dani-77/amorphis), installed for your distribution |

### 2. Install pmMac and the icons

Install from the repository checkout.

```sh
sudo make install
```

The system install puts the Quickshell configuration in `/usr/share/quickshell/pmmac` and the command in `/usr/bin/pmmac`. The installer verifies a pinned [WhiteSur](https://github.com/vinceliuice/WhiteSur-icon-theme) archive and installs the theme in `/usr/share/icons/WhiteSur-pmMac` with its GPL-3.0 license.

### 3. Enable startup and shortcuts in Niri

Add this at the end of `${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl`.

```kdl
include "/usr/share/quickshell/pmmac/niri-pmmac.kdl"
```

The include starts a single pmMac instance at login and assigns the pmMac shortcuts, including the volume and brightness keys. If your Niri config also starts another desktop shell, choose which one should start at login. [Niri include documentation](https://niri-wm.github.io/niri/Configuration:-Include.html)

```sh
niri validate --config "${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
```

From an existing Niri session, start pmMac immediately with:

```sh
qsd77 run -c pmmac
```

`qsd77` adds `/usr/share` to Quickshell's config search. You can also run `pmmac run --daemonize` for a background launch with duplicate detection. If you already have a local config named `pmmac`, Quickshell will select the local copy first.

### 4. Try it

| Shortcut | Action |
| --- | --- |
| Mod + Ctrl + Space | Search applications |
| Mod + Ctrl + Shift + C | Open Control Center |
| Mod + Ctrl + W | Choose a wallpaper |
| Mod + Ctrl + S | Open the session menu |
| Mod + Ctrl + O | Open Niri's overview |
| Mod + Alt + L | Lock the session |
| Volume and brightness keys | Adjust the setting and show the indicator |

In the Control Center, click **Network** to find Wi-Fi networks, connect, enter a password, disconnect, or check an Ethernet connection. Install `nm-connection-editor` to expose **Advanced settings** for profiles, hidden networks, and enterprise Wi-Fi. The **Battery** tile shows the time left, or the time to a full charge while charging, and the current power mode; click it to switch between the power-saver, balanced and performance modes, shown in an indicator.

The launcher and the dock open terminal applications (`Terminal=true` desktop entries) in a terminal as well. Set `TERMINAL` to a terminal executable name or absolute path in the Niri session environment to choose it; otherwise pmMac uses the first one installed from Alacritty, kitty, foot, WezTerm, Ghostty, st and xterm.

Click a dock icon to launch or focus the app. Click the focused app again to hide its windows, and click once more to restore them. Hidden windows appear in the **pmMac Hidden** workspace in Niri's overview. Right-click a dock icon to select an individual window or pin or unpin the app.

The wallpaper picker starts in `~/Wallpaper`. Set `PMMAC_WALLPAPER_DIR` or edit the installed `Settings.qml` to change it. The same file controls default pins, output selection, panel opacity, blur, and dock behavior. Reinstalling preserves your existing copy of `Settings.qml`. Pins and wallpaper choices are saved in `${XDG_STATE_HOME:-$HOME/.local/state}/pmmac`.

The bar shows the battery percentage and charging status. Click the date or time to switch between 24-hour and 12-hour display with AM/PM. pmMac remembers your choice. Volume and brightness indicators show the level as a percentage.

The interface includes European Portuguese and English. Dates and times follow the session locale. Set `PMMAC_LOCALE` before starting the shell to override both.

## Install for your user

Use `make install-user` from the checkout. It installs the command in `~/.local/bin`, the shell in `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/pmmac`, and WhiteSur in `${XDG_DATA_HOME:-$HOME/.local/share}/icons`. Add `~/.local/bin` to the Niri session's `PATH`. Use this include when Niri and Quickshell share the same XDG config root.

```kdl
include "../quickshell/pmmac/niri-pmmac.kdl"
```

## Reinstall the icons

```sh
sudo make install-icons
```

For an offline install, supply the exact archive pinned in the [Makefile](Makefile) with `WHITESUR_ARCHIVE=/path/to/whitesur.tar.gz`. The Makefile supports `DESTDIR` staging for packages. A custom config directory outside the standard lookup can be made visible to Quickshell by adding its root to the Niri session's `XDG_CONFIG_DIRS`.

## Credits

- [quickshell-d77](https://github.com/dani-77/quickshell-d77/tree/dc4edacd5e5c975e698f2729da5454dbb87b39fb) informed the IPC and wallpaper integration.
- [Utumno](https://github.com/dani-77/utumno/tree/a8994a68914b474559d9f4d75317ba5890031206) provided the basis for the per-output lock surfaces and PAM conversation.
- [WhiteSur Icon Theme](https://github.com/vinceliuice/WhiteSur-icon-theme) by vinceliuice and contributors provides the icons.
