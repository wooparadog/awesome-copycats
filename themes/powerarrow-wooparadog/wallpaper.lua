local awful = require("awful")
local gears = require("gears")
local dbus = require("themes.powerarrow-wooparadog.dbus"){}

local wallpaper = {}

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

  wallpaper.wp_index = args.index or 1
  wallpaper.wp_timeout  = args.timeout or 300
  wallpaper.wp_path = args.path or string.format("%s/Photos/wallpaper/", os.getenv("HOME"))
  wallpaper.wp_filter = function(s) return string.match(s,"%.png$") or string.match(s,"%.jpg$") or string.match(s,"%.jpeg$") or string.match(s,"%.JPG$") end
  wallpaper.wp_files = scandir(wallpaper.wp_path, wallpaper.wp_filter)
  wallpaper.wp_timer = gears.timer { timeout = wallpaper.wp_timeout }

  wallpaper.start = function()
    if #wallpaper.wp_files < 1 then
      return
    end
    -- set wallpaper to current index for all screens
    wallpaper.wp_index = math.random(#wallpaper.wp_files)
    wallpaper_path = wallpaper.wp_path .. wallpaper.wp_files[wallpaper.wp_index]
    gears.wallpaper.maximized(wallpaper_path, nil)

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
