-- global stuff
require("console").init()
require("overrides").init()

-- ensure IPC is there
hs.ipc.cliInstall()

-- no animations
hs.window.animationDuration = 0.0

-- hints
hs.expose.ui.showThumbnails = true
hs.expose.ui.includeOtherSpaces = false
hs.expose.ui.includeNonVisible = false
hs.expose.ui.showTitles = true
hs.expose.ui.onlyActiveApplication = false
hs.expose.ui.fitWindowsInBackground = true
-- hs.hints.fontName = "FiraCode"
hs.hints.fontSize = 22
hs.hints.hintChars = { "A", "S", "D", "F", "J", "K", "L", "Q", "W", "E", "R", "Z", "X", "C" }
hs.hints.iconAlpha = 0.5
hs.hints.showTitleThresh = 0

-- hs.window.filter.allowedWindowRoles = { AXStandardWindow = true, AXDialog = true }
-- hs.window.filter.forceRefreshOnSpaceChange = true

-- lower logging level for hotkeys
require("hs.hotkey").setLogLevel "warning"

local modules = { "bindings", "controlplane", "watchables", "watchers", "wm", "menubar" }
-- global config
_G.S_HS_CONFIG = {
   apps = {
      terms = { "Kitty", "iTerm2", "Termianl", "终端" },
      nvim = { "Alacritty" },
      browsers = { "Google Chrome", "Google Chrome Canary", "Safari" },
   },

   wm = {
      defaultDisplayLayouts = {
         ["Color LCD"] = "monocle",
         ["Built-in Retina Display"] = "monocle",
         ["B2431M"] = "main-work",
         ["LU28R55"] = "main-work",
      },

      displayLayouts = {
         ["Color LCD"] = { "monocle", "main-work" },
         ["Built-in Retina Display"] = { "monocle", "main-work" },
         ["B2431M"] = { "main-center", "main-work", "tab-right", "monocle", "gp-vertical" },
         ["LU28R55"] = { "main-center", "main-work", "tab-right", "monocle", "gp-vertical" },
      },
   },

   window = {
      highlightBorder = true,
      highlightMouse = true,
      historyLimit = 0,
   },

   network = {
      home = "Ting",
   },

   homebridge = {
      studioSpeakers = { aid = 10, iid = 11, name = "Studio Speakers" },
      studioLights = { aid = 9, iid = 11, name = "Studio Lights" },
      tvLights = { aid = 6, iid = 11, name = "TV Lights" },
   },
}

local config = {}

hs.fnutils.each(modules, function(module)
   config[module] = {}
end)
-- controlplane
config.controlplane.enabled = {}

-- watchers
config.watchers.enabled = { "ime", "autoborder" }

config.menubar.enabled = { "space" }
-- config.watchers.enabled = {}

-- bindings
config.bindings.enabled = {
   "ask-before-quit",
   -- "block-hide",
   -- "ctrl-esc",
   "focus",
   "grid",
   "global",
   "tiling",
   -- "term-ctrl-i",
   -- "vi-input",
   -- "viscosity",
}

hs.fnutils.each(modules, function(module)
   if config[module].enabled ~= nil then
      hs.fnutils.each(config[module].enabled, function(submodule)
         config[module][submodule] = {}
      end)
   end
end)

config.bindings["ask-before-quit"].askBeforeQuitApps = S_HS_CONFIG.apps.browsers
-- config.watchers.urlevent.urlPreference = S_HS_CONFIG.apps.browsers
config.bindings.global.apps = S_HS_CONFIG.apps
-- start/stop modules
local mods = {}

hs.fnutils.each(modules, function(module)
   local mod = require("utils." .. module)
   if mod then
      mod.start(config[module])
      mods[module] = mod
   end
end)

-- stop modules on shutdown
hs.shutdownCallback = function()
   hs.fnutils.each(modules, function(module)
      local mod = mods[module]
      if mod then
         mod.stop()
      end
   end)
end
