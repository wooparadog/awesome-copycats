local awful = require("awful")
local gears = require("gears")
local dbus = require("themes.powerarrow-wooparadog.dbus"){}
local wibox = require("wibox")
local my_table = awful.util.table


-- configuration - edit to your liking

math.randomseed(os.time())

function scandir(directory, filter)
  local i, t, popen = 0, {}, io.popen
  if not filter then
    filter = function(s) return true end
  end
  for filename in popen('ls -a "'..directory..'"'):lines() do
    if filter(filename) then
      i = i + 1
      t[i] = filename
    end
  end
  return t
end

local function factory(args)
  local args = args or {}
  local wallpaper = {}

  wallpaper.wp_index = args.index or 1
  wallpaper.wp_screen = args.screen or nil
  wallpaper.wp_timeout  = args.timeout or 300
  wallpaper.wp_vertical_path = args.vertical_path or string.format("%s/Photos/wallpaper/", os.getenv("HOME"))
  wallpaper.wp_horizontal_path = args.horizontal_path or string.format("%s/Photos/wallpaper/", os.getenv("HOME"))
  wallpaper.wp_filter = function(s) return string.match(s,"%.png$") or string.match(s,"%.jpg$") or string.match(s,"%.jpeg$") or string.match(s,"%.JPG$") end
  wallpaper.wp_normal_icon = args.widget_icon_wallpaper
  wallpaper.wp_paused_icon = args.widget_icon_wallpaper_paused

  wallpaper.choose_wallpaper = function(s)
    if not s.index == wallpaper.wp_screen.index then
      return
    end

    if wallpaper.wp_screen.geometry.width >= wallpaper.wp_screen.geometry.height then
      wallpaper.wp_path = wallpaper.wp_horizontal_path
    else
      wallpaper.wp_path = wallpaper.wp_vertical_path
    end
    gears.debug.print_warning(string.format("Chossing: %s for %sx%s", wallpaper.wp_path, wallpaper.wp_screen.geometry.width, wallpaper.wp_screen.geometry.height))
    wallpaper.wp_files = scandir(wallpaper.wp_path, wallpaper.wp_filter)
  end

  wallpaper.choose_wallpaper(wallpaper.wp_screen)
  screen.connect_signal("property::geometry", wallpaper.choose_wallpaper)
  
  wallpaper.wp_timer = gears.timer { timeout = wallpaper.wp_timeout }
  wallpaper.current = nil

  wallpaper.wp_wall_icon = wibox.widget.imagebox(wallpaper.wp_normal_icon)

  wallpaper.wp_wall_icon:buttons(
    my_table.join(
      awful.button({ }, 1, function()
        wallpaper.start()
        wallpaper.wp_wall_icon.image = wallpaper.wp_normal_icon
      end),
      awful.button({ }, 2, function()
        awful.spawn("xdg-open " .. wallpaper.current)
      end),
      awful.button({ }, 3, function()
        wallpaper.stop()
        wallpaper.wp_wall_icon.image = wallpaper.wp_paused_icon
      end)
      )
    )


  wallpaper.start = function()
    if #wallpaper.wp_files < 1 then
      return
    end

    -- set wallpaper to current index for all screens
    wallpaper.wp_index = math.random(#wallpaper.wp_files)
    wallpaper_path = wallpaper.wp_path .. wallpaper.wp_files[wallpaper.wp_index]
    gears.wallpaper.maximized(wallpaper_path, wallpaper.wp_screen)
    wallpaper.current = wallpaper_path

    -- Notify dbus we've changed wallpaper
    dbus.refresh_user_wallpaper(wallpaper_path)

    -- stop the timer (we don't need multiple instances running at the same time)
    if wallpaper.wp_timer.started then
      wallpaper.wp_timer:stop()
    end


    --restart the timer
    wallpaper.wp_timer.timeout = wallpaper.wp_timeout
    wallpaper.wp_timer:start()
  end

  wallpaper.stop = function()
    wallpaper.wp_timer:stop()
  end

  wallpaper.wp_timer:connect_signal("timeout", wallpaper.start)

  return wallpaper
end

return factory
