dofile('wifi.lua')(
  function ()
    -- HV enable
    gpio.mode(5,gpio.OUTPUT)
    gpio.write(5,gpio.LOW)
    print("beginning to fade rgb-leds")
    dofile("fadeleds.lua")
    print("scheduling gettime")
    dofile("gettime.lua").schedule()
  end,
  function()
    print("cannot connect to wifi")
    node.restore()
    node.restart()

  end)

