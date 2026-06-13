---@diagnostic disable-next-line
local dbus, root = dbus, root

local awful = require("awful")
local gears = require("gears")
local dbus_caller = require("themes.powerarrow-wooparadog.dbus"){}
local wibox = require("wibox")
local instances = {}


dbus.connect_signal("org.freedesktop.portal.Wallpaper",
  function (screen, uri, options)
      local height = options and options.height or 0
      local width = options and options.width or 0
      gears.debug.print_warning(string.format("getting new wallpaper from dbus %s: %s x %s", uri, width, height))

      local wallpaper =  instances[math.random(#instances)]
      if (width > height) == (wallpaper.wp_screen.geometry.width > wallpaper.wp_screen.geometry.height) then
        gears.debug.print_warning(string.format("Setting wallpaper %s: %s x %s", uri, width, height))
        wallpaper.set_wallpaper(uri)
      end
  end
  )
dbus.add_match('session', "type=signal,interface=org.freedesktop.portal.Wallpaper,path=/org/freedesktop/portal/desktop")

-- Seed the RNG once at module load. Reseeding on every rotation barely
-- changes a time-based seed and is an anti-pattern.
math.randomseed(os.time())

local function factory(input_args)
  local args = input_args or {}
  local wallpaper = {}

  wallpaper.wp_screen = args.screen or nil
  wallpaper.wp_timeout  = args.timeout or 300
  wallpaper.wp_paths = args.paths or {}
  wallpaper.wp_normal_icon = args.widget_icon_wallpaper
  wallpaper.wp_paused_icon = args.widget_icon_wallpaper_paused
  wallpaper.wp_files = {}
  wallpaper._scanning = false
  wallpaper._scan_callbacks = {}

  local function is_screen_valid()
    return wallpaper.wp_screen and wallpaper.wp_screen.valid
  end

  -- Scan all configured paths for images asynchronously, then invoke callback.
  -- Uses `find` via easy_async_with_shell so a slow/stale mount (e.g. Nextcloud)
  -- never blocks the WM main loop. Concurrent calls share the in-flight scan.
  wallpaper.scan_files = function(callback)
    if not is_screen_valid() then
      if callback then callback() end
      return
    end

    if callback then
      wallpaper._scan_callbacks[#wallpaper._scan_callbacks+1] = callback
    end
    if wallpaper._scanning then return end
    wallpaper._scanning = true

    wallpaper.wp_files = {}

    local function flush_callbacks()
      wallpaper._scanning = false
      local cbs = wallpaper._scan_callbacks
      wallpaper._scan_callbacks = {}
      for _, cb in ipairs(cbs) do cb() end
    end

    local pending = #wallpaper.wp_paths
    if pending == 0 then
      flush_callbacks()
      return
    end

    for key, value in ipairs(wallpaper.wp_paths) do
      local cmd = "find '" .. value .. "' -maxdepth 1 -type f " ..
                  "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \\) " ..
                  "-printf '%f\\n' 2>/dev/null"
      awful.spawn.easy_async_with_shell(cmd, function(stdout)
        local count = 0
        for filename in stdout:gmatch("[^\r\n]+") do
          wallpaper.wp_files[#wallpaper.wp_files+1] = {key, filename}
          count = count + 1
        end
        if is_screen_valid() then
          gears.debug.print_warning(string.format("Adding wallpaper: %s for %sx%s, Count: %s", value, wallpaper.wp_screen.geometry.width, wallpaper.wp_screen.geometry.height, count))
        end
        pending = pending - 1
        if pending == 0 then flush_callbacks() end
      end)
    end
  end

  wallpaper.change_path = function(new_paths)
    gears.debug.print_warning(gears.debug.dump_return(new_paths, 'Changing Wallpaper Path:'))
    wallpaper.wp_paths = new_paths
    wallpaper.scan_files(function() wallpaper.start() end)
  end

  wallpaper.wp_timer = gears.timer { timeout = wallpaper.wp_timeout }
  wallpaper.current = nil
  wallpaper.wp_wall_icon = wibox.widget.imagebox(wallpaper.wp_normal_icon)

  local tooltip = awful.tooltip({
    objects = { wallpaper.wp_wall_icon },
    text = "Wallpaper Operations:\n• Left click: Change wallpaper\n• Meta+Left click: Delete current\n• Middle click: Open in viewer\n• Right click: Pause rotation\n• Mod4+d: Change wallpaper (keyboard)"
  })

  wallpaper.wp_wall_icon:buttons(
    gears.table.join(
      awful.button({ }, 1, function()
        wallpaper.start()
      end),
      awful.button({ "Mod4" }, 1, function()
        local naughty = require("naughty")

        if not wallpaper.current then
          naughty.notify({
            preset = naughty.config.presets.normal,
            title = "Delete Wallpaper",
            text = "No wallpaper to delete"
          })
          return
        end

        local filename = wallpaper.current:match("([^/]+)$")
        if wallpaper.delete_current() then
          naughty.notify({
            preset = naughty.config.presets.normal,
            title = "Delete Wallpaper", 
            text = "Wallpaper '" .. filename .. "' deleted successfully"
          })
        else
          naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Delete Wallpaper",
            text = "Failed to delete wallpaper '" .. filename .. "'"
          })
        end
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
    if not is_screen_valid() then return end
    gears.debug.print_warning(string.format("New Wallpaper[of %s]: %s", #wallpaper.wp_files, wallpaper_path))
    gears.wallpaper.maximized(wallpaper_path, wallpaper.wp_screen)
    wallpaper.current = wallpaper_path

    -- Notify dbus_caller we've changed wallpaper
    dbus_caller.refresh_user_wallpaper(wallpaper_path)
  end

  -- Pick a random scanned wallpaper and display it. Assumes wp_files is populated.
  local function pick_and_set()
    if not is_screen_valid() or #wallpaper.wp_files < 1 then
      return
    end

    local wp_index = math.random(#wallpaper.wp_files)
    local wallpaper_item = table.remove(wallpaper.wp_files, wp_index)
    local wallpaper_path = wallpaper.wp_paths[wallpaper_item[1]] .. wallpaper_item[2]

    -- Set wallpaper to current index
    wallpaper.set_wallpaper(wallpaper_path)

    -- Change icon
    wallpaper.wp_wall_icon.image = wallpaper.wp_normal_icon

    -- Start the timer if not started
    wallpaper.wp_timer:again()
  end

  wallpaper.start = function()
    if not is_screen_valid() then
      wallpaper.wp_timer:stop()
      return
    end

    -- The pool empties as wallpapers are consumed; rescan (async) when drained.
    if #wallpaper.wp_files < 1 then
      wallpaper.scan_files(pick_and_set)
    else
      pick_and_set()
    end
  end

  wallpaper.stop = function()
    wallpaper.wp_timer:stop()
    -- Change icon
    wallpaper.wp_wall_icon.image = wallpaper.wp_paused_icon
  end

  wallpaper.delete_current = function()
    if not wallpaper.current then
      return false
    end

    local success = os.remove(wallpaper.current)
    if success then
      gears.debug.print_warning(string.format("Deleted wallpaper: %s", wallpaper.current))
      wallpaper.start()
      return true
    else
      gears.debug.print_warning(string.format("Failed to delete wallpaper: %s", wallpaper.current))
      return false
    end
  end

  root.buttons(gears.table.join(
    root.buttons(),
    awful.button({ }, 2, function ()
      if is_screen_valid() and wallpaper.current and awful.screen.focused().index == wallpaper.wp_screen.index then
        gears.debug.print_warning(string.format("Upload Wallpaper: %s", wallpaper.current))
        awful.spawn("upload_to_telegram.sh " .. '"' .. wallpaper.current .. '"')
      end
    end)
  ))

  wallpaper.wp_timer:connect_signal("timeout", wallpaper.start)

  -- Add global keybinding for this wallpaper instance
  root.keys(
    gears.table.join(
      root.keys(),
      awful.key({ "Mod4" }, "d", function()
        if is_screen_valid() and awful.screen.focused { client=false, mouse=true }.index == wallpaper.wp_screen.index then
          wallpaper.start()
        end
      end, {description = "Refresh wallpaper", group = "screen"})
    )
  )

  instances[#instances+1] = wallpaper

  return wallpaper
end

return factory
