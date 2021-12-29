local Garment = {}
Garment.__index = Garment
local ActiveGarment = {}

function Garment:new()
  local instance = setmetatable({}, Garment)

  instance.image = love.graphics.newImage(Assets.Garment.tshirt)
  instance.image:setFilter("nearest", "nearest")

  instance.id = love.math.random(0, 1000000)
  instance.x = Game.width + instance.image:getWidth()
  instance.y = Game.height/1.5 -- um quarto de tela
  instance.scaleX = 1
  instance.toBeRemoved = false

  instance.physics = {}
  instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "dynamic")
  instance.physics.shape = love.physics.newRectangleShape(instance.image:getWidth(), instance.image:getHeight())
  instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
  instance.physics.fixture:setSensor(true)
  instance.physics.fixture:setUserData(Tags.garment)

  table.insert(ActiveGarment, instance)
end

function Garment:load()
  ActiveGarment = {}
end

function Garment:update()
  DespawnGarments()
  AccelerateGarments()
end

function Garment:draw()
  for _, instance in ipairs(ActiveGarment) do
    RGBColor(Colors.White)
    love.graphics.draw(instance.image, instance.physics.body:getX(), instance.physics.body:getY(), 0, 1, 1, instance.image:getWidth()/2, instance.image:getHeight()/2)
  end
end

function DespawnGarments()
  for i, instance in ipairs(ActiveGarment) do
    if instance.physics.body:getX() < 0 then
      DestroyGarment(instance)
      PopGarment(GetIndex(ActiveGarment, instance))
    end
  end
end

function AccelerateGarments()
  Forces.powerUpXSpeed = Forces.powerUpXSpeed + Forces.powerUpXAccelerationRate
  for _, instance in ipairs(ActiveGarment) do
      instance.physics.body:setLinearVelocity(Forces.powerUpXSpeed * -1, Forces.powerUpYSpeed * -1)
  end
end

function Collect(instance)
  Player.score = Player.score + 1
  Player.sounds.collect:play()

  DestroyGarment(instance)
  PopGarment(GetIndex(ActiveGarment, instance))
end

function GetIndex(table, element)
  for index, value in pairs(table) do
    if value.id == element.id then
      return index
    end
  end
end

function DestroyGarment(instance)
  instance.physics.body:destroy()
end

function PopGarment(i)
  table.remove(ActiveGarment, i)
end

function Garment:destroy()
  self.physics.body:destroy()
end

function Garment.beginContact(a, b, collision)
  for i,instance in ipairs(ActiveGarment) do
    if a == instance.physics.fixture or b == instance.physics.fixture then
      if a == Player.fixture or b == Player.fixture then
        Collect(instance)
        return true
      end
    end
  end
end

return Garment
