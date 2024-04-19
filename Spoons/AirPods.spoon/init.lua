--- === AirPods ===

local obj = {}
-- Metadata
obj.name = "AirPods"
obj.version = "1.0"
obj.author = "sohunjug <sohunjug@gmail.com>"
obj.homepage = "https://github.com/sohunjug/AirPods.Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.mac = "mac"
obj.check = false
obj.cmd = "/opt/homebrew/bin/blueutil"

local logger = hs.logger.new "AirPods"
obj.logger = logger

local _store = {}
setmetatable(obj, {
  __index = function(_, k)
    return _store[k]
  end,
  __newindex = function(t, k, v)
    rawset(_store, k, v)
    if t._init_done then
      if t._attribs[k] then
        t:init()
      end
    end
  end,
})
obj.__index = obj

function obj:bindHotKeys(mapping)
  local spec = {
    active = hs.fnutils.partial(self.active, self),
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
  return self
end

local function _execute(args, callback)
  hs.task.new(obj.cmd, callback, function() end, args):start()
end

function obj:_checkCallback(exitCode, _, _)
  if exitCode == 1 then
    self:_handleDevice()
  else
    _execute({ "--connect", self.mac }, hs.fnutils.partial(self._handleDevice, self))
  end
end

--- AirPods:setAutoConnect(uuid)
--- Method
--- auto connect to a device
---
--- Parameters:
---  * uuid - A string containing the UUID of a device
---
--- Returns:
---  * A boolean, true if the device was added, otherwise false
function obj:setAutoConnect(uuid, auto)
  self.check = auto
  self.mac = uuid
end

function obj:_checkConnected()
  self.logger.i "Checking if connected"
  if self.check then
    _execute({ "--is-connected", obj.mac }, hs.fnutils.partial(self._checkCallback, self))
    return false
  end
  return true
end

function obj:_handleDevice()
  self.logger.i("Connected to " .. self.mac)
  print("Connected to " .. self.mac)
  local device = hs.audiodevice.findDeviceByUID(string.upper(self.mac) .. ":input")
  if device ~= nil then
    device:setDefaultInputDevice()
  end
  device = hs.audiodevice.findDeviceByUID(string.upper(self.mac) .. ":output")
  if device ~= nil then
    device:setDefaultOutputDevice()
  end
end

function obj:active()
  if self:_checkConnected() then
    self:_handleDevice()
  end
end

return obj
