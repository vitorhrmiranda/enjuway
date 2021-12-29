local Garment = require("garment")

Game = {
  width = 320,
  height = 180,
  scale = 5,
  name = "Enjuway",
  over = false,
  background = nil,
  sounds = {},
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
  obstacleXAccelerationRate = 0.02
}

Dimensions = {
  meter = 18 -- the height of a meter our worlds will be 64px
}

Random = {
  obstacleSpawnMin = 30,
  obstacleSpawnMax = 120,
  obstacleUpdateRate = 1
}

Tags = {
  ground = "Ground",
  player = "Player",
  obstacle = "Obstacle"
}

Keys = {
  esc = "escape",
  controlRight = "rctrl",
  arrowUp = "up",
  arrowLeft = "left",
  arrowDown = "down",
  arrowRight = "right",
  restart = "r"
}

Assets = {
  Player = {
    stopped = "assets/images/player.png",
    animation = "assets/images/player-animation.png",
    jump = "assets/images/player-jump.png",
  },
  Wall = {
    past = "assets/images/bg-wall-1.jpg"
  },
  Obstacle = {
    [0] = "assets/images/percent.png",
    [1] = "assets/images/percent_biggest.png"
  },
  Points = {
    tshirt = "assets/images/tshirt.png",
  }
}

Sounds = {
  Game = {
    gameover = "assets/sounds/explosion.wav",
    theme = "assets/sounds/beach-theme.wav",
  },
  Player = {
    jump = "assets/sounds/jump.wav",
    collect = "assets/sounds/pickupCoin.wav",
  }
}

Colors = {
  rgb = 255,
  Black = { r = 0, g = 0, b = 0 },
  Orange = { r = 208, g = 98, b = 36 },
  Red = { r = 255, g = 0, b = 0 },
  White = { r = 255, g = 255, b = 255 }
}
Player = {
  score = 0,
  velx = Forces.playerXSpeed,
  inGround = false,
  animation = {},
  sounds = {},
}

Ground = {}

Obstacles = {}

local cron = require 'cron'
local callback = function() PushObstacleAndScheduleNext() end
local obstacleClock

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.physics.setMeter(Dimensions.meter)

  Obstacles = {}

  -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
  World = love.physics.newWorld(Forces.hGravity, Forces.vGravity * Dimensions.meter, true)

  love.window.setMode(
    Game.width * Game.scale,
    Game.height * Game.scale
  )

  love.window.setTitle(Game.name)

  LoadPlayerAssets()
  PlayTheme()

  Ground.body = love.physics.newBody(World, 0, Game.height, "static")
	Ground.shape = love.physics.newRectangleShape(Game.width * Game.scale, 5)
	Ground.fixture = love.physics.newFixture(Ground.body, Ground.shape)
  Ground.fixture:setUserData(Tags.ground)

  Player.body = love.physics.newBody(World, 50, 5, "dynamic") -- player começa caindo
	Player.shape = love.physics.newRectangleShape(Player.image:getWidth(), Player.image:getHeight())
  Player.fixture = love.physics.newFixture(Player.body, Player.shape)
  Player.fixture:setUserData(Tags.player)

  Player.animation = NewAnimation(love.graphics.newImage(Assets.Player.animation), 16, 16, 1)
  Player.sounds.jump = love.audio.newSource(Sounds.Player.jump, "static")
  Player.sounds.jump:setVolume(0.05)

  Player.sounds.collect = love.audio.newSource(Sounds.Player.collect, "static")
  Player.sounds.collect:setVolume(0.05)

  love.graphics.setBackgroundColor(1, 1, 1)

  -- Agenda o primeiro obstaculo para um valor entre os próximos Random.obstacleSpawnMin e Random.obstacleSpawnMax
  ScheduleObstacule(love.math.random(Random.obstacleSpawnMin, Random.obstacleSpawnMax))

  Game.sounds.gameover = love.audio.newSource(Sounds.Game.gameover, "static")
  Game.sounds.gameover:setVolume(0.5)

  Garment.new()
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update(dt)
  World:update(dt)
  World:setCallbacks(BeginContact, EndContact, PreSolve, PostSolve)

  -- Atualiza o clock de spawn dos obstaculos a cada frame
  obstacleClock:update(Random.obstacleUpdateRate)

  -- Remove os obstáculos que já sairam da tela
  DespawnObstacles()
  -- Incrementa a velocidade de aceleração de todos os obstáculos
  AccelerateObstacles()

  PlayerWalk()

  if Player.body:getX() < 1 then -- limimar para o game over
    Game.over = true
    Game.theme:stop()
    Game.sounds.gameover:play()
  end

  -- Calcular o novo estado do player
  Player.animation.currentTime = Player.animation.currentTime + dt
  if Player.animation.currentTime >= Player.animation.duration then
    Player.animation.currentTime = Player.animation.currentTime - Player.animation.duration
  end

  Garment.update()
end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(Game.scale, Game.scale)

  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.draw(Game.background, 0, 0)

  if Game.over then
    RGBColor(Colors.White)
    love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)
    RGBColor(Colors.Black)
    love.graphics.print("Game Over \nSe não enjoou\nAperte 'r' para recomeçar", 10, Game.height/2)
    return
  end

  -- desenha o chão
  RGBColor(Colors.Orange)
  love.graphics.polygon("fill", Ground.body:getWorldPoints(Ground.shape:getPoints()))

  -- desenha o player na posição x e y
  RGBColor(Colors.White)
  Player:Draw()

  -- Desenha todos os obstáculos que estão no array de obstáculos
  DrawObstacles()

  -- Desenha a pontuação
  DrawPoints()
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

  -- Player
  if key == Keys.arrowUp then
    Player:Jump()
  end

  if key == Keys.arrowDown then
    Player:Land()
  end

  if key == Keys.restart and Game.over then
    Game.over = false
    love.load()
  end
end

function love.focus(f)
  -- Fecha o game quando perde o foco
  if not f then
    love.event.quit()
  end
end

-- Funções auxiliares
function PlayTheme()
  Game.theme = love.audio.newSource(Sounds.Game.theme, "static")
  Game.theme:setVolume(0.3)
  Game.theme:play()
end

function DrawPoints()
  love.graphics.print("Score: " ..Player.score, 10, 4)

  Garment.draw()

  local magicNumber = math.random(0, 2000)

  if magicNumber < 10 then

  end
end

function LoadPlayerAssets()
  Player:SetImage(Assets.Player.stopped)

  Game.background = love.graphics.newImage(Assets.Wall.past)
end

function RGBColor(color)
  local rgb = Colors.rgb
  love.graphics.setColor(color.r/rgb, color.g/rgb, color.b/rgb)
end

function GameOver()
  Game.over = true
end

function DrawObstacles()
  for _, obstacle in ipairs(Obstacles) do
    RGBColor(Colors.White)
    love.graphics.draw(obstacle.image, obstacle.body:getX(), obstacle.body:getY(), 0, 1, 1, obstacle.image:getWidth()/2, obstacle.image:getHeight()/2)
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
  ScheduleObstacule(love.math.random(Random.obstacleSpawnMin, Random.obstacleSpawnMax))
end

function ScheduleObstacule(afterFrames)
  obstacleClock = cron.after(afterFrames, callback)
end

function PushObstacle()
  local obstacle = {}
  obstacle.image = love.graphics.newImage(SelectObstacle())
  obstacle.image:setFilter("nearest", "nearest")

  obstacle.body = love.physics.newBody(World, Game.width, Game.height, "dynamic")
  obstacle.shape = love.physics.newRectangleShape(obstacle.image:getWidth(), obstacle.image:getHeight())
  obstacle.fixture = love.physics.newFixture(obstacle.body, obstacle.shape, 5)
  obstacle.fixture:setUserData(Tags.obstacle)

  table.insert(Obstacles, obstacle)
end

function SelectObstacle()
  return Assets.Obstacle[love.math.random(0, 1)]
end

function PopObstacle(i)
  table.remove(Obstacles, i)
end

function BeginContact(a, b, coll)
  if a:getUserData() == Tags.ground and b:getUserData() == Tags.player then
    Player.inGround = true
  end

  if Garment.beginContact(a, b, coll) then return end
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

function Player:Jump()
  if Player:InGround() then
    Player.body:applyLinearImpulse(Forces.playerXJump, Forces.playerYJump * -1)
    Player:SetImage(Assets.Player.jump)
    Player.sounds.jump:play()
  end
end

function Player:InGround()
  return Player.inGround
end

function Player:InAir()
  return not Player.inGround
end

function Player:Land()
  if Player:InAir() then
    Player.body:applyLinearImpulse(Forces.playerXDown, Forces.playerYDown)
  end
end

function Player:SetImage(image)
  Player.image = love.graphics.newImage(image)
  Player.image:setFilter("nearest", "nearest")

  Player.width = Player.image:getWidth()
  Player.height = Player.image:getHeight()
end

function NewAnimation(image, width, height, duration)
  local animation = {}
  animation.spriteSheet = image;
  animation.quads = {};

  for y = 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
    end
  end

  animation.duration = duration or 1
  animation.currentTime = 0

  return animation
end

function Player:Draw()
  RGBColor(Colors.White)

  if Player:InGround() then
    local spriteNum = math.floor(Player.animation.currentTime / Player.animation.duration * #Player.animation.quads) + 1
    love.graphics.draw(
      Player.animation.spriteSheet,
      Player.animation.quads[spriteNum],
      Player.body:getX(),
      Player.body:getY(),
      0,
      1,
      1,
      Player.image:getWidth()/2,
      Player.image:getHeight()/2
    )
  else
    love.graphics.draw(
      Player.image,
      Player.body:getX(),
      Player.body:getY(),
      0,
      1,
      1,
      Player.image:getWidth()/2,
      Player.image:getHeight()/2
    )
  end
end
