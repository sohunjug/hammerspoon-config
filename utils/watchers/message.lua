local cache = {}

local M = { cache = cache }

M.update = function()
   M.show(cache.text)
end

M.show = function(text)
   if not text then
      text = cache.text
   end
   local mainScreen = hs.screen.mainScreen()
   local mainRes = mainScreen:fullFrame()
   if not cache.canvas then
      cache.canvas = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 }):show()
   end
   cache.canvas[1] = {
      type = "text",
      text = "",
      textFont = "Impact",
      textSize = 10,
      textColor = { hex = "#1891C3" },
      textAlignment = "left",
   }
   cache.canvas:frame {
      x = (mainRes.w - 500),
      y = 151,
      w = 500,
      h = 230,
   }
   -- print(hs.inspect(text))
   cache.canvas[1].text = text
   cache.canvas:show()
   --[[ hs.timer.doAfter(30, function()
      cache.canvas:hide()
   end) ]]
end

M.getMessage = function()
   hs.http.doAsyncRequest(
      "https://www.ems.com.cn/apple/getMailNoRoutes",
      "POST",
      "mailNum=EZ690868955CN",
      nil,
      function(scode, sbody, _)
         if scode ~= 200 then
            print("get weather error:" .. scode)
            return
         end
         local msg = hs.json.decode(sbody).trails[1]
         local data = ""
         for _, item in pairs(msg) do
            data = string.format("%s%s   %s\n", data, item.optime, item.processingInstructions)
         end
         cache.text = data
         M.show(data)
      end
   )
end

M.start = function()
   M.getMessage()
   cache.timer = hs.timer.doEvery(30, M.getMessage)
   cache.timer:start()

   cache.spaceWatcher = hs.spaces.watcher.new(M.update)
   cache.spaceWatcher:start()
end

M.stop = function()
   cache.timer:stop()

   cache.spaceWatcher:stop()
end

return M
