Game = {
  width = 320,
  height = 180,
  scale = 4,
  name = "Enjuway",
  gravity = 0.1,
}

Player = {
  x = 0,
  y = 0,
  vely = 0,
  impulse = -2.5,
}

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.window.setMode(
    Game.width * Game.scale,
    Game.height * Game.scale
  )
  love.window.setTitle(Game.name)

  LoadPlayerAssets()
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update()
  Player.vely = Player.vely + Game.gravity

  Player.y = Player.y + Player.vely
  if Player.y > Game.height - Player.height then
    PutInGround(Player)
  end

end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(Game.scale, Game.scale)

  -- definimos a cor branca
  RGBColor(255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, Game.width, Game.height)

  -- desenha o player na posição x e y
  love.graphics.draw(Player.image, Player.x, Player.y)
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
