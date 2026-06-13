--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Luca CPZ
      * (c) 2013, Rman

--]]

local helpers    = require("lain.helpers")
local gears      = require("gears")
local awful      = require("awful")
local naughty    = require("naughty")
local wibox      = require("wibox")
local xresources = require("beautiful.xresources")
local root     = root
local math     = math
local string   = string
local type     = type
local tonumber = tonumber
local dpi      = xresources.apply_dpi

-- PipeWire-Pulse volume bar
-- lain.widget.pipe_pulsebar

local function factory(args)
    local pipe_pulsebar = {
        colors = {
            background       = "#000000",
            mute_background  = "#000000",
            mute             = "#EB8F8F",
            unmute           = "#A4CE8A",
            tooltip_fg_focus = "#32D6FF"
        },

        _current_level = 0,
        _mute          = "no",
        -- NOTE: two distinct "device" values are tracked here, do not confuse them:
        --   * pipe_pulsebar.device  -> the sink *index* (e.g. "49"), parsed from
        --     `pactl get-sink-volume` output. This is what rc.lua's volume keys and
        --     theme.lua's button handlers pass to `pactl set-sink-*`.
        --   * volume_now.device     -> the device.string (e.g. "alsa_output...."),
        --     a human-readable id only used for the tooltip. NOT a pactl target.
        device         = "N/A"
    }

    args             = args or {}

    local settings   = args.settings or function(_volume_now) end
    local width      = args.width or 63
    local height     = args.height or 1
    local margins    = args.margins or 1
    local paddings   = args.paddings or 1
    local ticks_size = args.ticks_size or 7
    local ticks      = args.ticks or false
    local tick       = args.tick or "|"
    local tick_pre   = args.tick_pre or "["
    local tick_post  = args.tick_post or "]"
    local tick_none  = args.tick_none or " "
    local volume_now = {
      index = "N/A",
      muted  = "N/A",
      channel = {},
      left = "N/A",
      right = "N/A",
    }
    local widgets    = {}
    local screen     = args.screen
    local button_handlers = args.button_handlers 

    pipe_pulsebar.colors              = args.colors or pipe_pulsebar.colors
    pipe_pulsebar.followtag           = args.followtag or false
    pipe_pulsebar.notification_preset = args.notification_preset
    pipe_pulsebar.devicetype          = args.devicetype or "sink"
    pipe_pulsebar.udevicetype         = pipe_pulsebar.devicetype:gsub("^%l",string.upper)
    pipe_pulsebar.cmd                 = args.cmd or "LANG=en_US.UTF-8 pactl get-" .. pipe_pulsebar.devicetype .. "-volume @DEFAULT_" .. string.upper(pipe_pulsebar.devicetype) .. "@; LANG=en_US.UTF-8 pactl get-" .. pipe_pulsebar.devicetype .. "-mute @DEFAULT_" .. string.upper(pipe_pulsebar.devicetype) .. "@; LANG=en_US.UTF-8 pactl list " .. pipe_pulsebar.devicetype .. "s | grep -B 2 'Name: '$(pactl get-default-" .. pipe_pulsebar.devicetype .. ")"
    pipe_pulsebar.scmd                = args.cmd or "LANG=en_US.UTF-8 pactl list " .. pipe_pulsebar.devicetype .. "s | sed -n -e '/" .. pipe_pulsebar.udevicetype .. " #/p' -e '/Base Volume/d' -e '/Volume:/p' -e '/Mute:/p' -e '/device\\.string/p'"

    if not pipe_pulsebar.notification_preset then
        pipe_pulsebar.notification_preset = {
            font = "Monospace 10"
        }
    end

    pipe_pulsebar.add_screen = function(screen)
      local bar = wibox.widget {
        color            = pipe_pulsebar.colors.unmute,
        background_color = pipe_pulsebar.colors.background,
        ticks            = ticks,
        widget           = wibox.widget.progressbar,
        forced_height    = dpi(height, screen),
        forced_width     = dpi(width, screen),
        paddings         = dpi(paddings, screen),
        ticks_size       = dpi(ticks_size, screen),
        margins          = dpi(margins, screen),
      }
      if button_handlers then
        bar:buttons(button_handlers(pipe_pulsebar))
      end
      local tooltip = awful.tooltip({
        objects = { bar },
        wibox = {
          fg = pipe_pulsebar.colors.tooltip_fg_focus
        }
      })

      widgets[#widgets+1] = {
        bar = bar ,
        tooltip = tooltip
      }
      return bar
    end

    -- Find the device
    helpers.async({
        awful.util.shell,
        "-c",
        type(pipe_pulsebar.scmd) == "string" and pipe_pulsebar.scmd or pipe_pulsebar.scmd()
      },
      function(s)
        volume_now.device = string.match(s, "device.string = \"(%S+)\"") or "N/A"
      end
    )

    function pipe_pulsebar.update(callback)
        helpers.async({ awful.util.shell, "-c", type(pipe_pulsebar.cmd) == "string" and pipe_pulsebar.cmd or pipe_pulsebar.cmd() },
        function(s)
            volume_now = {
                index = string.match(s, " #(%S+)") or "N/A",
                muted  = string.match(s, "Mute: (%S+)") or "N/A"
            }

            -- sink index used as the pactl target (see device note above)
            pipe_pulsebar.device = volume_now.index

            local ch = 1
            volume_now.channel = {}
            for v in string.gmatch(s, ":.-(%d+)%%") do
              volume_now.channel[ch] = v
              ch = ch + 1
            end

            volume_now.left  = volume_now.channel[1] or "N/A"
            volume_now.right = volume_now.channel[2] or "N/A"

            local volu = volume_now.left
            local mute = volume_now.muted

            if volu:match("N/A") or mute:match("N/A") then return end

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

                if type(callback) == "function" then callback() end
            end
        end)
    end


    function pipe_pulsebar.notify()
        pipe_pulsebar.update(function()
            local preset = pipe_pulsebar.notification_preset

            preset.title = string.format("%s %s - %s%%", pipe_pulsebar.devicetype, pipe_pulsebar.device, pipe_pulsebar._current_level)

            if pipe_pulsebar._mute == "yes" then
                preset.title = preset.title .. " muted"
            end

            -- tot is the maximum number of ticks to display in the notification
            -- fallback: default horizontal wibox height
            local wib, tot = awful.screen.focused().mywibox, 20

            -- if we can grab mywibox, tot is defined as its height if
            -- horizontal, or width otherwise
            if wib then
                if wib.position == "left" or wib.position == "right" then
                    tot = wib.width
                else
                    tot = wib.height
                end
            end

            local int = math.modf((pipe_pulsebar._current_level / 100) * tot)
            preset.text = string.format(
                "%s%s%s%s",
                tick_pre,
                string.rep(tick, int),
                string.rep(tick_none, tot - int),
                tick_post
            )

            if pipe_pulsebar.followtag then preset.screen = awful.screen.focused() end

            if not pipe_pulsebar.notification then
                pipe_pulsebar.notification = naughty.notify {
                    preset  = preset,
                    destroy = function() pipe_pulsebar.notification = nil end
                }
            else
                naughty.replace_text(pipe_pulsebar.notification, preset.title, preset.text)
            end
        end)
    end

    -- Subscribe to pactl events; update only when the sink or server actually changes.
    -- Auto-restarts after a 2 s delay if pactl subscribe exits unexpectedly.
    local function subscribe_volume_events()
        awful.spawn.with_line_callback("pactl subscribe", {
            stdout = function(line)
                if line:match("'change' on sink") or line:match("'change' on server") then
                    pipe_pulsebar.update()
                end
            end,
            exit = function()
                gears.timer.start_new(2, function()
                    subscribe_volume_events()
                    return false
                end)
            end
        })
    end

    root.keys(gears.table.join(root.keys(),
        awful.key({}, "#123", function()
            awful.spawn(string.format("pactl set-sink-volume %s +5%%", pipe_pulsebar.device))
            pipe_pulsebar.update()
        end, {description = "volume up", group = "hotkeys"}),
        awful.key({}, "#122", function()
            awful.spawn(string.format("pactl set-sink-volume %s -5%%", pipe_pulsebar.device))
            pipe_pulsebar.update()
        end, {description = "volume down", group = "hotkeys"}),
        awful.key({}, "#121", function()
            awful.spawn(string.format("pactl set-sink-mute %s toggle", pipe_pulsebar.device))
            pipe_pulsebar.update()
        end, {description = "toggle mute", group = "hotkeys"})
    ))

    pipe_pulsebar.update()
    subscribe_volume_events()

    return pipe_pulsebar
end

return factory
