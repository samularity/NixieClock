busid = 0  -- I2C Bus ID. Always zero
sda = 1
scl = 2

-- Writes to the pcf8574
function write_reg(dev_addr, value)
     i2c.start(busid)
     i2c.address(busid, dev_addr, i2c.TRANSMITTER)
     i2c.write(busid,value)
     i2c.stop(busid)
end




-- Seting up the I2C bus.
i2c.setup(busid,sda,scl,i2c.SLOW)

addr=0x20  -- the I2C address of our device (0x20 to 0x27)
value = 0x0

function i2c_write()
	value=value+1
	if value > 12 then
		value =0
    end
    print (value)
	write_reg(addr, value)	
end


tmr.alarm(2, 100, 1, i2c_write )
