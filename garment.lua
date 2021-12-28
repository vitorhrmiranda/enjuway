local Garment = {}
Garment.__index = Garment
local ActiveGarment = {}
local instanceClone

function Garment:new()
    local instance = setmetatable({}, Garment)

    instance.x = 320
    instance.y = 130
    instance.img = love.graphics.newImage("assets/images/camisa.png")
    instance.width = 10
    instance.height = 10
    instance.scaleX = 1
    instance.toBeRemoved = false

    instance.physics = {}
    instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "dynamic")
    instance.physics.body:setLinearVelocity(-50, 0)
    instance.physics.shape = love.physics.newRectangleShape(instance.width, instance.height)
    instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
    instance.physics.fixture:setSensor(true)

    instanceClone = instance
    table.insert(ActiveGarment, instance)
end

function Garment:draw()
    if instanceClone.toBeRemoved == false then
        RGBColor(0, 0, 0)
        love.graphics.polygon("fill", instanceClone.physics.body:getWorldPoints(instanceClone.physics.shape:getPoints()))
    end
end

function Garment:checkRemove()
    if instanceClone.toBeRemoved then
        instanceClone:remove()
    end
end

function Garment:update()
    instanceClone.physics.body:setLinearVelocity(-50, 0)
    instanceClone.checkRemove()
    
    if Obstacle.body:getX() < 1 then
        Garment:new()
    end
end

function Garment:remove()
    for i,instance in ipairs(ActiveGarment) do
       if instance == self then
            Player.score = Player.score + 1
            print(Player.score)
            table.remove(ActiveGarment, i)
       end
    end
end

function Garment.beginContact(a, b, collision)
    for i,instance in ipairs(ActiveGarment) do
        if a == instance.physics.fixture or b == instance.physics.fixture then
            if a == Player.fixture or b == Player.fixture then
                instance.toBeRemoved = true
                return true
            end
        end
    end
end

return Garment
