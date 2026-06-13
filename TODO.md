# Fix Tracker

- [x] #1  Shell injection — wallpaper.lua:188,267
- [x] #2  Duplicate root bindings on multi-monitor — wallpaper.lua:262-284
- [x] #3  Typo `tiemout` → `timeout` — local.lua:35 + theme.lua:373
- [x] #4  bat_now/widget globals — battery.lua + theme.lua settings callback
- [x] #5  enable_net missing from local.lua
- [x] #6  os.execute → awful.spawn — rc.lua:181-183
- [x] #7  Pipewire polling → pactl subscribe event-driven — pipewire.lua
- [x] #8  Blocking D-Bus init → async — dbus.lua
- [x] #9  Remove unused bling/ submodule
- [N/A] #10 dbus.get_battery_async — IS called from battery.lua:89 via UPower signal; not dead code
- [x] #11 Remove example/doc code — wifi.lua:52-104
- [x] #12 Remove stray --]] — theme.lua:201
- [x] #13 wlan0 hardcoded → local.lua — theme.lua:394 + local.lua + template
- [x] #14 Weather coords hardcoded → local.lua — theme.lua:129-130 + local.lua + template
- [x] #15 "N/a" typo → "N/A" — pipewire.lua:63
- [x] #16 _current_level/_mute set inside widget loop — pipewire.lua:152-155
