local M = {}
local hhtwm = require "widget.swm"
local spaces = require "hs._asm.undocumented.spaces"

local num = {
   "❶",
   "❷",
   "❸",
   "❹",
   "❺",
   "❻",
   "❼",
   "❽",
   "❾",
}

M.update = function()
   if M.menubar == nil then
      -- M.menubar = hs.menubar.newWithPriority(hs.menubar.priorities["system"])
      -- M.menubar = hs.menubar.new(hs.menubar.priorities["default"])
      -- M.menubar = hs.menubar.new(hs.menubar.priorities["system"])
      M.menubar = hs.menubar.new(true)
      M.menubar:priority(hs.menubar.priorities["default"])
   end
   local win = hs.window.frontmostWindow()
   local uuid = hs.window.frontmostWindow():screen():getUUID()
   local space = hhtwm.getSpaceId(win)
   local index = 1
   for i, id in ipairs(spaces.layout()[uuid]) do
      if space == id then
         index = i
      end
   end

   local disp_str = "" .. num[index]
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

M.start = function()
   M.darkmode =
      hs.osascript.applescript 'tell application "System Events"\nreturn dark mode of appearance preferences\nend tell'
   M.watcher = hs.spaces.watcher.new(M.update)
   M.watcher:start()
end

M.stop = function()
   M.watcher:stop()
end

return M
