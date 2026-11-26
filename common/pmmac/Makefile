.DEFAULT_GOAL := help

PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
CONFIG_HOME ?= $(PREFIX)/share
DATA_HOME ?= $(PREFIX)/share

PMMAC_CONFIG_DIR := $(DESTDIR)$(CONFIG_HOME)/quickshell/pmmac
PMMAC_COMMAND := $(DESTDIR)$(BINDIR)/pmmac
PMMAC_ICON_DIR := $(DESTDIR)$(DATA_HOME)/icons/WhiteSur-pmMac
SHELL_FILES := $(filter-out Settings.qml,$(wildcard *.qml)) qmldir matugen.toml \
	wallpaper.py window-state.py niri-pmmac.kdl LICENSE

WHITESUR_REV := 73d8040da51a9ed74e47c7366e7e9ff437601a5c
WHITESUR_URL := https://codeload.github.com/vinceliuice/WhiteSur-icon-theme/tar.gz/$(WHITESUR_REV)
WHITESUR_SHA256 := 96661649071d8a9664b40d42abea75286175234473106156e9a4b25f54e6cb0c
WHITESUR_ARCHIVE ?=

.PHONY: help install install-user install-icons

help:
	@printf '%s\n' \
		'make install        Install pmMac system-wide under /usr by default' \
		'make install-user   Install pmMac and the icons for the current user' \
		'make install-icons  Install or refresh just the pmMac icon theme' \
		'Set WHITESUR_ARCHIVE to use a local copy of the pinned archive.' \
		'Override PREFIX, CONFIG_HOME, DATA_HOME or DESTDIR to change the destinations.'

install: install-icons
	@set -eu; \
		config_dir="$(PMMAC_CONFIG_DIR)"; \
		if [ "$$config_dir" -ef . ]; then \
			printf 'Using the checkout already linked at %s\n' "$$config_dir"; \
		elif [ -L "$$config_dir" ]; then \
			printf 'Config directory %s is a symlink to another location. Install under a different CONFIG_HOME or remove that link first.\n' "$$config_dir" >&2; \
			exit 1; \
		else \
			install -d -- "$$config_dir"; \
			install -m 644 -- $(SHELL_FILES) "$$config_dir/"; \
			if [ ! -e "$$config_dir/Settings.qml" ]; then \
				install -m 644 -- Settings.qml "$$config_dir/Settings.qml"; \
			fi; \
		fi; \
		if [ ! "$(PMMAC_COMMAND)" -ef pmmac ]; then \
			install -D -m 755 -- pmmac "$(PMMAC_COMMAND)"; \
		fi; \
		printf 'pmMac installed. Niri include: %s/niri-pmmac.kdl\n' "$$config_dir"

install-user:
	$(MAKE) install PREFIX="$(HOME)/.local" \
		CONFIG_HOME="$(if $(XDG_CONFIG_HOME),$(XDG_CONFIG_HOME),$(HOME)/.config)" \
		DATA_HOME="$(if $(XDG_DATA_HOME),$(XDG_DATA_HOME),$(HOME)/.local/share)"

install-icons:
	@set -eu; \
		tmp=$$(mktemp -d); \
		trap 'rm -rf -- "$$tmp"' 0; \
		trap 'exit 1' HUP INT TERM; \
		if [ -n "$(WHITESUR_ARCHIVE)" ]; then \
			cp -- "$(WHITESUR_ARCHIVE)" "$$tmp/whitesur.tar.gz"; \
		else \
			curl --fail --location --silent --show-error --retry 2 \
				--proto '=https' --proto-redir '=https' \
				--output "$$tmp/whitesur.tar.gz" "$(WHITESUR_URL)"; \
		fi; \
		(cd "$$tmp" && printf '%s  whitesur.tar.gz\n' "$(WHITESUR_SHA256)" | sha256sum -c -); \
		mkdir -- "$$tmp/source" "$$tmp/icons"; \
		tar -xzf "$$tmp/whitesur.tar.gz" --strip-components=1 -C "$$tmp/source"; \
		bash "$$tmp/source/install.sh" -d "$$tmp/icons" -n WhiteSur-pmMac -t default; \
		theme="$$tmp/icons/WhiteSur-pmMac"; \
		install -m 644 -- "$$tmp/source/COPYING" "$$tmp/source/AUTHORS" "$$theme/"; \
		install -d -- "$(PMMAC_ICON_DIR)"; \
		cp -a -- "$$theme/." "$(PMMAC_ICON_DIR)/"; \
		printf 'WhiteSur-pmMac installed in %s\n' "$(PMMAC_ICON_DIR)"
