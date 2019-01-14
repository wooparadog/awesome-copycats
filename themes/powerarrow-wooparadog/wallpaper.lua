local awful = require("awful")
local gears = require("gears")

local wallpaper = {}

-- configuration - edit to your liking

math.randomseed(os.time())

function scandir(directory, filter)
  local i, t, popen = 0, {}, io.popen
  if not filter then
    filter = function(s) return true end
  end
  print(filter)
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
  wallpaper.wp_filter = function(s) return string.match(s,"%.png$") or string.match(s,"%.jpg$") end
  wallpaper.wp_files = scandir(wallpaper.wp_path, wallpaper.wp_filter)
  wallpaper.wp_timer = timer { timeout = wallpaper.wp_timeout }

  wallpaper.start = function()
    if #wallpaper.wp_files < 1 then
      return
    end
    -- set wallpaper to current index for all screens
    wallpaper.wp_index = math.random(#wallpaper.wp_files)
    gears.wallpaper.maximized(wallpaper.wp_path .. wallpaper.wp_files[wallpaper.wp_index], nil)

    -- stop the timer (we don't need multiple instances running at the same time)
    wallpaper.wp_timer:stop()


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
