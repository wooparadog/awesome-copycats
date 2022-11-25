-- Quick launchbar widget for Awesome WM
-- http://awesome.naquadah.org/wiki/Quick_launch_bar_widget/3.5
-- Put into your awesome/ folder and add the following to rc.lua:
--   local launchbar = require('launchbar')
--   local mylb = launchbar("/path/to/directory/with/shortcuts/")
-- Then add mylb to the wibox.

local layout = require("wibox.layout")
local util = require("awful.util")
local launcher = require("awful.widget.launcher")
local icon_theme = require("menubar.icon_theme")
local gears = require("gears")

local launchbar = {}

function split(str)
  local array = {}
  for mem in string.gmatch(str, "([^ ]+)") do
    table.insert(array, mem)
  end
  return array
end

local function getValue(t, key)
  local _, _, res = string.find(t, key .. " *= *([^%c]+)%c")
  return res
end

local function find_icon(icon_name)
  return icon_theme():find_icon_path(icon_name, 16)
end

function launchbar.new(args)
  local filedir = args.filedir
  if not filedir then
    error("Launchbar: filedir was not specified")
  end

  local spacing = args.spacing or 5


  local items = {}
  local widget = layout.fixed.horizontal()
  widget.spacing = spacing
  local files = io.popen("ls " .. filedir .. "*.desktop")
  for f in files:lines() do
    local ft = io.open(f)
    if ft then
      local t = ft:read("*all")
      local exec = getValue(t,"Exec")
      table.insert(items, { image = find_icon(getValue(t,"Icon")),
      command = exec,
      position = tonumber(getValue(t,"Position")) or 255 })
    else
      gears.debug.print_error("Failed to open " .. f)
    end
  end
  table.sort(items, function(a,b) return a.position < b.position end)
  for _, v in ipairs(items) do
    if v.image then
      widget:add(launcher(v))
    end
  end
  return widget
end

return setmetatable(launchbar, { __call = function(_, ...) return launchbar.new(...) end })
