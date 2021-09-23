local cache = {}
local module = { cache = cache }

module.start = function(config)
   hs.fnutils.each(config.enabled, function(watchName)
      cache[watchName] = require("utils.ui." .. watchName)
      cache[watchName]:start(config[watchName])
   end)
end

module.stop = function()
   hs.fnutils.each(cache, function(watcher)
      watcher:stop()
   end)
end

return module
