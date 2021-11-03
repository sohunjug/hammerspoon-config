-- hhtwm - hackable hammerspoon tiling wm

local defaultLayouts = require "widget.swm.layouts"
local spaces = require "hs._asm.undocumented.spaces"

local cache = { spaces = {}, layouts = {}, floating = {}, layoutOptions = {}, main = {} }
local M = { cache = cache, screen = {} }
local tilingLock = false

local layouts = defaultLayouts(M)
local log = hs.logger.new("swm", "debug")

local SWAP_BETWEEN_SCREENS = false

local DefaultLayoutOptions = function()
   return hs.fnutils.copy {
      mainPaneRatio = 0.5,
   }
end

local capitalize = function(str)
   return str:gsub("^%l", string.upper)
end

local ternary = function(cond, ifTrue, ifFalse)
   if cond then
      return ifTrue
   else
      return ifFalse
   end
end

local findWindowById = function(allWindows, winId)
   return hs.fnutils.find(allWindows, function(win)
      return win:id() == winId
   end)
end

local ensureCacheSpaces = function(screenIdx, spaceIdx)
   if screenIdx and not cache.spaces[screenIdx] then
      cache.spaces[screenIdx] = {}
   end
   if spaceIdx and not cache.spaces[screenIdx][spaceIdx] then
      cache.spaces[screenIdx][spaceIdx] = {}
   end
   if screenIdx and not cache.main[screenIdx] then
      cache.main[screenIdx] = {}
   end
   if spaceIdx and not cache.main[screenIdx][spaceIdx] then
      cache.main[screenIdx][spaceIdx] = {}
   end
   if type(screenIdx) == "number" then
      print(debug.traceback())
   end
   if not screenIdx or not spaceIdx then
      print(debug.traceback())
   end
   return cache.spaces[screenIdx][spaceIdx]
end

local getCurrentSpacesIds = function()
   return spaces.query(spaces.masks.currentSpaces)
end

M.getSpaceId = function(win)
   local spaceId

   win = win or hs.window.frontmostWindow()

   if win ~= nil and win:spaces() ~= nil and #win:spaces() > 0 then
      spaceId = win:spaces()[1]
   end

   return spaceId or spaces.activeSpace()
end

local getSpacesIdsTable = function()
   local spacesLayout = spaces.layout()
   local spacesIds = {}

   hs.fnutils.each(hs.screen.allScreens(), function(screen)
      local spaceUUID = screen:spacesUUID()

      local userSpaces = hs.fnutils.filter(spacesLayout[spaceUUID], function(spaceId)
         return spaces.spaceType(spaceId) == spaces.types.user
      end)

      hs.fnutils.concat(spacesIds, userSpaces or {})
   end)

   return spacesIds
end

local getScreenBySpaceId = function(spaceId)
   local spacesLayout = spaces.layout()

   return hs.fnutils.find(hs.screen.allScreens(), function(screen)
      local spaceUUID = screen:spacesUUID()
      return hs.fnutils.contains(spacesLayout[spaceUUID], spaceId)
   end)
end

local getSpaceIndex = function(win)
   win = win or hs.window.frontmostWindow()
   local uuid = win:screen():spacesUUID()
   local spaceIds = spaces.layout()[uuid]
   local spaceId = M.getSpaceId(win)
   for idx, id in ipairs(spaceIds) do
      if id == spaceId then
         return idx
      end
   end
   return spaceId
end

local SKIP_BUNDLES = {
   ["com.apple.WebKit.WebContent"] = true,
   ["com.apple.qtserver"] = true,
   ["com.google.Chrome.helper"] = true,
   ["org.pqrs.Karabiner-AXNotifier"] = true,
   ["com.adobe.PDApp.AAMUpdatesNotifier"] = true,
   ["com.adobe.csi.CS5.5ServiceManager"] = true,
   ["com.mcafee.McAfeeReporter"] = true,
   ["cn.com.10jqka.iHexinFee"] = true,
   -- ["N/A"] = true,
}

local SKIP_APPS = {
   ["imklaunchagent"] = true,
}

local getAllWindows = function()
   local r = {}
   for _, app in ipairs(hs.application.runningApplications()) do
      if app:kind() >= 0 then
         local name = app:name()
         local bid = app:bundleID() or "N/A" --just for safety; universalaccessd has no bundleid (but it's kind()==-1 anyway)
         if not SKIP_APPS[name] then
            if bid == "com.apple.finder" then --exclude the desktop "window"
               -- check the role explicitly, instead of relying on absent :id() - sometimes minimized windows have no :id() (El Cap Notes.app)
               for _, w in ipairs(app:allWindows()) do
                  if w:role() == "AXWindow" then
                     r[#r + 1] = w
                  end
               end
            elseif not SKIP_BUNDLES[bid] then
               for _, w in ipairs(app:allWindows()) do
                  r[#r + 1] = w
               end
            end
         end
      end
   end
   return r
end

local getSpaceIdx = function(spaceId, uuid)
   if spaceId == nil then
      return getSpaceIndex()
   end
   if uuid == nil then
      local screen = getScreenBySpaceId(spaceId)
      if not screen then
         return 0
      end
      -- log.d(hs.inspect { screen = screen, spaceid = spaceId, uuid = uuid })
      uuid = screen:spacesUUID()
   end
   local spaceIds = spaces.layout()[uuid]
   for idx, id in ipairs(spaceIds) do
      if id == spaceId then
         return idx
      end
   end
   return 0
end

local getAllWindowsUsingSpaces = function()
   local spacesIds = getSpacesIdsTable()

   local tmp = {}

   hs.fnutils.each(spacesIds, function(spaceId)
      local windows = spaces.allWindowsForSpace(spaceId)

      hs.fnutils.each(windows, function(win)
         table.insert(tmp, win)
      end)
   end)

   return tmp
end

local getCurrentSpacesByScreen = function()
   local currentSpaces = spaces.query(spaces.masks.currentSpaces)

   local spacesIds = {}

   hs.fnutils.each(hs.screen.allScreens(), function(screen)
      local screenSpaces = screen:spaces()

      local visibleSpace = hs.fnutils.find(screenSpaces, function(spaceId)
         return hs.fnutils.contains(currentSpaces, spaceId)
      end)

      spacesIds[screen:id()] = visibleSpace
   end)

   return spacesIds
end

local getScreenIndex = function(screenOrSpaceId)
   if not screenOrSpaceId then
      local win = hs.window.frontmostWindow()
      screenOrSpaceId = win:screen()
   end
   if type(screenOrSpaceId) == "number" then
      screenOrSpaceId = getScreenBySpaceId(screenOrSpaceId)
   end
   if not screenOrSpaceId then
      return M.defaultLayout
   end

   return M.screen[screenOrSpaceId:name()] or screenOrSpaceId:name()
end

local getSpaceOptions = function(screenIdx, spaceIdx)
   if screenIdx and not cache.layoutOptions[screenIdx] then
      cache.layoutOptions[screenIdx] = {}
   end
   if spaceIdx and not cache.layoutOptions[screenIdx][spaceIdx] then
      cache.layoutOptions[screenIdx][spaceIdx] = DefaultLayoutOptions()
   end

   return cache.layoutOptions[screenIdx][spaceIdx]
end

--[[ local getSpaceWins = function(spaceId)
   local spaceIdx = getSpaceIndex()
   local screen = getScreenIndex(spaceId)
   return ensureCacheSpaces(screen, spaceIdx)
end ]]

M.findTrackedWindow = function(winOrWinId)
   if winOrWinId then
      local win = winOrWinId
      local wId = winOrWinId
      if type(winOrWinId) ~= "string" then
         wId = winOrWinId:id()
      else
         win = hs.window(wId)
      end

      local _screenIdx = getScreenIndex(win:screen())
      local _spaceIdx = getSpaceIndex(win)
      ensureCacheSpaces(_screenIdx, _spaceIdx)

      for screenIdx, spaceIds in pairs(cache.spaces) do
         for spaceIdx, spaceWindows in ipairs(spaceIds) do
            for winIdx, _win in ipairs(spaceWindows) do
               if _win:id() == wId then
                  return _win:id(), spaceIdx, winIdx, screenIdx
               end
            end
         end
      end
   end

   return nil, nil, nil, nil
end

M.getLayouts = function()
   local layoutNames = {}

   for key in pairs(layouts) do
      table.insert(layoutNames, key)
   end

   return layoutNames
end

M.setLayout = function(layout, spaceId)
   local spaceIdx = getSpaceIdx(spaceId)
   local screenIdx = getScreenIndex(spaceId)
   if not spaceIdx or not screenIdx then
      return
   end

   if not cache.layouts[screenIdx] then
      cache.layouts[screenIdx] = {}
   end
   cache.layouts[screenIdx][spaceIdx] = layout

   M.tile()
end

-- get layout for space id, priorities:
-- 1. already set layout (cache)
-- 2. layout selected by setLayout
-- 3. layout assigned by tilign.displayLayouts
-- 4. if all else fails - 'monocle'
M.getLayout = function(spaceId)
   local spaceIdx = getSpaceIdx(spaceId)
   local screenIdx = getScreenIndex(spaceId)

   if spaceIdx == 0 then
      return "monocle"
   end

   local layout = spaces.layout()
   local foundScreenUUID

   for screenUUID, layoutSpaces in pairs(layout) do
      if not foundScreenUUID then
         if hs.fnutils.contains(layoutSpaces, spaceId) then
            foundScreenUUID = screenUUID
         end
      end
   end

   local screen = hs.fnutils.find(hs.screen.allScreens(), function(screen)
      return screen:spacesUUID() == foundScreenUUID
   end)

   local name = (screen and M.displayLayouts and M.displayLayouts[screen:id()] and M.displayLayouts[screen:id()])
      or (screen and M.displayLayouts and M.displayLayouts[screen:name()] and M.displayLayouts[screen:name()][1])
      or "monocle"
   if cache.layouts[screenIdx] then
      local _name = cache.layouts[screenIdx][spaceIdx]
         or (screen and M.displayLayouts and M.displayLayouts[screen:id()] and M.displayLayouts[screen:id()])
         or (screen and M.displayLayouts and M.displayLayouts[screen:name()] and M.displayLayouts[screen:name()][1])
         or "monocle"
      if type(_name) == "string" then
         name = _name
      end
   end
   return name
end

-- resbuild cache.layouts table using provided hhtwm.displayLayouts and hhtwm.defaultLayout
M.resetLayouts = function()
   for k, screen in pairs(cache.layouts) do
      if type(screen) ~= "table" then
         cache.layouts[k] = {}
      end
      for key in pairs(screen) do
         screen[key] = {}
         screen[key] = M.getLayout(key)
      end
   end
end

M.clear = function()
   local spaceIdx = getSpaceIndex()
   local screenIdx = getScreenIndex()
   cache.spaces[screenIdx][spaceIdx] = {}
   cache.main[screenIdx][spaceIdx] = nil

   M.tile()
end

M.setMain = function()
   local win = hs.window.frontmostWindow()
   local spaceIdx = getSpaceIndex(win)
   local screenIdx = getScreenIndex()

   cache.main[screenIdx][spaceIdx] = win:id()

   M.tile()
end

M.resizeLayout = function(resizeOpt)
   local spaceId = M.getSpaceId()
   if not spaceId then
      return
   end

   local spaceIdx = getSpaceIdx(spaceId)
   local screenIdx = getScreenIndex(spaceId)

   local options = getSpaceOptions(screenIdx, spaceIdx)

   local calcResizeStep = M.calcResizeStep or function()
      return 0.01
   end

   local screen = getScreenBySpaceId(spaceId)
   local step = calcResizeStep(screen)
   local ratio = options.mainPaneRatio

   if not resizeOpt then
      ratio = 0.5
   elseif resizeOpt == "thinner" then
      ratio = math.max(ratio - step, 0)
   elseif resizeOpt == "wider" then
      ratio = math.min(ratio + step, 1)
   end

   options.mainPaneRatio = ratio
   M.tile()
end

M.equalizeLayout = function()
   local spaceIdx = getSpaceIndex()
   local screenIdx = getScreenIndex()
   if not screenIdx or not spaceIdx then
      return
   end

   if cache.layoutOptions[screenIdx][spaceIdx] then
      cache.layoutOptions[screenIdx][spaceIdx] = DefaultLayoutOptions()
      M.tile()
   end
end

-- swap windows in direction
-- works between screens
M.swapInDirection = function(win, direction)
   win = win or hs.window.frontmostWindow()

   if M.isFloating(win) then
      return
   end

   local winCmd = "windowsTo" .. capitalize(direction)
   local ONLY_FRONTMOST = true
   local STRICT_ANGLE = true
   -- local windowsInDirection = cache.filter[winCmd](cache.filter, win, ONLY_FRONTMOST, STRICT_ANGLE)
   local windowsInDirection = win[winCmd](win, nil, ONLY_FRONTMOST, STRICT_ANGLE)

   windowsInDirection = hs.fnutils.filter(windowsInDirection, function(testWin)
      return testWin:isStandard() and not M.isFloating(testWin)
   end)

   if #windowsInDirection >= 1 then
      local winInDirection = windowsInDirection[1]

      local _, winInDirectionSpaceIdx, winInDirectionIdx, winInDirectionScreenIdx = M.findTrackedWindow(winInDirection)
      local _, winSpaceIdx, winIdx, winScreenIdx = M.findTrackedWindow(win)

      if
         hs.fnutils.some({
            win,
            winInDirection,
            winInDirectionSpaceIdx,
            winInDirectionIdx,
            winSpaceIdx,
            winIdx,
         }, function(_)
            return _ == nil
         end)
      then
         log.e("swapInDirection error", hs.inspect { winInDirectionSpaceIdx, winInDirectionIdx, winSpaceIdx, winIdx })
         return
      end

      local winInDirectionScreen = winInDirection:screen()
      local winScreen = win:screen()

      -- local winInDirectionFrame  = winInDirection:frame()
      -- local winFrame             = win:frame()

      -- if swapping between screens is disabled, then return early if screen ids differ
      if not SWAP_BETWEEN_SCREENS and winScreen:id() ~= winInDirectionScreen:id() then
         return
      end

      -- otherwise, move to screen if they differ
      if winScreen:id() ~= winInDirectionScreen:id() then
         win:moveToScreen(winInDirectionScreen)
         winInDirection:moveToScreen(winScreen)
      end

      ensureCacheSpaces(winScreenIdx, winSpaceIdx)
      ensureCacheSpaces(winInDirectionScreenIdx, winInDirectionSpaceIdx)

      -- swap frames

      if
         winInDirection:id() == cache.main[winScreenIdx][winSpaceIdx]
         or win:id() == cache.main[winScreenIdx][winSpaceIdx]
      then
         cache.main[winScreenIdx][winSpaceIdx] = nil
      end
      -- swap positions in arrays
      cache.spaces[winScreenIdx][winSpaceIdx][winIdx] = winInDirection
      cache.spaces[winInDirectionScreenIdx][winInDirectionSpaceIdx][winInDirectionIdx] = win

      -- ~~no need to retile, assuming both windows were previously tiled!~~
      M.tile()
   end
end

-- throw window to screen - de-attach and re-attach
M.throwToScreen = function(win, direction)
   win = win or hs.window.frontmostWindow()

   if M.isFloating(win) then
      return
   end

   local directions = {
      next = "next",
      prev = "previous",
   }

   if not directions[direction] then
      log.e("can't throw in direction:", direction)
      return
   end

   local screen = win:screen()
   local screenInDirection = screen[directions[direction]](screen)

   if screenInDirection then
      local _, winSpaceIdx, winIdx, winScreenIdx = M.findTrackedWindow(win)

      if hs.fnutils.some({ winSpaceIdx, winIdx }, function(_)
         return _ == nil
      end) then
         log.e("throwToScreen error", hs.inspect { winSpaceIdx, winIdx })
         return
      end

      -- remove from tiling so we re-tile that window after it was moved
      if cache.spaces[winScreenIdx][winSpaceIdx] then
         table.remove(cache.spaces[winScreenIdx][winSpaceIdx], winIdx)
      else
         log.e("throwToScreen no cache.spaces for space id:", winSpaceIdx)
      end

      -- move window to screen
      win:moveToScreen(screenInDirection)

      -- retile to update layouts
      if hs.window.animationDuration > 0 then
         hs.timer.doAfter(hs.window.animationDuration * 1.2, M.tile)
      else
         M.tile()
      end
   end
end

M.throwToScreenUsingSpaces = function(win, direction)
   win = win or hs.window.frontmostWindow()

   if M.isFloating(win) then
      return
   end

   local directions = {
      next = "next",
      prev = "previous",
   }

   if not directions[direction] then
      log.e("can't throw in direction:", direction)
      return
   end

   local screen = win:screen()
   local screenInDirection = screen[directions[direction]](screen)
   local currentSpaces = getCurrentSpacesByScreen()
   local throwToSpaceId = currentSpaces[screenInDirection:id()]

   if not throwToSpaceId then
      log.e "no space to throw to"
      return
   end

   local _, winSpaceIdx, winIdx, winScreenIdx = M.findTrackedWindow(win)

   if hs.fnutils.some({ winSpaceIdx, winIdx }, function(_)
      return _ == nil
   end) then
      log.e("throwToScreenUsingSpaces error", hs.inspect { winSpaceIdx, winIdx })
      return
   end

   -- remove from tiling so we re-tile that window after it was moved
   if cache.spaces[winScreenIdx][winSpaceIdx] then
      table.remove(cache.spaces[winScreenIdx][winSpaceIdx], winIdx)
   else
      log.e("throwToScreenUsingSpaces no cache.spaces for space id:", winSpaceIdx)
   end

   local newX = screenInDirection:frame().x
   local newY = screenInDirection:frame().y

   spaces.moveWindowToSpace(win:id(), throwToSpaceId)
   win:setTopLeft(newX, newY)

   M.tiling()
end

M.throwToSpaceIdx = function(win, screenIdx, spaceIdx)
   if not win then
      log.e "throwToSpace tried to throw nil window"
      return false
   end

   local targetScreen = screenIdx
   for _, screen in pairs(hs.screen.allScreens()) do
      --[[ log.d(hs.inspect {
         target = targetScreen,
         screen = screenIdx,
         screens = screen,
         name = module.screen[screen:name()],
      }) ]]
      if screen:name() == screenIdx then
         targetScreen = screen
      elseif M.screen[screen:name()] == screenIdx then
         targetScreen = screen
      end
   end
   local spaceId = spaces.layout()[targetScreen:spacesUUID()][spaceIdx]
   local targetScreenFrame = targetScreen:frame()

   if M.isFloating(win) then
      -- adjust frame for new screen offset
      local newX = win:frame().x - win:screen():frame().x + targetScreenFrame.x
      local newY = win:frame().y - win:screen():frame().y + targetScreenFrame.y

      -- move to space
      spaces.moveWindowToSpace(win:id(), spaceId)

      if targetScreen:name() ~= win:screen():name() then
         newX = targetScreenFrame.x
         newY = targetScreenFrame.y

         win:setTopLeft(newX, newY)
      else
         win:setTopLeft(newX, newY)
         spaces.changeToSpace(spaceId, false)
      end
      -- ensure window is visible

      return true
   end

   local _, winSpaceIdx, winIdx, winScreenIdx = M.findTrackedWindow(win)

   if hs.fnutils.some({ winSpaceIdx, winIdx }, function(_)
      return _ == nil
   end) then
      log.e("throwToSpace error", hs.inspect { winSpaceIdx, winIdx })
      return false
   end

   -- remove from tiling so we re-tile that window after it was moved
   if cache.spaces[winScreenIdx][winSpaceIdx] then
      table.remove(cache.spaces[winScreenIdx][winSpaceIdx], winIdx)
   else
      log.e("throwToSpace no cache.spaces for space id:", winSpaceIdx)
   end

   -- move to space
   spaces.moveWindowToSpace(win:id(), spaceId)

   spaces.changeToSpace(spaceId, false)
   -- ensure window is visible
   win:setTopLeft(targetScreenFrame.x, targetScreenFrame.y)

   -- retile when finished
   M.tile()

   return true
end

-- throw window to space, indexed
M.throwToSpace = function(win, spaceId)
   if not win then
      log.e "throwToSpace tried to throw nil window"
      return false
   end

   local targetScreen = getScreenBySpaceId(spaceId)
   local targetScreenFrame = targetScreen:frame()

   if M.isFloating(win) then
      -- adjust frame for new screen offset
      local newX = win:frame().x - win:screen():frame().x + targetScreen:frame().x
      local newY = win:frame().y - win:screen():frame().y + targetScreen:frame().y

      -- move to space
      spaces.moveWindowToSpace(win:id(), spaceId)

      -- ensure window is visible
      win:setTopLeft(newX, newY)

      return true
   end

   local _, winSpaceIdx, winIdx, winScreenIdx = M.findTrackedWindow(win)

   if hs.fnutils.some({ winSpaceIdx, winIdx }, function(_)
      return _ == nil
   end) then
      log.e("throwToSpace error", hs.inspect { winSpaceIdx, winIdx })
      return false
   end

   -- remove from tiling so we re-tile that window after it was moved
   if cache.spaces[winScreenIdx][winSpaceIdx] then
      table.remove(cache.spaces[winScreenIdx][winSpaceIdx], winIdx)
   else
      log.e("throwToSpace no cache.spaces for space id:", winSpaceIdx)
   end

   -- move to space
   spaces.moveWindowToSpace(win:id(), spaceId)

   -- ensure window is visible
   win:setTopLeft(targetScreenFrame.x, targetScreenFrame.y)

   -- retile when finished
   M.tile()

   return true
end

-- check if window is floating
M.isFloating = function(win)
   local trackedWinId, _, _, _ = M.findTrackedWindow(win)
   local isTrackedAsTiling = trackedWinId ~= nil

   if isTrackedAsTiling then
      return false
   end

   local isTrackedAsFloating = hs.fnutils.find(cache.floating, function(floatingWinId)
      return floatingWinId == win:id()
   end)

   -- if window is not floating and not tiling, then default to floating?
   if isTrackedAsFloating == nil and trackedWinId == nil then
      return true
   end

   return isTrackedAsFloating ~= nil
end

-- toggle floating state of window
M.toggleFloat = function(win)
   win = win or hs.window.frontmostWindow()

   if not win then
      return
   end

   if M.isFloating(win) then
      local foundIdx

      for index, floatingWinId in pairs(cache.floating) do
         if not foundIdx then
            if floatingWinId == win:id() then
               foundIdx = index
            end
         end
      end
      local spaceIdx = getSpaceIndex(win)
      local screenIdx = getScreenIndex(win:screen())

      ensureCacheSpaces(screenIdx, spaceIdx)

      table.insert(cache.spaces[screenIdx][spaceIdx], win)
      table.remove(cache.floating, foundIdx)
   else
      local winId, winSpaceIdx, winIdx, winScreenIdx = M.findTrackedWindow(win)

      if cache.spaces[winScreenIdx][winSpaceIdx] then
         table.remove(cache.spaces[winScreenIdx][winSpaceIdx], winIdx)
      else
         log.e("window made floating without previous :space()", winId)
      end

      table.insert(cache.floating, win:id())
   end

   -- update tiling
   M.tile()
end

-- internal function for deciding if window should float when recalculating tiling
local shouldFloat = function(win)
   -- if window is in tiling cache, then it is not floating
   local inTilingCache, _, _, _ = M.findTrackedWindow(win)
   if inTilingCache then
      return false
   end

   -- if window is already tracked as floating, then leave it be
   local isTrackedAsFloating = hs.fnutils.find(cache.floating, function(floatingWinId)
      return floatingWinId == win:id()
   end) ~= nil
   if isTrackedAsFloating then
      return true
   end

   -- otherwise detect if window should be floated/tiled
   return not M.detectTile(win)
end

M.ignore = {
   "imklaunchagent",
   "cn.com.10jqka.iHexinFee",
   "com.surteesstudios.Bartender",
   "com.macitbetter.betterzip.Quick-Look-Extension",
}

-- tile windows - combine caches with current state, and apply layout
M.recache = function()
   -- this allows us to have tabs and do proper tiling!
   local tilingWindows = {}
   local floatingWindows = {}

   local starttime = hs.timer.secondsSinceEpoch()
   -- local allWindows = spaces.allWindowsForSpace(M.getSpaceId())
   -- local allWindows = hs.window.visibleWindows()
   -- local allWindows = hs.window.allWindows()
   local allWindows = getAllWindows()
   local usedTime = hs.timer.secondsSinceEpoch() - starttime
   if usedTime > 0.3 then
      log.d(string.format("recache took %.2fs", usedTime))
   end
   -- local allWindows = cache.filter:getWindows()

   -- log.d(hs.inspect(allWindows))

   hs.fnutils.each(allWindows or {}, function(win)
      -- we don't care about minimized or fullscreen windows
      if win:isMinimized() or win:isFullscreen() then
         return
      end

      -- we also don't care about special windows that have no spaces
      if not win:spaces() or #win:spaces() == 0 then
         return
      end

      if win:subrole() == "AXUnknown" then
         return
      end

      if hs.fnutils.find(M.ignore, function(name)
         return win:application():name() == name
      end) then
         return
      end

      if
         hs.fnutils.find(M.ignore, function(bundleID)
            return win:application():bundleID() == bundleID
         end)
      then
         return
      end

      if shouldFloat(win) then
         table.insert(floatingWindows, win)
      else
         table.insert(tilingWindows, win)
      end
   end)

   -- add new tiling windows to cache
   hs.fnutils.each(tilingWindows, function(win)
      if not win or #win:spaces() == 0 then
         return
      end

      local _screenIdx = getScreenIndex(win:screen())
      local _spaceIdx = getSpaceIndex(win)
      local tmp = ensureCacheSpaces(_screenIdx, _spaceIdx)
      local trackedWinId, trackedSpaceIdx, trackedWinIdx, trackedScreenIdx = M.findTrackedWindow(win)

      if win:id() == cache.main[_screenIdx][_spaceIdx] then
         -- local t = tmp
         -- for index, _win in ipairs(t) do
         -- if _win:id() == cache.main[_screenIdx][_spaceIdx] then
         -- table.remove(tmp, index)
         -- end
         -- end
         -- table.remove(tmp, trackedWinIdx)
         for i = #tmp, 1, -1 do
            if tmp[i]:id() == win:id() then
               table.remove(tmp, i)
            end
         end
         table.insert(tmp, 1, win)
         -- window is "new" if it's not in cache at all, or if it changed space
      elseif not trackedWinId or trackedSpaceIdx ~= _spaceIdx or trackedScreenIdx ~= _screenIdx then
         -- table.insert(tmp, 1, win)
         --[[ log.d(hs.inspect {
            trackedScreenIdx = trackedScreenIdx,
            trackedWinId = trackedWinId,
            trackedSpaceIdx = trackedScreenIdx,
            winid = win:id(),
            winSpaceIdx = _spaceIdx,
            winScreeIdx = _screenIdx,
            winname = win:application():name(),
            wintitle = win:title(),
            screen = win:screen(),
         }) ]]
         table.insert(tmp, win)
         if trackedScreenIdx and trackedSpaceIdx then
            table.remove(cache.spaces[trackedScreenIdx][trackedSpaceIdx], trackedWinIdx)
         end
      end

      cache.spaces[_screenIdx][_spaceIdx] = tmp
   end)
   -- add new windows to floating cache
   hs.fnutils.each(floatingWindows, function(win)
      if not M.isFloating(win) then
         table.insert(cache.floating, win:id())
      end
   end)

   -- clean up floating cache
   --[[ cache.floating = hs.fnutils.filter(cache.floating, function(cacheWinId)
      return hs.fnutils.find(floatingWindows, function(win)
         return cacheWinId == win:id()
      end)
   end) ]]
   --[[ floatingWindows = hs.fnutils.copy(cache.floating)
   cache.floating = {}
   hs.fnutils.each(floatingWindows, function(winId)
      local win = findWindowById(allWindows, winId)
      if win then
         table.insert(cache.floating, win:id())
      end
   end) ]]

   return tilingWindows
end

M.tile = function()
   if cache.timer and not tilingLock then
      cache.timer:stop()
   end
   cache.timer = --hs.timer.doAfter(0.3, M.tiling)
      hs.timer.delayed.new(0.05, M.tiling)
   cache.timer:start()
end

M.tiling = function()
   --[[ if not tilingLock then
      tilingLock = true
   else
      return
   end ]]
   local currentSpaces = getCurrentSpacesIds()

   local tilingWindows = M.recache()
   local starttime = hs.timer.secondsSinceEpoch()
   -- clean up tiling cache
   hs.fnutils.each(currentSpaces, function(spaceId)
      local screen = getScreenBySpaceId(spaceId)
      if not screen then
         return
      end
      local screenIdx = getScreenIndex(screen)
      local spaceIdx = getSpaceIdx(spaceId, screen:spacesUUID())

      if spaceIdx == 0 then
         return
      end

      local spaceWindows = ensureCacheSpaces(screenIdx, spaceIdx)

      local checkDuplicate = function(windows)
         for i = #windows, 1, -1 do
            -- window exists in cache if there's spaceId and windowId match
            local existsOnScreen = hs.fnutils.find(tilingWindows, function(win)
               return win:id() == windows[i]:id() and win:spaces()[1] == spaceId
            end)

            -- window is duplicated (why?) if it's tracked more than once
            -- this shouldn't happen, but helps for now...
            local duplicateIdx = 0

            for j = 1, #windows do
               if windows[i]:id() == windows[j]:id() and i ~= j then
                  duplicateIdx = j
               end
            end

            if duplicateIdx > 0 then
               log.e(
                  "duplicate idx",
                  hs.inspect {
                     i = i,
                     duplicateIdx = duplicateIdx,
                     windows = windows,
                  }
               )
            end

            if not existsOnScreen or duplicateIdx > 0 then
               -- if spaceWindows[i] == win then
               table.remove(spaceWindows, i)
               --[[ if duplicateIdx > 0 then
                  table.remove(spaceWindows, duplicateIdx)
               end ]]
               -- return true
               -- else
               -- end
               -- table.remove(spaceWindows, duplicateIdx)
               -- i = i - 1
            else
               i = i + 1
            end
         end
         return false
      end

      -- while checkDuplicate(spaceWindows) do
      -- end
      checkDuplicate(spaceWindows)

      cache.spaces[screenIdx][spaceIdx] = spaceWindows
   end)
   -- apply layout window-by-window
   local moveToFloat = {}

   hs.fnutils.each(currentSpaces, function(spaceId)
      local screen = getScreenBySpaceId(spaceId)
      local screenIdx = getScreenIndex(screen)
      if not screen then
         return
      end
      local spaceIdx = getSpaceIdx(spaceId, screen:spacesUUID())
      local spaceWindows = ensureCacheSpaces(screenIdx, spaceIdx)

      if spaceIdx == 0 then
         return
      end
      local screenWindows = hs.fnutils.filter(spaceWindows, function(win)
         return win:screen():id() == screen:id()
      end)
      local layoutName = M.getLayout(spaceId)

      if not layoutName or not layouts[layoutName] then
         log.e("layout doesn't exist: " .. layoutName)
      else
         -- log.d(hs.inspect { spaceidx = spaceIdx, screenidx = screenIdx, wins = screenWindows })
         for index, window in pairs(screenWindows) do
            local frame = layouts[layoutName](
               window,
               screenWindows,
               screen,
               index,
               getSpaceOptions(screenIdx, spaceIdx) or DefaultLayoutOptions()
            )

            -- only set frame if returned,
            -- this allows for layout to decide if window should be floating
            if frame then
               window:setFrame(frame)
            else
               table.insert(moveToFloat, window)
            end
         end
      end
   end)
   local usedTime = hs.timer.secondsSinceEpoch() - starttime
   if usedTime > 0.3 then
      log.d(string.format("tiling took %.2fs", usedTime))
   end

   hs.fnutils.each(moveToFloat, function(win)
      local _, spaceIdx, winIdx, screenIdx = M.findTrackedWindow(win)

      table.remove(cache.spaces[screenIdx][spaceIdx], winIdx)
      table.insert(cache.floating, win:id())
   end)
   -- tilingLock = false
   -- log.d(string.format("tiling took %.2fs", hs.timer.secondsSinceEpoch() - starttime))
end

-- tile detection:
-- 1. test tiling.filters if exist
-- 2. check if there's fullscreen button -> yes = tile, no = float
M.detectTile = function(win)
   local app = win:application():name()
   local bundle = win:application():bundleID()
   local role = win:role()
   local subrole = win:subrole()
   local title = win:title()

   if M.filters then
      local foundMatch = hs.fnutils.find(M.filters, function(obj)
         local appMatches = ternary(obj.app ~= nil and app ~= nil, string.match(app, obj.app or ""), true)
         local bundleMatches = false
         if bundle then
            bundleMatches = ternary(obj.bundle ~= nil and bundle ~= nil, string.match(bundle, obj.bundle or ""), true)
         end
         local titleMatches = ternary(obj.title ~= nil and title ~= nil, string.match(title, obj.title or ""), true)
         local roleMatches = ternary(obj.role ~= nil, obj.role == role, true)
         local subroleMatches = ternary(obj.subrole ~= nil, obj.subrole == subrole, true)

         return appMatches and bundleMatches and titleMatches and roleMatches and subroleMatches
      end)

      if foundMatch then
         --[[ if foundMatch.tile and not cache.filter:isAppAllowed(app) then
            cache.filter:allowApp(app)
         end ]]
         return foundMatch.tile
      end
   end

   local shouldTileDefault = hs.axuielement.windowElement(win):isAttributeSettable "AXSize"
   return shouldTileDefault
end

M.detectSpace = function(win)
   local app = win:application():name()
   local bundle = win:application():bundleID()
   local role = win:role()
   local subrole = win:subrole()
   local title = win:title()

   if M.filters then
      local foundMatch = hs.fnutils.find(M.filters, function(obj)
         local appMatches = ternary(obj.app ~= nil and app ~= nil, string.match(app, obj.app or ""), true)
         local bundleMatches = false
         if bundle then
            bundleMatches = ternary(obj.bundle ~= nil and bundle ~= nil, string.match(bundle, obj.bundle or ""), true)
         end
         local titleMatches = ternary(obj.title ~= nil and title ~= nil, string.match(title, obj.title or ""), true)
         local roleMatches = ternary(obj.role ~= nil, obj.role == role, true)
         local subroleMatches = ternary(obj.subrole ~= nil, obj.subrole == subrole, true)

         return appMatches and bundleMatches and titleMatches and roleMatches and subroleMatches
      end)

      if foundMatch then
         local spaceIdx = getSpaceIndex(win)
         local screenIdx = getScreenIndex(win:screen())
         -- log.d(hs.inspect { match = foundMatch, space = spaceIdx, screen = screenIdx })
         if foundMatch.screen ~= screenIdx or foundMatch.space ~= spaceIdx then
            return foundMatch.screen, foundMatch.space
         end
      end
   end
   return nil, nil
end

M.autoThrow = function(_, event, application)
   --[[ log.d(hs.inspect {
      name = name,
      event = event,
      launched = hs.application.watcher.launched,
      watcher = hs.application.watcher,
      app = application,
   }) ]]
   local windows = application:allWindows()
   if event == hs.application.watcher.launched or event == hs.application.watcher.launching then
      for _, win in pairs(windows) do
         local screenIdx, spaceIdx = M.detectSpace(win)
         -- log.d(hs.inspect { name = name, screen = screenIdx, space = spaceIdx })
         if screenIdx and spaceIdx then
            --[[ local screen = hs.fnutils.find(hs.screen.allScreens(), function(s)
               return getScreenIndex(s) == screenIdx
            end)
            if screen:name() ~= win:screen():name() then
               spaces.moveWindowToSpace()
            end ]]
            M.throwToSpaceIdx(win, screenIdx, spaceIdx)
         end
      end
      -- M.tile()
      -- elseif event == hs.application.watcher.activated then
   end
   M.tile()
end

-- mostly for debugging
M.reset = function()
   cache.main = {}
   cache.spaces = {}
   cache.layouts = {}
   cache.floating = {}

   M.tile()
end

local loadSettings = function()
   local jsonTilingCache = hs.settings.get "swm.tilingCache"

   log.d "reading from hs.settings"
   log.d("swm.tilingCache", jsonTilingCache)

   local allWindows = getAllWindowsUsingSpaces()

   if jsonTilingCache then
      local tilingCache = hs.json.decode(jsonTilingCache)
      for k, v in pairs(tilingCache) do
         if hs.fnutils.contains({ "main", "spaces", "layouts", "layoutOptions" }, k) then
            M.cache[k] = {}
            for kk, vv in pairs(v) do
               M.cache[k][kk] = {}
               for kkk, vvv in pairs(vv) do
                  local key = tonumber(kkk)
                  if not key then
                     key = kkk
                  end
                  if k == "spaces" then
                     M.cache[k][kk][key] = {}
                     hs.fnutils.each(vvv, function(winId)
                        local win = findWindowById(allWindows, winId)
                        if win then
                           table.insert(M.cache[k][kk][key], win)
                        end
                     end)
                  elseif k == "layoutOptions" then
                     M.cache[k][kk][key] = hs.fnutils.copy(vvv)
                  else
                     M.cache[k][kk][key] = vvv
                  end
               end
            end
         else
            M.cache[k] = v
         end
      end
   end
end

local saveSettings = function()
   local tilingCache = {
      floating = cache.floating,
      layouts = cache.layouts,
      layoutOptions = cache.layoutOptions,
   }

   for k, v in pairs(cache) do
      if hs.fnutils.contains({ "main", "spaces", "layouts", "layoutOptions" }, k) then
         tilingCache[k] = {}
         for kk, vv in pairs(v) do
            tilingCache[k][kk] = {}
            for key, vvv in pairs(vv) do
               if type(key) == "number" then
                  key = string.format("%d", key)
               end
               if k == "spaces" then
                  tilingCache[k][kk][key] = {}
                  for _, win in pairs(vvv) do
                     table.insert(tilingCache[k][kk][key], win:id())
                  end
               else
                  tilingCache[k][kk][key] = vvv
               end
            end
         end
      end
   end

   local jsonTilingCache = hs.json.encode(tilingCache)
   log.d "storing to hs.settings"
   log.d("swm.tiling", jsonTilingCache)

   hs.settings.set("swm.tilingCache", jsonTilingCache)
end

M.start = function()
   --[[ cache.filter = hs.window.filter.new():setDefaultFilter():setOverrideFilter {
      visible = true, -- only allow visible windows
      -- fullscreen = false, -- ignore fullscreen windows
      currentSpace = true, -- only windows on current space
      allowRoles = { "AXStandardWindow", "AXWindow" },
      -- allowRoles = "*",
   } ]]

   loadSettings()

   M.screenWatcher = hs.screen.watcher.newWithActiveScreen(M.tile)

   cache.appWatcher = hs.application.watcher.new(M.autoThrow)

   -- cache.spaceWatcher = hs.spaces.watcher.new(M.tile)

   -- cache.filter:subscribe({ hs.window.filter.windowMoved, hs.window.windowsChanged }, M.tile)

   -- cache.spaceWatcher:start()

   M.screenWatcher:start()

   cache.appWatcher:start()

   M.tile()
end

M.stop = function()
   -- store cache so we persist layouts between restarts
   saveSettings()

   -- stop filter
   -- cache.filter:unsubscribeAll()

   M.screenWatcher:stop()

   -- cache.spaceWatcher:stop()

   cache.appWatcher:stop()
end

return M
