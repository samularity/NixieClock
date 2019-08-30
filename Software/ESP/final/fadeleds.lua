numled = 6


ws2812.init(ws2812.MODE_SINGLE)
-- create a buffer, 60 LEDs with 3 color bytes
strip_buffer = ws2812.newBuffer(numled, 3)
-- init the effects module, set color to red and start blinking

ws2812_effects.init(strip_buffer)
ws2812_effects.set_speed(100)
ws2812_effects.set_brightness(100)

ws2812_effects.set_mode("rainbow")
ws2812_effects.start()

