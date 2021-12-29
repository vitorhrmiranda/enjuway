button = {}
Fonts = {
    Minecraft = "assets/fonts/Minecraft.ttf",
  }
  
local font = love.graphics.newFont(Fonts.Minecraft, 18)

function button_spawn(x, y, text, id)
    table.insert(button, {x = x, y = y, text = text, id = id})
end

function button_draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(love.graphics.newImage('assets/images/bg-main-menu.png'), 0, 0, 0, 3.2, 3.6)

    for i, v in ipairs(button) do
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(v.text, v.x, v.y, 0, 2)
    end
end

function button_click(x, y)
    for i, v in ipairs(button) do
        if x > v.x and
        x < v.x + font:getWidth(v.text) and
        y > v.y and
        y < v.y + font:getHeight() then
            if v.id == 'start' then
                Game.state = 'playing'
            end

            if v.id == 'exit' then
                love.event.quit()
            end
        end
    end
end
