local highlightWindow = require("ext.drawing").highlightWindow
-- local spaces = require "hs._asm.undocumented.spaces"
local capitalize = require("ext.utils").capitalize
local wm = require "utils.wm"

local cache = {}
local module = { cache = cache }
local windowMeta = {}
local hhtwm = wm.cache.hhtwm

local move = function(dir)
   local win = hs.window.frontmostWindow()

   if hhtwm.isFloating(win) then
      local directions = {
         west = "left",
         south = "down",
         north = "up",
         east = "right",
      }

      hs.grid["pushWindow" .. capitalize(directions[dir])](win)
   else
      hhtwm.swapInDirection(win, dir)
   end

   highlightWindow()
end

local throw = function(dir)
   local win = hs.window.frontmostWindow()

   if hhtwm.isFloating(win) then
      hs.grid["pushWindow" .. capitalize(dir) .. "Screen"](win)
   else
      hhtwm.throwToScreenUsingSpaces(win, dir)
   end

   highlightWindow()
end

local resize = function(resize)
   local win = hs.window.frontmostWindow()

   if hhtwm.isFloating(win) then
      hs.grid["resizeWindow" .. capitalize(resize)](win)

      highlightWindow()
   else
      hhtwm.resizeLayout(resize)
   end
end

function windowMeta.new()
   local self = setmetatable(windowMeta, {
      -- Treate table like a function
      -- Event listener when windowMeta() is called
      __call = function(cls, ...)
         return cls.new(...)
      end,
   })
   self.window = hs.window.focusedWindow()
   self.screen = hs.window.focusedWindow():screen()
   self.windowGrid = hs.grid.get(self.window)
   self.screenGrid = hs.grid.getGrid(self.screen)
   self.windowFrame = hs.window.frontmostWindow():frame()
   self.screenFrame = hs.window.frontmostWindow():screen():frame()

   return self
end

local larger = function()
   local this = windowMeta.new()
   local center = this.windowFrame.center
   local w = this.windowFrame.w / 0.9
   local h = this.windowFrame.h / 0.9
   local x = center.x - w / 2
   local y = center.y - h / 2
   w = w > this.screenFrame.w and this.screenFrame.w or w
   h = h > this.screenFrame.h and this.screenFrame.h or h
   x = x > 0 and x or 0
   y = y > 0 and y or 0
   local cell = hs.geometry(x, y, w, h)
   this.window:move(cell)
   -- grid.set(this.window, cell, this.screen)
end

local maximizeWindow = function()
   local this = windowMeta.new()
   -- hs.grid.maximizeWindow(this.window)
   this.window:maximize()
end

local center = function()
   local this = windowMeta.new()
   -- this.window:maximum()
   -- this = windowMeta.new()
   local center = this.windowFrame.center
   local w = this.windowFrame.w * 0.6
   local h = this.windowFrame.h * 0.6
   local x = center.x - w / 2
   local y = center.y - h / 2
   local cell = hs.geometry(x, y, w, h)
   this.window:move(cell)
   -- grid.set(this.window, cell, this.screen)
end

local smaller = function()
   local this = windowMeta.new()
   local c = this.windowFrame.center
   local w = this.windowFrame.w * 0.9
   local h = this.windowFrame.h * 0.9
   local x = c.x - w / 2
   local y = c.y - h / 2
   local cell = hs.geometry(x, y, w, h)
   this.window:move(cell)
   -- grid.set(this.window, cell, this.screen)
end

module.start = function()
   local bind = function(key, fn)
      hs.hotkey.bind({ "ctrl", "shift" }, key, fn, nil, fn)
   end

   -- move window
   hs.fnutils.each({
      { key = "h", dir = "west" },
      { key = "j", dir = "south" },
      { key = "k", dir = "north" },
      { key = "l", dir = "east" },
   }, function(obj)
      bind(obj.key, function()
         move(obj.dir)
      end)
   end)

   -- throw between screens
   hs.fnutils.each({
      { key = "]", dir = "prev" },
      { key = "[", dir = "next" },
   }, function(obj)
      bind(obj.key, function()
         throw(obj.dir)
      end)
   end)

   -- resize (floating only)
   hs.fnutils.each({
      { key = ",", dir = "thinner" },
      { key = ".", dir = "wider" },
      { key = ";", dir = "shorter" },
      { key = "'", dir = "taller" },
   }, function(obj)
      bind(obj.key, function()
         resize(obj.dir)
      end)
   end)

   bind("-", smaller)
   bind("=", larger)
   bind("m", center)
   bind("return", maximizeWindow)

   -- toggle [f]loat
   bind("f", function()
      local win = hs.window.frontmostWindow()

      if not win then
         return
      end

      hhtwm.toggleFloat(win)

      if hhtwm.isFloating(win) then
         hs.grid.center(win)
      end

      highlightWindow()
   end)

   -- [r]eset
   bind("r", hhtwm.reset)

   local fn = function()
      -- spaces.createSpace(hs.window.frontmostWindow():screen():getUUID(), true)
      hs.spaces.addSpaceToScreen(hs.window.frontmostWindow():screen():getUUID())
      -- spaces.createSpace(nil, true)
      -- print(
      --    spaces.spaceScreenUUID(spaces.currentSpace()),
      --    hs.window.frontmostWindow():screen():getUUID(),
      --    spaces.mainScreenUUID()
      -- )
      -- spaces.createSpace(spaces.spaceScreenUUID(spaces.currentSpace()), false)
   end
   hs.hotkey.bind({ "ctrl", "shift", "command" }, "n", fn, nil, fn)

   -- re[t]ile
   bind("t", hhtwm.tile)

   -- [e]qualize
   bind("'", hhtwm.equalizeLayout)

   bind("e", hhtwm.setMain)

   bind("x", hhtwm.clear)

   bind("d", function()
      local id = hhtwm.getSpaceId()
      hhtwm.cache.spaces[id][1]:focus()
   end)

   -- [c]enter window
   --[[ bind("c", function()
      local win = hs.window.frontmostWindow()

      if not hhtwm.isFloating(win) then
         hhtwm.toggleFloat(win)
      end

      -- win:centerOnScreen()
      hs.grid.center(win)
      highlightWindow()
   end) ]]

   -- toggle [z]oom window
   bind("z", function()
      local win = hs.window.frontmostWindow()

      if not hhtwm.isFloating(win) then
         hhtwm.toggleFloat(win)
         hs.grid.maximizeWindow(win)
      else
         hhtwm.toggleFloat(win)
      end

      highlightWindow()
   end)

   -- throw window to space (and move)
   for n = 1, 9 do
      local idx = tostring(n)

      --[[local function tfn()
         hs.execute "killall Dock"
         cache.timer = nil
      end

      local timerReload = function()
         if cache.timer then
            cache.timer:stop()
         end
         cache.timer = hs.timer.doAfter(30, tfn)
         cache.timer:start()
      end]]

      hs.hotkey.bind({ "shift", "alt" }, idx, nil, function()
         local uuid = hs.screen.mainScreen():spacesUUID()
         local spaceID = hs.spaces.spacesForScreen(uuid)[n]
         -- local ID = spaces.activeSpace()
         local ID = hs.spaces.focusedSpace()

         if ID ~= spaceID and spaceID ~= nil then
            -- spaces.changeToSpace(spaceID, false)
            hs.spaces.gotoSpace(spaceID)
            -- timerReload()
         end
         -- hs.window.filter.switchedToSpace(idx)
      end)

      hs.hotkey.bind({ "ctrl", "alt", "shift" }, idx, nil, function()
         local win = hs.window.focusedWindow()
         local uuid = win:screen():spacesUUID()
         -- local spaceID = spaces.layout()[uuid][n]
         -- local ID = spaces.activeSpace()
         local spaceID = hs.spaces.spacesForScreen(uuid)[n]
         local ID = hs.spaces.focusedSpace()

         if ID ~= spaceID and spaceID ~= nil then
            hs.spaces.removeSpace(spaceID, true)
         end
         -- hs.window.filter.switchedToSpace(idx)
      end)
      -- important: use this with onKeyReleased, not onKeyPressed
      hs.hotkey.bind({ "ctrl", "shift" }, idx, nil, function()
         local win = hs.window.focusedWindow()
         local uuid = win:screen():spacesUUID()

         -- local spaceID = spaces.layout()[uuid][n]
         -- local ID = spaces.activeSpace()

         local spaceID = hs.spaces.spacesForScreen(uuid)
         local ID = hs.spaces.focusedSpace()

         if ID == spaceID[n] or spaceID == nil then
            return
         end
         -- print(hs.inspect(spaceID), "idx:", idx, "spaceID:", spaceID[tonumber(idx)])
         -- local isFloating = hhtwm.isFloating(win)
         -- local success = hhtwm.throwToSpace(win, spaceID)
         local success = hs.spaces.moveWindowToSpace(win, spaceID[n])

         -- if window switched space, then follow it (ctrl + 0..9) and focus
         if success then
            hs.spaces.gotoSpace(spaceID[n])
            -- spaces.changeToSpace(spaceID, false)
            -- timerReload()
            -- hs.eventtap.keyStroke({ "ctrl" }, idx)

            -- retile and re-highlight window after we switch space
            --[[ hs.timer.doAfter(0.05, function()
               if not isFloating then
                  hhtwm.tile()
               end
               highlightWindow(win)
            end) ]]
         end
      end)
   end
end

module.stop = function()
   if cache.timer then
      cache.timer:stop()
      cache.timer = nil
   end
end

return module
