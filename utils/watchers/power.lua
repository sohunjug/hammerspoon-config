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

   local watt = "ｗ"
   local disp_str = string.format("%.1f%s", energy / 1000, watt)
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
   local energy = data.processor.package_energy
      + data.processor.cpu_energy
      + data.processor.ane_energy
      + data.processor.gpu_energy
      + data.processor.dram_energy
   if not M.energy then
      M.energy = energy
   else
      M.energy = M.energy * 0.8 + energy * 0.2
   end
   M.update(M.energy)
   return true
end

M.task = function()
   hs.task.new(
      "/usr/bin/sudo",
      M.monitor,
      { "/usr/bin/powermetrics", "-f", "plist", "-i", "4000", "-n", "1", "-s", "cpu_power" }
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
