game = {
  width = 320,
  height = 180,
  scale = 3.5,
  name = "Enjuway"
}

-- Roda quando o jogo abre (Inicialização deve acontecer aqui)
function love.load()
  love.window.setMode(
    game.width * game.scale,
    game.height * game.scale
  )
  love.window.setTitle(game.name)
end

-- Roda a cada frame (Realizar update de estado aqui)
function love.update()

end

-- Roda a cada frame (Realizar update de tela aqui)
function love.draw()
  love.graphics.scale(game.scale, game.scale)

  -- definimos a cor azul
  rgbColor(255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, game.width, game.height)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end

function rgbColor(r, g, b)
  love.graphics.setColor(r/255, g/255, b/255)
end
