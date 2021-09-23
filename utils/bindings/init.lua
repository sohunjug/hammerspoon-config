local cache = {}
local module = { cache = cache }

-- modifiers in use:
-- * cltr+alt: move focus between windows
-- * ctrl+shift: do things to windows
-- * ultra: custom/global bindings

module.start = function(config)
   hs.fnutils.each(config.enabled, function(binding)
      cache[binding] = require("utils.bindings." .. binding)
      cache[binding].start(config[binding])
   end)
end

module.stop = function()
   hs.fnutils.each(cache, function(binding)
      binding.stop()
   end)
end

return module
