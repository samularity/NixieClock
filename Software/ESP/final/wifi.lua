return function(onSuccess, onFailure)
  print("Starting enduser")
  enduser_setup.start(onSuccess,onFailure)
  ws2812.write(string.char(0,255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,255,0))
end
