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


local i = 0
local address = 0x10

local function refresh_nixie()

  -- smallest address is first second char
  write_ic(address,i)
  -- print(string.format("%x -> %d",address, i) )
  i = i + 1
  if i > 6 then
    i = 0
  end

end

local function schedule(tid)
  tmr.alarm(tid or 6, 1000, tmr.ALARM_AUTO,function() refresh_nixie() end)
end


return {write_ic=write_ic,init_nixie=init_nixie,sync=sync_time,schedule=schedule}
