-- HV enable
gpio.mode(5,gpio.OUTPUT)
gpio.write(5,gpio.LOW)


dofile("fadeleds.lua")
dofile("gettime.lua").schedule()
