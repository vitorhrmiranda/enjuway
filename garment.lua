local Garment = {}
Garment.__index = Garment
local ActiveGarment = {}

function Garment:new()
  local instance = setmetatable({}, Garment)

  instance.image = love.graphics.newImage(Assets.Garment.tshirt)
  instance.image:setFilter("nearest", "nearest")

  instance.id = love.math.random(Random.instanceIdMin, Random.instanceIdMax)
  instance.x = Game.width + instance.image:getWidth()
  instance.y = Game.height/1.5 -- um quarto de tela
  instance.scaleX = 1

  instance.physics = {}
  instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "dynamic")
  instance.physics.shape = love.physics.newRectangleShape(instance.image:getWidth(), instance.image:getHeight())
  instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
  instance.physics.fixture:setSensor(true)
  instance.physics.fixture:setUserData({ tag = Tags.garment, id = instance.id })

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
      PopGarment(GetGarmentTableIndex(instance))
    end
  end
end

function AccelerateGarments()
  Forces.garmentXSpeed = Forces.garmentXSpeed + Forces.garmentXAccelerationRate
  for _, instance in ipairs(ActiveGarment) do
      instance.physics.body:setLinearVelocity(Forces.garmentXSpeed * -1, Forces.garmentYSpeed * -1)
  end
end

function Garment:collect()
  Player.score = Player.score + 1
  Player.sounds.collect:play()

  DestroyGarment(self)
  PopGarment(GetGarmentTableIndex(self))
end

function GetGarmentTableIndex(element)
  for index, value in ipairs(ActiveGarment) do
    if value.id == element.id then
      return index
    end
  end
end

function GetGarmentById(id)
  for index, value in ipairs(ActiveGarment) do
    if value.id == id then
      return value
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
  local instance = nil

  if a:getUserData().tag == Tags.garment and b:getUserData().tag == Tags.player then
    instance = a
  elseif a:getUserData().tag == Tags.player and b:getUserData().tag == Tags.garment then 
    instance = b
  end   

  if (instance ~= nil) then 
    local garment = GetGarmentById(instance:getUserData().id)
    garment:collect()

    return true
  end
end

return Garment
