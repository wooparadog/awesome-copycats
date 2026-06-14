--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Luca CPZ
      * (c) 2013, Rman

--]]

local helpers = require("lib.lain.helpers")
local gears = require("gears")
local awful = require("awful")
local lgi = require("lgi")
local Wp = lgi.require("Wp", "0.5")
local GLib = lgi.GLib
local wibox = require("wibox")
local xresources = require("beautiful.xresources")
local root = root
local string = string
local type = type
local tonumber = tonumber
local dpi = xresources.apply_dpi

-- PipeWire-Pulse volume bar
-- lain.widget.pipe_pulsebar

local function factory(args)
  local pipe_pulsebar = {
    colors = {
      background = "#000000",
      mute_background = "#000000",
      mute = "#EB8F8F",
      unmute = "#A4CE8A",
      tooltip_fg_focus = "#32D6FF",
    },

    _current_level = 0,
    _mute = "no",
    -- NOTE: two distinct "device" values are tracked here, do not confuse them:
    --   * pipe_pulsebar.device  -> the sink *index* (e.g. "49"), parsed from
    --     `pactl get-sink-volume` output. This is what rc.lua's volume keys and
    --     theme.lua's button handlers pass to `pactl set-sink-*`.
    --   * volume_now.device     -> the device.string (e.g. "alsa_output...."),
    --     a human-readable id only used for the tooltip. NOT a pactl target.
    device = "N/A",
  }

  args = args or {}

  local settings = args.settings or function(_volume_now) end
  local width = args.width or 63
  local height = args.height or 1
  local margins = args.margins or 1
  local paddings = args.paddings or 1
  local ticks_size = args.ticks_size or 7
  local ticks = args.ticks or false
  local volume_now = {
    index = "N/A",
    muted = "N/A",
    channel = {},
    left = "N/A",
    right = "N/A",
  }
  local widgets = {}
  local button_handlers = args.button_handlers

  pipe_pulsebar.colors = args.colors or pipe_pulsebar.colors
  pipe_pulsebar.devicetype = args.devicetype or "sink"
  pipe_pulsebar.udevicetype = pipe_pulsebar.devicetype:gsub("^%l", string.upper)
  pipe_pulsebar.cmd = args.cmd
    or "LANG=en_US.UTF-8 pactl get-"
      .. pipe_pulsebar.devicetype
      .. "-volume @DEFAULT_"
      .. string.upper(pipe_pulsebar.devicetype)
      .. "@; LANG=en_US.UTF-8 pactl get-"
      .. pipe_pulsebar.devicetype
      .. "-mute @DEFAULT_"
      .. string.upper(pipe_pulsebar.devicetype)
      .. "@; LANG=en_US.UTF-8 pactl list "
      .. pipe_pulsebar.devicetype
      .. "s | grep -B 2 'Name: '$(pactl get-default-"
      .. pipe_pulsebar.devicetype
      .. ")"
  pipe_pulsebar.scmd = args.cmd
    or "LANG=en_US.UTF-8 pactl list "
      .. pipe_pulsebar.devicetype
      .. "s | sed -n -e '/"
      .. pipe_pulsebar.udevicetype
      .. " #/p' -e '/Base Volume/d' -e '/Volume:/p' -e '/Mute:/p' -e '/device\\.string/p'"

  pipe_pulsebar.add_screen = function(screen)
    local bar = wibox.widget({
      color = pipe_pulsebar.colors.unmute,
      background_color = pipe_pulsebar.colors.background,
      ticks = ticks,
      widget = wibox.widget.progressbar,
      forced_height = dpi(height, screen),
      forced_width = dpi(width, screen),
      paddings = dpi(paddings, screen),
      ticks_size = dpi(ticks_size, screen),
      margins = dpi(margins, screen),
    })
    if button_handlers then
      bar:buttons(button_handlers(pipe_pulsebar))
    end
    local tooltip = awful.tooltip({
      objects = { bar },
      wibox = {
        fg = pipe_pulsebar.colors.tooltip_fg_focus,
      },
    })

    widgets[#widgets + 1] = {
      bar = bar,
      tooltip = tooltip,
    }
    return bar
  end

  -- Find the device
  helpers.async({
    awful.util.shell,
    "-c",
    type(pipe_pulsebar.scmd) == "string" and pipe_pulsebar.scmd or pipe_pulsebar.scmd(),
  }, function(s)
    volume_now.device = string.match(s, 'device.string = "(%S+)"') or "N/A"
  end)

  function pipe_pulsebar.update(callback)
    helpers.async(
      { awful.util.shell, "-c", type(pipe_pulsebar.cmd) == "string" and pipe_pulsebar.cmd or pipe_pulsebar.cmd() },
      function(s)
        volume_now = {
          index = string.match(s, " #(%S+)") or "N/A",
          muted = string.match(s, "Mute: (%S+)") or "N/A",
        }

        -- sink index used as the pactl target (see device note above)
        pipe_pulsebar.device = volume_now.index

        local ch = 1
        volume_now.channel = {}
        for v in string.gmatch(s, ":.-(%d+)%%") do
          volume_now.channel[ch] = v
          ch = ch + 1
        end

        volume_now.left = volume_now.channel[1] or "N/A"
        volume_now.right = volume_now.channel[2] or "N/A"

        local volu = volume_now.left
        local mute = volume_now.muted

        if volu:match("N/A") or mute:match("N/A") then
          return
        end

        if volu ~= pipe_pulsebar._current_level or mute ~= pipe_pulsebar._mute then
          pipe_pulsebar._current_level = tonumber(volu)
          pipe_pulsebar._mute = mute
          local is_muted = pipe_pulsebar._current_level == 0 or mute == "yes"
          for _, w in ipairs(widgets) do
            w.bar:set_value(pipe_pulsebar._current_level / 100)
            if is_muted then
              w.tooltip:set_text("[muted]")
              w.bar.color = pipe_pulsebar.colors.mute
              w.bar.background_color = pipe_pulsebar.colors.mute_background
            else
              w.tooltip:set_text(string.format("%s %s: %s", pipe_pulsebar.devicetype, pipe_pulsebar.device, volu))
              w.bar.color = pipe_pulsebar.colors.unmute
              w.bar.background_color = pipe_pulsebar.colors.background
            end
          end

          settings(volume_now)

          if type(callback) == "function" then
            callback()
          end
        end
      end
    )
  end

  -- Subscribe to PipeWire volume/mute changes via WirePlumber's GObject API.
  -- No subprocess — WpCore connects to the PipeWire socket directly on the
  -- GLib main loop that AwesomeWM already runs. When params-changed fires on
  -- any Audio/Sink node with id "Props", we call update() to refresh the bar.
  local function subscribe_volume_events()
    -- Guard: Wp.init() must only run once per process.
    if not pipe_pulsebar._wp_inited then
      Wp.init(Wp.InitFlags.PIPEWIRE + Wp.InitFlags.SPA_TYPES)
      pipe_pulsebar._wp_inited = true
    end

    local core = Wp.Core.new(GLib.MainContext.default(), nil, nil)
    local om = Wp.ObjectManager.new()

    local interest = Wp.ObjectInterest.new_type(Wp.Node)
    interest:add_constraint(
      Wp.ConstraintType.PW_PROPERTY,
      "media.class",
      Wp.ConstraintVerb.EQUALS,
      GLib.Variant("s", "Audio/Sink")
    )
    om:add_interest_full(interest)

    om:request_object_features(
      Wp.Node,
      Wp.ProxyFeatures.PROXY_FEATURE_BOUND
        + Wp.ProxyFeatures.PIPEWIRE_OBJECT_FEATURE_INFO
        + Wp.ProxyFeatures.PIPEWIRE_OBJECT_FEATURE_PARAM_PROPS
    )

    local debounce_timer
    om.on_object_added:connect(function(_, node)
      node.on_params_changed:connect(function(_, param_id)
        if param_id ~= "Props" then
          return
        end
        if debounce_timer then
          debounce_timer:stop()
        end
        debounce_timer = gears.timer.start_new(0.1, function()
          debounce_timer = nil
          pipe_pulsebar.update()
          return false
        end)
      end)
    end)

    core.on_connected:connect(function()
      core:install_object_manager(om)
    end)

    core:connect()

    -- Keep core and om alive for the lifetime of awesome.
    pipe_pulsebar._wp_core = core
    pipe_pulsebar._wp_om = om
  end

  root.keys(gears.table.join(
    root.keys(),
    awful.key({}, "#123", function()
      awful.spawn(string.format("pactl set-sink-volume %s +5%%", pipe_pulsebar.device))
      pipe_pulsebar.update()
    end, { description = "volume up", group = "hotkeys" }),
    awful.key({}, "#122", function()
      awful.spawn(string.format("pactl set-sink-volume %s -5%%", pipe_pulsebar.device))
      pipe_pulsebar.update()
    end, { description = "volume down", group = "hotkeys" }),
    awful.key({}, "#121", function()
      awful.spawn(string.format("pactl set-sink-mute %s toggle", pipe_pulsebar.device))
      pipe_pulsebar.update()
    end, { description = "toggle mute", group = "hotkeys" })
  ))

  pipe_pulsebar.update()
  subscribe_volume_events()

  return pipe_pulsebar
end

return factory
