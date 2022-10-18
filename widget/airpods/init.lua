-- local template = require "ext.template"
local cache = {}
local M = { cache = cache }

local function Trim(str)
   return string.gsub(str, "[\t\n\r]+", "")
end

local function Execute(cmd)
   local output, status = hs.execute(cmd)
   if not status then
      hs.alert "execute error"
      -- Log("execute error" .. cmd)
   end
   return Trim(output)
end

local function ExecuteBrewCmd(command, params, noExec)
   local execCmd = "/opt/homebrew/bin/" .. command .. " "
   local cmd = "[ -x " .. execCmd .. " ] && " .. execCmd .. params
   if noExec then
      return cmd
   end
   return Execute(cmd)
end

local function ExecBlueutilCmd(params, noExec)
   return ExecuteBrewCmd("blueutil", params, noExec)
end

local function GetDeviceId(id)
   if id == nil then
      local uid = hs.audiodevice.defaultOutputDevice():uid()
      local index = string.find(uid, ":")
      if index ~= nil then
         uid = string.sub(uid, 0, index - 1)
      end
      return uid
   end

   return id .. ":output"
end

local function BlueutilIsConnected(callback)
   local isConnected = "0"
   local id = M.AirPodsId
   isConnected = ExecBlueutilCmd("--is-connected " .. id)
   if callback ~= nil then
      callback(isConnected, id)
   end
   return isConnected
end

local function bluetoothSwitch(state)
   local paramStr = "--power "
   local value = ExecBlueutilCmd(paramStr)
   if value ~= tostring(state) then
      ExecBlueutilCmd(paramStr .. state)
   end
end

local function handleDevice(connect)
   local param = "--connect"
   local value = "1"
   if connect == false then
      param = "--disconnect"
      value = "0"
   end

   return function()
      BlueutilIsConnected(function(isConnected, id)
         if isConnected ~= value then
            -- fix --disconnect add --info params
            -- https://github.com/toy/blueutil/issues/58
            print(param)
            ExecBlueutilCmd(param .. " " .. id .. " --info " .. id)

         -- 连接/断开后发布消息
         -- LoopWait(function ()
         --   -- 直接修改，避免下面的回调多查询一次
         --   isConnected = BlueutilIsConnected()
         --   return isConnected == value
         -- end, function ()
         --   -- 连接返回 true 未连接返回 false
         --   Event:emit(Event.keys[1], isConnected == '1')
         -- end)
         elseif value == "1" then
            -- 查找并设置为默认输入输出设备
            local device = hs.audiodevice.findDeviceByUID(GetDeviceId(string.upper(id)))
            if device ~= nil then
               device:setDefaultInputDevice()
               device:setDefaultOutputDevice()
            else
               -- 断开再重新连接
               DisconnectDevice()
               ConnectDevice()
            end
         end
      end)
   end
end

ConnectDevice = handleDevice(true)
DisconnectDevice = handleDevice(false)

M.connect = function(name)
   M.AirPodsId = name
   ConnectDevice()
end

M.Connect = function(name)
   local audiodevice = hs.audiodevice.findOutputByName(name)
   if not audiodevice then
      --[[
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
      ]]
      --   { AIRPODS = name }
      --))
      hs.timer.delayed
         .new(
            1,
            hs.fnutils.partial(hs.timer.waitUntil, function()
               return hs.audiodevice.findOutputByName(name)
            end, function()
               local audioDevice = hs.audiodevice.findOutputByName(name)
               -- audioDevice:setDefaultEffectDevice()
               audioDevice:setDefaultOutputDevice()
               audioDevice:setDefaultInputDevice()
               audioDevice:setMuted(false)
            end)
         )
         :start()
   else
      audiodevice:setDefaultOutputDevice()
      audiodevice:setDefaultInputDevice()
      audiodevice:setMuted(false)
   end
end

return M
