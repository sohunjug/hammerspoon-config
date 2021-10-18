local template = require "ext.template"
local cache = {}
local M = { cache = cache }

M.connect = function(name)
   local audiodevice = hs.audiodevice.findOutputByName(name)
   if not audiodevice then
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
         { AIRPODS = name }
      ))
      hs.timer.waitUntil(function()
         return hs.audiodevice.findOutputByName(name)
      end, function()
         local audioDevice = hs.audiodevice.findOutputByName(name)
         -- audioDevice:setDefaultEffectDevice()
         audioDevice:setDefaultOutputDevice()
         audioDevice:setDefaultInputDevice()
         audioDevice:setMuted(false)
      end)
   else
      audiodevice:setDefaultOutputDevice()
      audiodevice:setDefaultInputDevice()
      audiodevice:setMuted(false)
   end
end

return M
