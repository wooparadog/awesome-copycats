--[[

     Powerarrow Awesome WM theme
     github.com/lcpz

--]]

local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")

local net_widgets = require("net_widgets")
local launchbar = require("themes.powerarrow-wooparadog.launchbar")
local consts = require("themes.powerarrow-wooparadog.consts")
local pipewire = require("themes.powerarrow-wooparadog.pipewire")

local local_configs = require("local")

local theme                                     = {}
theme.dir                                       = os.getenv("HOME") .. "/.config/awesome/themes/powerarrow-wooparadog"
theme.font                                      = "Terminus (TTF) 9"
theme.fg_normal                                 = "#FEFEFE"
theme.fg_focus                                  = "#32D6FF"
theme.fg_urgent                                 = "#C83F11"
theme.bg_normal                                 = "#222222"
theme.bg_focus                                  = "#1E2320"
theme.bg_urgent                                 = "#3F3F3F"
theme.taglist_fg_focus                          = "#00CCFF"
theme.tasklist_bg_focus                         = "#222222"
theme.tasklist_fg_focus                         = "#00CCFF"
theme.border_width                              = 1
theme.border_normal                             = "#3F3F3F"
theme.border_focus                              = "#6F6F6F"
theme.border_marked                             = "#CC9393"
theme.titlebar_bg_focus                         = "#3F3F3F"
theme.titlebar_bg_normal                        = "#3F3F3F"
theme.titlebar_bg_focus                         = theme.bg_focus
theme.titlebar_bg_normal                        = theme.bg_normal
theme.titlebar_fg_focus                         = theme.fg_focus
theme.menu_height                               = 16
theme.menu_width                                = 140
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
theme.tasklist_plain_task_name                  = true
theme.tasklist_disable_icon                     = true
theme.useless_gap                               = 5
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

theme.notification_max_height = 200
theme.notification_max_width = 800
theme.notification_opacity = 0.9
theme.notification_margin = 5
theme.notification_icon_size = 128

naughty.config.defaults.position = "top_middle"
naughty.config.defaults.timeout = 10

local markup = lain.util.markup
local separators = lain.util.separators


-- Textclock
local textclock = wibox.widget.textclock(markup.font(theme.font, " %a %d %b  %H:%M")
)

-- Calendar
theme.cal = lain.widget.cal({
    cal = "cal --color=always",
    attach_to = { textclock },
    followtag = true,
    notification_preset = {
        font = "Terminus (TTF) 9",
        fg   = theme.fg_normal,
        bg   = theme.bg_normal,
        position = "top_right",
    }
})

-- weather
local weather = lain.widget.weather({
  APPID = "a58a85c3f4640139fc31ffb88b6d2331",
  city_id=1787960,
  weather_na_markup="NA",
  settings = function()
    widget:set_markup(weather_now["main"]["temp"] .. "°C")
  end,
  notification_preset = {
      font = "Terminus (TTF) 12",
      fg   = theme.fg_normal,
      bg   = theme.bg_normal,
      position = "top_right",
  }
})

-- Scissors (xsel copy and paste)
--local scissors = wibox.widget.imagebox(theme.widget_scissors)
--scissors:buttons(gears.table.join(awful.button({}, 1, function() awful.spawn.with_shell("xsel | xsel -i -b") end)))

-- Mail IMAP check
--[[ commented because it needs to be set before use
local mailicon = wibox.widget.imagebox(theme.widget_mail)
mailicon:buttons(gears.table.join(awful.button({ }, 1, function () awful.spawn(mail) end)))
theme.mail = lain.widget.imap({
    timeout  = 180,
    server   = "server",
    mail     = "mail",
    password = "keyring get mail",
    settings = function()
        if mailcount > 0 then
            widget:set_text(" " .. mailcount .. " ")
            mailicon:set_image(theme.widget_mail_on)
        else
            widget:set_text("")
            mailicon:set_image(theme.widget_mail)
        end
    end
})
--]]

-- MEM
local memicon = wibox.widget.imagebox(theme.widget_mem)
local mem = lain.widget.mem({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. mem_now.used .. "MB "))
    end
})

-- CPU
local cpuicon = wibox.widget.imagebox(theme.widget_cpu)
local cpu = lain.widget.cpu({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. cpu_now.usage .. "% "))
    end
})

--[[ Coretemp (lm_sensors, per core)
local tempwidget = awful.widget.watch({awful.util.shell, '-c', 'sensors | grep Core'}, 30,
function(widget, stdout)
    local temps = ""
    for line in stdout:gmatch("[^\r\n]+") do
        temps = temps .. line:match("+(%d+).*°C")  .. "° " -- in Celsius
    end
    widget:set_markup(markup.font(theme.font, " " .. temps))
end)
--]]
-- Coretemp (lain, average)

local temp = lain.widget.temp({
    tempfile = local_configs.tempfile,
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. coretemp_now .. "°C "))
    end
})
--]]
local tempicon = wibox.widget.imagebox(theme.widget_temp)

-- / fs
--local fsicon = wibox.widget.imagebox(theme.widget_hdd)
--[[ commented because it needs Gio/Glib >= 2.54
theme.fs = lain.widget.fs({
    notification_preset = { fg = theme.fg_normal, bg = theme.bg_normal, font = "xos4 Terminus 10" },
    settings = function()
        local fsp = string.format(" %3.2f %s ", fs_now["/"].free, fs_now["/"].units)
        widget:set_markup(markup.font(theme.font, fsp))
    end
})
--]]

--[[ Battery
]]
local baticon = wibox.widget.imagebox(theme.widget_battery)
local bat = lain.widget.bat({
    settings = function()
        if bat_now.status and bat_now.status ~= "N/A" then
            if bat_now.ac_status == 1 then
                widget:set_markup(markup.font(theme.font, " AC "))
                baticon:set_image(theme.widget_ac)
                return
            elseif not bat_now.perc and tonumber(bat_now.perc) <= 5 then
                baticon:set_image(theme.widget_battery_empty)
            elseif not bat_now.perc and tonumber(bat_now.perc) <= 15 then
                baticon:set_image(theme.widget_battery_low)
            else
                baticon:set_image(theme.widget_battery)
            end
            widget:set_markup(markup.font(theme.font, " " .. bat_now.perc .. "% "))
        else
            widget:set_markup()
            baticon:set_image(theme.widget_ac)
        end
    end
})

-- net indicator
-- local net_wireless = net_widgets.wireless({interface="wlp3s0", font=theme.font})
local net_wired = net_widgets.indicator({font=theme.font, interfaces={"lan"}})

-- launcher
local mylb = launchbar {
  filedir = string.format("%s/Applications/", os.getenv("HOME")),
  spacing = 5
}


-- pulse volume bar
local volicon = wibox.widget.imagebox(theme.widget_vol)

theme.volume = pipewire {
    width = 59, border_width = 0, ticks = true, ticks_size = 6,
    notification_preset = { font = theme.font },
    --togglechannel = "IEC958,3",
    settings = function()
        if volume_now.status == "off" then
            volicon:set_image(theme.widget_vol_mute)
        else
            volicon:set_image(theme.widget_vol)
        end
    end,
    colors = {
        background   = "#343434",
        mute         = red,
        unmute       = theme.fg_normal
    }
}
theme.volume.tooltip.wibox.fg = theme.fg_focus
theme.volume.bar:buttons(gears.table.join (
          awful.button({}, 1, function()
            awful.spawn("pavucontrol")
          end),
          awful.button({}, 2, function()
            os.execute(string.format("pactl set-sink-volume %s 100%%", theme.volume.device))
            theme.volume.update()
          end),
          awful.button({}, 3, function()
            os.execute(string.format("pactl set-sink-mute %s toggle", theme.volume.device))
            theme.volume.update()
          end),
          awful.button({}, 4, function()
            os.execute(string.format("pactl set-sink-volume %s +5%%", theme.volume.device))
            theme.volume.update()
          end),
          awful.button({}, 5, function()
            os.execute(string.format("pactl set-sink-volume %s -5%%", theme.volume.device))
            theme.volume.update()
          end)
))
local volumebg = wibox.container.background(theme.volume.bar, "#474747", gears.shape.rectangle)
local volumewidget = wibox.widget{volicon, wibox.container.margin(volumebg, 2, 7, 4, 4), layout=wibox.layout.align.horizontal}


-- Net
local net = lain.widget.net({
    settings = function()
        widget:set_markup(markup.fontfg(theme.font, "#FEFEFE", " " .. net_now.received .. " ↓↑ " .. net_now.sent .. " "))
    end
})

-- Separators
local arrow = separators.arrow_left
local right_arrow = separators.arrow_right

function theme.powerline_rl(cr, width, height)
    local arrow_depth, offset = height/2, 0

    -- Avoid going out of the (potential) clip area
    if arrow_depth < 0 then
        width  =  width + 2*arrow_depth
        offset = -arrow_depth
    end

    cr:move_to(offset + arrow_depth         , 0        )
    cr:line_to(offset + width               , 0        )
    cr:line_to(offset + width - arrow_depth , height/2 )
    cr:line_to(offset + width               , height   )
    cr:line_to(offset + arrow_depth         , height   )
    cr:line_to(offset                       , height/2 )

    cr:close_path()
end

local function pl(widget, bgcolor, padding)
    return wibox.container.background(wibox.container.margin(widget, 16, 16), bgcolor, theme.powerline_rl)
end

local systray = wibox.widget.systray()
screen.connect_signal("screen.focus", function(c)
  systray:set_screen(awful.screen.focused())
end)

local wallpaper_changers = {}
root.keys(
  awful.key({ "Mod4",           }, "d", function()
    wallpaper_changers[awful.screen.focused { client=false, mouse=true }.index].start()
  end, {description = "Refresh wallpaper", group = "screen"})
)

function theme.at_screen_connect(s)
    local is_horizon = s.geometry.width >= s.geometry.height

    -- Predicate orientation of screen
    if is_horizon then
      awful.tag(awful.util.tagnames, s, awful.layout.taglayouts)
    else
      awful.tag(awful.util.vertical_tagnames, s, awful.layout.vertical_taglayouts)
    end

    -- create wallpaper
    local wallpaper_changer = require("themes.powerarrow-wooparadog.wallpaper"){
      paths=is_horizon and local_configs.wallpapers.horizontal_path or local_configs.wallpapers.vertical_path,
      timeout=180,
      screen=s,
      widget_icon_wallpaper=theme.widget_icon_wallpaper,
      widget_icon_wallpaper_paused=theme.widget_icon_wallpaper_paused,
    }

    screen.connect_signal("property::geometry", function(signal_screen)
      if not s.valid then
        return
      end
      if s.index == signal_screen.index then
        if is_horizon ~= (s.geometry.width >= s.geometry.height) then
          is_horizon = not is_horizon
          gears.debug.print_warning(string.format("Changing wallpaper path by resolution change: %sx%s", s.geometry.width, s.geometry.height))
          wallpaper_changer.change_path(is_horizon and local_configs.wallpapers.horizontal_path or local_configs.wallpapers.vertical_path)
        end
      else
        -- Also reset wallpaper of unchanged screen to prevent tearing
        wallpaper_changer.set_wallpaper(wallpaper_changer.current)
      end
    end)

    wallpaper_changer.start()
    wallpaper_changers[s.index] = wallpaper_changer

    -- Quake application
    s.quake = lain.util.quake({ app = "urxvt", followtag = true })

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({}, 1, function () awful.layout.inc( 1) end),
                           awful.button({}, 2, function () awful.layout.set( awful.layout.layouts[1] ) end),
                           awful.button({}, 3, function () awful.layout.inc(-1) end),
                           awful.button({}, 4, function () awful.layout.inc( 1) end),
                           awful.button({}, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = 18, bg = theme.bg_normal, fg = theme.fg_normal, opacity=0.8 })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            right_arrow(theme.bg_normal, "#343434"),
            wibox.container.background(wibox.container.margin(mylb, 4, 4), "#343434"),
            right_arrow("#343434", theme.bg_normal),
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            systray,
            --wibox.container.margin(scissors, 4, 8),
            --[[ using shapes
            pl(wibox.widget { mpdicon, theme.mpd.widget, layout = wibox.layout.align.horizontal }, "#343434"),
            pl(task, "#343434"),
            --pl(wibox.widget { mailicon, mail and theme.mail.widget, layout = wibox.layout.align.horizontal }, "#343434"),
            pl(wibox.widget { memicon, mem.widget, layout = wibox.layout.align.horizontal }, "#777E76"),
            pl(wibox.widget { cpuicon, cpu.widget, layout = wibox.layout.align.horizontal }, "#4B696D"),
            pl(wibox.widget { tempicon, temp.widget, layout = wibox.layout.align.horizontal }, "#4B3B51"),
            --pl(wibox.widget { fsicon, theme.fs and theme.fs.widget, layout = wibox.layout.align.horizontal }, "#CB755B"),
            pl(wibox.widget { baticon, bat.widget, layout = wibox.layout.align.horizontal }, "#8DAA9A"),
            pl(wibox.widget { neticon, net.widget, layout = wibox.layout.align.horizontal }, "#5e3636"),
            pl(binclock.widget, "#777E76"),
            --]]
            -- using separators
            arrow(theme.bg_normal, "#343434"),
            wibox.container.background(volumewidget, "#343434"),
            arrow("#343434", "#777E76"),
            wibox.container.background(wibox.container.margin(wibox.widget { memicon, mem.widget, layout = wibox.layout.align.horizontal }, 2, 3), "#777E76"),
            arrow("#777E76", "#4B696D"),
            wibox.container.background(wibox.container.margin(wibox.widget { cpuicon, cpu.widget, layout = wibox.layout.align.horizontal }, 3, 4), "#4B696D"),
            arrow("#4B696D", "#4B3B51"),
            wibox.container.background(wibox.container.margin(wibox.widget { tempicon, temp.widget, layout = wibox.layout.align.horizontal }, 4, 4), "#4B3B51"),
            -- arrow("#4B3B51", "#CB755B"),
            -- wibox.container.background(wibox.container.margin(wibox.widget { baticon, bat.widget, layout = wibox.layout.align.horizontal }, 3, 3), "#CB755B"),
            arrow("#4B3B51", "#5e3636"),
            --wibox.container.background(wibox.container.margin(wibox.widget { nil, net_wired, net_wireless, layout = wibox.layout.align.horizontal }, 3, 3), "#5e3636"),
            wibox.container.background(wibox.container.margin(wibox.widget { nil, nil, net.widget, layout = wibox.layout.align.horizontal }, 3, 3), "#5e3636"),
            arrow("#5e3636", "#777E76"),
            wibox.container.background(wibox.container.margin(textclock, 4, 8), "#777E76"),
            wibox.container.background(wibox.container.margin(weather.icon, 4, 8), "#777E76"),
            wibox.container.background(wibox.container.margin(weather.widget, 4, 8), "#777E76"),
            arrow("#777E76", "alpha"),
            --]]
            s.mylayoutbox,
            wallpaper_changer.wp_wall_icon,
        },
    }
end

return theme
