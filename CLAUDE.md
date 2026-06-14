# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a customized AwesomeWM configuration based on the "awesome-copycats" themes collection. It's a window manager setup for Linux using Lua configuration files.

## Architecture

### Main Configuration Files
- `rc.lua` - Main configuration file that defines layouts, keybindings, rules, and autostart processes
- `local.lua` - Local configuration settings (screen DPI, battery paths, wallpaper settings)  
- `local.lua.template` - Template for creating local configuration

### Theme System
- `themes/powerarrow-wooparadog/` - Current active theme directory
- `theme.lua` - Main theme file defining colors, fonts, icons, and wibar configuration
- Theme includes custom modules: `launchbar.lua`, `pipewire.lua`, `wifi.lua`, `wallpaper.lua`

### External Libraries (git submodules, root level)
- `freedesktop/` - Freedesktop.org compliant menu system

**Never modify files inside these directories.** If different behavior is needed, wrap or override from within the theme or `lib/`.

### Vendored Libraries (`lib/lain/`)
The lain library is vendored into `lib/lain/` (not a submodule). Only the modules actually used are present: `helpers`, `util/markup`, `util/separators`, `util/quake`, `util/dkjson`, `widget/cal`, `widget/weather`, `widget/mem`, `widget/cpu`, `widget/temp`, `widget/net`. All internal `require("lain.*")` paths were rewritten to `require("lib.lain.*")`. Require it as `lib.lain`.

### Reusable Widgets (`lib/`)
Generic widgets and utilities owned by this repo, usable across themes. Required via `lib.X`.

- `lib/revelation.lua` - Window switcher/overview (vendored)
- `lib/dbus.lua` - D-Bus singleton (system bus access, UPower, AccountsService)
- `lib/battery.lua` - UPower-backed battery widget factory
- `lib/wifi.lua` - iwd/iwctl WiFi info and D-Bus signal widget
- `lib/wallpaper.lua` - Wallpaper rotation/switching engine
- `lib/pipewire.lua` - PipeWire/PulseAudio volume bar widget factory
- `lib/binclock.lua` - Binary clock widget
- `lib/launchbar.lua` - Quick-launch bar widget

### Internal Notification Convention
All `naughty.notify` calls that originate from within this config (battery alerts, wallpaper change, wifi change, startup errors, etc.) **must** include `app_name = "awesome"`. This marker is checked in `themes/powerarrow-wooparadog/notifications.lua`'s `request::display` handler and causes:
- The dunst-like custom layout but with **no size constraints**, so content (battery/wifi/wallpaper text) is never clipped. External app notifications instead get the constrained layout (fixed width, max height) plus a bold app-name header.
- Fallback icon `icons/notif/awesome-wm.png` when the notification supplies none (wifi, etc. bring their own and keep them); external apps fall back to the urgency bell icon.
- An optional `on_click` arg is wired to left-click. It **must** be read from `n._private.on_click` — custom args passed to `naughty.notify` are stored in `_private`, not as real notification properties, so `n.on_click` always reads back `nil`. Used by the wallpaper notification to open the image.

**Exception — lain widget popups:** the calendar and weather popups tag their `notification_preset` with `is_widget_popup = true` (in `theme.lua`, along with a slightly larger font). The handler detects `n.preset.is_widget_popup` and renders them with a **refined content-sized layout** (roomy padding, a gap between the weather icon and the text), distinct from the alert template. Its outer `wibox.container.constraint` uses `strategy = "max"` (not `"exact"`) so the popup grows to fit its content — using `"exact"`, or routing them through the alert template, pins them to the fixed notification width because naughty force-sets `beautiful.notification_max_width` onto the outermost `set_width`-capable widget.

External D-Bus notifications (from apps) must **not** set `app_name = "awesome"`.

### D-Bus Convention
All D-Bus interaction goes through the singleton in `themes/powerarrow-wooparadog/dbus.lua`.
Never call `Gio.bus_get_sync` or hold a raw `Gio.DBusConnection` directly in other modules.
The singleton exposes:
- `dbus.system` — the raw `Gio.DBusConnection` (system bus) for advanced use
- `dbus.subscribe_signal(sender, interface, signal, path, arg0, callback)` — subscribe to a system bus signal; returns an id
- `dbus.unsubscribe_signal(id)` — cancel a subscription
- `dbus.get_battery_async(battery, callback)` — fetch UPower battery properties
- `dbus.parse_battery_props(dict)` — parse a UPower `a{sv}` variant into a Lua table
- `dbus.refresh_user_wallpaper(path)` — persist wallpaper path via AccountsService

### Key Components
- **Layouts**: Uses standard awesome layouts (`awful.layout.suit.*`)
- **Tags**: 6 predefined tags: Firefox, Terminal, Files, IM, Steam, Spotify with specific layouts per tag
- **Autostart**: Uses `dex` to handle XDG autostart applications
- **Terminal**: Uses custom `terminal.sh` script
- **Application Rules**: Specific window rules for Firefox, Steam, Spotify, floating dialogs

## Configuration Customization

### Switching Themes
Change `chosen_theme` variable in `rc.lua:63` and restart AwesomeWM (Mod4+Ctrl+R).

### Local Settings
Copy `local.lua.template` to `local.lua` and modify settings like:
- Screen DPI settings
- Battery and AC adapter paths
- CPU temperature sensor path  
- Wallpaper directories and rotation settings

### Key Bindings
- Modkey is Super/Windows key (Mod4)
- Terminal: Mod4+Return
- Browser: Mod4+q  
- File manager: Mod4+e
- Launcher: Mod4+r (uses rofi)
- Window switcher: Mod4+Tab (uses revelation)

## Development Workflow

### Testing Configuration Changes
After making changes to configuration files:
1. Check syntax: `awesome -k` (tests configuration without applying)
2. Restart AwesomeWM: Mod4+Ctrl+R or `awesome-client "awesome.restart()"`

### Debugging
- AwesomeWM logs errors to stdout/stderr when started from terminal
- Use `awesome.connect_signal("debug::error", function)` in rc.lua for custom error handling
- Lua prompt available via Mod4+x for runtime debugging

## File Structure Notes
- Main config files are in the root directory
- Themes are modular - each theme has its own directory with complete styling
- External libraries are included as subdirectories (lain/, bling/, etc.)
- Icons and images are stored within theme directories