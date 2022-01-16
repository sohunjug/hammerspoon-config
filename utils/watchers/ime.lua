local cache = {}
local M = { cache = cache }

local function Chinese()
   return "com.sogou.inputmethod.sogou.pinyin"
   -- hs.keycodes.currentSourceID("com.sogou.inputmethod.sogou.pinyin")
   -- hs.keycodes.currentSourceID("im.rime.inputmethod.Squirrel.Rime")
   -- hs.keycodes.currentSourceID("com.apple.inputmethod.SCIM.ITABC")
   -- return "com.apple.inputmethod.SCIM.ITABC"
end

local function English()
   return "com.apple.keylayout.ABC"
end

-- app to expected ime config
M.app2Ime = {
   ["/Applications/iTerm.app"] = English(),
   ["/Applications/kitty.app"] = English(),
   ["/Applications/Alfred 4.app"] = English(),
   ["/Applications/Alacritty.app"] = English(),
   ["/Applications/Xcode.app"] = English(),
   ["/Applications/Xcode-beta.app"] = English(),
   ["/Applications/Google Chrome.app"] = English(),
   ["/Applications/Google Chrome Canary.app"] = Chinese(),
   ["/System/Library/CoreServices/Finder.app"] = English(),
   ["/Applications/DingTalk.app"] = Chinese(),
   ["/Applications/Kindle.app"] = English(),
   ["/Applications/NeteaseMusic.app"] = Chinese(),
   ["/Applications/Telegram Desktop.app"] = Chinese(),
   ["/Applications/微信.app"] = Chinese(),
   ["/Applications/钉钉.app"] = Chinese(),
   ["/Applications/WeChat.app"] = Chinese(),
   ["/Applications/Microsoft Edge.app"] = Chinese(),
   ["/Applications/Microsoft Edge Beta.app"] = Chinese(),
   ["/Applications/QQ.app"] = Chinese(),
   ["/Applications/QQ体验版.app"] = Chinese(),
   ["/Applications/VimR.app"] = English(),
   ["/Applications/MacVim.app"] = English(),
   ["/Applications/System Preferences.app"] = English(),
   ["/Applications/Dash.app"] = English(),
   ["/Applications/MindNode.app"] = Chinese(),
   ["/Applications/Preview.app"] = Chinese(),
   ["/Applications/Safari.app"] = Chinese(),
   ["/Applications/wechatwebdevtools.app"] = English(),
   ["/Applications/Sketch.app"] = English(),
   ["/Applications/uTools.app"] = English(),
}

M.app2flag = {}

local function updateFocusAppInputMethod()
   local win = hs.window.frontmostWindow()
   if not win then
      return
   end
   local app = win:application()
   if app == nil then
      return
   end
   local focusAppPath = app:path()
   local choose = M.app2Ime[focusAppPath] and M.app2Ime[focusAppPath] or English()
   hs.keycodes.currentSourceID(choose)
end

function M.save()
   local focusAppPath = hs.window.frontmostWindow():application():path()
   local flag = M.app2flag[focusAppPath] and M.app2flag[focusAppPath] or true
   if flag == true then
      M.app2Ime[focusAppPath] = hs.keycodes.currentSourceID()
   end
   print(M.app2Ime[focusAppPath])
end

-- helper hotkey to figure out the app path and name of current focused window
function M.echoInfo()
   local source = M.app2Ime[hs.window.focusedWindow():application():path()]
   local language = source and source or English()
   hs.alert.show(
      "App path:        "
         .. hs.window.focusedWindow():application():path()
         .. "\nApp name:      "
         .. hs.window.focusedWindow():application():name()
         .. "\nBundleID:      "
         .. hs.window.focusedWindow():application():bundleID()
         .. "\nIM source id:  "
         .. hs.keycodes.currentSourceID()
         .. "\n"
         .. "IM name:         "
         .. language
   )
end

function M.chooseFlag()
   local focusAppPath = hs.window.frontmostWindow():application():path()
   local flag = M.app2flag[focusAppPath] and M.app2flag[focusAppPath] or true
   M.app2flag[focusAppPath] = flag and false or true
end

-- Handle cursor focus and application's screen manage.
-- local function applicationWatcher(appName, eventType, appObject)
local function applicationWatcher(_, eventType, _)
   if eventType == hs.application.watcher.activated then
      updateFocusAppInputMethod()
   end
end

M.appWatcher = hs.application.watcher.new(applicationWatcher)

function M.start()
   M.appWatcher:start()
   hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "i", M.echoInfo)
end

function M.stop()
   M.appWatcher:stop()
end

return M
