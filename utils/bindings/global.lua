local module = {}
local template = require "ext.template"
local wm = require "utils.wm"
local grid = require "ext.grid"
local smartLaunchOrFocus = require("ext.application").smartLaunchOrFocus
local system = require "ext.system"
local window = require "ext.window"
<<<<<<< HEAD
-- local cache = {}
=======
local cache = {}
>>>>>>> 74b3eecda18dfe7b71b1f9819a3919ad06372096

-- local toggleCaffeine = require('utils.controlplane.caffeine').toggleCaffeine
-- local toggleVPN      = require('utils.controlplane.persistvpn').toggleVPN

module.start = function(config)
   hs.application.enableSpotlightForNameSearches(true)
   -- ultra bindings
   local ultra = { "ctrl", "alt", "cmd" }

   -- ctrl + tab as alternative to cmd + tab
   hs.hotkey.bind({ "ctrl" }, "tab", window.windowHints)

   -- force paste (sometimes cmd + v is blocked)
   --[[ hs.hotkey.bind({ "cmd", "alt", "shift" }, "v", function()
      hs.eventtap.keyStrokes(hs.pasteboard.getContents())
   end) ]]

   local airpods = function()
      hs.osascript.applescript(template(
         [[
         use framework "IOBluetooth"
         use scripting additions

         set AirPodsName to "{AIRPODS}"

         on getFirstMatchingDevice(deviceName)
            repeat with device in (current application's IOBluetoothDevice's pairedDevices() as list)
               if (device's nameOrAddress as string) contains deviceName then return device
            end repeat
         end getFirstMatchingDevice

         on toggleDevice(device)
            if not (device's isConnected as boolean) then
               device's openConnection()
               return "Connecting " & (device's nameOrAddress as string)
            else
               device's closeConnection()
               return "Disconnecting " & (device's nameOrAddress as string)
            end if
         end toggleDevice

         return toggleDevice(getFirstMatchingDevice(AirPodsName))
      ]],
         { AIRPODS = S_HS_CONFIG.airpods }
      ))
      hs.audiodevice.watcher.setCallback(function(event)
         if event == "dev#" then
            -- print(hs.inspect(event))
            -- print(hs.inspect(hs.audiodevice.allDevices()))
            local dev = hs.audiodevice.findDeviceByName(S_HS_CONFIG.airpods)
            if dev ~= nil then
               dev:setDefaultEffectDevice()
               dev:setDefaultInputDevice()
               dev:setDefaultOutputDevice()
            end
            hs.audiodevice.watcher.stop()
            hs.audiodevice.watcher.setCallback(nil)
         end
      end)
<<<<<<< HEAD
      if not hs.audiodevice.watcher.isRunning() then
         hs.audiodevice.watcher.start()
      end
=======
      hs.audiodevice.watcher.start()
>>>>>>> 74b3eecda18dfe7b71b1f9819a3919ad06372096
   end
   -- toggles
   hs.fnutils.each({
      { key = "/", fn = system.toggleConsole },
      { key = "b", fn = system.toggleBluetooth },
      -- { key = "d", fn = system.toggleDND },
      {
         key = "d",
         fn = function()
            hs.execute "killall Dock"
         end,
      },
      { key = "a", fn = airpods },
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

module.stop = function()
   hs.audiodevice.watcher.stop()
end

return module
