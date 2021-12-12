local module = {}
local wm = require "utils.wm"
local grid = require "ext.grid"
local smartLaunchOrFocus = require("ext.application").smartLaunchOrFocus
local system = require "ext.system"
local window = require "ext.window"

local airpods = require "widget.airpods"

-- local log = hs.logger.new("global", "debug")
-- local cache = {}

-- local toggleCaffeine = require('utils.controlplane.caffeine').toggleCaffeine
-- local toggleVPN      = require('utils.controlplane.persistvpn').toggleVPN

--[[ dodgerblue = hs.drawing.color.x11.dodgerblue
darkblue = { red = 24 / 255, blue = 195 / 255, green = 145 / 255, alpha = 1 }

local function showavailableHotkey()
   if not hotkeytext then
      local hotkey_list = hs.hotkey.getHotkeys()
      local mainScreen = hs.screen.mainScreen()
      local mainRes = mainScreen:fullFrame()
      local localMainRes = mainScreen:absoluteToLocal(mainRes)
      local hkbgrect = hs.geometry.rect(
         mainScreen:localToAbsolute(
            localMainRes.w / 5,
            localMainRes.h / 5,
            localMainRes.w / 5 * 3,
            localMainRes.h / 5 * 3
         )
      )
      local hotkeybg = hs.drawing.rectangle(hkbgrect)
      -- hotkeybg:setStroke(false)
      if not hotkey_tips_bg then
         hotkey_tips_bg = "dark"
      end
      if hotkey_tips_bg == "light" then
         hotkeybg:setFillColor { red = 238 / 255, blue = 238 / 255, green = 238 / 255, alpha = 0.95 }
      elseif hotkey_tips_bg == "dark" then
         hotkeybg:setFillColor { alpha = 1, blue = 0.663, green = 0.663, red = 0.663 }
      end
      hotkeybg:setRoundedRectRadii(10, 10)
      hotkeybg:setLevel(hs.drawing.windowLevels.modalPanel)
      hotkeybg:behavior(hs.drawing.windowBehaviors.stationary)
      local hktextrect = hs.geometry.rect(hkbgrect.x + 40, hkbgrect.y + 30, hkbgrect.w - 80, hkbgrect.h - 60)
      hotkeytext = hs.drawing.text(hktextrect, "")
      hotkeytext:setLevel(hs.drawing.windowLevels.modalPanel)
      hotkeytext:behavior(hs.drawing.windowBehaviors.stationary)
      hotkeytext:setClickCallback(nil, function()
         hotkeytext:delete()
         hotkeytext = nil
         hotkeybg:delete()
         hotkeybg = nil
      end)
      hotkey_filtered = {}
      for i = 1, #hotkey_list do
         -- if hotkey_list[i].idx ~= hotkey_list[i].msg then
         table.insert(hotkey_filtered, hotkey_list[i])
         -- end
      end
      local availablelen = 70
      local hkstr = ""
      for i = 2, #hotkey_filtered, 2 do
         local tmpstr = hotkey_filtered[i - 1].msg .. hotkey_filtered[i].msg
         if string.len(tmpstr) <= availablelen then
            local tofilllen = availablelen - string.len(hotkey_filtered[i - 1].msg)
            hkstr = hkstr
               .. hotkey_filtered[i - 1].msg
               .. string.format("%" .. tofilllen .. "s", hotkey_filtered[i].msg)
               .. "\n"
         else
            hkstr = hkstr .. hotkey_filtered[i - 1].msg .. "\n" .. hotkey_filtered[i].msg .. "\n"
         end
      end
      if math.fmod(#hotkey_filtered, 2) == 1 then
         hkstr = hkstr .. hotkey_filtered[#hotkey_filtered].msg
      end
      local hkstr_styled = hs.styledtext.new(hkstr, {
         font = { name = "Courier-Bold", size = 16 },
         color = dodgerblue,
         paragraphStyle = { lineSpacing = 12.0, lineBreak = "truncateMiddle" },
         shadow = { offset = { h = 0, w = 0 }, blurRadius = 0.5, color = darkblue },
      })
      hotkeytext:setStyledText(hkstr_styled)
      hotkeybg:show()
      hotkeytext:show()
   else
      hotkeytext:delete()
      hotkeytext = nil
      hotkeybg:delete()
      hotkeybg = nil
   end
end ]]

module.start = function(config)
   -- hs.application.enableSpotlightForNameSearches(true)
   -- ultra bindings
   local ultra = { "ctrl", "alt", "cmd" }

   -- ctrl + tab as alternative to cmd + tab
   hs.hotkey.bind({ "ctrl" }, "tab", window.windowHints)

   -- force paste (sometimes cmd + v is blocked)
   --[[ hs.hotkey.bind({ "cmd", "alt", "shift" }, "v", function()
      hs.eventtap.keyStrokes(hs.pasteboard.getContents())
   end) ]]

   -- toggles
   hs.fnutils.each({
      { key = "/", fn = system.toggleConsole },
      { key = "b", fn = system.toggleBluetooth },
      { key = "d", fn = hs.fnutils.partial(hs.execute, "killall Dock") },
      { key = "a", fn = hs.fnutils.partial(airpods.connect, S_HS_CONFIG.airpods) },
      { key = "g", fn = grid.toggleGrid },
      { key = "c", fn = wm.cycleLayout },
      { key = "-", fn = hs.fnutils.partial(wm.cache.hhtwm.resizeLayout, "thinner") },
      { key = "=", fn = hs.fnutils.partial(wm.cache.hhtwm.resizeLayout, "wider") },
      { key = "x", fn = hs.fnutils.partial(wm.switcherLayout, "main-left") },
      { key = ";", fn = hs.fnutils.partial(wm.switcherLayout, "gp-vertical") },
      { key = "l", fn = hs.fnutils.partial(wm.switcherLayout, "main-work") },
      { key = "f", fn = hs.fnutils.partial(wm.switcherLayout, "floating") },
      { key = "h", fn = hs.fnutils.partial(wm.switcherLayout, "tabbed-left") },
      { key = "k", fn = hs.fnutils.partial(wm.switcherLayout, "half-left") },
      { key = "j", fn = hs.fnutils.partial(wm.switcherLayout, "monocle") },
      { key = "q", fn = system.displaySleep },
      { key = "r", fn = system.reloadHS },
      { key = "t", fn = system.toggleTheme },
      { key = "w", fn = system.toggleWiFi },
   }, function(object)
      hs.hotkey.bind(ultra, object.key, object.fn)
   end)

   -- apps
   hs.fnutils.each({
      { key = "return", apps = config.apps.terms },
      { key = "\\", apps = config.apps.nvim },
      { key = "space", apps = config.apps.browsers },
      { key = ",", apps = { "System Preferences" } },
   }, function(object)
      hs.hotkey.bind(ultra, object.key, function()
         smartLaunchOrFocus(object.apps)
      end)
   end)

   --[[ local showhotkey_keys = { { "cmd", "shift", "ctrl" }, "space" }
   if string.len(showhotkey_keys[2]) > 0 then
      hs.hotkey.bind(showhotkey_keys[1], showhotkey_keys[2], "Toggle Hotkeys Cheatsheet", function()
         showavailableHotkey()
      end)
   end ]]
end

module.stop = function()
   hs.audiodevice.watcher.stop()
end

return module
