-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

hl.layer_rule({
    match = { namespace = "vicinae" },
    blur = true,
    ignore_alpha = 0,
})


hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = { top = 6, right = 6, bottom = 6, left = 6 },

        border_size = 1,

        col = {
            active_border   = { colors = {"#ffffff", "#20063d"}, angle = 45 },
            inactive_border = "#000000",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = true,

        layout = "dwindle",
    },

    dwindle = {
        preserve_split = true,
        --precise_mouse_move = true,
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,
        border_part_of_window = false,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.05,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled = true,
            brightness = 1.2,
            contrast = 1.0,
            size = 12,
            variant = "acrylic",
            vibrancy = 0.9,
            vibrancy_darkness = 0.2,
            proportional = true,
            --noise = 0.0,
            passes = 4,

            acrylic = {
                aberration = 0.25,
                bulb = 70,
                clarity = 0.1,
                refraction = 34,
                tint = '#1e1358b2',
            },
        },

    },
    
    render = {
        cm_auto_hdr = 0,
    },

    animations = {
        enabled = true,
    },
})