tmr.alarm(0, 5000, tmr.ALARM_SINGLE, function() 
    print("Start running")
    dofile("i2c.lua")
end) 