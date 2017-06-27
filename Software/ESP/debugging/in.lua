-- for debugging, do not call it init.lua
blink = true


-- HV enable
gpio.mode(5,gpio.OUTPUT)
gpio.write(5,gpio.LOW)


-- init
ws2812.init()
tmr.alarm(0,1000, 1, function()
 if blink then
  ws2812.write(string.char(0,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
 else
   ws2812.write(string.char(255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
 end
 blink = not blink
end)


dofile("gettime.lua").schedule()
