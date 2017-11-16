local M={}
M.conf="config.json"
--M.data : may be used in other functions

M.defaults = {
    brightness = 1,
    fadedelay=1000,
    numled=3,
    pin=1,
    mode="off",
    off_color={0,0,0},
    on_color={0,200,0},
    wifi_ssid='shack',
    wifi_pw='welcome2shack'
}


function M:save()
    local tmp_index = self.state.__index
    self.state.__index = nil
    print("saving config")
    file.open(self.conf,"w+")
    file.write(cjson.encode(self.state))
    file.close()
    self.state.__index = tmp_index
    collectgarbage()
end

function M:load()
    if pcall(function()
        file.open(self.conf)
        self.state = setmetatable(cjson.decode(file.read()),{__index=self.defaults})
        print("found config to load")
    end ) then
    else
        print("unable to load config, using default")
        self.state = setmetatable({},{__index=self.defaults})
    end
    collectgarbage()
end

M:load()

return M
