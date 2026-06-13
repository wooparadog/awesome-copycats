local awful = require("awful")
local lgi   = require("lgi")
local Gio   = lgi.Gio

local wifi_utils = {}

function wifi_utils.get_wifi_info_async(callback, device_name_param)
    local device_name = device_name_param or "wlan0" -- Default to wlan0 if not provided

    -- The command to get just the SSID
    local get_ssid_command = string.format(
        "bash -c 'iwctl station %s show 2>/dev/null | grep \"Connected network\" | awk \"{print \\$3}\"'",
        device_name
    )

    awful.spawn.easy_async(get_ssid_command, function(stdout, stderr, exitreason, exitcode)
        local wifi_info = {} -- Initialize the table to be passed to the callback

        if exitcode == 0 and stdout then
            local current_ssid = stdout:match("^%s*(.-)%s*$") -- Trim whitespace

            if current_ssid and #current_ssid > 0 then
                wifi_info.name = current_ssid
            else
                -- Command ran, but no SSID found (e.g., not connected)
                wifi_info.name = nil -- Or an empty string: ""
            end
        else
            -- Command failed or produced an error
            -- wifi_info.name will remain nil by default if not set
            wifi_info.name = nil -- Or an empty string: ""
            -- You could also add error information to the table if desired
            -- wifi_info.error = stderr or exitreason or "Unknown error executing command"
            -- print("Error getting SSID: " .. (stderr or exitreason or "Unknown error, Exitcode: " .. tostring(exitcode)))
        end

        -- Invoke the callback with the wifi_info table
        if type(callback) == "function" then
            callback(wifi_info)
        else
            print("Error: Provided callback is not a function.")
        end
    end)
end


-- Subscribe to iwd D-Bus signals so the callback fires whenever the connected
-- network changes. Filters on arg0 = "net.connman.iwd.Station" so only station
-- property changes are delivered (not RSSI noise from other interfaces).
-- Within each signal, only State and ConnectedNetwork changes trigger a re-query.
-- Returns a handle with a :disconnect() method.
function wifi_utils.subscribe_ssid_changes(callback, device_name_param)
    local device_name = device_name_param or "wlan0"

    local system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, nil)
    if not system_bus then return { disconnect = function() end } end

    local id = system_bus:signal_subscribe(
        "net.connman.iwd",
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        nil,                          -- any object path
        "net.connman.iwd.Station",    -- arg0: only Station property changes
        Gio.DBusSignalFlags.NONE,
        function(_conn, _sender, _path, _iface, _signal, params)
            -- changed properties dict (index 1) and invalidated array (index 2)
            local changed    = params:get_child_value(1)
            local invalidated = params:get_child_value(2)

            local relevant = changed:lookup_value("State", nil) ~= nil
                          or changed:lookup_value("ConnectedNetwork", nil) ~= nil

            if not relevant then
                for i = 0, invalidated:n_children() - 1 do
                    if invalidated:get_child_value(i).value == "ConnectedNetwork" then
                        relevant = true
                        break
                    end
                end
            end

            if not relevant then return end

            wifi_utils.get_wifi_info_async(function(wifi_data)
                callback(wifi_data and wifi_data.name)
            end, device_name)
        end
    )

    return {
        disconnect = function()
            system_bus:signal_unsubscribe(id)
        end
    }
end

return wifi_utils
