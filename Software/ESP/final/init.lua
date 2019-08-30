
ws2812.init()

dofile('startup.lc')

print('delayed startup')
mytimer = tmr.create()
-- delay startup for 5 seconds
mytimer:register(5000,tmr.ALARM_SINGLE, function ()
  dofile('wifi.lc')(
    function ()
      -- HV enable
      gpio.mode(5,gpio.OUTPUT)
      gpio.write(5,gpio.LOW)
      print("beginning to fade rgb-leds")
      dofile("fadeleds.lc")
      print("scheduling gettime")
      dofile("gettime.lc").schedule()
    end,
    function()
      print("cannot connect to wifi")
      node.restore()
      node.restart()

    end)
end)
mytimer:start()
