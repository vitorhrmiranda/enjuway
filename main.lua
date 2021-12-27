game = {
  width = 320,
  height = 180,
  scale = 3.5,
  name = "Enjuway"
}

player = {
  x = 30,
  y = 150,
  width = 22,
  height = 34
}

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.window.setMode(
    game.width * game.scale,
    game.height * game.scale
  )
  love.window.setTitle(game.name)

  loadPlayerAssets()
end

function loadPlayerAssets()
  player.image = love.graphics.newImage("assets/images/player.png")
  player.image:setFilter("nearest", "nearest")
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update()

end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(game.scale, game.scale)

  -- definimos a cor branca
  rgbColor(255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, game.width, game.height)

  -- desenha o player na posição x e y
  love.graphics.draw(player.image, player.x, player.y)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end

function rgbColor(r, g, b)
  love.graphics.setColor(r/255, g/255, b/255)
end
