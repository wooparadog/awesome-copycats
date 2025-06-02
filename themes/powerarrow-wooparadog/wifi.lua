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

-- Example Usage:

-- 1. Define your callback function
-- local function handle_wifi_data(wifi_data)
--     if wifi_data and wifi_data.name then
--         if wifi_data.name == "wifi_2" then
--             print("Asynchronously connected to: wifi_2")
--             -- Update your widget: my_widget:set_text("On wifi_2")
--         else
--             print("Asynchronously connected to: " .. wifi_data.name)
--             -- Update your widget: my_widget:set_text("WiFi: " .. wifi_data.name)
--         end
--     elseif wifi_data then -- wifi_data exists but wifi_data.name is nil or empty
--         print("Asynchronously Wi-Fi disconnected or SSID not found.")
--         -- Update your widget: my_widget:set_text("No Wi-Fi")
--     else
--         -- This case should ideally not happen if the callback is always called with a table
--         print("Asynchronously failed to get Wi-Fi data.")
--     end
-- end

-- 2. Call the function with your callback
-- get_wifi_info_async(handle_wifi_data) -- Uses default "wlan0"
-- Or specify the device:
-- get_wifi_info_async(handle_wifi_data, "wlan1")


-- Example for a widget that updates periodically:
-- local my_wifi_widget = wibox.widget.textbox("Checking WiFi...")
--
-- local function update_my_widget()
--     get_wifi_info_async(function(wifi_data)
--         if wifi_data and wifi_data.name then
--             if wifi_data.name == "wifi_2" then
--                 my_wifi_widget:set_text("󰖩 wifi_2") -- Example Nerd Font icon
--             else
--                 my_wifi_widget:set_text("󰖩 " .. wifi_data.name)
--             end
--         else
--             my_wifi_widget:set_text("󰖪 Disconnected")
--         end
--     end, "wlan0") -- Specify your device name
-- end
--
-- -- Initial update
-- update_my_widget()
--
-- -- Timer to update periodically
-- local wifi_update_timer = gears.timer {
--    timeout   = 20, -- Check every 20 seconds
--    autostart = true,
--    callback  = update_my_widget
-- }
