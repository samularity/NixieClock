-- ATTENTION: unix2date only works correctly with INTEGER nodemcu firmware!

-- origin timzeone berlin (not dst)
local otz = 1
local tz = otz
local hour = 0
local min = 0
local seconds = 0
local year = 1970
local month = 1
local day = 1

local id = 0
local disp = nil

-- we retrieve our current timezone offset
-- local ntpserver = "time.nist.gov"
local ntpserver = "pool.ntp.org"

local function write_ic(dev_addr,value)
    i2c.start(id)
    -- print("sending to "..dev_addr.." value "..value)
    i2c.address(id, dev_addr, i2c.TRANSMITTER)
    i2c.write(id, value)
    i2c.stop(id)
end

local function init_nixie()
  local sda = 3
  local scl = 4
  i2c.setup(id, sda, scl, i2c.SLOW)
end

local function init_display(soft)
  -- print("init display")
  local sda = 1
  local scl = 2
  local sla = 0x3c
  i2c.setup(0, sda, scl, i2c.SLOW)
  if not soft then
    disp = u8g.ssd1306_128x64_i2c(sla)
    disp:setFont(u8g.font_6x10)
  end
end


local function draw()
  disp:drawStr(0,10, "--===Nixie Clock===--")
  disp:drawStr(0,25,string.format("%d-%02d-%02d   %02d:%02d:%02d",year,month,day,hour,min,seconds))
  -- disp:drawStr(0,35,string.format(,))
  disp:drawStr(0,58,string.format("(UTC%s%d)    DST: %s",
    (tz > 0) and "+" or "", tz,
    (otz == tz) and "false" or "true"))
end


local function sync_time()
  print("syncing time")
  -- sntp.sync(ntpserver)
end


-- Central Europe (Germany):
--   Begin DST: last sunday in march
--   End   DST: last sunday in october
local function isDST(day,month,dow)
  if (month < 3 or month > 10 ) then return false end
  if (month > 3 and month < 10 ) then return true end
  lastSunday = day - dow
  -- 31 days in march and october:
  --  last sunday must be between 31 and 24
  if (month == 3) then return (lastSunday >= 25) end
  return (lastSunday < 25)
end

-- return h, m, s, Y, M, D, W (0-sun, 6-sat)
local function unix2date(t)
    local jd, f, e, h, y, m, d
    jd = t / 86400 + 2440588
    f = jd + 1401 + (((4 * jd + 274277) / 146097) * 3) / 4 - 38
    e = 4 * f + 3
    h = 5 * ((e % 1461) / 4) + 2
    d = (h % 153) / 5 + 1
    m = (h / 153 + 2) % 12 + 1
    y = e / 1461 - 4716 + (14 - m) / 12
    return (t%86400)/3600, (t%3600)/60, t%60, y, m, d, (jd+8)%7
end

-- get the latest time every day or at restart
local function refresh_data()
  local sec,usec = rtctime.get()
  local _,_,_,_,m,d,dow = unix2date(sec)

  tz = isDST(d,m,dow) and (otz + 1) or otz

  -- hour,min,seconds,year,month,day,_ = unix2date(sec + (tz * 3600))
  hour = hour + 1
  if hour > 12 then
    hour = 1
  end
  min = min + 1
  if min > 60 then
    min = 0
  end
  seconds = seconds + 1
  if seconds > 60 then
    seconds = 0
  end
end

local function refresh_nixie()
  -- print(string.format("%x -> %d",seconds_addr, seconds) )

  -- smallest address is first second char
  local r = string.format("%02d%02d%02d",hour,min,seconds):reverse()
  for i = 1, #r do
  -- for i = 1, 1 do
    local c = string.byte(r:sub(i,i)) - 48 -- - "0"
    if seconds %2 == 0 then
      c = c + 0x10
    end
    -- local i_addr = i
    local i_addr = 0x0F + i
    write_ic(i_addr,c)
    -- tmr.delay(50000)
  end

end

local function show()
  refresh_data()

  -- display code
  -- init_display(disp)
  -- disp:firstPage()
  -- repeat draw()
  -- until disp:nextPage() == false

  init_nixie()
  refresh_nixie()
end

local function schedule(tid)
  sync_time()
  tmr.alarm(tid or 6, 1000, tmr.ALARM_AUTO,function() show() end)
end


return {init_display=init_display,init_nixie=init_nixie,sync=sync_time,show=show,schedule=schedule}
