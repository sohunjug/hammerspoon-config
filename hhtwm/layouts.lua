-- hhtwm layouts

return function(hhtwm)
   local layouts = {}

   local getInsetFrame = function(screen)
      local screenFrame = screen:fullFrame()
      local screenMargin = hhtwm.screenMargin or { top = 0, bottom = 0, right = 0, left = 0 }

      return {
         x = screenFrame.x + screenMargin.left,
         y = screenFrame.y + screenMargin.top,
         w = screenFrame.w - (screenMargin.left + screenMargin.right),
         h = screenFrame.h - (screenMargin.top + screenMargin.bottom),
      }
   end

   layouts["floating"] = function()
      return nil
   end

   layouts["monocle"] = function(_, _, screen)
      local margin = hhtwm.margin or 0
      local insetFrame = getInsetFrame(screen)

      local frame = {
         x = insetFrame.x + margin / 2,
         y = insetFrame.y + margin / 2,
         w = insetFrame.w - margin,
         h = insetFrame.h - margin,
      }

      return frame
   end

   layouts["half-left"] = function(window, windows, screen, index, layoutOptions)
      if #windows == 1 then
         return layouts["monocle"](window, windows, screen)
      end

      local margin = hhtwm.margin or 0
      local insetFrame = getInsetFrame(screen)

      local frame = {
         x = insetFrame.x,
         y = insetFrame.y,
         w = 0,
         h = 0,
      }

      if index == 1 then
         frame.x = frame.x + margin / 2
         frame.y = frame.y + margin / 2
         frame.h = insetFrame.h - margin
         frame.w = insetFrame.w * layoutOptions.mainPaneRatio - margin
      else
         local divs = #windows - 1
         local h = insetFrame.h / divs

         frame.h = h - margin
         frame.w = insetFrame.w * (1 - layoutOptions.mainPaneRatio) - margin
         frame.x = frame.x + insetFrame.w * layoutOptions.mainPaneRatio + margin / 2
         frame.y = frame.y + h * (index - 2) + margin / 2
      end

      return frame
   end

   layouts["main-right"] = function(window, windows, screen, index, layoutOptions)
      if #windows == 1 then
         return layouts["monocle"](window, windows, screen)
      end

      local margin = hhtwm.margin or 0
      local insetFrame = getInsetFrame(screen)

      local frame = {
         x = insetFrame.x,
         y = insetFrame.y,
         w = 0,
         h = 0,
      }

      if index == 1 then
         frame.x = frame.x + insetFrame.w * layoutOptions.mainPaneRatio + margin / 2
         frame.y = frame.y + margin / 2
         frame.h = insetFrame.h - margin
         frame.w = insetFrame.w * (1 - layoutOptions.mainPaneRatio) - margin
      else
         local divs = #windows - 1
         local h = insetFrame.h / divs

         frame.x = frame.x + margin / 2
         frame.y = frame.y + h * (index - 2) + margin / 2
         frame.w = insetFrame.w * layoutOptions.mainPaneRatio - margin
         frame.h = h - margin
      end

      return frame
   end

   layouts["main-center"] = function(_, windows, screen, index, layoutOptions)
      local insetFrame = getInsetFrame(screen)
      local margin = hhtwm.margin or 0
      local mainColumnWidth = insetFrame.w * layoutOptions.mainPaneRatio + margin / 2

      if index == 1 then
         return {
            x = insetFrame.x + (insetFrame.w - mainColumnWidth) / 2 + margin / 2,
            y = insetFrame.y + margin / 2,
            w = mainColumnWidth - margin,
            h = insetFrame.h - margin,
         }
      end

      local frame = {
         x = insetFrame.x,
         y = 0,
         w = (insetFrame.w - mainColumnWidth) / 2 - margin,
         h = 0,
      }

      if (index - 1) % 2 == 0 then
         local divs = math.floor((#windows - 1) / 2)
         local h = insetFrame.h / divs

         frame.x = frame.x + margin / 2
         frame.h = h - margin
         frame.y = insetFrame.y + h * math.floor(index / 2 - 1) + margin / 2
      else
         local divs = math.ceil((#windows - 1) / 2)
         local h = insetFrame.h / divs

         frame.x = frame.x + (insetFrame.w - frame.w - margin) + margin / 2
         frame.h = h - margin
         frame.y = insetFrame.y + h * math.floor(index / 2 - 1) + margin / 2
      end

      return frame
   end

   layouts["tabbed-left"] = function(window, windows, screen, index, layoutOptions)
      if #windows == 1 then
         return layouts["monocle"](window, windows, screen)
      end

      local margin = hhtwm.margin or 0
      local insetFrame = getInsetFrame(screen)

      local frame = {
         x = insetFrame.x,
         y = insetFrame.y,
         w = 0,
         h = 0,
      }

      if index == 1 then
         frame.x = frame.x + insetFrame.w * layoutOptions.mainPaneRatio + margin / 2
         frame.y = frame.y + margin / 2
         frame.w = insetFrame.w * (1 - layoutOptions.mainPaneRatio) - margin
         frame.h = insetFrame.h - margin
      else
         frame.x = frame.x + margin / 2
         frame.y = frame.y + margin / 2
         frame.w = insetFrame.w * layoutOptions.mainPaneRatio - margin
         frame.h = insetFrame.h - margin
      end

      return frame
   end
   layouts["tab-right"] = function(window, windows, screen, index, layoutOptions)
      if #windows == 1 then
         return layouts["monocle"](window, windows, screen)
      end

      local margin = hhtwm.margin or 0
      local insetFrame = getInsetFrame(screen)

      local frame = {
         x = insetFrame.x,
         y = insetFrame.y,
         w = 0,
         h = 0,
      }

      if index == 1 then
         frame.x = frame.x + margin / 2
         frame.y = frame.y + margin / 2
         frame.w = insetFrame.w * layoutOptions.mainPaneRatio - margin
         frame.h = insetFrame.h - margin
      else
         frame.x = frame.x + insetFrame.w * layoutOptions.mainPaneRatio + margin / 2
         frame.y = frame.y + margin / 2
         frame.w = insetFrame.w * (1 - layoutOptions.mainPaneRatio) - margin
         frame.h = insetFrame.h - margin
      end

      return frame
   end

   layouts["main-work"] = function(window, windows, screen, index, layoutOptions)
      if #windows == 1 then
         return layouts["monocle"](window, windows, screen)
      end

      local margin = hhtwm.margin or 0
      local insetFrame = getInsetFrame(screen)

      if layoutOptions.mainPaneRatio < 0.51 then
         layoutOptions.mainPaneRatio = 0.6
      end

      local frame = {
         x = insetFrame.x,
         y = insetFrame.y,
         w = 0,
         h = 0,
      }

      if index == 1 then
         frame.x = frame.x + margin / 2
         frame.y = frame.y + margin / 2
         frame.w = insetFrame.w * layoutOptions.mainPaneRatio - margin
         frame.h = insetFrame.h - margin
      else
         frame.x = frame.x + insetFrame.w * layoutOptions.mainPaneRatio + margin / 2
         frame.y = frame.y + margin / 2
         frame.w = insetFrame.w * (1 - layoutOptions.mainPaneRatio) - margin
         frame.h = insetFrame.h - margin
      end
      return frame
   end

   layouts["gp-vertical"] = function(_, windows)
      local winCount = #windows

      if winCount == 1 then
         return layouts["fullscreen"](windows)
      end

      local width
      local height
      local x = 0
      local y = 0

      for index, win in pairs(windows) do
         local frame = win:screen():frame()

         if index == 1 then
            height = frame.h
            width = frame.w / 2
         elseif index % 2 == 0 then
            if index ~= winCount then
               height = height / 2
            end
            x = x + width
         else
            if index ~= winCount then
               width = width / 2
            end
            y = y + height
         end

         frame.x = frame.x + x
         frame.y = frame.y + y
         frame.w = width
         frame.h = height

         win:setFrame(frame)
      end
   end

   -- TODO
   -- layouts["stacking-columns"] = function(window, windows, screen, index, layoutOptions)
   --   return nil
   -- end

   return layouts
end
