Game = {
  width = 320,
  height = 180,
  scale = 5,
  name = "Enjuway",
  over = false,
  background = nil
}

Forces = {
  hGravity = 0,
  vGravity = 9.81,
  playerYJump = 100,
  playerXJump = 0,
  playerYDown = 100,
  playerXDown = 0,
  playerXSpeed = 1,
  obstacleXSpeed = 50,
  obstacleYSpeed = 0,
  obstacleXAccelerationRate = 0.02,
  powerUpXSpeed = 50,
  powerUpYSpeed = 0,
  powerUpXAccelerationRate = 0.02
}

Dimensions = {
  meter = 18 -- the height of a meter our worlds will be 64px
}

Random = {
  obstacleSpawnMin = 0.5, -- every x seconds
  obstacleSpawnMax = 2, -- every x seconds
  powerUpSpawnChance = 35, -- x% in 100
  powerUpYPositionMin = 50,
  powerUpYPositionMax = 100,
}

Tags = {
  ground = "Ground",
  player = "Player",
  obstacle = "Obstacle",
  powerUp = "PowerUp"
}

Keys = {
  esc = "escape",
  controlRight = "rctrl",
  arrowUp = "up",
  arrowLeft = "left",
  arrowDown = "down",
  arrowRight = "right"
}

Assets = {
  Player = {
    main = "assets/images/player.png"
  },
  Wall = {
    past = "assets/images/bg-wall-1.jpg"
  }
}

Colors = {
  rgb = 255,
  Black = { r = 0, g = 0, b = 0 },
  Orange = { r = 208, g = 98, b = 36 },
  Red = { r = 255, g = 0, b = 0 },
  White = { r = 255, g = 255, b = 255 }
}

local PowerUps = {}
local Obstacles = {}

local cron = require 'cron'

local obstacleCallback = function() PushObstacleAndScheduleNext() end
local obstacleClock

local powerUpCallback = function() TryPushPowerUp() end
local powerUpClock = cron.every(1, powerUpCallback) -- executes every second

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.physics.setMeter(Dimensions.meter)

  -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
  World = love.physics.newWorld(Forces.hGravity, Forces.vGravity * Dimensions.meter, true)
  Player = {
    velx = Forces.playerXSpeed,
    inGround = false
  }
  Ground = {}
  
  love.window.setMode(
    Game.width * Game.scale,
    Game.height * Game.scale
  )

  love.window.setTitle(Game.name)

  LoadPlayerAssets()

  Ground.body = love.physics.newBody(World, 0, Game.height, "static")
	Ground.shape = love.physics.newRectangleShape(Game.width * Game.scale, 5)
	Ground.fixture = love.physics.newFixture(Ground.body, Ground.shape)
  Ground.fixture:setUserData(Tags.ground)

  Player.body = love.physics.newBody(World, 50, 5, "dynamic") -- player começa caindo
	Player.shape = love.physics.newRectangleShape(Player.image:getWidth(), Player.image:getHeight())
  Player.fixture = love.physics.newFixture(Player.body, Player.shape)
  Player.fixture:setUserData(Tags.player)

  love.graphics.setBackgroundColor(1, 1, 1)

  -- Agenda o primeiro obstaculo para um valor entre os próximos Random.obstacleSpawnMin e Random.obstacleSpawnMax
  ScheduleObstacule(RandomFloat(Random.obstacleSpawnMin, Random.obstacleSpawnMax))
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update(dt)
  World:update(dt)
  World:setCallbacks(BeginContact, EndContact, PreSolve, PostSolve)

  UpdateClocks(dt)

  DespawnPowerUps()
  AcceleratePowerUps()

  -- Remove os obstáculos que já sairam da tela
  DespawnObstacles()
  -- Incrementa a velocidade de aceleração de todos os obstáculos
  AccelerateObstacles()

  PlayerWalk()

  if Player.body:getX() < 1 then -- limimar para o game over
    Game.over = true
  end
end

-- Atualiza o clock de spawn dos obstaculos e powerUps a cada frame
function UpdateClocks(dt) 
  obstacleClock:update(dt)
  powerUpClock:update(dt)
end 

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(Game.scale, Game.scale)

  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.draw(Game.background, 0, 0)

  if Game.over then
    RGBColor(Colors.Red)
    love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)
    return
  end

  -- desenha o chão
  RGBColor(Colors.Orange)
  love.graphics.polygon("fill", Ground.body:getWorldPoints(Ground.shape:getPoints()))

  -- desenha o player na posição x e y
  RGBColor(Colors.White)
  love.graphics.draw(Player.image, Player.body:getX(), Player.body:getY(), 0,  1, 1, Player.image:getWidth()/2, Player.image:getHeight()/2)

  -- Desenha todos os obstáculos que estão no array de obstáculos
  DrawObstacles()
  -- Desenha todos os power ups que estão no array de obstáculos
  DrawPowerUps()
end

function love.keypressed(key)
  -- ESC para sair do jogo
  if key == Keys.escape then
    love.event.quit()
  end

  -- Debug CTRL Direito
  if key == Keys.controlRight then
    debug.debug()
  end

  -- Player jump
  if key == Keys.arrowUp then
    if InGround() then
      Player.body:applyLinearImpulse(Forces.playerXJump, Forces.playerYJump * -1)
    end
  end

  -- Player down
  if key == Keys.arrowDown then
    if InAir() then
      Player.body:applyLinearImpulse(Forces.playerXDown, Forces.playerYDown)
    end
  end
end

function love.focus(f)
  -- Fecha o game quando perde o foco
  if not f then
    love.event.quit()
  end
end

-- Funções auxiliares
function LoadPlayerAssets()
  Player.image = love.graphics.newImage(Assets.Player.main)
  Player.image:setFilter("nearest", "nearest")
  Player.width = Player.image:getWidth()
  Player.height = Player.image:getHeight()

  Game.background = love.graphics.newImage(Assets.Wall.past)
end

function RGBColor(color)
  local rgb = Colors.rgb
  love.graphics.setColor(color.r/rgb, color.g/rgb, color.b/rgb)
end

function GameOver()
  Game.over = true
end

-- Start Obstacle
function DrawObstacles()
  for _, obstacle in ipairs(Obstacles) do
      RGBColor(Colors.Black)
      love.graphics.polygon("fill", obstacle.body:getWorldPoints(obstacle.shape:getPoints()))
  end
end

function DespawnObstacles() 
  for i, obstacle in ipairs(Obstacles) do
    if obstacle.body:getX() < 0 then
      PopObstacle(i)
    end
  end
end

function AccelerateObstacles() 
  Forces.obstacleXSpeed = Forces.obstacleXSpeed + Forces.obstacleXAccelerationRate

  for _, obstacle in ipairs(Obstacles) do
      obstacle.body:setLinearVelocity(Forces.obstacleXSpeed * -1, Forces.obstacleYSpeed * -1)
  end
end 

-- Adiciona um obstáculo novo à lista e agenda o próximo
function PushObstacleAndScheduleNext()
  PushObstacle()
  ScheduleObstacule(RandomFloat(Random.obstacleSpawnMin, Random.obstacleSpawnMax))
end 

function ScheduleObstacule(afterFrames) 
  obstacleClock = cron.after(afterFrames, obstacleCallback)
end

function PushObstacle() 
  local obstacle = {}
  obstacle.body = love.physics.newBody(World, Game.width, Game.height, "dynamic")
  obstacle.shape = love.physics.newRectangleShape(0, 0, 10, 15) -- 10x15 tamanho do obstaculo
  obstacle.fixture = love.physics.newFixture(obstacle.body, obstacle.shape, 5)
  obstacle.fixture:setUserData(Tags.obstacle)

  table.insert(Obstacles, obstacle)
end 

function PopObstacle(i)
  table.remove(Obstacles, i)
end 
-- End Obstacle

-- Start PowerUp
function PushPowerUp() 
  local yPosition = RandomFloat(Random.powerUpYPositionMin, Random.powerUpYPositionMax)

  local powerUp = {}
  powerUp.id = love.math.random(0, 100000000)
  powerUp.body = love.physics.newBody(World, Game.width, Game.height, "dynamic")
  powerUp.shape = love.physics.newRectangleShape(0, yPosition * -1, 10, 15) -- 10x15 tamanho do obstaculo
  powerUp.fixture = love.physics.newFixture(powerUp.body, powerUp.shape, 5)
  powerUp.fixture:setUserData(Tags.powerUp)

  table.insert(PowerUps, powerUp)
end 

function PopPowerUp(i)
  table.remove(PowerUps, i)
end 

function TryPushPowerUp() 
  local randomNumber = love.math.random(0, 100)

  if randomNumber <= Random.powerUpSpawnChance then
    PushPowerUp()
  end 
end

function DrawPowerUps()
  for _, powerUp in ipairs(PowerUps) do
      RGBColor(Colors.White)
      love.graphics.polygon("fill", powerUp.body:getWorldPoints(powerUp.shape:getPoints()))
  end
end

function DespawnPowerUps() 
  for i, powerUp in ipairs(PowerUps) do
    if powerUp.body:getX() < 0 then
      PopPowerUp(i)
    end
  end
end

function AcceleratePowerUps() 
  Forces.powerUpXSpeed = Forces.powerUpXSpeed + Forces.powerUpXAccelerationRate

  for _, powerUp in ipairs(PowerUps) do
    powerUp.body:setLinearVelocity(Forces.powerUpXSpeed * -1, 0)
  end
end 

function ApplyPowerUp(powerUp) 
  local powerUpIndex = PowerUpFind(PowerUps, powerUp)
  -- Apply powerUp to player then pop it from list
  print(powerUpIndex)
  PopPowerUp(powerUpIndex)
end 

function PowerUpFind(table, element)
  for index, value in pairs(table) do
    if value.id == element.id then
      return index
    end
  end
end
-- End PowerUp

function RandomFloat(lower, greater)
  return lower + math.random() * (greater - lower);
end

function InGround()
  return Player.inGround
end

function InAir()
  return not Player.inGround
end

function BeginContact(a, b, coll)
  print(a:getUserData() .. " - " .. b:getUserData())
  if (b:getUserData() == Tags.player and a:getUserData() == Tags.ground) then
    Player.inGround = true
  elseif a:getUserData() == Tags.player and b:getUserData() == Tags.powerUp then 
    ApplyPowerUp(b)
  end  
end

function EndContact(a, b, coll)
  if a:getUserData() == Tags.ground and b:getUserData() == Tags.player then
    Player.inGround = false
  end
end

function PreSolve(a, b, coll)

end

function PostSolve(a, b, coll, normalimpulse, tangentimpulse)

end

function PlayerWalk()
  if love.keyboard.isDown(Keys.arrowLeft) then
    Player.body:setX(Player.body:getX() - Player.velx)
  end

  if love.keyboard.isDown(Keys.arrowRight) then
    Player.body:setX(Player.body:getX() + Player.velx)
  end

  if Player.body:getX() < 0 then
    Player.body:setX(0)
  end

  if Player.body:getX() + Player.width > Game.width then
    Player.body:setX(Game.width - Player.width)
  end
end