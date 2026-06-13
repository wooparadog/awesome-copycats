-- Notification styling for AwesomeWM's naughty, reproducing the previous dunst
-- setup (Catppuccin Mocha). Required and called from theme.lua with the theme
-- table, so it can set the beautiful notification_* variables and read
-- theme.dir / theme.font.

local awful   = require("awful")
local gears   = require("gears")
local wibox   = require("wibox")
local naughty = require("naughty")
local dpi     = require("beautiful.xresources").apply_dpi

return function(theme)
    theme.notification_bg           = "#1e1e2e"
    theme.notification_fg           = "#cdd6f4"
    theme.notification_border_color = "#b4befe"
    theme.notification_border_width = 1
    theme.notification_margin       = 14
    theme.notification_spacing      = 5
    theme.notification_icon_size    = 64
    theme.notification_max_width    = 520   -- fixed popup width (see request::display)
    theme.notification_max_height   = 160   -- popup grows with content up to this cap
    theme.notification_opacity      = 1
    -- A touch larger than the wibar font, sized in DPI-scaled pixels so it
    -- tracks the screen DPI (the "px" suffix stops Pango double-scaling).
    theme.notification_font         = "Terminus " .. dpi(16) .. "px"
    -- dunst: corner_radius = 5, corners = top-left,bottom (top-right left square).
    theme.notification_shape        = function(cr, w, h)
        gears.shape.partially_rounded_rect(cr, w, h, true, false, true, true, 5)
    end

    naughty.config.defaults.position = "top_right"
    naughty.config.defaults.timeout  = 10

    -- Per-urgency frame and text color, mirroring the old dunstrc. Presets are
    -- fallbacks only (an explicit value always wins). The stock `critical` preset
    -- is white-on-red, so it is recolored to the dark dunst box.
    -- NB: mutate the preset tables in place. naughty.config.mapping (which selects
    -- the preset for incoming DBus notifications) holds references to these exact
    -- tables, so reassigning the keys would not be seen by new notifications.
    local function style_urgency(preset, color, timeout)
        preset.bg           = theme.notification_bg
        preset.fg           = color
        preset.border_color = color
        if timeout ~= nil then preset.timeout = timeout end
    end
    style_urgency(naughty.config.presets.low,      "#a6e3a1")
    style_urgency(naughty.config.presets.normal,   "#74c7ec")
    style_urgency(naughty.config.presets.critical, "#f38ba8", 0)

    -- Fallback bell icon per urgency, applied in request::display only when the
    -- app provides no icon. It can't live in the preset: preset.icon is crushed
    -- into the notification and would shadow a real app icon (Spotify art, etc.).
    local fallback_icon = {
        low      = theme.dir .. "/icons/notif/bell-badge-low.png",
        normal   = theme.dir .. "/icons/notif/bell-badge.png",
        critical = theme.dir .. "/icons/notif/alert-decagram.png",
    }

    -- Render notifications with a dunst-like layout. Per-urgency colors and the
    -- fallback icon come from the presets above; internal awesome notifications
    -- (calendar, weather, battery, etc.) mark themselves app_name="awesome" and
    -- bypass the fixed size constraints so their content is never clipped.
    local awesome_icon = theme.dir .. "/icons/notif/awesome-wm.png"

    naughty.connect_signal("request::display", function(n)
        local is_internal = n.app_name == "awesome"
        local has_app = not is_internal and n.app_name ~= nil and n.app_name ~= ""

        if is_internal then
            -- Top-left corner, away from external app notifications (top-right).
            n.position = "top_left"
            -- Use the AwesomeWM logo when the notification doesn't supply its own icon
            -- (weather, wifi, etc. bring their own; calendar and battery alerts don't).
            if not n.icon then
                n.icon = awesome_icon
            end
        elseif has_app and not n.icon then
            -- App notifications without their own icon get the urgency bell, like dunst.
            n.icon = fallback_icon[n.urgency] or fallback_icon.normal
        end

        local text_column = {
            naughty.widget.title,
            naughty.widget.message,
            spacing = 4,
            layout  = wibox.layout.fixed.vertical,
        }

        -- dunst format "<b>󰁕 %a</b>\n%s\n<i>%b</i>": bold app-name header line.
        if has_app then
            table.insert(text_column, 1, {
                markup = "<b><span foreground='" .. (n.fg or theme.notification_fg)
                         .. "'>󰁕 " .. gears.string.xml_escape(n.app_name) .. "</span></b>",
                font   = theme.notification_font,
                widget = wibox.widget.textbox,
            })
        end

        -- If the notification carries an on_click callback, wire it onto the
        -- background_role container (which covers the full notification area) so
        -- a left-click anywhere dismisses the notification and fires the callback.
        local click_buttons = n.on_click and gears.table.join(
            awful.button({}, 1, function()
                n.on_click()
                n:destroy()
            end)
        ) or nil

        naughty.layout.box {
            notification    = n,
            -- Tag the popup as a notification window so the compositor can target
            -- it (e.g. picom's inactive-opacity rule must skip window_type
            -- 'notification', otherwise it dims unfocused popups to 0.8).
            type            = "notification",
            widget_template = {
                {
                    {
                        {
                            naughty.widget.icon,
                            {
                                -- Center the text against the (taller) icon and
                                -- let it fill the remaining width.
                                text_column,
                                valign                  = "center",
                                content_fill_horizontal = true,
                                widget                  = wibox.container.place,
                            },
                            fill_space = true,
                            spacing    = 14,
                            layout     = wibox.layout.fixed.horizontal,
                        },
                        margins = theme.notification_margin,
                        widget  = wibox.container.margin,
                    },
                    buttons = click_buttons,
                    id      = "background_role",
                    widget  = naughty.container.background,
                },
                -- Cap the height: the popup shrinks to fit short content and clips
                -- anything taller (it never grows past this). Skipped for internal
                -- notifications so calendar/weather/etc. are never truncated.
                strategy = "max",
                height   = not is_internal and theme.notification_max_height or nil,
                widget   = wibox.container.constraint,
            },
            -- Fixed width so stacked notifications line up. Skipped for internals.
            strategy = "exact",
            width    = not is_internal and theme.notification_max_width or nil,
            widget   = wibox.container.constraint,
        }
    end)
end
