return function(onSuccess, onFailure)
  print("Starting enduser")
  ws2812.write(string.char(0,255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,255,0))
  enduser_setup.start(onSuccess,onFailure)
end
