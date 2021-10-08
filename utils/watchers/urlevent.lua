-- local template = require "ext.template"
local module = {}

-- watch for http and https events and open in currently running browser instead of default one
-- click with 'cmd' to open in background, otherwise opens with focus
module.start = function(_)
   hs.urlevent.setDefaultHandler "http"

   hs.urlevent.httpCallback = function(_, _, _, fullURL)
      -- local modifiers = hs.eventtap.checkKeyboardModifiers()
      -- local shouldFocusBrowser = not modifiers["cmd"]

      --[[ local runningBrowser = hs.fnutils.find(config.urlPreference, function(browserName)
         return hs.application.get(browserName) ~= nil
      end) ]]

      -- local browserName = runningBrowser or config.urlPreference[1]
      -- local currentApp = hs.application:frontmostApplication()

      -- hs.applescript.applescript(template(
      --[[
      -- tell application "{APP_NAME}"
      -- {ACTIVATE}
      -- open location "{URL}"
      -- end tell
      ]]
      -- ,{
      -- APP_NAME = browserName,
      -- URL = fullURL,
      -- ACTIVATE = shouldFocusBrowser and "activate" or "", -- 'activate' brings to front if cmd is clicked
      -- }
      -- ))

      local isAtHome = hs.wifi.currentNetwork() == S_HS_CONFIG.network.home.wifi
      local isAtWork = hs.wifi.currentNetwork() == S_HS_CONFIG.network.work.wifi

      local handler = hs.urlevent.getDefaultHandler "http"

      if isAtHome and handler ~= S_HS_CONFIG.network.home.browser then
         hs.urlevent.openURLWithBundle(fullURL, S_HS_CONFIG.network.home.browser)
      elseif isAtWork and handler ~= S_HS_CONFIG.network.work.browser then
         hs.urlevent.openURLWithBundle(fullURL, S_HS_CONFIG.network.work.browser)
      elseif not isAtWork and not isAtHome then
         hs.urlevent.openURLWithBundle(fullURL, "com.apple.Safari")
      end
      -- focus back the current app
      -- if not shouldFocusBrowser and not currentApp:isFrontmost() then
      -- currentApp:activate()
      -- end
   end
end

module.stop = function()
   hs.urlevent.httpCallback = nil
end

return module
