--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Applications that are normally used together i.e. productivity
hl.window_rule({
    name = "Inactive Opacity Alternative",
    match = {
        class = "helium|codium|com.system76.CosmicFiles",
    },
    opacity = "1.0 override 0.82 override 1.0 override",
})

-- Wezterm has its own opacity functionality
hl.window_rule({
    name = "Inactive Opacity Exceptions",
    match = {
        class = "org.wezfurlong.wezterm",
    },
    opacity = "1.0 override 1.0 override 1.0 override",
})

-------------------------
---- WORKSPACE GROUPS ----
-------------------------

--main monitor
hl.workspace_rule({ workspace = "1", monitor = "DP-1",     persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1",     persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1",     persistent = true })

--side monitors
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", persistent = true })

hl.workspace_rule({ workspace = "7", monitor = "DP-2",     persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "DP-2",     persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "DP-2",     persistent = true })

--Huion Tablet
hl.workspace_rule({workspace = "10", monitor = "HDMI-A-2"})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})