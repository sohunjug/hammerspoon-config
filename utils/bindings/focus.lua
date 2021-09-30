local activeScreen = require("ext.screen").activeScreen
local capitalize = require("ext.utils").capitalize
local cycleWindows = require("ext.window").cycleWindows
local focusScreen = require("ext.screen").focusScreen
local forceFocus = require("ext.window").forceFocus

local cache = {}
local module = { cache = cache }

local APP_WINDOWS_ONLY = false
local ONLY_FRONTMOST = true
local SCREEN_WINDOWS_ONLY = true
local STRICT_ANGLE = true

-- works for windows and screens!
local focusAndHighlight = function(cmd)
   local focusedWindow = hs.window.focusedWindow()
   local focusedScreen = activeScreen()

   local winCmd = "windowsTo" .. capitalize(cmd)
   local screenCmd = "to" .. capitalize(cmd)

   -- local windowsToFocus    = cache.focusFilter[winCmd](cache.focusFilter, focusedWindow, ONLY_FRONTMOST, STRICT_ANGLE)
   local windowsToFocus = focusedWindow[winCmd](focusedWindow, nil, ONLY_FRONTMOST, STRICT_ANGLE)
   local screenInDirection = focusedScreen[screenCmd](focusedScreen)
   local filterWindows = cache.focusFilter:getWindows()

   local windowOnSameOrNextScreen = function(testWin, currentScreen, nextScreen)
      return testWin:screen():id() == currentScreen:id() or testWin:screen():id() == nextScreen:id()
   end

   local firstWin = function(wins)
      for _, win in ipairs(wins) do
         if win:subrole() ~= "AXUnknown" then
            return win
         end
      end
   end

   local win = nil
   if #windowsToFocus > 0 then
      win = firstWin(windowsToFocus)
   end

   -- focus window if we have any, and it's on nearest or current screen (don't jump over empty screens)
   if
      #windowsToFocus > 0
      and win ~= nil
      and windowOnSameOrNextScreen(windowsToFocus[1], focusedScreen, screenInDirection)
   then
      forceFocus(win)
      -- focus screen in given direction if exists
   elseif screenInDirection then
      focusScreen(screenInDirection)
      -- focus first window if there are any
   elseif #filterWindows > 0 then
      forceFocus(filterWindows[1])
      -- finally focus the screen if nothing else works
   else
      focusScreen(focusedScreen)
   end
end

local highlightinit = function()
   hs.window.highlight.ui.overlay = true
   hs.window.highlight.ui.overlayColor = { 0.2, 0.05, 0, 0.25 }
   hs.window.highlight.ui.overlayColorInverted = { 0.8, 0.9, 1, 0.3 }
   hs.window.highlight.ui.isolateColor = { 0, 0, 0, 0.95 }
   hs.window.highlight.ui.isolateColorInverted = { 1, 1, 1, 0.95 }
   hs.window.highlight.ui.frameWidth = 10
   hs.window.highlight.ui.frameColor = { 0, 0.6, 1, 0.5 }
   hs.window.highlight.ui.frameColorInvert = { 1, 0.4, 0, 0.5 }
   hs.window.highlight.ui.flashDuration = 0
   hs.window.highlight.ui.windowShownFlashColor = { 0, 1, 0, 0.8 }
   hs.window.highlight.ui.windowHiddenFlashColor = { 1, 0, 0, 0.8 }
   hs.window.highlight.ui.windowShownFlashColorInvert = { 1, 0, 1, 0.8 }
   hs.window.highlight.ui.windowHiddenFlashColorInvert = { 0, 1, 1, 0.8 }
end

module.start = function()
   local bind = function(key, fn)
      hs.hotkey.bind({ "ctrl", "alt" }, key, fn, nil, fn)
   end

   highlightinit()
   cache.focusFilter = hs.window.filter.new():setCurrentSpace(true):setDefaultFilter():keepActive()

   hs.fnutils.each({
      { key = "h", cmd = "west" },
      { key = "j", cmd = "south" },
      { key = "k", cmd = "north" },
      { key = "l", cmd = "east" },
   }, function(object)
      bind(object.key, function()
         focusAndHighlight(object.cmd)
      end)
   end)

   bind("g", function()
      hs.window.highlight.start()
   end)

   bind("t", function()
      hs.window.highlight.stop()
   end)

   bind("y", function()
      hs.window.highlight.toggleIsolate()
   end)
   -- cycle between windows on current screen, useful in tiling monocle mode
   bind("]", function()
      cycleWindows("next", APP_WINDOWS_ONLY, SCREEN_WINDOWS_ONLY)
   end)
   bind("[", function()
      cycleWindows("prev", APP_WINDOWS_ONLY, SCREEN_WINDOWS_ONLY)
   end)
end

module.stop = function() end

return module
