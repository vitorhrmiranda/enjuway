Game = {
  width = 320,
  height = 180,
  scale = 5,
  name = "Enjuway",
  over = false,
  background = nil,
  sounds = {},
}

Player = {
  velx = 1,
  inGround = false,
  animation = {},
  sounds = {},
}
Ground = {}
Obstacle = {
  velx = -50,
  vely = 0,
}

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  -- the height of a meter our worlds will be 64px
  local meter  = 18
  love.physics.setMeter(meter)
  -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
  World = love.physics.newWorld(0, 9.81*meter, true)

  love.window.setMode(
    Game.width * Game.scale,
    Game.height * Game.scale
  )

  love.window.setTitle(Game.name)

  LoadPlayerAssets()

  Ground.body = love.physics.newBody(World, 0, Game.height, "static")
	Ground.shape = love.physics.newRectangleShape(Game.width * Game.scale, 5)
	Ground.fixture = love.physics.newFixture(Ground.body, Ground.shape)
  Ground.fixture:setUserData("Ground")

  Player.body = love.physics.newBody(World, 50, 5, "dynamic") -- player começa caindo
	Player.shape = love.physics.newRectangleShape(Player.image:getWidth(), Player.image:getHeight())
  Player.fixture = love.physics.newFixture(Player.body, Player.shape)
  Player.fixture:setUserData("Player")

  Obstacle.body = love.physics.newBody(World, Game.width, Game.height, "dynamic")
  Obstacle.shape = love.physics.newRectangleShape(Obstacle.image:getWidth(), Obstacle.image:getHeight())
  Obstacle.fixture = love.physics.newFixture(Obstacle.body, Obstacle.shape, 5)
  Obstacle.fixture:setUserData("Obstacle")

  love.graphics.setBackgroundColor(1, 1, 1)

  Player.animation = NewAnimation(love.graphics.newImage("assets/images/player-animation.png"), 16, 16, 1)
  Player.sounds.jump = love.audio.newSource("assets/sounds/jump.wav", "static")
  Player.sounds.jump:setVolume(0.05)

  Game.sounds.gameover = love.audio.newSource("assets/sounds/explosion.wav", "static")
  Game.sounds.gameover:setVolume(0.5)
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
    Game.sounds.gameover:play()
  end

  Player.animation.currentTime = Player.animation.currentTime + dt
  if Player.animation.currentTime >= Player.animation.duration then
    Player.animation.currentTime = Player.animation.currentTime - Player.animation.duration
  end
end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(Game.scale, Game.scale)

  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.draw(Game.background, 0, 0)

  if Game.over then
    RGBColor(255, 0, 0)
    love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)
    return
  end

  -- desenha o chão
  RGBColor(208, 98, 36)
  love.graphics.polygon("fill", Ground.body:getWorldPoints(Ground.shape:getPoints()))

  -- desenha o player na posição x e y
  Player:Draw()

  -- desenha o obstaculo
  RGBColor(255, 255, 255)
  love.graphics.draw(Obstacle.image, Obstacle.body:getX(), Obstacle.body:getY(), 0,  1, 1, Obstacle.image:getWidth()/2, Obstacle.image:getHeight()/2)
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
    Player:Jump()
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
  Player:SetImage("player.png")

  Game.background = love.graphics.newImage("assets/images/bg-wall-1.jpg")

  Obstacle.image = love.graphics.newImage("assets/images/percent.png")
  Obstacle.image:setFilter("nearest", "nearest")
  Obstacle.width = Obstacle.image:getWidth()
  Obstacle.height = Obstacle.image:getHeight()
end

function RGBColor(r, g, b)
  love.graphics.setColor(r/255, g/255, b/255)
end

function GameOver()
  Game.over = true
end

function InGround()
  return Player.inGround
end

function BeginContact(a, b, coll)
  if a:getUserData() == "Ground" and b:getUserData() == "Player" then
    Player.inGround = true
  end
end

function EndContact(a, b, coll)
  if a:getUserData() == "Ground" and b:getUserData() == "Player" then
    Player.inGround = false
  end
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

function Player:Jump()
  if Player:InGround() then
    Player.body:applyLinearImpulse(0, -100)
    Player:SetImage("player-jump.png")
    Player.sounds.jump:play()
  end
end

function Player:InGround()
  return Player.inGround
end

function Player:SetImage(image)
  local imagePath = "assets/images/" .. image
  Player.image = love.graphics.newImage(imagePath)
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
  RGBColor(255, 255, 255)

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
