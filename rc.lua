---@diagnostic disable-next-line
local awesome, client, screen, root, mousegrabber = awesome, client, screen, root, mousegrabber

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")

awful.screen.set_auto_dpi_enabled(true)

local capi = {mousegrabber = mousegrabber}

local revelation=require("revelation")


-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

-- Autostart
-- This function implements the XDG autostart specification
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment awesome --autostart;' .. -- https://github.com/jceb/dex
    'vicinae server;'
)

-- Variable definitions
local modkey       = "Mod4"
local altkey       = "Mod1"
local ctrlkey      = "Control"
local terminal     = "terminal.sh"
local editor       = "vim"
local browser      = "firefox"
local filemanager  = "nautilus"
local mod_shift = { modkey, "Shift" }

-- Set theme
local chosen_theme = "powerarrow-wooparadog"
beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))

revelation.init()

-- Import bling to update layout icon
local bling = require("bling")

-- Layouts
awful.util.terminal = terminal
awful.layout.layouts = {
    bling.layout.centered,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.max,
    awful.layout.suit.floating,
}

awful.util.tagnames = { "Firefox", "Terminal", "Files", "IM", "Steam", "Spotify" }
awful.layout.taglayouts = {
    bling.layout.centered,
    awful.layout.suit.tile,
    awful.layout.suit.tile,
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile,
}
awful.layout.vertical_taglayouts = {
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.top,
}
awful.util.vertical_tagnames = { "Firefox", "Terminal", "Files", "IM" }

awful.util.taglist_buttons = awful.util.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = awful.util.table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            --c:emit_signal("request::activate", "tasklist", {raise = true})<Paste>

            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function (c) c:kill() end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

-- Menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}

awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or 16,
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})

-- Screen
-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(beautiful.at_screen_connect)

-- Mouse bindings
root.buttons(gears.table.join(
    root.buttons(),
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- {{{ Key bindings
local globalkeys = awful.util.table.join(
  root.keys(),

  -- Hotkeys
  awful.key({ }, "Print", function () awful.util.spawn("flameshot gui") end, {description = "Screenshot", group = "hotkeys"}),
  awful.key({ modkey }, "Next", function () awful.util.spawn("playerctl next") end, {description = "Player Next", group = "hotkeys"}),
  awful.key({ modkey }, "Prior", function () awful.util.spawn("playerctl previous") end, {description = "Player Next", group = "hotkeys"}),
  awful.key({ modkey }, "s", hotkeys_popup.show_help, {description = "show help", group="awesome"}),
  awful.key({ modkey }, "Return", function () awful.spawn(terminal) end, {description = "open a terminal", group = "hotkeys"}),
  awful.key({ modkey }, "q", function () awful.spawn(browser) end, {description = "run browser", group = "hotkeys"}),
  awful.key({ modkey }, "e", function () awful.spawn(filemanager) end, {description = "run file manager", group = "hotkeys"}),

  awful.key({ modkey }, "r", function() awful.spawn("vicinae toggle") end, {description = "Run launcher", group = "hotkeys"}),
  --awful.key({ modkey }, "Tab", function () awful.spawn("rofi -show window -show-icons") end, {description = "switch client", group = "hotkeys"}),

  awful.key({ modkey, }, "z", function () awful.screen.focused().quake:toggle() end, {description = "dropdown application", group = "hotkeys"}),

  -- Hotkeys: ALSA volume control
  awful.key({}, "#123", function () os.execute(string.format("pactl set-sink-volume %s +5%%", beautiful.volume.device)) beautiful.volume.update() end, {description = "volume up", group = "hotkeys"}),
  awful.key({}, "#122", function () os.execute(string.format("pactl set-sink-volume %s -5%%", beautiful.volume.device)) beautiful.volume.update() end, {description = "volume down", group = "hotkeys"}),
  awful.key({}, "#121", function () os.execute(string.format("pactl set-sink-mute %s toggle", beautiful.volume.device)) beautiful.volume.update() end, {description = "toggle mute", group = "hotkeys"}),

  -- Hotkeys: Backlight
  awful.key({}, "XF86MonBrightnessUp", function () os.execute("brightnessctl s +10%") end, {description = "Increase Screen Brightness", group = "hotkeys"}),
  awful.key({}, "XF86MonBrightnessDown", function () os.execute("brightnessctl s 10%-") end, {description = "Decrease Screen Brightness", group = "hotkeys"}),
  awful.key({ ctrlkey, modkey, "Shift" }, "l", function () os.execute("xset s activate") end, {description = "Lock current screen", group = "hotkeys"}),

  -- Hotkeys: Calculator
  awful.key({}, "#148", function () awful.util.spawn('gnome-calculator') end, {description = "Calculator", group = "hotkeys"}),
  -- Hotkeys: Enpass
  awful.key({ ctrlkey, "Shift" }, "\\", function () awful.util.spawn('/opt/enpass/Enpass showassistant') end, {description = "Enpass Quick Access", group = "hotkeys"}),
  -- Hotkeys: Htop
  awful.key({ ctrlkey, "Shift" }, "Escape", function () awful.util.spawn(terminal .. " -e htop") end, {description = "Htop", group = "hotkeys"}),
  -- Client: Focus
  awful.key({ modkey }, "u", awful.client.urgent.jumpto, {description = "jump to urgent client", group = "client: switch"}),

  -- Client: focus by direction
  awful.key({ modkey }, "j", function() awful.client.focus.global_bydirection("down") if client.focus then client.focus:raise() end end, {description = "focus down", group = "client: switch"}),
  awful.key({ modkey }, "k", function() awful.client.focus.global_bydirection("up") if client.focus then client.focus:raise() end end, {description = "focus up", group = "client: switch"}),
  awful.key({ modkey }, "h", function() awful.client.focus.global_bydirection("left") if client.focus then client.focus:raise() end end, {description = "focus left", group = "client: switch"}),
  awful.key({ modkey }, "l", function() awful.client.focus.global_bydirection("right") if client.focus then client.focus:raise() end end, {description = "focus right", group = "client: switch"}),
  awful.key({ modkey }, "Tab", revelation),

  -- Client: layout manipulation
  awful.key(mod_shift, "j", function () awful.client.swap.byidx(  1) end, {description = "swap with next client by index", group = "client: switch"}),
  awful.key(mod_shift, "k", function () awful.client.swap.byidx( -1) end, {description = "swap with previous client by index", group = "client: switch"}),

  -- Client: window manipulation
  awful.key({ modkey, "Control" }, "n",
            function ()
                local c = awful.client.restore()
                -- Focus restored client
                if c then
                    client.focus = c
                    c:raise()
                end
            end,
            {description = "restore minimized", group = "client"}),

  --  Screen: Focus
  awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end, {description = "focus the next screen", group = "screen: switch"}),
  awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end, {description = "focus the previous screen", group = "screen: switch"}),

  -- Tag: browsing
  awful.key({ modkey }, "Escape", awful.tag.history.restore, {description = "go back", group = "tag"}),

  -- Awesome: Show/Hide Wibox
  awful.key({ modkey }, "b", function ()
          for s in screen do
              s.mywibox.visible = not s.mywibox.visible
              if s.mybottomwibox then
                  s.mybottomwibox.visible = not s.mybottomwibox.visible
              end
          end
      end,
      {description = "toggle wibox", group = "awesome"}),

  -- Awesome: basics
  awful.key({ modkey, }, "w", function () awful.util.mymainmenu:show() end, {description = "show main menu", group = "awesome"}),
  awful.key({ modkey, "Control" }, "r", awesome.restart, {description = "reload awesome", group = "awesome"}),
  awful.key({ modkey, "Shift" }, "q", awesome.quit, {description = "quit awesome", group = "awesome"}),

  awful.key({ modkey }, "x",
            function ()
                awful.prompt.run {
                  prompt       = "Run Lua code: ",
                  textbox      = awful.screen.focused().mypromptbox.widget,
                  exe_callback = awful.util.eval,
                  history_path = awful.util.get_cache_dir() .. "/history_eval"
                }
            end,
            {description = "lua execute prompt", group = "awesome"}),

  -- Layout manipulation
  awful.key({ modkey, }, "space", function () awful.layout.inc( 1) end, {description = "select next", group = "layout:switch"}),
  awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(-1) end, {description = "select previous", group = "layout:switch"}),

  awful.key({ modkey, "Control" }, "h", function () awful.tag.incncol( 1, nil, true) end, {description = "increase the number of columns", group = "layout: modify"}),
  awful.key({ modkey, "Control" }, "l", function () awful.tag.incncol(-1, nil, true) end, {description = "decrease the number of columns", group = "layout: modify"}),

  awful.key({ altkey, "Shift" }, "l", function () awful.tag.incmwfact( 0.05) end, {description = "increase master width factor", group = "layout: modify"}),
  awful.key({ altkey, "Shift" }, "h", function () awful.tag.incmwfact(-0.05) end, {description = "decrease master width factor", group = "layout: modify"}),

  awful.key({ modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1, nil, true) end, {description = "increase the number of master clients", group = "layout: modify"}),
  awful.key({ modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1, nil, true) end, {description = "decrease the number of master clients", group = "layout: modify"})
)

local clientkeys = awful.util.table.join(
  awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
  awful.key({ modkey, "Shift" }, "c", function (c) c:kill() end, {description = "close", group = "client"}),

  awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle , {description = "toggle floating", group = "client"}),
  awful.key({ modkey, "Control" }, "Return", function (c)
    local current_master = awful.client.getmaster()
    if current_master then
      c:swap(current_master)
    end
  end, {description = "move to master", group = "client"}),

  awful.key({ modkey, }, "o", function (c) c:move_to_screen() end, {description = "move to screen", group = "client"}),
  awful.key({ modkey, }, "t", function (c) c.ontop = not c.ontop end, {description = "toggle keep on top", group = "client"}),
  awful.key({ modkey, "Shift" }, "t", awful.titlebar.toggle, {description = "toggle titlebar", group = "client"}),
  awful.key({ modkey, }, "y", function (c) c.sticky = not c.sticky end, {description = "toggle sticky on top", group = "client"}),
  awful.key({ modkey, }, "n", function (c) c.minimized = true end , {description = "minimize", group = "client"}),
  awful.key({ modkey, }, "m", function (c) c.maximized = not c.maximized c:raise() end , {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = "view tag #", group = "tag"}
        descr_toggle = {description = "toggle tag #", group = "tag"}
        descr_move = {description = "move focused client to tag #", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #", group = "tag"}
    end
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local tag = awful.screen.focused().tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  descr_view),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local tag = awful.screen.focused().tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  descr_toggle),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  descr_move),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  descr_toggle_focus)
    )
end
root.keys(globalkeys)

-- Client: buttons
local clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end),
    awful.button({ modkey }, 4, function (c)
      c:emit_signal("request::activate", "mouse_click", {raise = true})
      capi.mousegrabber.run(function ()
        c.opacity = c.opacity + 0.1
        return false
      end, 'mouse')
    end, nil),
    awful.button({ modkey }, 5, function (c)
      c:emit_signal("request::activate", "mouse_click", {raise = true})
      capi.mousegrabber.run(function ()
        c.opacity = c.opacity - 0.1
        return false
      end, 'mouse')
    end, nil)
)


awful.rules.rules = {
    { rule = { },
      properties = {
        border_width = beautiful.border_width,
        border_color = beautiful.border_normal,
        focus = awful.client.focus.filter,
        raise = true,
        keys = clientkeys,
        buttons = clientbuttons,
        screen = awful.screen.preferred,
        placement = awful.placement.no_overlap+awful.placement.no_offscreen,
        size_hints_honor = false
      }
    },

    -- Titlebars
    { rule_any = { type = { "dialog", "normal" } },
      properties = { titlebars_enabled = false, placement = awful.placement.next_to_mouse + awful.placement.no_offscreen  } },

    { rule_any = { type = { "dialog" } },
      properties = { floating = true, ontop = true} },

    { rule_any = { class = { "Gnome-screenshot", "Calculator", "Blueman-manager", "1Password"} },
      properties = { ontop = true, floating = true } },

    { rule_any = { class = { "vlc", "Lightdm-gtk-greeter-settings", "gnome-calculator", "Evolution-alarm-notify", "Pavucontrol"} },
      properties = { floating = true } },

    { rule = { modal = true },
      properties = { floating = true }},

    { rule = { class = "Bytedance-feishu" },
      properties = { floating = true }},

     { rule = { class = "Lark" },
       callback = function(c)
         local focused_screen = awful.screen.focused()
         if focused_screen.tags[4] and focused_screen.tags[4].name == "IM" then
           c:move_to_tag(focused_screen.tags[4])
         end
       end },

    { rule = { class = "flameshot" },
      properties = { floating = true }},

    { rule = { class = "wechat" },
      properties = { focus=false }},

    { rule = { class = "com.alibabainc.dingtalk" },
      properties = { focus=false }},

    { rule = { class = "Nextcloud" },
      properties = { floating = true }},

    { rule = { class = "digikam" ,  modal = true },
      properties = { ontop=true}},

    { rule = { class = "digikam" },
      properties = { screen = 1, tag = awful.util.tagnames[3] } },

    { rule = { class = "firefox" },
      properties = { screen = 1, tag = awful.util.tagnames[1] } },

    { rule = { class = "Spotify" },
      properties = { tag = awful.util.tagnames[6] } },

    { rule = { class = "Gimp", role = "gimp-image-window" },
          properties = { maximized = true } },

    { rule = { class = "Gpicview" },
      properties = { floating = true, ontop = true },
      callback = function(c)
        awful.placement.centered(c, nil)
      end},

    { rule = { class = "Steam" },
      properties = { screen = 1, tag = awful.util.tagnames[5] } },

    { rule = { class = "vicinae" },
      properties = { floating = true },
      callback = function(c)
        awful.placement.centered(c, nil)
      end},
}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end

    --if c.size_hints.program_position then
      --c.floating = true
    --end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 2, function() c:kill() end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = 16}) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    -- Skip activation for wechat windows
    if c.class ~= "wechat" then
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
    end

    if c.class ~= "com.alibabainc.dingtalk" then
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
    end
end)

-- No border for maximized clients
local function border_adjust(c)
    if c.maximized then -- no borders if only 1 client visible
        c.border_width = 0
    elseif #awful.screen.focused().clients > 1 then
        c.border_width = beautiful.border_width
        c.border_color = beautiful.border_focus
    end
end

client.connect_signal("property::maximized", border_adjust)
client.connect_signal("focus", border_adjust)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
