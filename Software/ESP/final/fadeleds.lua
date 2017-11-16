
h = 0
incr = 0.01



local function hsv2rgb(h,s,v)
    local r,g,b
    local i=math.floor(h*6)
    local f=h*6-i
    local p=v*(1-s)
    local q=v*(1-f*s)
    local t=v*(1-(1-f)*s)
    i=i%6
    if i==0 then r,g,b=v,t,p
    elseif i==1 then r,g,b=q,v,p
    elseif i==2 then r,g,b=p,v,t
    elseif i==3 then r,g,b=p,q,v
    elseif i==4 then r,g,b=t,p,v
    elseif i==5 then r,g,b=v,p,q
    end
    return {r*255,g*255,b*255}
end


ws2812.init()
tmr.alarm(0,400, tmr.ALARM_AUTO, function()
  rgb = hsv2rgb(h,1,1)
  -- print(rgb[2],rgb[1],rgb[3])
  ws2812.write(string.char(rgb[2],rgb[1],rgb[3],
                           rgb[2],rgb[1],rgb[3],
                           rgb[2],rgb[1],rgb[3],
                           rgb[2],rgb[1],rgb[3],
                           rgb[2],rgb[1],rgb[3],
                           rgb[2],rgb[1],rgb[3]
              ))
  h = h + incr
  if h > 1 then
    h = 0
  end
end)
