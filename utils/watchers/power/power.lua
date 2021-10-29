local cache = {}
local M = { cache = cache }

M.monitor = function(_, out, _)
   log.d(hs.inspect(hs.plist.readString(out)))
end

M.start = function()
   if cache.task and cache.task:isRunning() then
      return
   end
   if not cache.task then
      cache.task = hs.task.new(
         "/usr/bin/sudo",
         nil,
         M.monitor,
         { "powermetrics", "-f", "plist", "-i", "1000", "-s", "cpu_power" }
      )
   end
   if not cache.task:isRunning() then
      cache.task:start()
   end
end

M.stop = function()
   cache.task:terminate()
end

return M
