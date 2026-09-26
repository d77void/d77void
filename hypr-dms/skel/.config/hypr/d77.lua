-- d77void additions on top of the DMS-generated config. Kept in their own
-- file (required last from hyprland.lua) so a DMS rewrite of hyprland.lua
-- or of dms/*.lua doesn't lose them, and so they override DMS defaults.

-- Session services. The compositor doesn't run XDG autostart, so pipewire
-- has to be spawned here; dms itself is started from the DMS_STARTUP block.
hl.on("hyprland.start", function()
	hl.exec_cmd("pipewire")
	hl.exec_cmd("udiskie -at")
	hl.exec_cmd("/usr/libexec/polkit-mate-authentication-agent-1")
	hl.exec_cmd("dcal run --session --hidden")
end)

-- Binds: DMS puts the overview on both SUPER + TAB and SUPER + O; keep
-- SUPER + TAB for it and give SUPER + O to d77run
hl.unbind("SUPER + O")
hl.bind("SUPER + O", hl.dsp.exec_cmd("d77run"))

-- Window rules
hl.window_rule({
	-- Ignore maximize requests from all apps
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})
hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})
hl.window_rule({ name = "d77run", match = { class = "^(d77run)$" }, float = true })
hl.window_rule({ name = "qt-sudo", match = { class = "^(qt-sudo)$" }, float = true })
hl.window_rule({ name = "nmtui-float", match = { class = "^(nmtui-float)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.quickshell)$" }, float = true })
