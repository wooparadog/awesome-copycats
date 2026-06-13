---@diagnostic disable-next-line
local dbus, root = dbus, root
-- NOTE: `dbus` above is AwesomeWM's built-in session-bus bridge (a C global),
-- used below for the freedesktop portal Wallpaper signal. Our lib/dbus singleton
-- only covers the system bus, so this session-bus path is a deliberate exception.
-- `lgi` below is used solely for Gio.File directory enumeration, not for D-Bus.

local awful = require("awful")
local gears = require("gears")
local lgi = require("lgi")
local Gio, GLib = lgi.Gio, lgi.GLib
local dbus_caller = require("lib.dbus"){}
local wibox = require("wibox")
local naughty = require("naughty")
local instances = {}

local IMAGE_EXT = { png = true, jpg = true, jpeg = true }


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

-- Global bindings registered once. Callbacks search `instances` at call time so
-- they naturally handle new screens added after startup.
root.buttons(gears.table.join(
  root.buttons(),
  awful.button({}, 2, function()
    local s = awful.screen.focused()
    for _, inst in ipairs(instances) do
      if inst.wp_screen == s and inst.current then
        gears.debug.print_warning(string.format("Upload Wallpaper: %s", inst.current))
        awful.spawn({"upload_to_telegram.sh", inst.current})
        return
      end
    end
  end)
))

root.keys(gears.table.join(
  root.keys(),
  awful.key({"Mod4"}, "d", function()
    local s = awful.screen.focused{client=false, mouse=true}
    for _, inst in ipairs(instances) do
      if inst.wp_screen == s then
        inst.start()
        return
      end
    end
  end, {description = "Refresh wallpaper", group = "screen"})
))

local function factory(input_args)
  local args = input_args or {}
  local wallpaper = {}

  wallpaper.wp_screen = args.screen or nil
  wallpaper.wp_timeout  = args.timeout or 300
  wallpaper.wp_paths = args.paths or {}
  wallpaper.wp_normal_icon = args.widget_icon_wallpaper
  wallpaper.wp_paused_icon = args.widget_icon_wallpaper_paused
  wallpaper.wp_notif_icon  = args.notification_icon
  wallpaper.wp_files = {}
  wallpaper._scanning = false
  wallpaper._scan_callbacks = {}

  local function is_screen_valid()
    return wallpaper.wp_screen and wallpaper.wp_screen.valid
  end

  -- Enumerate one directory's image files asynchronously via Gio, appending
  -- {key, filename} entries to wp_files. Runs on GIO's thread pool, so a
  -- slow/stale mount (e.g. Nextcloud) never blocks the WM main loop, and there
  -- is no subprocess/shell. Invokes on_done(count) when the directory is fully read.
  local function enumerate_dir(key, path, on_done)
    local dir = Gio.File.new_for_path(path)
    dir:enumerate_children_async(
      "standard::name", Gio.FileQueryInfoFlags.NONE, GLib.PRIORITY_DEFAULT, nil,
      function(obj, res)
        local ok, en = pcall(function() return obj:enumerate_children_finish(res) end)
        if not ok or not en then on_done(0) return end

        local count = 0
        local function read_batch()
          en:next_files_async(64, GLib.PRIORITY_DEFAULT, nil, function(e, res2)
            local ok2, infos = pcall(function() return e:next_files_finish(res2) end)
            if not ok2 or not infos or #infos == 0 then
              e:close_async(GLib.PRIORITY_DEFAULT, nil, nil)
              on_done(count)
              return
            end
            for _, info in ipairs(infos) do
              local name = info:get_name()
              local ext = name:match("%.([^.]+)$")
              if ext and IMAGE_EXT[ext:lower()] then
                wallpaper.wp_files[#wallpaper.wp_files+1] = {key, name}
                count = count + 1
              end
            end
            read_batch()
          end)
        end
        read_batch()
      end
    )
  end

  -- Scan all configured paths for images asynchronously, then invoke callback.
  -- Concurrent calls share the in-flight scan.
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

    -- Captured up front: a scan over zero paths (e.g. the startup start() that
    -- runs before paths are resolved) shouldn't pop a "0 candidates" notice.
    local total_paths = #wallpaper.wp_paths

    local function flush_callbacks()
      if total_paths > 0 and is_screen_valid() then
        naughty.notify({
          app_name = "awesome",
          preset  = naughty.config.presets.normal,
          title   = "Wallpaper Pool Refreshed",
          text    = string.format("Screen %s: %s candidates collected",
                                  wallpaper.wp_screen.index, #wallpaper.wp_files),
          timeout = 5,
        })
      end
      wallpaper._scanning = false
      local cbs = wallpaper._scan_callbacks
      wallpaper._scan_callbacks = {}
      for _, cb in ipairs(cbs) do cb() end
    end

    local pending = total_paths
    if pending == 0 then
      flush_callbacks()
      return
    end

    for key, value in ipairs(wallpaper.wp_paths) do
      enumerate_dir(key, value, function(count)
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
        if not wallpaper.current then
          naughty.notify({
            app_name = "awesome",
            preset = naughty.config.presets.normal,
            title = "Delete Wallpaper",
            text = "No wallpaper to delete"
          })
          return
        end

        local filename = wallpaper.current:match("([^/]+)$")
        if wallpaper.delete_current() then
          naughty.notify({
            app_name = "awesome",
            preset = naughty.config.presets.normal,
            title = "Delete Wallpaper",
            text = "Wallpaper '" .. filename .. "' deleted successfully"
          })
        else
          naughty.notify({
            app_name = "awesome",
            preset = naughty.config.presets.critical,
            title = "Delete Wallpaper",
            text = "Failed to delete wallpaper '" .. filename .. "'"
          })
        end
      end),
      awful.button({ }, 2, function()
        if not wallpaper.current then return end
        awful.spawn({"xdg-open", wallpaper.current})
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

    -- Notify the user; clicking anywhere on the popup opens the file.
    local filename = wallpaper_path:match("([^/]+)$") or wallpaper_path
    naughty.notify({
      app_name = "awesome",
      title    = filename,
      text     = "Screen " .. wallpaper.wp_screen.index,
      screen   = wallpaper.wp_screen,
      icon     = wallpaper.wp_notif_icon,
      timeout  = 5,
      on_click = function() awful.spawn({"xdg-open", wallpaper_path}) end,
    })
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

  wallpaper.wp_timer:connect_signal("timeout", wallpaper.start)

  instances[#instances+1] = wallpaper

  return wallpaper
end

return factory
