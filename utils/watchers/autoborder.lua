local drawBorder = require("ext.drawing").drawBorder

local cache = {}
local M = { cache = cache }

M.action = function(_, event, application)
   local win = application:focusedWindow()
   if not win or win:isFullScreen() then
      return
   end
   if event == hs.application.watcher.activated then
      drawBorder()
   end
end

M.start = function()
   cache.watcher = hs.application.watcher.new(M.action)
   --[[ cache.filter = hs.window.filter.new():setCurrentSpace(true):setDefaultFilter():setOverrideFilter {
      fullscreen = false,
      allowRoles = { "AXStandardWindow" },
   } ]]

   -- cache.filter:subscribe({
   -- hs.window.filter.windowCreated,
   -- hs.window.filter.windowDestroyed,
   -- hs.window.filter.windowsChanged,
   -- hs.window.filter.windowMoved,
   -- hs.window.filter.windowFocused,
   -- hs.window.filter.windowUnfocused,
   -- }, drawBorder)
   cache.watcher:start()

   drawBorder()
end

M.stop = function()
   cache.watcher:stop()
   -- cache.filter:unsubscribeAll()
end

return M
