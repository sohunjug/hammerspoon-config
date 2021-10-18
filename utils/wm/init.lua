local activeScreen = require("ext.screen").activeScreen
local table = require "ext.table"
local hhtwm = require "widget.swm"
-- local hhtwm = require "hhtwm"
local log = hs.logger.new("wm", "debug")

local cache = { hhtwm = hhtwm }
local module = { cache = cache }

-- local IMAGE_PATH = os.getenv "HOME" .. "/.hammerspoon/assets/modal.png"

local notify = function(text)
   --[[ hs.notify.new({
      title = "Tiling",
      subTitle = text,
      contentImage = IMAGE_PATH,
      autoWithdraw = true,
      withdrawAfter = 2,
   }):send() ]]
   hs.alert.show(text)
end

local screenWatcher = function(_, _, _, prevScreens, screens)
   if prevScreens == nil or #prevScreens == 0 then
      return
   end

   if table.equal(prevScreens, screens) then
      return
   end

   log.d "resetting display layouts"

   hhtwm.displayLayouts = S_HS_CONFIG.wm.defaultDisplayLayouts
   hhtwm.resetLayouts()
   hhtwm.tile()
end

--[[ local calcResizeStep = function(screen)
   return 1 / hs.grid.getGrid(screen).w
end ]]

module.setLayout = function(layout)
   hhtwm.setLayout(layout)
   hhtwm.resizeLayout()

   notify("Switching to: " .. layout)
end

module.cycleLayout = function()
   local screen = activeScreen()

   local layouts = S_HS_CONFIG.wm.displayLayouts[screen:name()]

   local currentLayout = hhtwm.getLayout()
   local currentLayoutIndex = hs.fnutils.indexOf(layouts, currentLayout) or 0

   local nextLayoutIndex = (currentLayoutIndex % #layouts) + 1
   local nextLayout = layouts[nextLayoutIndex]

   module.setLayout(nextLayout)
end

--[[ module.sohunjugLayout = function()
   local layout = "main-left"

   module.setLayout(layout)
end ]]

module.switcherLayout = function(layout)
   module.setLayout(layout)
end

module.start = function(_)
   cache.watcher = hs.watchable.watch("status.connectedScreenIds", screenWatcher)

   local screenAlias = {
      ["LU28R55"] = "primary",
      ["B2431M"] = "primary",
      ["Built-in Retina Display"] = "laptop",
   }

   local filters = {
      { app = "Alacritty", tile = true },
      { app = "AppCleaner", tile = false },
      { app = "Application Loader", tile = true },
      { app = "Archive Utility", tile = false },
      { app = "DiskImages UI Agent", tile = false },
      { app = "FaceTime", tile = false },
      { app = "Finder", title = "Copy", tile = false },
      { app = "Finder", title = "Move", tile = false },
      { app = "Focus", tile = false },
      { app = "GIF Brewery 3", tile = false },
      { app = "Hammerspoon", title = "Hammerspoon Console", tile = true },
      { app = "Helium", tile = false },
      { app = "Kap", tile = false },
      { app = "Max", tile = true },
      { app = "Messages", tile = false },
      { app = "Photo Booth", tile = false },
      { app = "Pixelmator", subrole = "AXDialog", tile = false },
      { app = "Pixelmator", subrole = "AXUnknown", tile = false },
      { app = "QuickTime Player", tile = false },
      { app = "Reminders", tile = false },
      { app = "Simulator", tile = false },
      { app = "System Preferences", tile = false },
      { app = "The Unarchiver", tile = false },
      { app = "Transmission", tile = false },
      { app = "Tweetbot", tile = false },
      { app = "UnmountAssistantAgent", tile = false },
      { app = "Viscosity", tile = false },
      { app = "iTerm2", subrole = "AXDialog", tile = false },
      { app = "向日葵远程控制", tile = false, screen = "primary", space = 5 },
      -- { app = "信息", tile = false },
      { app = "QQ音乐", tile = false, screen = "laptop", space = 1 },
      { app = "爱奇艺", tile = true, screen = "laptop", space = 1 },
      { app = "QQ", tile = true, screen = "primary", space = 3 },
      { app = "同花顺至尊版", tile = false, screen = "primary", space = 2 },
      { app = "iTunes", title = "Mini Player", tile = false },
      { app = "iTunes", title = "Multiple Song Info", tile = false },
      { app = "iTunes", title = "Song Info", tile = false },
      { app = "App Store", tile = false },
      { app = "Docker Desktop", tile = false },
      { app = "钉钉", title = "钉钉", tile = true },
      { app = "钉钉", title = "Window", role = "AXWindow", subrole = "AXStandardWindow", tile = false },
      { app = "微信", title = "聊天", role = "AXWindow", subrole = "AXStandardWindow", tile = true },
      { app = "微信", role = "AXWindow", subrole = "AXStandardWindow", tile = false },
      { app = "odonate-desktop", tile = true, screen = "laptop", space = 1 },
      { title = "GVim", tile = true },
      { title = "Little Snitch Configuration", tile = true },
      { title = "Little Snitch Network Monitor", tile = false },
      -- { title = "Window", tile = false },
      { title = "MenuBarCover", tile = false },
      -- { subrole = "AXUnknown", title = "Window", tile = false },
      { title = "Quick Look", tile = false },
      { title = "TeamViewer", tile = true },
   }

   local isMenubarVisible = hs.screen.primaryScreen():frame().y > 0

   local fullMargin = 10
   local halfMargin = fullMargin / 2

   local screenMargin = {
      top = (isMenubarVisible and 22 or 0) + halfMargin,
      bottom = halfMargin,
      left = halfMargin,
      right = halfMargin,
   }

   hhtwm.screen = screenAlias
   hhtwm.margin = fullMargin
   hhtwm.screenMargin = screenMargin
   hhtwm.filters = filters
   -- hhtwm.calcResizeStep = calcResizeStep
   hhtwm.displayLayouts = S_HS_CONFIG.wm.displayLayouts[activeScreen():name()]
   hhtwm.defaultLayout = "monocle"

   hhtwm.start()
end

module.stop = function()
   cache.watcher:release()
   hhtwm.stop()
end

return module
