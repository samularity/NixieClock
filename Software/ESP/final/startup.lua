print('running debug startup')
nixie = dofile("gettime.lc")
nixie.init_nixie()
i = 0
mytimer = tmr.create()
-- enable HV
gpio.mode(5,gpio.OUTPUT)
gpio.write(5,gpio.LOW)


mytimer:alarm(500,tmr.ALARM_AUTO, function (mytimer)

  local c = i
  print(i)

  if (i % 2 == 0) then -- blink or not
    print('dot')
    c = c + 0x10
  else
    print ('no dot')
  end

  if (i % 3 == 0) then
    -- green
    print('green')
    ws2812.write(string.char(255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,255,0,0))
  end
  if ((i+1) % 3 == 0) then
    -- red
    print('red')
    ws2812.write(string.char(0,255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,255,0))
  else
    -- blue
    print('blue')
    ws2812.write(string.char(0,0,255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,255))
  end

  for j = 1, 6 do -- go trough all nixies
    local i_addr = 0x0F + j
    nixie.write_ic(i_addr,c)
    -- print(string.format('writing to %x -> %x',i_addr,c))
  end

  if (i == 9) then
    print("stopping")
    mytimer:stop()
    mytimer:unregister()
  end
  i = i + 1
end)
