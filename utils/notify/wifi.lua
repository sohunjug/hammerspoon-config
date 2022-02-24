local cache = {}
local module = { cache = cache }

local IMAGE_PATH = os.getenv "HOME" .. "/.hammerspoon/assets/airport.png"

local notifyWifi = function()
  local net = hs.wifi.currentNetwork()

  if hs.fnutils.contains(S_HS_CONFIG.network.work.wifi, net) then
    hs.task.new(
      "/usr/bin/sudo",
      nil,
      { os.getenv "HOME" .. "/.local/bin/" .. "work.sh" }
    ):start()
    print("work")
  else
    hs.task.new(
      "/usr/bin/sudo",
      nil,
      { os.getenv "HOME" .. "/.local/bin/" .. "home.sh" }
    ):start()
    print("home")
  end

end

module.start = function()
  cache.watcher = hs.wifi.watcher.new(notifyWifi)
  cache.watcher:start()
end

module.stop = function()
   cache.watcher:stop()
end

return module
