-- Lua function to get the current Wi-Fi SSID asynchronously
-- and pass it to a callback as a table
-- Replace 'wlan0' with your actual wireless device name if different in the command string.
-- You can also make the device_name a parameter of this function if needed.

local awful = require("awful")

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


return wifi_utils
