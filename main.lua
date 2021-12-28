local Garment = require("garment")

Game = {
  width = 320,
  height = 180,
  scale = 5,
  name = "Enjuway",
  over = false,
}

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  -- the height of a meter our worlds will be 64px
  local meter  = 18
  love.physics.setMeter(meter)
  -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
  World = love.physics.newWorld(0, 9.81*meter, true)

  Player = {
    velx = 1,
    score = 0
  }
  Ground = {}
  Obstacle = {
    velx = -50,
    vely = 0,
  }

  love.window.setMode(
    Game.width * Game.scale,
    Game.height * Game.scale
  )

  love.window.setTitle(Game.name)

  LoadPlayerAssets()

  Ground.body = love.physics.newBody(World, 0, Game.height, "static")
	Ground.shape = love.physics.newRectangleShape(Game.width * Game.scale, 5)
	Ground.fixture = love.physics.newFixture(Ground.body, Ground.shape)

  Player.body = love.physics.newBody(World, 50, 5, "dynamic") -- player começa caindo
	Player.shape = love.physics.newRectangleShape(Player.image:getWidth(), Player.image:getHeight())
  Player.fixture = love.physics.newFixture(Player.body, Player.shape)

  Obstacle.body = love.physics.newBody(World, Game.width, Game.height, "dynamic")
  Obstacle.shape = love.physics.newRectangleShape(0, 0, 10, 15) -- 10x15 tamanho do obstaculo
  Obstacle.fixture = love.physics.newFixture(Obstacle.body, Obstacle.shape, 5)

  love.graphics.setBackgroundColor(0.41, 0.53, 0.97)

  Garment.new()
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update(dt)
  World:update(dt)
  World:setCallbacks(BeginContact, EndContact, PreSolve, PostSolve)

  Obstacle.body:setLinearVelocity(Obstacle.velx, Obstacle.vely)

  PlayerWalk()

  if Obstacle.body:getX() < 0 then
    Obstacle.body:setX(Game.width)
  end

  if Player.body:getX() < 1 then -- limimar para o game over
    Game.over = true
  end

  Garment.update()
end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(Game.scale, Game.scale)
  
  if Game.over then
    RGBColor(255, 0, 0)
    love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)
    return
  end

  -- desenha o chão
  RGBColor(0, 255, 0)
  love.graphics.polygon("fill", Ground.body:getWorldPoints(Ground.shape:getPoints()))

  -- desenha o player na posição x e y
  RGBColor(255, 255, 255)
  love.graphics.draw(Player.image, Player.body:getX(), Player.body:getY(), Player.body:getAngle(),  1, 1, Player.image:getWidth()/2, Player.image:getHeight()/2)

  RGBColor(0, 0, 0)
  love.graphics.polygon("fill", Obstacle.body:getWorldPoints(Obstacle.shape:getPoints()))

  -- desenha a pontuação
  love.graphics.print("Score: " ..Player.score, 10, 4)

  Garment.draw()

  magicNumber = math.random(0, 2000)

  if magicNumber < 10 then
    
  end
end

function love.keypressed(key)
  -- ESC para sair do jogo
  if key == "escape" then
    love.event.quit()
  end

  -- Debug CTRL Direito
  if key == "rctrl" then
    debug.debug()
  end

  -- Player
  if key == "up" then
    if InGround() then
      Player.body:applyLinearImpulse(0, -100)
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
  Player.image = love.graphics.newImage("assets/images/player.png")
  Player.image:setFilter("nearest", "nearest")
  Player.width = Player.image:getWidth()
  Player.height = Player.image:getHeight()
end

function RGBColor(r, g, b)
  love.graphics.setColor(r/255, g/255, b/255)
end

function GameOver()
  Game.over = true
end

function InGround()
  return Player.body:getY() > Ground.body:getY() - 11 -- 11 espaço em pixels entre o chão e o player
end

function BeginContact(a, b, coll)
  if Garment.beginContact(a, b, coll) then return end
end

function EndContact(a, b, coll)
  
end

function PreSolve(a, b, coll)

end

function PostSolve(a, b, coll, normalimpulse, tangentimpulse)

end

function PlayerWalk()
  if love.keyboard.isDown("left") then
    Player.body:setX(Player.body:getX() - Player.velx)
  end

  if love.keyboard.isDown("right") then
    Player.body:setX(Player.body:getX() + Player.velx)
  end

  if Player.body:getX() < 0 then
    Player.body:setX(0)
  end

  if Player.body:getX() + Player.width > Game.width then
    Player.body:setX(Game.width - Player.width)
  end
end
