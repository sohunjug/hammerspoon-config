local log = hs.logger.new("autoweb", "debug")

local cache = {}
local module = { cache = cache }

local sleepWatcher = function(_, _, _, _, event)
   local isTurningOff = event == hs.caffeinate.watcher.systemWillSleep
      or event == hs.caffeinate.watcher.systemWillPowerOff
   local isAtHome = hs.wifi.currentNetwork() == S_HS_CONFIG.network.home.wifi
   local isAtWork = hs.wifi.currentNetwork() == S_HS_CONFIG.network.work.wifi

   local handler = hs.urlevent.getDefaultHandler "http"

   if isTurningOff and isAtHome and handler ~= S_HS_CONFIG.network.home.browser then
      hs.urlevent.setDefaultHandler("http", S_HS_CONFIG.network.home.browser)
      log.d "home set browser"
   elseif isTurningOff and isAtWork and handler ~= S_HS_CONFIG.network.work.browser then
      hs.urlevent.setDefaultHandler("http", S_HS_CONFIG.network.work.browser)
      log.d "work set browser"
   end
end

module.start = function()
   cache.watcherSleep = hs.watchable.watch("status.sleepEvent", sleepWatcher)

   sleepWatcher(nil, nil, nil, nil, hs.caffeinate.watcher.systemWillSleep)
end

module.stop = function()
   cache.watcherSleep:release()
end

return module
