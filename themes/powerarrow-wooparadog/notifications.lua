-- Notification styling for AwesomeWM's naughty, reproducing the previous dunst
-- setup (Catppuccin Mocha). Required and called from theme.lua with the theme
-- table, so it can set the beautiful notification_* variables and read
-- theme.dir / theme.font.

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")
local menubar_utils = require("menubar.utils")
local dpi = require("beautiful.xresources").apply_dpi

return function(theme)
  theme.notification_bg = "#1e1e2e"
  theme.notification_fg = "#cdd6f4"
  theme.notification_border_color = "#b4befe"
  theme.notification_border_width = 1
  theme.notification_margin = 14
  theme.notification_spacing = 5
  theme.notification_icon_size = 64
  theme.notification_max_width = 520 -- fixed popup width (see request::display)
  theme.notification_max_height = 160 -- popup grows with content up to this cap
  theme.notification_opacity = 1
  -- A touch larger than the wibar font, sized in DPI-scaled pixels so it
  -- tracks the screen DPI (the "px" suffix stops Pango double-scaling).
  theme.notification_font = "Terminus " .. dpi(16) .. "px"
  -- dunst: corner_radius = 5, corners = top-left,bottom (top-right left square).
  theme.notification_shape = function(cr, w, h)
    gears.shape.partially_rounded_rect(cr, w, h, true, false, true, true, 5)
  end

  naughty.config.defaults.position = "top_right"
  naughty.config.defaults.timeout = 10

  -- Per-urgency frame and text color, mirroring the old dunstrc. Presets are
  -- fallbacks only (an explicit value always wins). The stock `critical` preset
  -- is white-on-red, so it is recolored to the dark dunst box.
  -- NB: mutate the preset tables in place. naughty.config.mapping (which selects
  -- the preset for incoming DBus notifications) holds references to these exact
  -- tables, so reassigning the keys would not be seen by new notifications.
  local function style_urgency(preset, color, timeout)
    preset.bg = theme.notification_bg
    preset.fg = color
    preset.border_color = color
    if timeout ~= nil then
      preset.timeout = timeout
    end
  end
  style_urgency(naughty.config.presets.low, "#a6e3a1")
  style_urgency(naughty.config.presets.normal, "#74c7ec")
  style_urgency(naughty.config.presets.critical, "#f38ba8", 0)

  -- Fallback bell icon per urgency, applied in request::display only when the
  -- app provides no icon. It can't live in the preset: preset.icon is crushed
  -- into the notification and would shadow a real app icon (Spotify art, etc.).
  local fallback_icon = {
    low = theme.dir .. "/icons/notif/bell-badge-low.png",
    normal = theme.dir .. "/icons/notif/bell-badge.png",
    critical = theme.dir .. "/icons/notif/alert-decagram.png",
  }

  -- Render notifications with a dunst-like layout. Per-urgency colors and the
  -- fallback icon come from the presets above; internal awesome notifications
  -- (calendar, weather, battery, wallpaper, etc.) mark themselves
  -- app_name="awesome", get the AwesomeWM logo when they carry no icon, and
  -- bypass the fixed size constraints so their content is never clipped.
  local awesome_icon = theme.dir .. "/icons/notif/awesome-wm.png"

  -- App-icon fallback for external notifications that ship no icon of their
  -- own: resolve one from the user's freedesktop icon theme (theme.icon_theme,
  -- configured in local.lua), then fall back to hicolor, before the urgency bell.
  --
  -- menubar.utils.lookup_icon_uncached already does proper freedesktop lookup —
  -- honouring beautiful.icon_theme with a hicolor fallback, across all icon base
  -- dirs and png/svg — and returns false on a miss. But it only understands the
  -- <size>/apps layout (hicolor, Adwaita, Papirus). Breeze (KDE) themes use the
  -- reversed apps/<size> layout (plain pixel sizes, SVG), which it silently
  -- misses, so we probe the configured theme in that layout first.
  local icon_theme = theme.icon_theme

  local icon_base_dirs = {
    os.getenv("HOME") .. "/.icons",
    os.getenv("HOME") .. "/.local/share/icons",
    "/usr/local/share/icons",
    "/usr/share/icons",
  }
  -- Breeze icons are SVG (scalable), but a given icon may exist at only one
  -- size dir (e.g. only apps/48), so probe every size Breeze actually ships
  -- plus larger ones other reversed-layout themes use. Largest first.
  local breeze_sizes = {
    "512", "256", "128", "96", "64", "48", "32",
    "24", "24@2x", "24@3x", "22", "22@2x", "22@3x", "16", "16@2x", "16@3x",
  }
  local icon_exts = { "svg", "png" }

  -- Probe the reversed apps/<size> layout (Breeze) for `name` in `theme_name`.
  -- Returns a path or nil; a no-op for standard themes (they lack apps/<size>).
  local function lookup_reversed_layout(theme_name, name)
    for _, base in ipairs(icon_base_dirs) do
      for _, size in ipairs(breeze_sizes) do
        for _, ext in ipairs(icon_exts) do
          local path = base .. "/" .. theme_name .. "/apps/" .. size .. "/" .. name .. "." .. ext
          if gears.filesystem.file_readable(path) then
            return path
          end
        end
      end
    end
    return nil
  end

  -- Resolved icons are memoized by app_name so the filesystem probing below
  -- runs at most once per app per session. Misses are cached as `false` (vs
  -- `nil` = "not looked up yet") so unresolved apps don't re-probe every time.
  local app_icon_cache = {}

  -- Resolve an installed application icon by app name. Notification app_name
  -- values vary in case/spacing (e.g. "Firefox", "Telegram Desktop"), so probe
  -- a few normalized candidates. For each, the configured theme wins (including
  -- Breeze's reversed layout), then the standard lookup which ends at hicolor.
  -- Returns a path or nil.
  local function find_app_icon(app_name)
    local cached = app_icon_cache[app_name]
    if cached ~= nil then
      return cached or nil
    end

    local seen, candidates = {}, {}
    local function add(name)
      if name and name ~= "" and not seen[name] then
        seen[name] = true
        candidates[#candidates + 1] = name
      end
    end
    add(app_name)
    add(app_name:lower())
    add(app_name:lower():gsub("%s+", "-"))
    add(app_name:lower():gsub("%s+", ""))

    local result = nil
    for _, name in ipairs(candidates) do
      if icon_theme then
        result = lookup_reversed_layout(icon_theme, name)
      end
      if not result then
        -- Standard <size>/apps lookup: configured theme (via beautiful.icon_theme)
        -- first, hicolor last; returns false on a miss (normalized to nil here).
        result = menubar_utils.lookup_icon_uncached(name) or nil
      end
      if result then
        break
      end
    end

    app_icon_cache[app_name] = result or false
    return result
  end

  naughty.connect_signal("request::display", function(n)
    -- Calendar/weather are interactive lain widget popups (tagged in their
    -- notification_preset). They get a refined, content-sized layout rather
    -- than the custom alert template below: roomy padding and, when there's an
    -- icon (weather), a clear gap between it and the text. The outer
    -- constraint uses strategy "max" (like naughty's default) so the popup
    -- grows to fit its content instead of being pinned to the alert width.
    -- `type` tags the popup window so the compositor (picom) can target it.
    if n.preset and n.preset.is_widget_popup then
      -- Allow these popups to grow wider than the alert max so the weather
      -- forecast lines don't word-wrap (the longest OpenWeatherMap
      -- descriptions reach ~820px); strategy "max" below still shrinks the
      -- narrower calendar to its content.
      n.max_width = dpi(560)

      local text = {
        naughty.widget.title,
        naughty.widget.message,
        spacing = dpi(4),
        layout = wibox.layout.fixed.vertical,
      }

      -- No icon → just the text; with an icon → icon and text side by side
      -- with a gap between them. The icon is wrapped in a centered `place`
      -- so it sits vertically centered against the (taller) text block
      -- instead of floating at the top. `place` reports the child's natural
      -- width here, so it doesn't stretch the popup.
      local body = text
      if n.icon then
        -- Enlarge the widget-popup icon (calendar/weather) past the
        -- default beautiful.notification_icon_size.
        n.icon_size = dpi(64)
        body = {
          {
            naughty.widget.icon,
            valign = "center",
            widget = wibox.container.place,
          },
          text,
          spacing = dpi(28),
          layout = wibox.layout.fixed.horizontal,
        }
      end

      naughty.layout.box({
        notification = n,
        type = "notification",
        widget_template = {
          {
            {
              body,
              margins = dpi(16),
              widget = wibox.container.margin,
            },
            id = "background_role",
            widget = naughty.container.background,
          },
          strategy = "max",
          widget = wibox.container.constraint,
        },
      })
      return
    end

    local is_internal = n.app_name == "awesome"
    local has_app = not is_internal and n.app_name ~= nil and n.app_name ~= ""

    -- Custom args (on_click) live in n._private, not as a real property, so
    -- n.on_click would always read back nil — read the private slot directly.
    local on_click = n._private.on_click

    if is_internal then
      -- Use the AwesomeWM logo when the notification doesn't supply its own icon
      -- (wifi etc. bring their own; battery/wallpaper alerts don't).
      if not n.icon then
        n.icon = awesome_icon
      end
    elseif has_app and not n.icon then
      -- App notifications without their own icon: first try to match an
      -- installed application icon by name in the freedesktop theme, then fall
      -- back to the urgency bell like dunst.
      n.icon = find_app_icon(n.app_name) or fallback_icon[n.urgency] or fallback_icon.normal
    end

    local text_column = {
      naughty.widget.title,
      naughty.widget.message,
      spacing = 4,
      layout = wibox.layout.fixed.vertical,
    }

    -- dunst format "<b>󰁕 %a</b>\n%s\n<i>%b</i>": bold app-name header line.
    if has_app then
      table.insert(text_column, 1, {
        markup = "<b><span foreground='" .. (n.fg or theme.notification_fg) .. "'>󰁕 " .. gears.string.xml_escape(
          n.app_name
        ) .. "</span></b>",
        font = theme.notification_font,
        widget = wibox.widget.textbox,
      })
    end

    -- If the notification carries an on_click callback, wire it onto the
    -- background_role container (which covers the full notification area) so
    -- a left-click anywhere dismisses the notification and fires the callback.
    local click_buttons = on_click
        and gears.table.join(awful.button({}, 1, function()
          on_click()
          n:destroy()
        end))
      or nil

    naughty.layout.box({
      notification = n,
      -- Tag the popup as a notification window so the compositor can target
      -- it (e.g. picom's inactive-opacity rule must skip window_type
      -- 'notification', otherwise it dims unfocused popups to 0.8).
      type = "notification",
      widget_template = {
        {
          {
            {
              naughty.widget.icon,
              {
                -- Center the text against the (taller) icon and
                -- let it fill the remaining width.
                text_column,
                valign = "center",
                content_fill_horizontal = true,
                widget = wibox.container.place,
              },
              fill_space = true,
              spacing = 14,
              layout = wibox.layout.fixed.horizontal,
            },
            margins = theme.notification_margin,
            widget = wibox.container.margin,
          },
          buttons = click_buttons,
          id = "background_role",
          widget = naughty.container.background,
        },
        -- Cap the height: the popup shrinks to fit short content and clips
        -- anything taller (it never grows past this). Skipped for internal
        -- alerts (battery/wifi/wallpaper) so their content is never truncated.
        strategy = "max",
        height = not is_internal and theme.notification_max_height or nil,
        widget = wibox.container.constraint,
      },
      -- Fixed width so external notifications line up. Skipped for internals.
      strategy = "exact",
      width = not is_internal and theme.notification_max_width or nil,
      widget = wibox.container.constraint,
    })
  end)
end
