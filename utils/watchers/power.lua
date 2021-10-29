local cache = {}
local M = { cache = cache }
-- local log = hs.logger.new("power", "debug")

M.energy = 0

M.update = function(energy)
   if M.menubar == nil then
      -- M.menubar = hs.menubar.newWithPriority(hs.menubar.priorities["system"])
      -- M.menubar = hs.menubar.new(hs.menubar.priorities["default"])
      -- M.menubar = hs.menubar.new(hs.menubar.priorities["system"])
      M.menubar = hs.menubar.new(true)
      -- M.menubar:priority(hs.menubar.priorities["default"])
   end

   local disp_str = string.format("%.1fｗ", energy)
   local disp = hs.styledtext.new {
      disp_str,
      {
         starts = 1,
         ends = #disp_str,
         attributes = {
            font = { size = 13 },
            ligature = 0,
            paragraphStyle = { lineHeightMultiple = 1 },
         },
      },
   }

   -- 
   M.menubar:setTitle(disp)
end

M.monitor = function(_, out, _)
   -- log.d(hs.inspect(hs.plist.readString(out)))
   local data = hs.plist.readString(out)
   M.energy = M.energy * 0.8 + data.processor.package_energy * 0.2
   M.update(M.energy)
   return true
end

M.task = function()
   hs.task.new(
      "/usr/bin/sudo",
      M.monitor,
      { "/usr/bin/powermetrics", "-f", "plist", "-i", "1", "-n", "1", "-s", "cpu_power" }
   ):start()
end

M.start = function()
   if cache.timer and cache.timer:running() then
      return
   end
   if not cache.timer then
      cache.timer = hs.timer.doEvery(5, M.task)
   end
   if not cache.timer:running() then
      cache.timer:start()
   end
end

M.stop = function()
   cache.timer:stop()
end

return M
