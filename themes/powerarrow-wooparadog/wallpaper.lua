local awful = require("awful")
local gears = require("gears")
local dbus = require("themes.powerarrow-wooparadog.dbus"){}
local consts = require("themes.powerarrow-wooparadog.consts")
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
  wallpaper.wp_paths = args.paths or {}
  wallpaper.wp_filter = function(s) return string.match(s,"%.png$") or string.match(s,"%.jpg$") or string.match(s,"%.jpeg$") or string.match(s,"%.JPG$") end
  wallpaper.wp_normal_icon = args.widget_icon_wallpaper
  wallpaper.wp_paused_icon = args.widget_icon_wallpaper_paused
  wallpaper.wp_files = {}

  wallpaper.scan_files = function()
    wallpaper.wp_files = {}
    for key,value in ipairs(wallpaper.wp_paths) do
      local folder_files = scandir(value, wallpaper.wp_filter)
      for _, file_path in ipairs(folder_files) do
        wallpaper.wp_files[#wallpaper.wp_files+1] = {key, file_path}
      end
      gears.debug.print_warning(string.format("Adding wallpaper: %s for %sx%s, Count: %s", value, wallpaper.wp_screen.geometry.width, wallpaper.wp_screen.geometry.height, #folder_files))
    end
  end

  wallpaper.change_path = function(new_paths)
    wallpaper.wp_paths = new_paths
    wallpaper.scan_files()
    wallpaper.start()
  end

  wallpaper.scan_files()
  wallpaper.wp_timer = gears.timer { timeout = wallpaper.wp_timeout }
  wallpaper.current = nil

  wallpaper.wp_wall_icon = wibox.widget.imagebox(wallpaper.wp_normal_icon)

  wallpaper.wp_wall_icon:buttons(
    my_table.join(
      awful.button({ }, 1, function()
        wallpaper.start()
      end),
      awful.button({ }, 2, function()
        awful.spawn("xdg-open '" .. wallpaper.current .. "'")
      end),
      awful.button({ }, 3, function()
        wallpaper.stop()
      end)
      )
    )

  wallpaper.set_wallpaper = function(wallpaper_path)
    gears.debug.print_warning(string.format("New Wallpaper: %s", wallpaper_path))
    gears.wallpaper.maximized(wallpaper_path, wallpaper.wp_screen)
    wallpaper.current = wallpaper_path

    -- Notify dbus we've changed wallpaper
    dbus.refresh_user_wallpaper(wallpaper_path)
  end

  wallpaper.start = function()
    if #wallpaper.wp_files < 1 then
      return
    end

    -- Choose one wallpaper
    wallpaper.wp_index = math.random(#wallpaper.wp_files)
    wallpaper_path = wallpaper.wp_paths[wallpaper.wp_files[wallpaper.wp_index][1]] .. wallpaper.wp_files[wallpaper.wp_index][2]

    -- Set wallpaper to current index
    wallpaper.set_wallpaper(wallpaper_path)

    -- Change icon
    wallpaper.wp_wall_icon.image = wallpaper.wp_normal_icon

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
    -- Change icon
    wallpaper.wp_wall_icon.image = wallpaper.wp_paused_icon
  end

  root.buttons(gears.table.join(
    root.buttons(),
    awful.button({ }, 2, function (args)
      if wallpaper.current and awful.screen.focused().index == wallpaper.wp_screen.index then
        gears.debug.print_warning(string.format("Upload Wallpaper: %s", wallpaper.current))
        awful.util.spawn("upload_to_telegram.sh " .. '"' .. wallpaper.current .. '"')
      end
    end)
  ))

  wallpaper.wp_timer:connect_signal("timeout", wallpaper.start)

  return wallpaper
end

return factory
