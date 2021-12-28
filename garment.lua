Garment = {}
Garment.__index = Garment
ActiveGarments = {}

function Garment:new()
    instance = setmetatable({}, Garment)
    instance.x = 200
    instance.y = 130
    instance.img = love.graphics.newImage("assets/images/camisa.png")
    instance.width = instance.img:getWidth()
    instance.height = instance.img:getHeight()

    instance.physics = {}
    instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "static")
    instance.physics.shape = love.physics.newRectangleShape(instance.width, instance.height)
    instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)

    table.insert(ActiveGarments, instance)
end

function Garment:draw()
    love.graphics.draw(self.img, self.x, self.y, 0, 1, 1, self.width / w, self.height / 2)
end

function Garment:randomRespawn()
    magicNumber = math.random(0, 20)

    if magicNumber < 10
       instance.draw() 
    end
end


--[[ function Garment:update(dt)
    -- checa a colisão
    if Player.y + Player.height > o2.y and Player.y < o2.y + o2.h and Player.x + Player.width > o2.x and Player.x < o2.x + o2.w then
        Player.score = Player.score + 1
        dt.remove()
    end
end

function Garment:draw()
    RGBColor(0, 255, 0)
    love.graphics.rectangle("fill", o2.x, o2.y, o2.w, o2.h)
end

function Garment:randomRespawn() 
    magicNumber = math.random(0, 30)

    if magicNumber < 10 then
        o2.x = 200
        o2.y = 130
        RGBColor(0, 255, 0)
        love.graphics.rectangle("fill", o2.x, o2.y, o2.w, o2.h)
    end
end ]]