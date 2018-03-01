-- ATTENTION: unix2date only works correctly with INTEGER nodemcu firmware!

-- origin timzeone berlin (not dst)
local otz = 1
local tz = otz
local hour = 0
local min = 0
local seconds = 0
local refresh_delay = 1000
local id = 0
local disp = nil

-- we retrieve our current timezone offset
-- local ntpserver = "time.nist.gov"
local ntpserver = "pool.ntp.org"

local function write_ic(dev_addr,value)
    -- print(string.format("[write_ic] addr: %x  value: %x",dev_addr,value))
    i2c.start(id)
    i2c.address(id, dev_addr, i2c.TRANSMITTER)
    i2c.write(id, value)
    i2c.stop(id)
end

local function init_nixie()
  local sda = 1
  local scl = 2
  i2c.setup(id, sda, scl, i2c.SLOW)
end


local function sync_time()
  print("syncing time")
  sntp.sync(ntpserver, function ()
    local tm = rtctime.epoch2cal(rtctime.get())
    print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
  end)
end


-- Central Europe (Germany):
--   Begin DST: last sunday in march
--   End   DST: last sunday in october
local function isDST(day,month,dow)
  if (month < 3 or month > 10 ) then return false end
  if (month > 3 and month < 10 ) then return true end
  local lastSunday = day - (dow - 1)
  -- 31 days in march and october:
  --  last sunday must be between 31 and 24
  if (month == 3) then return (lastSunday >= 25) end
  return (lastSunday < 25)
end

-- get the latest time every day or at restart
local function refresh_data()
  local tm = rtctime.epoch2cal(rtctime.get())

  tz = isDST(tm["day"],tm["mon"],tm["wday"]) and (otz + 1) or otz
  local tm = rtctime.epoch2cal(rtctime.get() + (3600 * tz))

  hour,min,seconds = tm["hour"],tm["min"],tm["sec"]

end

local function refresh_nixie()
  -- print(string.format("%x -> %d",seconds_addr, seconds) )

  -- smallest address is first second char
  local r = string.format("%02d%02d%02d",hour,min,seconds):reverse()
  -- print(r)
  for i = 1, #r do
  -- for i = 1, 1 do
    local c = string.byte(r:sub(i,i)) - 48 -- - "0"
    if seconds %2 == 0 then
      c = c + 0x10
    end
    -- local i_addr = i
    -- first part Seconds = 0x10
    -- second part Seconds = 0x11
    -- and so on

    local i_addr = 0x0F + i
    write_ic(i_addr,c)
    -- tmr.delay(50000)
  end

end

local function show()
  refresh_data()

  refresh_nixie()
end

init_nixie()

local function schedule(tid,t2id)
  sync_time()
  tmr.alarm(tid or 6, refresh_delay, tmr.ALARM_AUTO,function() show() end)

  cron.schedule("0 4 * * *", function(e)
    sync_time()
  end)
end


return {init_display=init_display,init_nixie=init_nixie,sync=sync_time,show=show,schedule=schedule}
