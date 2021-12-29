local Garment = require("garment")
local PowerUp = require("powerup")
local cron = require ("cron")
require('menu')

Game = {
  width = 320,
  height = 180,
  scale = 5,
  name = "Enjuway",
  over = false,
  background = nil,
  sounds = {},
  state = 'menu'
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
  garmentXSpeed = 50,
  garmentYSpeed = 0,
  garmentXAccelerationRate = 0.02,
  powerUpXSpeed = 50,
  powerUpYSpeed = 0,
  powerUpXAccelerationRate = 0.02,
  powerUpXBoostSpeed = 0.5, -- extra speed
  powerUpXMaxBoost = 1, -- max boost 
  powerUpBoostDecayRate = 0.1 -- will decay x per second
}

Dimensions = {
  meter = 18 -- the height of a meter our worlds will be 64px
}

Random = {
  instanceIdMin = 0,
  instanceIdMax = 10000000,
  obstacleSpawnMin = 0.5, -- every x seconds
  obstacleSpawnMax = 2, -- every x seconds
  garmentSpawnChance = 40, -- x% in 100
  powerUpSpawnChance = 5, -- x% in 100
}

Tags = {
  ground = "Ground",
  player = "Player",
  obstacle = "Obstacle",
  garment = "Garment",
}

Keys = {
  esc = "escape",
  controlRight = "rctrl",
  arrowUp = "up",
  arrowLeft = "left",
  arrowDown = "down",
  arrowRight = "right",
  restart = "r",
  m = "m",
}

Assets = {
  Game = {
    score = "assets/images/score.png",
  },
  Background = {
    [0] = "assets/images/bg-asset-1.png",
    [1] = "assets/images/bg-asset-2.png",
    [2] = "assets/images/bg-asset-3.png",
    [3] = "assets/images/bg-asset-4.png",
    [4] = "assets/images/bg-asset-5.png",
    [5] = "assets/images/bg-asset-6.png",
    [6] = "assets/images/bg-asset-7.png",
    [7] = "assets/images/bg-asset-8.png",
    [8] = "assets/images/bg-asset-9.png",
    [9] = "assets/images/bg-asset-10.png",
  },
  Player = {
    stopped = "assets/images/player.png",
    animation = "assets/images/player-animation.png",
    jump = "assets/images/player-jump.png",
  },
  Wall = {
    past = "assets/images/bg-wall-1.jpg",
    gameover = "assets/images/gameover.png"
  },
  Obstacle = {
    [0] = "assets/images/percent.png",
    [1] = "assets/images/percent_biggest.png",
    [2] = "assets/images/bundle.png"
  },
  Garment = {
    [0] = "assets/images/tshirt.png",
    [1] = "assets/images/boots-gray.png",
    [2] = "assets/images/boots-brown.png",
    [3] = "assets/images/skirt.png",
  },
  PowerUp = {
    sparkles = "assets/images/spark.png"
  }
}

Sounds = {
  Game = {
    gameover = "assets/sounds/gameover.wav",
    theme = "assets/sounds/beach-theme.wav",
  },
  Player = {
    jump = "assets/sounds/jump.wav",
    collect = "assets/sounds/pickupCoin.wav",
    powerUp = "assets/sounds/powerUp.wav",
  }
}

Fonts = {
  Minecraft = "assets/fonts/Minecraft.ttf",
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
  currentXBoost = 0,
  inGround = false,
  animation = {},
  sounds = {},
}

Ground = {}
Obstacles = {}

local obstacleCallback = function() PushObstacleAndScheduleNext() end
local obstacleClock

local garmentCallback = function() TryPushGarment() end
local garmentClock = cron.every(1, garmentCallback) -- executes every second

local powerUpCallback = function() TryPushPowerUp() end
local powerUpClock = cron.every(1, powerUpCallback) -- executes every second

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.physics.setMeter(Dimensions.meter)

  local font = love.graphics.newFont(Fonts.Minecraft, 18)
  love.graphics.setFont(font)

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
  Ground.fixture:setUserData({ tag = Tags.ground })

  Player.body = love.physics.newBody(World, 50, 5, "dynamic") -- player começa caindo
	Player.shape = love.physics.newRectangleShape(Player.image:getWidth(), Player.image:getHeight())
  Player.fixture = love.physics.newFixture(Player.body, Player.shape)
  Player.fixture:setUserData({ tag = Tags.player })

  Player.animation = NewAnimation(LoadImage(Assets.Player.animation), 16, 16, 1)
  Player.sounds.jump = love.audio.newSource(Sounds.Player.jump, "static")
  Player.sounds.jump:setVolume(0.05)

  Player.sounds.collect = love.audio.newSource(Sounds.Player.collect, "static")
  Player.sounds.collect:setVolume(0.05)

  Player.sounds.powerUp = love.audio.newSource(Sounds.Player.powerUp, "static")
  Player.sounds.powerUp:setVolume(0.05)

  love.graphics.setBackgroundColor(1, 1, 1)

  -- Agenda o primeiro obstaculo para um valor entre os próximos Random.obstacleSpawnMin e Random.obstacleSpawnMax
  ScheduleObstacle(RandomFloat(Random.obstacleSpawnMin, Random.obstacleSpawnMax))

  Game.sounds.gameover = love.audio.newSource(Sounds.Game.gameover, "static")
  Game.sounds.gameover:setVolume(0.5)

  Game.ScoreAsset = LoadImage(Assets.Game.score)

  Garment:load()

  PowerUp:load()

  LoadBackgroundAssets()

  button_spawn(797, 300, "Start", 'start')
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update(dt)
  if Game.state == 'playing' then
    World:update(dt)
    World:setCallbacks(BeginContact, EndContact, PreSolve, PostSolve)
  
    UpdateClocks(dt)
  
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
  
    Garment:update()
    PowerUp:update(dt)
  end
end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  if Game.state == 'playing' then
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

    -- Desenha as vestimentas
    Garment.draw()

    PowerUp.draw()

    -- Desenha a pontuação
    DrawPoints()
  end

  if Game.state == 'menu' then
    button_draw()
  end
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
    Player:Jump()
  end

  -- Player down
  if key == Keys.arrowDown then
    Player:Land()
  end

  -- Restart and game over
  if key == Keys.restart and Game.over then
    Game.over = false
    love.load()
  end

  -- Mute
  if key == Keys.m then
    love.audio.stop()
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
  Game.theme:setLooping(true)
  Game.theme:play()
end

-- Atualiza o clock de spawn dos obstaculos e powerUps a cada frame
function UpdateClocks(dt)
  obstacleClock:update(dt)
  garmentClock:update(dt)
  powerUpClock:update(dt)
end

function LoadBackgroundAssets()
  Game.backgroundAssets = {}
  Game.backgroundAssets[4] = LoadImage(Assets.Background[4])
  Game.backgroundAssets[3] = LoadImage(Assets.Background[3])
  Game.backgroundAssets[5] = LoadImage(Assets.Background[5])
  Game.backgroundAssets[9] = LoadImage(Assets.Background[9])
end

function DrawBackgroundAssets()
  RGBColor(Colors.White)
  love.graphics.draw(Game.backgroundAssets[4], 100, 0, 0, 1/Game.scale, 1/Game.scale)

  RGBColor(Colors.White)
  love.graphics.draw(Game.backgroundAssets[3], 200, 0, 0, 1/Game.scale, 1/Game.scale)

  RGBColor(Colors.White)
  love.graphics.draw(Game.backgroundAssets[5], 260, 50, 0, 1/Game.scale, 1/Game.scale)

  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.draw(Game.backgroundAssets[9], 150, 40, 0, 1/Game.scale, 1/Game.scale)
end

function DrawPoints()
  love.graphics.draw(Game.ScoreAsset, 10, 0)

  RGBColor(Colors.Black)
  love.graphics.print(Player.score, 50, 28)

  local magicNumber = math.random(0, 2000)

  if magicNumber < 10 then

  end
end

function LoadPlayerAssets()
  Player:SetImage(Assets.Player.stopped)

  Game.background = LoadImage(Assets.Wall.past)
  Game.backgroundGameover = LoadImage(Assets.Wall.gameover)
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
      DestroyObstacle(obstacle)
      PopObstacle(i)
    end
  end
end

function DestroyObstacle(obstacle)
  obstacle.body:destroy()
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
  ScheduleObstacle(RandomFloat(Random.obstacleSpawnMin, Random.obstacleSpawnMax))
end

function ScheduleObstacle(afterFrames)
  obstacleClock = cron.after(afterFrames, obstacleCallback)
end

function PushObstacle()
  local obstacle = {}
  obstacle.image = LoadImage(SelectObstacle())

  obstacle.body = love.physics.newBody(World, Game.width, Game.height, "dynamic")
  obstacle.shape = love.physics.newRectangleShape(obstacle.image:getWidth(), obstacle.image:getHeight())
  obstacle.fixture = love.physics.newFixture(obstacle.body, obstacle.shape, 5)
  obstacle.fixture:setUserData({ tag = Tags.obstacle })

  table.insert(Obstacles, obstacle)
end

function SelectObstacle()
  return Assets.Obstacle[love.math.random(0, #Assets.Obstacle)]
end

function PopObstacle(i)
  table.remove(Obstacles, i)
end

function TryPushGarment()
  local randomNumber = love.math.random(0, 100)

  if randomNumber <= Random.garmentSpawnChance then
    Garment.new()
  end
end

function TryPushPowerUp()
  local randomNumber = love.math.random(0, 100)

  if randomNumber <= Random.powerUpSpawnChance then
    PowerUp.new()
  end
end

function RandomFloat(lower, greater)
  return lower + math.random() * (greater - lower);
end

function BeginContact(a, b, coll)
  if (a:getUserData().tag == Tags.ground and b:getUserData().tag == Tags.player) or (a:getUserData().tag == Tags.player and b:getUserData().tag == Tags.obstacle) then
    Player.inGround = true
  end

  if Garment.beginContact(a, b, coll) then return end

  if PowerUp.beginContact(a, b, coll) then return end
end

function EndContact(a, b, coll)
  if (a:getUserData().tag == Tags.ground and b:getUserData().tag == Tags.player) or (a:getUserData().tag == Tags.player and b:getUserData().tag == Tags.obstacle) then
    Player.inGround = false
  end
end

function PreSolve(a, b, coll)

end

function PostSolve(a, b, coll, normalimpulse, tangentimpulse)

end

function GetPlayerXSpeed() 
  return Player.velx + Player.currentXBoost
end

function PlayerWalk()
  if love.keyboard.isDown(Keys.arrowLeft) then
    Player.body:setX(Player.body:getX() - GetPlayerXSpeed())
  end

  if love.keyboard.isDown(Keys.arrowRight) then
    Player.body:setX(Player.body:getX() + GetPlayerXSpeed())
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
  Player.image = LoadImage(image)

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

function love.mousepressed(x, y)
  if Game.state == "menu" then
    button_click(x, y)
  end
end

function LoadImage(name)
  local img = love.graphics.newImage(name)
  img:setFilter("nearest", "nearest")
  return img
end

function DrawGameover()
  RGBColor(Colors.White)
  love.graphics.draw(Game.backgroundGameover, 0, 0, 0, 0.2, 0.23)

  RGBColor(Colors.Black)
  love.graphics.print("Score: " .. Player.score, 130, Game.height/2)
end
