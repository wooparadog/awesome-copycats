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

local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local local_configs = require("local")

local theme                                     = {}
theme.wibar_margin_left                         = local_configs.wibar_margin_left or 0
theme.wibar_margin_right                        = local_configs.wibar_margin_right or 0
theme.dir                                       = os.getenv("HOME") .. "/.config/awesome/themes/powerarrow-wooparadog"
theme.font                                      = "Terminus 9"
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
        font = "Terminus 9",
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
      font = "Terminus 12",
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
if local_configs.enable_bat then
  local baticon = wibox.widget.imagebox(theme.widget_battery)
  theme.bat = lain.widget.bat({
      battery = local_configs.battery,
      ac = local_configs.ac,
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
end

-- net indicator
-- local net_wireless = net_widgets.wireless({interface="wlp3s0", font=theme.font})
local net_wired = net_widgets.indicator({font=theme.font, interfaces={"lan"}})

-- launcher
local mylb = launchbar {
  filedir = string.format("%s/Applications/", os.getenv("HOME")),
  spacing = 5
}


-- Volume
local volicon = wibox.widget.imagebox(theme.widget_vol)

theme.volume = pipewire {
    width = 59, border_width = 0, ticks = true, ticks_size = 6,
    notification_preset = { font = theme.font },
    --togglechannel = "IEC958,3",
    settings = function(volume_now)
        if volume_now.status == "off" then
            volicon:set_image(theme.widget_vol_mute)
        else
            volicon:set_image(theme.widget_vol)
        end
    end,
    colors = {
        background   = "#343434",
        mute         = red,
        unmute       = theme.fg_normal,
        tooltip_fg_focus = theme.fg_focus
      },
      button_handlers = function(volume)
        return gears.table.join (
          awful.button({}, 1, function()
            awful.spawn("pavucontrol")
          end),
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
        end
    }

function buildVolume(screen)
    local bar = theme.volume.add_screen(screen)
    local volumebg = wibox.container.background(bar, "#474747", gears.shape.rectangle)
    return wibox.widget{
      volicon,
      wibox.container.margin(volumebg, dpi(2, s), dpi(7, s), dpi(4, s), dpi(4, s)),
      layout=wibox.layout.align.horizontal
    }
end


-- Net
local net = lain.widget.net({
    settings = function()
        widget:set_markup(markup.fontfg(theme.font, "#FEFEFE", " " .. net_now.received .. " ↓↑ " .. net_now.sent .. " "))
    end
})

-- Separators
local arrow = separators.arrow_left
local right_arrow = separators.arrow_right

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
    if s.dpi >= 192 then
      xresources.set_dpi(192, s)
    else
      xresources.set_dpi(96, s)
    end

    gears.debug.print_warning(string.format("Setting Up Screen %s %sx%s DPI: %s", s.index, s.geometry.width, s.geometry.height, s.dpi))

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
    s.mytaglist = awful.widget.taglist({
      screen=s,
      filter=awful.widget.taglist.filter.all,
      buttons=awful.util.taglist_buttons,
      style={
        bg_focus = "#343434",
        spacing = dpi(1, s),
        squares_resize = true,
      }
    })

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({
      position = "top",
      screen = s,
      height = dpi(18, s),
      bg = theme.bg_normal,
      fg = theme.fg_normal,
      opacity = 0.8
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.container.margin(s.mytaglist, dpi(theme.wibar_margin_left, s)),
            right_arrow(theme.bg_normal, "#343434"),
            wibox.container.background(wibox.container.margin(mylb, dpi(4, s), dpi(4, s)), "#343434"),
            right_arrow("#343434", theme.bg_normal),
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            systray,
            -- using separators
            arrow(theme.bg_normal, "#343434"),
            wibox.container.background(buildVolume(s), "#343434"),
            arrow("#343434", "#777E76"),
            wibox.container.background(wibox.container.margin(wibox.widget { memicon, mem.widget, layout = wibox.layout.align.horizontal }, dpi(2, s), dpi(3, s)), "#777E76"),
            arrow("#777E76", "#4B696D"),
            wibox.container.background(wibox.container.margin(wibox.widget { cpuicon, cpu.widget, layout = wibox.layout.align.horizontal }, dpi(3, s), dpi(4, s)), "#4B696D"),
            arrow("#4B696D", "#4B3B51"),
            wibox.container.background(wibox.container.margin(wibox.widget { tempicon, temp.widget, layout = wibox.layout.align.horizontal }, dpi(4, s), dpi(4, s)), "#4B3B51"),
            -- arrow("#4B3B51", "#CB755B"),
            local_configs.enable_bat and wibox.container.background(wibox.container.margin(wibox.widget { baticon, theme.bat.widget, layout = wibox.layout.align.horizontal }, dpi(3, s), dpi(3, s)), "#CB755B") or wibox.container.background(),
            arrow("#4B3B51", "#5e3636"),
            --wibox.container.background(wibox.container.margin(wibox.widget { nil, net_wired, net_wireless, layout = wibox.layout.align.horizontal }, 3, 3), "#5e3636"),
            wibox.container.background(wibox.container.margin(wibox.widget { nil, nil, net.widget, layout = wibox.layout.align.horizontal }, dpi(3, s), dpi(3, s)), "#5e3636"),
            arrow("#5e3636", "#777E76"),
            wibox.container.background(wibox.container.margin(textclock, dpi(4, s), dpi(8, s)), "#777E76"),
            wibox.container.background(wibox.container.margin(weather.icon, dpi(4, s), dpi(8, s)), "#777E76"),
            wibox.container.background(wibox.container.margin(weather.widget, dpi(4, s), dpi(8, s)), "#777E76"),
            arrow("#777E76", "alpha"),
            --]]
            s.mylayoutbox,
            wibox.container.margin(wallpaper_changer.wp_wall_icon, 0, dpi(theme.wibar_margin_right, s)),
        },
    }
end

return theme
