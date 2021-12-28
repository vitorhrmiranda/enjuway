Game = {
  width = 320,
  height = 180,
  scale = 4,
  name = "Enjuway"
}

Player = {
  x = 0,
  y = 0,
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
  Player.y = Game.height - Player.height
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

  --Debug CTRL Direito
  if key == "rctrl" then
    debug.debug()
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
