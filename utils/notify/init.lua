local cache = {}
local module = { cache = cache }

module.start = function(config)
   hs.fnutils.each(config.enabled, function(notifyName)
      cache[notifyName] = require("utils.notify." .. notifyName)
      cache[notifyName]:start(config[notifyName])
   end)
end

module.stop = function()
   hs.fnutils.each(cache, function(notify)
      notify:stop()
   end)
end

return module
