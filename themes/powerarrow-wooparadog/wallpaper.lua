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
  wallpaper.wp_vertical_path = args.vertical_path or { string.format("%s/Photos/wallpaper/", os.getenv("HOME")) }
  wallpaper.wp_horizontal_path = args.horizontal_path or { string.format("%s/Photos/wallpaper/", os.getenv("HOME")) }
  wallpaper.wp_filter = function(s) return string.match(s,"%.png$") or string.match(s,"%.jpg$") or string.match(s,"%.jpeg$") or string.match(s,"%.JPG$") end
  wallpaper.wp_normal_icon = args.widget_icon_wallpaper
  wallpaper.wp_paused_icon = args.widget_icon_wallpaper_paused
  wallpaper.wp_files = {}
  wallpaper.wp_paths = {}

  wallpaper.choose_wallpaper = function(s)
    local path

    if s.index ~= wallpaper.wp_screen.index then
      return
    end

    if wallpaper.orientation == consts.orientation_horiontal then
      wallpaper.wp_paths = wallpaper.wp_horizontal_path
    elseif wallpaper.orientation == consts.orientation_vertical then
      wallpaper.wp_paths = wallpaper.wp_vertical_path
    else -- Predicate screen orientation if not specified
      if wallpaper.wp_screen.geometry.width >= wallpaper.wp_screen.geometry.height then
        wallpaper.wp_paths = wallpaper.wp_horizontal_path
      else
        wallpaper.wp_paths = wallpaper.wp_vertical_path
      end
    end

    for key,value in ipairs(wallpaper.wp_paths) do
      local folder_files = scandir(value, wallpaper.wp_filter)
      for _,file_path in ipairs(folder_files) do
        wallpaper.wp_files[#wallpaper.wp_files+1] = {key, file_path}
      end
      gears.debug.print_warning(string.format("Chossing: %s for %sx%s, Count: %s", value, wallpaper.wp_screen.geometry.width, wallpaper.wp_screen.geometry.height, #folder_files))
    end
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
      end),
      awful.button({ }, 2, function()
        awful.spawn("xdg-open '" .. wallpaper.current .. "'")
      end),
      awful.button({ }, 3, function()
        wallpaper.stop()
      end)
      )
    )

  wallpaper.start = function()
    if #wallpaper.wp_files < 1 then
      return
    end

    -- set wallpaper to current index for all screens
    wallpaper.wp_index = math.random(#wallpaper.wp_files)
    wallpaper_path = wallpaper.wp_paths[wallpaper.wp_files[wallpaper.wp_index][1]] .. wallpaper.wp_files[wallpaper.wp_index][2]
    gears.debug.print_warning(string.format("New Wallpaper: %s", wallpaper_path))
    gears.wallpaper.maximized(wallpaper_path, wallpaper.wp_screen)
    wallpaper.current = wallpaper_path

    -- Notify dbus we've changed wallpaper
    dbus.refresh_user_wallpaper(wallpaper_path)

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
