
ws2812.init()


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

