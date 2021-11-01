local cache = {}
local M = { cache = cache }
-- local log = hs.logger.new("network", "debug")
-- obj.__index = obj

M.start = function()
   M.menubar = hs.menubar.new()
   M.config()
   M.network()
   if cache.timer then
      cache.timer:stop()
      cache.timer = nil
   end
   cache.timer = hs.timer.doEvery(1, M.task)
   cache.timer:start()
end

M.stop = function()
   cache.timer:stop()
end

M.task = function()
   hs.task.new(
      "/usr/bin/sudo",
      M.network_data,
      { "/usr/bin/powermetrics", "-f", "plist", "-i", "500", "-n", "1", "-s", "network" }
   ):start()
end

function M.network_data(_, out, _)
   local data = hs.plist.readString(out)
   -- log.d(hs.inspect(data))
   local ib = data.network.ibytes
   local ob = data.network.obytes
   if ib / 1024 > 1024 then
      M.kbin = string.format("%6.2f", ib / 1024 / 1024) .. " M"
   else
      M.kbin = string.format("%6.2f", ib / 1024) .. " K"
   end
   if ob / 1024 > 1024 then
      M.kbout = string.format("%6.2f", ob / 1024 / 1024) .. " M"
   else
      M.kbout = string.format("%6.2f", ob / 1024) .. " K"
   end
   M.color = "#000000"
   M.size = 9
   if M.darkmode then
      M.color = "#FFFFFF"
   end
   local disp_str = "⥄ " .. M.kbout .. "\n"
   local first_len = #disp_str
   disp_str = disp_str .. "⥂ " .. M.kbin
   M.disp_str = hs.styledtext.new {
      disp_str,
      {
         starts = 1,
         ends = #disp_str,
         attributes = {
            font = { size = M.size },
            ligature = 0,
            baselineOffset = -22,
            paragraphStyle = {
               -- maximumLineHeight = 28,
               tighteningFactorForTruncation = 0,
               AllowSteeringForTruncation = false,
            },
         },
      },
      {
         starts = 1,
         ends = 3,
         attributes = {
            color = { red = 1 },
            font = { size = M.size },
            ligature = 0,
            baselineOffset = -22,
            paragraphStyle = {
               -- maximumLineHeight = 28,
               tighteningFactorForTruncation = 0,
               AllowSteeringForTruncation = false,
            },
            -- ligature = 0,
            -- paragraphStyle = { lineHeightMultiple = 1 },
         },
      },
      {
         starts = first_len,
         ends = first_len + 3,
         attributes = {
            color = { blue = 1 },
            font = { size = M.size },
            ligature = 0,
            baselineOffset = -22,
            paragraphStyle = {
               -- maximumLineHeight = 8,
               tighteningFactorForTruncation = 0,
               AllowSteeringForTruncation = false,
            },
            -- ligature = 0,
            -- paragraphStyle = { lineHeightMultiple = 1 },
         },
      },
   }
   -- log.d(hs.inspect(M.disp_str:asTable()))
   -- hs.console.printStyledtext(obj.disp_str)
   -- for i, v in pairs(obj.disp_str:asTable()) do print(i, v) end
   -- hs.inspect(obj.disp_str:asTable())

   -- if obj.darkmode then
   --   obj.disp_str = hs.styledtext.new(disp_str, {
   --     font = {size = 9.1, color = {hex = "#FFFFFF"}},
   --   })
   -- else
   --   obj.disp_str = hs.styledtext.new(disp_str, {
   --     font = {size = 9.1, color = {hex = "#000000"}},
   --   })
   -- end
   -- print(obj.menubar.network:frame())
   M.menubar:setTitle(M.disp_str)
end

function M.config()
   M.darkmode =
      hs.osascript.applescript 'tell application "System Events"\nreturn dark mode of appearance preferences\nend tell'
end

function M.network()
   M.interface = hs.network.primaryInterfaces()
   local menuitems_table = {}
   if M.interface then
      -- Inspect active interface and create menuitems
      local interface_detail = hs.network.interfaceDetails(M.interface)
      if interface_detail.AirPort then
         local ssid = interface_detail.AirPort.SSID
         table.insert(menuitems_table, {
            title = hs.styledtext.new {
               "SSID: " .. ssid,
               { starts = 1, ends = 6, attributes = { color = { red = 1 } } },
            },
            tooltip = "Copy SSID to clipboard",
            fn = function()
               hs.pasteboard.setContents(ssid)
            end,
         })
      end
      local code, pubaddr = hs.http.doRequest("https://ipecho.net/plain", "GET")
      if code == 200 then
         table.insert(menuitems_table, {
            title = hs.styledtext.new {
               "Pulbic Addr: " .. pubaddr,
               { starts = 1, ends = 13, attributes = { color = { green = 1 } } },
            },
            tooltip = "Copy Public Address to clipboard",
            fn = function()
               hs.pasteboard.setContents(pubaddr)
            end,
         })
      end
      if interface_detail.IPv4 then
         local ipv4 = interface_detail.IPv4.Addresses[1]
         table.insert(menuitems_table, {
            title = "IPv4: " .. ipv4,
            tooltip = "Copy IPv4 to clipboard",
            fn = function()
               hs.pasteboard.setContents(ipv4)
            end,
         })
      end
      if interface_detail.IPv6 then
         local ipv6 = interface_detail.IPv6.Addresses[1]
         table.insert(menuitems_table, {
            title = "IPv6: " .. ipv6,
            tooltip = "Copy IPv6 to clipboard",
            fn = function()
               hs.pasteboard.setContents(ipv6)
            end,
         })
      end
      local macaddr = hs.execute("ifconfig " .. M.interface .. " | grep ether | awk '{print $2}'")
      table.insert(menuitems_table, {
         title = "MAC Addr: " .. macaddr,
         tooltip = "Copy MAC Address to clipboard",
         fn = function()
            hs.pasteboard.setContents(macaddr)
         end,
      })
      -- Start watching the netspeed delta
      -- M.instr = "netstat -ibn | grep -e " .. M.interface .. " -m 1 | awk '{print $7}'"
      -- M.outstr = "netstat -ibn | grep -e " .. M.interface .. " -m 1 | awk '{print $10}'"

      -- M.network_command = "sudo powermetrics -f plist -i 200 -n 1 -s network"
      -- M.data = hs.execute(M.instr)
   end
   table.insert(menuitems_table, {
      title = hs.styledtext.new {
         "Rescan Network Interfaces",
         { starts = 1, ends = 25, attributes = { color = { blue = 1 } } },
      },
      fn = function()
         M.network()
      end,
   })
   M.menubar:setTitle "⚠︎"
   M.menubar:setMenu(menuitems_table)
end

return M
