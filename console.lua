-- local axuiWindowElement = require('hs._asm.axuielement').windowElement
-- local axuiWindowElement = require("hs.axuielement").windowElement
-- local reloadHS = require("ext.system").reloadHS

local module = {}

module.init = function()
   -- some global functions for console
   -- inspect = hs.inspect
   -- reload = reloadHS
   --[[
   dumpWindows = function()
      hs.fnutils.each(hs.window.allWindows(), function(win)
         print(hs.inspect {
            id = win:id(),
            title = win:title(),
            app = win:application():name(),
            role = win:role(),
            subrole = win:subrole(),
            frame = win:frame(),
            buttonZoom = axuiWindowElement(win):attributeValue "AXZoomButton",
            buttonFullScreen = axuiWindowElement(win):attributeValue "AXFullScreenButton",
            isResizable = axuiWindowElement(win):isAttributeSettable "AXSize",
         })
      end)
   end

   dumpScreens = function()
      hs.fnutils.each(hs.screen.allScreens(), function(s)
         print(s:id(), s:position(), s:frame(), s:name())
      end)
   end

   timestamp = function(date)
      date = date or hs.timer.secondsSinceEpoch()
      return os.date("%F %T" .. ((tostring(date):match "(%.%d+)$") or ""), math.floor(date))
   end ]]

   -- console styling
   local grayColor = {
      red = 24 * 4 / 255,
      green = 24 * 4 / 255,
      blue = 24 * 4 / 255,
      alpha = 1,
   }

   local blackColor = {
      red = 24 / 255,
      green = 24 / 255,
      blue = 24 / 255,
      alpha = 1,
   }

   hs.console.consoleCommandColor(blackColor)
   hs.console.consoleResultColor(grayColor)
   hs.console.consolePrintColor(grayColor)

   -- no toolbar
   hs.console.toolbar(nil)
end

return module
