#! /usr/bin/env lua

local lgi = require("lgi")
local Gio, GLib = lgi.Gio, lgi.GLib

local dbus = {}

local function factory(args)
  bus_type = args.type or "SYSTEM"
  assert(bus_type == "SYSTEM", "USER DBUS STILL NOT SUPPORTED")

  if bus_type == "SYSTEM" then
    dbus.system = Gio.bus_get_sync(Gio.BusType.SYSTEM, nil)
  end

  current_user = GLib.get_user_name()
  result = dbus.system:call_sync ('org.freedesktop.Accounts',
                          '/org/freedesktop/Accounts',
                          'org.freedesktop.Accounts',
                          'FindUserByName',
                          GLib.Variant ('(s)', {current_user,}),
                          GLib.VariantType.new ('(o)'),
                          Gio.DBusCallFlags.NONE,
                          -1,
                          None)
  dbus.current_user_path = result.value[1]

  dbus.refresh_user_wallpaper = function(path)
    dbus.system:call_sync(
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
        GLib.VariantType.new ('()'),
        Gio.DBusCallFlags.NONE,
        -1,
        nil
    )
  end
  return dbus
end

return factory
