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
local id = 0
local sda = 1
local scl = 2
i2c.setup(id, sda, scl, i2c.SLOW)


local i = 0 -- second
local j = 0 -- second tens
local dot = 0
local address = 0x10
local function refresh_nixie()

  -- smallest address is first second char
  write_ic(address,i + dot)
  write_ic(address+1,j)
  -- write_ic(address+2,i + dot)
  -- write_ic(address+3,i + dot)
  -- write_ic(address+4,i + dot)
  -- write_ic(address+5,i + dot)
  -- write_ic(address+6,i + dot)
  -- write_ic(address+7,i + dot)
  -- write_ic(address+8,i + dot)

  if dot == 16 then dot = 0
  else dot = 16 end

  -- print(string.format("%x -> %d",address, i) )
  i = i + 1
  if i > 9 then
    i = 0
    j = j + 1
  end
  if j > 9 then
    j = 0
  end

end

local function schedule(tid)
  tmr.alarm(tid or 6, 1000, tmr.ALARM_AUTO,function() refresh_nixie() end)
end


return {write_ic=write_ic,init_nixie=init_nixie,sync=sync_time,schedule=schedule}
