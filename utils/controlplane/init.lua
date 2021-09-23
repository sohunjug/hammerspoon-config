local cache = {}
local module = { cache = cache }

module.start = function(config)
   hs.fnutils.each(config.enabled, function(controlName)
      cache[controlName] = require("utils.controlplane." .. controlName)
      cache[controlName]:start(config[controlName])
   end)
end

module.stop = function()
   hs.fnutils.each(cache, function(control)
      control:stop()
   end)
end

return module
