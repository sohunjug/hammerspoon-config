local module = {}
local wm = require "utils.wm"
local grid = require "ext.grid"
local smartLaunchOrFocus = require("ext.application").smartLaunchOrFocus
local system = require "ext.system"
local window = require "ext.window"

-- local toggleCaffeine = require('utils.controlplane.caffeine').toggleCaffeine
-- local toggleVPN      = require('utils.controlplane.persistvpn').toggleVPN

module.start = function(config)
   hs.application.enableSpotlightForNameSearches(true)
   -- ultra bindings
   local ultra = { "ctrl", "alt", "cmd" }

   -- ctrl + tab as alternative to cmd + tab
   hs.hotkey.bind({ "ctrl" }, "tab", window.windowHints)

   -- force paste (sometimes cmd + v is blocked)
   hs.hotkey.bind({ "cmd", "alt", "shift" }, "v", function()
      hs.eventtap.keyStrokes(hs.pasteboard.getContents())
   end)

   -- toggles
   hs.fnutils.each({
      { key = "/", fn = system.toggleConsole },
      { key = "b", fn = system.toggleBluetooth },
      { key = "d", fn = system.toggleDND },
      { key = "g", fn = grid.toggleGrid },
      { key = "c", fn = wm.cycleLayout },
      { key = "-", fn = hs.fnutils.partial(wm.cache.hhtwm.resizeLayout, "thinner") },
      { key = "=", fn = hs.fnutils.partial(wm.cache.hhtwm.resizeLayout, "wider") },
      { key = "x", fn = hs.fnutils.partial(wm.switcherLayout, "main-left") },
      { key = ";", fn = hs.fnutils.partial(wm.switcherLayout, "main-left") },
      { key = "l", fn = hs.fnutils.partial(wm.switcherLayout, "main-work") },
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
end

module.stop = function() end

return module
