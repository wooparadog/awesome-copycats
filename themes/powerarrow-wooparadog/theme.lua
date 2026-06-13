---@diagnostic disable-next-line
local screen, root = screen, root

local gears          = require("gears")
local lain           = require("lib.lain")
local awful          = require("awful")
local wibox          = require("wibox")
local naughty        = require("naughty")
local launchbar      = require("lib.launchbar")
local pipewire       = require("lib.pipewire")
local wifi           = require("lib.wifi")
local battery_widget = require("lib.battery")
local wallpaper      = require("lib.wallpaper")
local xresources     = require("beautiful.xresources")
local dpi            = xresources.apply_dpi
local local_configs  = require("local")

-- Backfill defaults for fields added after the initial template so that older
-- local.lua files don't crash on nil-indexing or produce silent wrong behaviour.
do
    local cfg = local_configs

    if not cfg.weather then cfg.weather = {} end
    cfg.weather.lat    = cfg.weather.lat or 0.0
    cfg.weather.lon    = cfg.weather.lon or 0.0

    cfg.wifi_interface = cfg.wifi_interface or "wlan0"

    if not cfg.wallpapers then cfg.wallpapers = {} end
    local wp = cfg.wallpapers
    wp.timeout                      = wp.timeout or 300
    wp.enable_wifi_specific_sources = wp.enable_wifi_specific_sources or false
    wp.horizontal_path              = wp.horizontal_path or {}
    wp.vertical_path                = wp.vertical_path   or {}
end

-- ── Theme ────────────────────────────────────────────────────────────────────

local theme = {}
theme.wibar_margin_left  = local_configs.wibar_margin_left  or 0
theme.wibar_margin_right = local_configs.wibar_margin_right or 0
theme.dir                = os.getenv("HOME") .. "/.config/awesome/themes/powerarrow-wooparadog"
theme.font               = "Terminus 9"
theme.fg_normal          = "#FEFEFE"
theme.fg_focus           = "#32D6FF"
theme.fg_urgent          = "#C83F11"
theme.bg_normal          = "#222222"
theme.bg_focus           = "#1E2320"
theme.bg_urgent          = "#3F3F3F"
theme.taglist_fg_focus   = "#00CCFF"
theme.tasklist_bg_focus  = "#222222"
theme.tasklist_fg_focus  = "#00CCFF"
theme.border_width       = 0
theme.border_normal      = "#3F3F3F"
theme.border_focus       = "#6F6F6F"
theme.border_marked      = "#CC9393"
theme.titlebar_bg_focus  = theme.bg_focus
theme.titlebar_bg_normal = theme.bg_normal
theme.titlebar_fg_focus  = theme.fg_focus

theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon    = true
theme.icon_theme               = "breeze-dark"
theme.useless_gap              = 2

theme.menu_submenu_icon                         = theme.dir .. "/icons/submenu.png"
theme.awesome_icon                              = theme.dir .. "/icons/awesome.png"
theme.taglist_squares_sel                       = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel                     = theme.dir .. "/icons/square_unsel.png"
theme.layout_tile                               = theme.dir .. "/icons/tile.png"
theme.layout_tileleft                           = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom                         = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop                            = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv                              = theme.dir .. "/icons/fairv.png"
theme.layout_fairh                              = theme.dir .. "/icons/fairh.png"
theme.layout_spiral                             = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle                            = theme.dir .. "/icons/dwindle.png"
theme.layout_max                                = theme.dir .. "/icons/max.png"
theme.layout_fullscreen                         = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier                          = theme.dir .. "/icons/magnifier.png"
theme.layout_floating                           = theme.dir .. "/icons/floating.png"
theme.widget_ac                                 = theme.dir .. "/icons/ac.png"
theme.widget_battery                            = theme.dir .. "/icons/battery.png"
theme.widget_battery_low                        = theme.dir .. "/icons/battery_low.png"
theme.widget_battery_empty                      = theme.dir .. "/icons/battery_empty.png"
theme.widget_mem                                = theme.dir .. "/icons/mem.png"
theme.widget_cpu                                = theme.dir .. "/icons/cpu.png"
theme.widget_temp                               = theme.dir .. "/icons/temp.png"
theme.widget_net                                = theme.dir .. "/icons/net.png"
theme.widget_hdd                                = theme.dir .. "/icons/hdd.png"
theme.widget_music                              = theme.dir .. "/icons/note.png"
theme.widget_music_on                           = theme.dir .. "/icons/note_on.png"
theme.widget_music_pause                        = theme.dir .. "/icons/pause.png"
theme.widget_music_stop                         = theme.dir .. "/icons/stop.png"
theme.widget_vol                                = theme.dir .. "/icons/vol.png"
theme.widget_vol_low                            = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no                             = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute                           = theme.dir .. "/icons/vol_mute.png"
theme.widget_mail                               = theme.dir .. "/icons/mail.png"
theme.widget_mail_on                            = theme.dir .. "/icons/mail_on.png"
theme.widget_task                               = theme.dir .. "/icons/task.png"
theme.widget_scissors                           = theme.dir .. "/icons/scissors.png"
theme.widget_icon_wallpaper                     = theme.dir .. "/icons/wall.png"
theme.widget_icon_wallpaper_paused              = theme.dir .. "/icons/wall_paused.png"
theme.titlebar_close_button_focus               = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal              = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active        = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active       = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive      = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive     = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active       = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active      = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive     = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive    = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active     = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active    = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive   = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive  = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active    = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active   = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

require("themes.powerarrow-wooparadog.notifications")(theme)

-- ── Shared widgets (singletons, one instance for all screens) ────────────────

local markup      = lain.util.markup
local separators  = lain.util.separators
local arrow       = separators.arrow_left
local right_arrow = separators.arrow_right

local textclock = wibox.widget.textclock(markup.font(theme.font, " %a %d %b  %H:%M"))

theme.cal = lain.widget.cal({
    cal      = "cal --color=always",
    attach_to = { textclock },
    followtag = true,
    notification_preset = {
        font     = "Terminus 9",
        fg       = theme.fg_normal,
        bg       = theme.bg_normal,
        position = "top_right",
    },
})

local weather = lain.widget.weather({
    APPID    = local_configs.openweathermap_key,
    lat      = local_configs.weather.lat,
    lon      = local_configs.weather.lon,
    settings = function()
        widget:set_markup(weather_now["main"]["temp"] .. "°C")
    end,
    notification_preset = {
        font     = "Terminus 12",
        fg       = theme.fg_normal,
        bg       = theme.bg_normal,
        position = "top_right",
    },
})

local memicon = wibox.widget.imagebox(theme.widget_mem)
local mem = lain.widget.mem({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. mem_now.used .. "MB "))
    end,
})

local cpuicon = wibox.widget.imagebox(theme.widget_cpu)
local cpu = lain.widget.cpu({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. cpu_now.usage .. "% "))
    end,
})

local tempicon = wibox.widget.imagebox(theme.widget_temp)
local temp = lain.widget.temp({
    tempfile = local_configs.tempfile,
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. coretemp_now .. "°C "))
    end,
})

local baticon
if local_configs.enable_bat then
    baticon = wibox.widget.imagebox(theme.widget_battery)
    theme.bat = battery_widget({
        battery  = local_configs.battery,
        settings = function(bat_now, widget)
            if bat_now.status == "N/A" then
                widget:set_markup("")
                baticon:set_image(theme.widget_ac)
                return
            end
            if bat_now.ac_status == 1 then
                widget:set_markup(markup.font(theme.font, " " .. bat_now.status .. " " .. bat_now.perc .. "% "))
                baticon:set_image(theme.widget_ac)
                return
            end
            local perc = tonumber(bat_now.perc) or 0
            if perc <= 5 then
                baticon:set_image(theme.widget_battery_empty)
            elseif perc <= 15 then
                baticon:set_image(theme.widget_battery_low)
            else
                baticon:set_image(theme.widget_battery)
            end
            local time_str = ""
            if bat_now.tte and bat_now.tte > 0 then
                local h = math.floor(bat_now.tte / 3600)
                local m = math.floor((bat_now.tte % 3600) / 60)
                time_str = string.format(" %dh%02dm", h, m)
            end
            widget:set_markup(markup.font(theme.font, " " .. bat_now.perc .. "%" .. time_str .. " "))
        end,
    })
end

local mylb = launchbar {
    filedir = string.format("%s/Applications/", os.getenv("HOME")),
    spacing = 5,
}

local volicon = wibox.widget.imagebox(theme.widget_vol)
theme.volume = pipewire {
    width = 59, border_width = 0, ticks = true, ticks_size = 6,
    notification_preset = { font = theme.font },
    settings = function(volume_now)
        volicon:set_image(volume_now.status == "off" and theme.widget_vol_mute or theme.widget_vol)
    end,
    colors = {
        background       = "#343434",
        unmute           = theme.fg_normal,
        tooltip_fg_focus = theme.fg_focus,
    },
    button_handlers = function(volume)
        return gears.table.join(
            awful.button({}, 1, function() awful.spawn("pavucontrol") end),
            awful.button({}, 2, function()
                os.execute(string.format("pactl set-sink-volume %s 100%%", volume.device))
                volume.update()
            end),
            awful.button({}, 3, function()
                os.execute(string.format("pactl set-sink-mute %s toggle", volume.device))
                volume.update()
            end),
            awful.button({}, 4, function()
                os.execute(string.format("pactl set-sink-volume %s +5%%", volume.device))
                volume.update()
            end),
            awful.button({}, 5, function()
                os.execute(string.format("pactl set-sink-volume %s -5%%", volume.device))
                volume.update()
            end)
        )
    end,
}

local net = local_configs.enable_net and lain.widget.net({
    settings = function()
        widget:set_markup(markup.fontfg(theme.font, "#FEFEFE", " " .. net_now.received .. " ↓↑ " .. net_now.sent .. " "))
    end,
}) or nil

local systray = wibox.widget.systray()
local function update_systray_screen()
    local s = mouse.screen
    if s and s.mywibox and s.mywibox.visible then systray:set_screen(s) end
end
tag.connect_signal("property::selected", update_systray_screen)
client.connect_signal("focus", update_systray_screen)

-- ── Wibar builders ───────────────────────────────────────────────────────────

local function buildVolume(s)
    local bar      = theme.volume.add_screen(s)
    local volumebg = wibox.container.background(bar, "#474747", gears.shape.rectangle)
    return wibox.widget {
        volicon,
        wibox.container.margin(volumebg, dpi(2, s), dpi(7, s), dpi(4, s), dpi(4, s)),
        layout = wibox.layout.align.horizontal,
    }
end

local function buildLeftWidgets(s)
    return {
        layout = wibox.layout.fixed.horizontal,
        wibox.container.margin(s.mytaglist, dpi(theme.wibar_margin_left, s)),
        right_arrow(theme.bg_normal, "#343434"),
        wibox.container.background(wibox.container.margin(mylb, dpi(4, s), dpi(4, s)), "#343434"),
        right_arrow("#343434", theme.bg_normal),
        s.mypromptbox,
    }
end

local function buildRightWidgets(s, wp)
    local pre_clock_color = local_configs.enable_bat and "#CB755B" or "#4B3B51"
    return {
        layout = wibox.layout.fixed.horizontal,
        systray,
        arrow(theme.bg_normal, "#343434"),
        wibox.container.background(buildVolume(s), "#343434"),
        arrow("#343434", "#777E76"),
        wibox.container.background(wibox.container.margin(wibox.widget { memicon,  mem.widget,        layout = wibox.layout.align.horizontal }, dpi(2, s), dpi(3, s)), "#777E76"),
        arrow("#777E76", "#4B696D"),
        wibox.container.background(wibox.container.margin(wibox.widget { cpuicon,  cpu.widget,        layout = wibox.layout.align.horizontal }, dpi(3, s), dpi(4, s)), "#4B696D"),
        arrow("#4B696D", "#4B3B51"),
        wibox.container.background(wibox.container.margin(wibox.widget { tempicon, temp.widget,       layout = wibox.layout.align.horizontal }, dpi(4, s), dpi(4, s)), "#4B3B51"),
        local_configs.enable_bat and arrow("#4B3B51", "#CB755B") or nil,
        local_configs.enable_bat and wibox.container.background(wibox.container.margin(wibox.widget { baticon, theme.bat.widget, layout = wibox.layout.align.horizontal }, dpi(3, s), dpi(3, s)), "#CB755B") or nil,
        local_configs.enable_net and arrow(pre_clock_color, "#5e3636") or arrow(pre_clock_color, "#777E76"),
        local_configs.enable_net and wibox.container.background(wibox.container.margin(wibox.widget { nil, nil, net and net.widget, layout = wibox.layout.align.horizontal }, dpi(3, s), dpi(3, s)), "#5e3636") or nil,
        local_configs.enable_net and arrow("#5e3636", "#777E76") or nil,
        wibox.container.background(wibox.container.margin(textclock,      dpi(4, s), dpi(8, s)), "#777E76"),
        wibox.container.background(wibox.container.margin(weather.icon,   dpi(4, s), dpi(8, s)), "#777E76"),
        wibox.container.background(wibox.container.margin(weather.widget, dpi(4, s), dpi(8, s)), "#777E76"),
        arrow("#777E76", "alpha"),
        s.mylayoutbox,
        wibox.container.margin(wp.wp_wall_icon, 0, dpi(theme.wibar_margin_right, s)),
    }
end

-- ── Screen setup ─────────────────────────────────────────────────────────────

function theme.at_screen_connect(s)
    -- DPI override per screen
    if local_configs.screen_dpi then
        xresources.set_dpi(
            s.dpi >= local_configs.screen_dpi.high
                and local_configs.screen_dpi.high
                or  local_configs.screen_dpi.low,
            s
        )
    end

    gears.debug.print_warning(string.format(
        "Setting Up Screen %s %sx%s DPI: %s", s.index, s.geometry.width, s.geometry.height, s.dpi
    ))

    local is_horizon = s.geometry.width >= s.geometry.height

    if is_horizon then
        awful.tag(awful.util.tagnames,          s, awful.layout.taglayouts)
    else
        awful.tag(awful.util.vertical_tagnames, s, awful.layout.vertical_taglayouts)
    end

    -- Wallpaper
    local wp = wallpaper {
        timeout                    = local_configs.wallpapers.timeout or 300,
        screen                     = s,
        widget_icon_wallpaper      = theme.widget_icon_wallpaper,
        widget_icon_wallpaper_paused = theme.widget_icon_wallpaper_paused,
        notification_icon          = theme.dir .. "/icons/notif/wallpaper.png",
    }

    local function wallpaper_path_for(ssid)
        local sources = local_configs.wallpapers.wifi_specific_sources
        if ssid and sources and sources[ssid] then
            return is_horizon and sources[ssid].horizontal_path or sources[ssid].vertical_path
        end
        return is_horizon and local_configs.wallpapers.horizontal_path or local_configs.wallpapers.vertical_path
    end

    if local_configs.wallpapers.enable_wifi_specific_sources then
        wifi.get_wifi_info_async(function(wifi_data)
            wp.change_path(wallpaper_path_for(wifi_data and wifi_data.name))
        end, local_configs.wifi_interface)

        wifi.subscribe_ssid_changes(function(ssid)
            if not s.valid then return end
            if s.index == 1 then
                naughty.notify({
                    app_name  = "awesome",
                    preset    = naughty.config.presets.normal,
                    title     = "Network Changed",
                    text      = ssid and ("Connected to " .. ssid) or "Disconnected",
                    icon      = theme.dir .. "/icons/network-wireless.png",
                    icon_size = 64,
                    timeout   = 5,
                })
            end
            wp.change_path(wallpaper_path_for(ssid))
        end, local_configs.wifi_interface)
    else
        wp.change_path(wallpaper_path_for(nil))
    end

    screen.connect_signal("property::geometry", function(signal_screen)
        if not s.valid then return end
        if s.index == signal_screen.index then
            if is_horizon ~= (s.geometry.width >= s.geometry.height) then
                is_horizon = not is_horizon
                gears.debug.print_warning(string.format(
                    "Changing wallpaper path by resolution change: %sx%s", s.geometry.width, s.geometry.height
                ))
                wp.change_path(wallpaper_path_for(nil))
            end
        else
            if wp.current then wp.set_wallpaper(wp.current) end
        end
    end)

    -- Per-screen widgets
    s.quake = lain.util.quake({ app = "urxvt", followtag = true })

    s.mypromptbox = awful.widget.prompt()

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc( 1) end),
        awful.button({}, 2, function() awful.layout.set(awful.layout.layouts[1]) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc( 1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)
    ))

    s.mytaglist = awful.widget.taglist({
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = awful.util.taglist_buttons,
        style   = { bg_focus = "#343434", spacing = dpi(1, s), squares_resize = true },
    })

    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

    -- Wibar
    s.mywibox = awful.wibar({
        position = "top",
        screen   = s,
        height   = dpi(18, s),
        bg       = theme.bg_normal,
        fg       = theme.fg_normal,
        opacity  = 0.8,
    })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        buildLeftWidgets(s),
        s.mytasklist,
        buildRightWidgets(s, wp),
    }
end

return theme
