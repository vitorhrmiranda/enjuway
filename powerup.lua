local PowerUp = {}
PowerUp.__index = PowerUp
local ActivePowerUp = {}

function PowerUp:new()
  local instance = setmetatable({}, PowerUp)

  instance.image = love.graphics.newImage(Assets.PowerUp.sparkles)
  instance.image:setFilter("nearest", "nearest")

  instance.id = love.math.random(0, 1000000)
  instance.x = Game.width + instance.image:getWidth()
  instance.y = Game.height/1.5 -- um quarto de tela
  instance.scaleX = 1

  instance.physics = {}
  instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "dynamic")
  instance.physics.shape = love.physics.newRectangleShape(instance.image:getWidth(), instance.image:getHeight())
  instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
  instance.physics.fixture:setSensor(true)
  instance.physics.fixture:setUserData(Tags.powerUp)

  table.insert(ActivePowerUp, instance)
end

function PowerUp:load()
  ActivePowerUp = {}
end

function PowerUp:update()
  DespawnPowerUps()
  AcceleratePowerUps()
end

function PowerUp:draw()
  for _, instance in ipairs(ActivePowerUp) do
    RGBColor(Colors.White)
    love.graphics.draw(instance.image, instance.physics.body:getX(), instance.physics.body:getY(), 0, 1, 1, instance.image:getWidth()/2, instance.image:getHeight()/2)
  end
end

function DespawnPowerUps()
  for i, instance in ipairs(ActivePowerUp) do
    if instance.physics.body:getX() < 0 then
      DestroyPowerUp(instance)
      PopPowerUp(GetIndex(ActivePowerUp, instance))
    end
  end
end

function AcceleratePowerUps()
  Forces.powerUpXSpeed = Forces.powerUpXSpeed + Forces.powerUpXAccelerationRate
  for _, instance in ipairs(ActivePowerUp) do
      instance.physics.body:setLinearVelocity(Forces.powerUpXSpeed * -1, Forces.powerUpYSpeed * -1)
  end
end

function Collect(instance)
  Player.score = Player.score + 1
  Player.sounds.collect:play()

  DestroyPowerUp(instance)
  PopPowerUp(GetIndex(ActivePowerUp, instance))
end

function GetIndex(table, element)
  for index, value in pairs(table) do
    if value.id == element.id then
      return index
    end
  end
end

function DestroyPowerUp(instance)
  instance.physics.body:destroy()
end

function PopPowerUp(i)
  table.remove(ActivePowerUp, i)
end

function PowerUp:destroy()
  self.physics.body:destroy()
end

function PowerUp.beginContact(a, b, collision)
  for i,instance in ipairs(ActivePowerUp) do
    if a == instance.physics.fixture or b == instance.physics.fixture then
      if a == Player.fixture or b == Player.fixture then
        Collect(instance)
        return true
      end
    end
  end
end

return PowerUp
