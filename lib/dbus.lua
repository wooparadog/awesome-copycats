#! /usr/bin/env lua

local lgi = require("lgi")
local Gio, GLib = lgi.Gio, lgi.GLib

local dbus = {}
local _instance

local function factory(args)
  if _instance then return _instance end
  local bus_type = (args and args.type) or "SYSTEM"
  assert(bus_type == "SYSTEM", "USER DBUS STILL NOT SUPPORTED")

  local system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, nil)
  dbus.system = system_bus

  local current_user = GLib.get_user_name()
  system_bus:call(
    'org.freedesktop.Accounts',
    '/org/freedesktop/Accounts',
    'org.freedesktop.Accounts',
    'FindUserByName',
    GLib.Variant('(s)', {current_user}),
    GLib.VariantType.new('(o)'),
    Gio.DBusCallFlags.NONE,
    -1,
    nil,
    function(conn, res)
      local ok, result = pcall(function() return conn:call_finish(res) end)
      if ok and result then
        dbus.current_user_path = result.value[1]
      end
    end
  )

  dbus.refresh_user_wallpaper = function(path)
    if not dbus.current_user_path then return end
    system_bus:call_sync(
        "org.freedesktop.Accounts",
        dbus.current_user_path,
        "org.freedesktop.DBus.Properties",
        "Set",
        GLib.Variant(
            '(ssv)',
            {
              'org.freedesktop.DisplayManager.AccountsService',
              'BackgroundFile',
              GLib.Variant('s', path)
            }
        ),
        GLib.VariantType.new('()'),
        Gio.DBusCallFlags.NONE,
        -1,
        nil
    )
  end

  -- Parse a{sv} GLib.Variant dict into a battery props table.
  local function parse_battery_props(dict)
    local function get(key)
      local v = dict:lookup_value(key, nil)
      return v and v.value
    end
    return {
      state   = get("State"),
      tte     = get("TimeToEmpty"),
      perc    = get("Percentage"),
      watt    = get("EnergyRate"),
      present = get("IsPresent"),
    }
  end
  dbus.parse_battery_props = parse_battery_props

  -- Subscribe to a D-Bus signal on the system bus.
  -- Returns an integer subscription id; pass it to unsubscribe_signal to cancel.
  dbus.subscribe_signal = function(sender, interface_name, signal_name, object_path, arg0, callback)
    return system_bus:signal_subscribe(
      sender, interface_name, signal_name, object_path, arg0,
      Gio.DBusSignalFlags.NONE,
      callback
    )
  end

  dbus.unsubscribe_signal = function(id)
    system_bus:signal_unsubscribe(id)
  end

  -- Async fetch of all UPower battery properties.
  -- callback receives a table: {state, tte, perc, watt, present}
  -- state: 1=charging 2=discharging 3=empty 4=fully-charged 5/6=pending
  dbus.get_battery_async = function(battery, callback)
    local path = "/org/freedesktop/UPower/devices/battery_" .. battery
    system_bus:call(
      "org.freedesktop.UPower",
      path,
      "org.freedesktop.DBus.Properties",
      "GetAll",
      GLib.Variant("(s)", {"org.freedesktop.UPower.Device"}),
      GLib.VariantType.new("(a{sv})"),
      Gio.DBusCallFlags.NONE,
      5000,
      nil,
      function(conn, res)
        local ok2, reply = pcall(function() return conn:call_finish(res) end)
        if not ok2 or not reply then return end
        callback(parse_battery_props(reply:get_child_value(0)))
      end
    )
  end

  _instance = dbus
  return dbus
end

return factory
