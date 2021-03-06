local cron = require("cron")

local boostCallback = function() DecayBoost() end
local boostClock = cron.every(1, boostCallback) -- executes every second

local PowerUp = {}
PowerUp.__index = PowerUp
local ActivePowerUp = {}

function PowerUp:new()
  local instance = setmetatable({}, PowerUp)

  instance.image = love.graphics.newImage(Assets.PowerUp.sparkles)
  instance.image:setFilter("nearest", "nearest")

  instance.id = love.math.random(Random.instanceIdMin, Random.instanceIdMax)
  instance.x = Game.width + instance.image:getWidth()
  instance.y = Game.height/RandonHeight()
  instance.scaleX = 1

  instance.physics = {}
  instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "dynamic")
  instance.physics.shape = love.physics.newRectangleShape(instance.image:getWidth(), instance.image:getHeight())
  instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
  instance.physics.fixture:setSensor(true)
  instance.physics.fixture:setUserData({ tag = Tags.powerUp, id = instance.id })

  table.insert(ActivePowerUp, instance)
end

function PowerUp:load()
  ActivePowerUp = {}
end

function PowerUp:update(dt)
  UpdatePowerUpClocks(dt)

  DespawnPowerUps()
  AcceleratePowerUps()
end

function UpdatePowerUpClocks(dt)
  boostClock:update(dt)
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
      PopPowerUp(GetPowerUpTableIndex(instance))
    end
  end
end

function AcceleratePowerUps()
  WorldForces.powerUpXSpeed = WorldForces.powerUpXSpeed + WorldForces.powerUpXAccelerationRate

  for _, instance in ipairs(ActivePowerUp) do
      instance.physics.body:setLinearVelocity(WorldForces.powerUpXSpeed * -1, WorldForces.powerUpYSpeed * -1)
  end
end

function PowerUp:collect()
  Player.sounds.powerUp:play()
  AddBoost(Forces.powerUpXBoost)

  DestroyPowerUp(self)
  PopPowerUp(GetPowerUpTableIndex(self))
end

function AddBoost(xForce)
  if Player.velx < Forces.playerXSpeed then
    Player.velx = Forces.playerXSpeed
  end

  local newBoost = Player.currentXBoost + Forces.powerUpXBoostSpeed
  if (newBoost >= Forces.powerUpXMaxBoost) then
    newBoost = Forces.powerUpXMaxBoost
  end

  Player.currentXBoost = newBoost
end

function DecayBoost()
  if Player.currentXBoost > 0 then
    Player.currentXBoost = Player.currentXBoost - Forces.powerUpBoostDecayRate
  end
end

function GetPowerUpTableIndex(element)
  for index, value in ipairs(ActivePowerUp) do
    if value.id == element.id then
      return index
    end
  end
end

function GetPowerUpById(id)
  for index, value in ipairs(ActivePowerUp) do
    if value.id == id then
      return value
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
  local instance = nil
  if a:getUserData().tag == Tags.powerUp and b:getUserData().tag == Tags.player then
    instance = a
  elseif a:getUserData().tag == Tags.player and b:getUserData().tag == Tags.powerUp then
    instance = b
  end

  if (instance ~= nil) then
    local powerUp = GetPowerUpById(instance:getUserData().id)
    powerUp:collect()
    return true
  end
end

return PowerUp
