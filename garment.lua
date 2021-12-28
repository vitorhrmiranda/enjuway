Garment = {}

function Garment:new()
    o2 = {
        w = 10,
        h = 10,
        x = math.random(220 - 10),
        y = 130,
    }

    setmetatable(o2, { __index = Garment })
    return o2
end

function Garment:update(dt)
    -- checa a colisão
    if Player.y + Player.height > o2.y and Player.y < o2.y + o2.h and Player.x + Player.width > o2.x and Player.x < o2.x + o2.w then
        Player.score = Player.score + 1
        Garment: respawn()
    end
end

function Garment:draw()
    RGBColor(0, 255, 0)
    love.graphics.rectangle("fill", o2.x, o2.y, o2.w, o2.h)
end

function Garment:respawn() 
    o2.x = math.random(220 - 10)
    o2.y = 130
end