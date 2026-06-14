#! /usr/bin/env lua

-- Battery widget backed by UPower DBus signals.
-- Zero polling cost: updates fire only when UPower reports a state change.

local wibox = require("wibox")
local naughty = require("naughty")
local math = math
local string = string

local function factory(args)
  args = args or {}

  local bat_now = {
    status = "N/A",
    ac_status = "N/A",
    perc = "N/A",
    tte = 0,
    watt = "N/A",
  }

  local bat = { widget = args.widget or wibox.widget.textbox() }
  local battery = args.battery or "BAT0"
  local settings = args.settings or function(_bat_now, _widget) end
  local notify = args.notify ~= false
  local n_perc = args.n_perc or { 5, 15 }

  local upower = require("lib.dbus")({})
  local path = "/org/freedesktop/UPower/devices/battery_" .. battery

  local fullnotification = false

  local function apply(data)
    if not data or not data.state then
      return
    end

    -- Map UPower State to bat_now fields
    local s = data.state
    if s == 1 or s == 5 then
      bat_now.status, bat_now.ac_status = "Charging", 1
    elseif s == 2 or s == 6 then
      bat_now.status, bat_now.ac_status = "Discharging", 0
    elseif s == 3 then
      bat_now.status, bat_now.ac_status = "Empty", 0
    elseif s == 4 then
      bat_now.status, bat_now.ac_status = "Full", 1
    else
      bat_now.status, bat_now.ac_status = "N/A", "N/A"
    end

    bat_now.perc = data.perc and math.floor(data.perc) or "N/A"
    bat_now.tte = data.tte or 0
    bat_now.watt = data.watt and tonumber(string.format("%.2f", data.watt)) or "N/A"

    if notify then
      local perc = tonumber(bat_now.perc)
      if bat_now.status == "Discharging" and perc then
        if perc <= n_perc[1] then
          bat.id = naughty.notify({
            app_name = "awesome",
            preset = {
              title = "Battery exhausted",
              text = "Shutdown imminent",
              timeout = 15,
              fg = "#000000",
              bg = "#FFFFFF",
            },
            replaces_id = bat.id,
          }).id
        elseif perc <= n_perc[2] then
          bat.id = naughty.notify({
            app_name = "awesome",
            preset = {
              title = "Battery low",
              text = "Plug the cable!",
              timeout = 15,
              fg = "#202020",
              bg = "#CDCDCD",
            },
            replaces_id = bat.id,
          }).id
        end
        fullnotification = false
      elseif bat_now.status == "Full" and not fullnotification then
        bat.id = naughty.notify({
          app_name = "awesome",
          preset = {
            title = "Battery charged",
            text = "Reached " .. tostring(bat_now.perc) .. "%",
            timeout = 15,
            fg = "#202020",
            bg = "#CDCDCD",
          },
          replaces_id = bat.id,
        }).id
        fullnotification = true
      end
    end

    settings(bat_now, bat.widget)
  end

  local function refresh()
    upower.get_battery_async(battery, apply)
  end

  -- Subscribe to UPower PropertiesChanged on this battery device.
  -- Fires only when battery state actually changes — no polling timer needed.
  upower.subscribe_signal(
    nil,
    "org.freedesktop.DBus.Properties",
    "PropertiesChanged",
    path,
    "org.freedesktop.UPower.Device",
    refresh
  )

  -- Initial async fetch to populate the widget on startup.
  upower.get_battery_async(battery, apply)

  return bat
end

return factory
