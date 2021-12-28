require('garment')

Game = {
  width = 320,
  height = 180,
  scale = 4,
  name = "Enjuway",
  gravity = 0.1,
  over = false,
}

Player = {
  x = 40,
  y = 0,
  velx = 1,
  vely = 0,
  impulse = -2.5,
  score = 0
}

Obstacle = {
  x = Game.width - 8,
  y = Game.height - 16,
  width = 8,
  height = 16,
  velx = -1,
}

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.window.setMode(
    Game.width * Game.scale,
    Game.height * Game.scale
  )
  love.window.setTitle(Game.name)

  LoadPlayerAssets()
  nom = Garment:new()
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update(dt)
  Player.vely = Player.vely + Game.gravity -- variação da velocidade
  Player.y = Player.y + Player.vely -- variação da posição
  if Player.y > Game.height - Player.height then
    PutInGround(Player)
  end

  PlayerWalk()
  nom:update(dt)

  Obstacle.x = Obstacle.x + Obstacle.velx
  if Obstacle.x < 0 then
    Obstacle.x = Game.width
  end

  if HasCollision(Player, Obstacle) then
    GameOver()
  end
end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(Game.scale, Game.scale)

  if Game.over then
    RGBColor(255, 0, 0)
    love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)
    return
  end

  -- definimos a cor branca
  RGBColor(255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)

  -- desenha o player na posição x e y
  love.graphics.draw(Player.image, Player.x, Player.y)
  
  -- desenha o obstáculo na posição x e y
  RGBColor(0, 0, 0)
  love.graphics.rectangle("fill", Obstacle.x, Obstacle.y, Obstacle.width, Obstacle.height)

  nom:draw()

  RGBColor(0, 0, 0)
  love.graphics.print('Score: ' .. Player.score, 5, 5)
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
    -- o pulo pode iniciar se o avatar estiver no chão
    if Game.height - Player.height == Player.y then
      Player.vely = Player.impulse
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

function PutInGround(obj)
  obj.y = Game.height - obj.height
  obj.vely = 0
end

function HasCollision(obj1, obj2)
  return obj1.x < obj2.x + obj2.width and
    obj1.x + obj1.width > obj2.x and
    obj1.y < obj2.y + obj2.height and
    obj1.y + obj1.height > obj2.y
end

function GameOver()
  Game.over = true
end

function PlayerWalk()
  if love.keyboard.isDown("left") then
    Player.x = Player.x - Player.velx
  end

  if love.keyboard.isDown("right") then
    Player.x = Player.x + Player.velx
  end

  if Player.x < 0 then
    Player.x = 0
  end

  if Player.x + Player.width > Game.width then
    Player.x = Game.width - Player.width
  end
end
