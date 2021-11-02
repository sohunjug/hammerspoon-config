local urlApi = "https://tianqiapi.com/api?version="
local auth = "&appid=95116734&appsecret=S5bhUM3T"
local cache = {}
local M = { cache = cache }
M.menubar = hs.menubar.new()
M.menuData = {}

M.citys = { "101280301", "101280601" }

local weaEmoji = {
   lei = "⛈",
   qing = "☀️",
   shachen = "😷",
   wu = "🌫",
   xue = "❄️",
   yu = "🌧",
   yujiaxue = "🌨",
   yun = "☁️",
   zhenyu = "🌧",
   yin = "⛅️",
   default = "",
}

function M:updateMenubar()
   self.menubar:setTooltip "Weather Info"
   local menu = {}
   for _, item in pairs(self.menuData) do
      table.insert(menu, item)
   end
   self.menubar:setMenu(menu)
end

function M:getWeatherFromIP(ip)
   if ip == nil then
      return
   end
   hs.http.doAsyncRequest(urlApi .. "v6" .. auth .. "&ip=" .. ip, "GET", nil, nil, function(code, body, _)
      if code ~= 200 then
         print("get weather error:" .. code)
         return
      end
      local msg = hs.json.decode(body)
      local city = msg.city
      self.menubar:setTitle(weaEmoji[msg.wea_img])
      local titlestr = string.format(
         "%s %s 🌡️%s 💧%s 💨%s 🌬%s %s",
         city,
         weaEmoji[msg.wea_img],
         msg.tem,
         msg.humidity,
         msg.air,
         msg.win_speed,
         msg.wea
      )
      local item = { title = titlestr }
      hs.http.doAsyncRequest(urlApi .. "v1" .. auth .. "&ip=" .. ip, "GET", nil, nil, function(scode, sbody, _)
         if scode ~= 200 then
            print("get weather error:" .. scode)
            return
         end
         local smsg = hs.json.decode(sbody).data
         local menu = {}
         for _, data in pairs(smsg) do
            local day = string.format(
               "%14s %s 🌡️%s 🌬%s %s",
               data.day,
               weaEmoji[data.wea_img],
               data.tem,
               data.win_speed,
               data.wea
            )
            local smenu = {}
            for _, sdata in pairs(data.hours) do
               local hour = string.format(
                  "%14s %s 🌬%s %s %s",
                  sdata.day,
                  sdata.tem,
                  sdata.win,
                  sdata.win_speed,
                  sdata.wea
               )
               local hitem = { title = hour }
               table.insert(smenu, hitem)
            end
            local sitem = { title = day, menu = smenu }
            table.insert(menu, sitem)
         end
         item = { title = titlestr, menu = menu }
         self.menuData[city] = item
         self:updateMenubar()
      end)
      self.menuData[city] = item
      self:updateMenubar()
   end)
end

function M:getWeatherFromName(name)
   if type(name) ~= "string" then
      return
   end
   hs.http.doAsyncRequest(urlApi .. "v6" .. auth .. "&cityid=" .. name, "GET", nil, nil, function(code, body, htable)
      if code ~= 200 then
         print("get " .. name .. " weather error:" .. code)
         print(urlApi .. "v61" .. auth .. "&cityid=" .. name)
         print(body)
         print(hs.inspect(htable))
         return
      end
      local msg = hs.json.decode(body)
      local city = msg.city
      self.menubar:setTitle(weaEmoji[msg.wea_img])
      local titlestr = string.format(
         "%s %s 🌡️%s 💧%s 💨%s 🌬%s %s",
         city,
         weaEmoji[msg.wea_img],
         msg.tem,
         msg.humidity,
         msg.air,
         msg.win_speed,
         msg.wea
      )
      local item = { title = titlestr }
      hs.http.doAsyncRequest(urlApi .. "v1" .. auth .. "&cityid=" .. name, "GET", nil, nil, function(scode, sbody, _)
         if scode ~= 200 then
            print("get weather error:" .. scode)
            return
         end
         local smsg = hs.json.decode(sbody).data
         local menu = {}
         for _, data in pairs(smsg) do
            local day = string.format(
               "%14s %s 🌡️%s 🌬%s %s",
               data.day,
               weaEmoji[data.wea_img],
               data.tem,
               data.win_speed,
               data.wea
            )
            local smenu = {}
            for _, sdata in pairs(data.hours) do
               local hour = string.format(
                  "%14s %s 🌬%s %s %s",
                  sdata.day,
                  sdata.tem,
                  sdata.win,
                  sdata.win_speed,
                  sdata.wea
               )
               local hitem = { title = hour }
               table.insert(smenu, hitem)
            end
            local sitem = { title = day, menu = smenu }
            table.insert(menu, sitem)
         end
         item = { title = titlestr, menu = menu }
         self.menuData[city] = item
         self:updateMenubar()
      end)
      self.menuData[city] = item
      self:updateMenubar()
   end)
end

function M:getPublicIP()
   hs.http.doAsyncRequest("http://ip-api.com/json/?lang=zh-CN", "GET", nil, nil, function(code, body, _)
      if code ~= 200 then
         print("get ip error:" .. code)
         return
      end
      local rawjson = hs.json.decode(body)
      self:getWeatherFromIP(rawjson.query)
   end)
end

function M:refreshWeather()
   self.menuData = {}
   self:getPublicIP()
   for _, city in pairs(self.citys) do
      self:getWeatherFromName(city)
   end
end

M.start = function()
   M.menubar:setTitle "⌛"
   M:refreshWeather()
   M:updateMenubar()
   cache.timer = hs.timer.doEvery(600, hs.fnutils.partial(M.refreshWeather, M))
   cache.timer:start()
end

M.stop = function()
   cache.timer:stop()
end

return M
