-- Required Libraries
require("sprites")
require("map")
require("particles")
require("items")

-- Global Variables
local camera = require 'libraries/camera'
local cam
local camSpeed = 350
local miningSrc, breakSrc, musicSrc
local spriteToBlock = 50 / 32
local chestOpen = nil
local fullscreenX, fullscreenY
local particleTriggered = false
local particleX, particleY = 0, 0
local pickaxes = {}
local pick
local cx, cy, cw, ch
local exitButtonSize = 16
local chestMenuScale = 3
local chestMenuX, chestMenuY
local canMine = true
local currentPickSprite
local pickAnimTimer = 0
local pickSwinging = false
local loadedChunks = {}
local renderDistance = 1000
local inventory = {}


local dynamiteThrown = false
local currentDynamiteSprite = dynamite1
local dynamiteAnimTimer = 0
local dynamiteScale = 1

local explosionAnimTimer = 0
local explosionScale = 1

-- Load Function
function love.load()
    cam = camera()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Load audio sources
    miningSrc = love.audio.newSource('Assets/mining.wav', 'stream')
    breakSrc = love.audio.newSource('Assets/break.wav', 'stream')
    musicSrc = love.audio.newSource('Assets/music.mp3', 'stream')
    musicSrc:setLooping(true)
    musicSrc:setVolume(0.1)
    musicSrc:play()

    -- Initialize canvas and shader
    canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    shaderCode = love.filesystem.read("shaders/shader.glsl")
    shader = love.graphics.newShader(shaderCode)
    screenshot = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

    -- Set fullscreen button position
    fullscreenX = love.graphics.getWidth() - 16
    fullscreenY = 0

    -- Initialize game components
    initializePickaxes()
    initializeChestMenu()
    initializeInventory(6)
    generateMap(20, 20)
end

-- Handle window resize
function love.resize(w, h)
    screenshot = love.graphics.newCanvas(w, h)
end

-- Initialize Pickaxes
function initializePickaxes()
    pickaxes = {
        flintPick = { idle = flintPickIdle, swing = flintPickSwing, final = flintPickFinal, damage = 1 },
        ironPick = { idle = ironPickIdle, swing = ironPickSwing, final = ironPickFinal, damage = 2.5 },
        goldPick = { idle = goldPickIdle, swing = goldPickSwing, final = goldPickFinal, damage = 5 },
        diamondPick = { idle = diamondPickIdle, swing = diamondPickSwing, final = diamondPickFinal, damage = 7.5 },
        amethystPick = { idle = amethystPickIdle, swing = amethystPickSwing, final = amethystPickFinal, damage = 10 },
        forrestitePick = { idle = forrestitePickIdle, swing = forrestitePickSwing, final = forrestitePickFinal, damage = 15 }
    }

    pick = { type = pickaxes.flintPick, x = 100, y = 100 }
    currentPickSprite = pick.type.idle
end

-- Initialize Chest Menu
function initializeChestMenu()
    cx, cy, cw, ch = chestMenu:getViewport()
    chestMenuX = (love.graphics.getWidth() / 2) - ((cw * chestMenuScale) / 2)
    chestMenuY = (love.graphics.getHeight() / 2) - ((ch * chestMenuScale) / 2)
end

-- Initialize Inventory
function initializeInventory(number)
    for i = 1, number do
        local slot = { item = nil, amount = 0 }
        table.insert(inventory, slot)
    end
end

-- Draw Function
function love.draw()
    -- Draw the entire scene to the canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    drawBackground()
    cam:attach()
    drawMap()
    drawParticles()
    cam:detach()

    -- HUD/Overlay elements drawn after shader
    drawPick(pick.x, pick.y)

    drawDynamite(targetX, targetY)
    drawExplosion(targetX, targetY)

    drawInventory()
    love.graphics.draw(spriteSheet, fullscreenIcon, fullscreenX, fullscreenY)

    if chestOpen ~= nil then
        drawChest(chestOpen)
    end

    -- Apply shader effect
    love.graphics.setCanvas() -- Back to main screen
    love.graphics.setShader(shader)
    love.graphics.draw(canvas)
    love.graphics.setShader() -- Turn off the shader

    drawBorderedText(love.timer.getFPS(), 0, 0)
end

-- Post Draw Function
function love.postDraw()
    love.graphics.setCanvas()
end

-- Draw Map
function drawMap()
  local camX, camY = cam:position()

  -- Clear the loadedChunks table at the start of each frame
  loadedChunks = {}

  -- Load chunks within the render distance
  for chunkIndex, chunk in ipairs(chunks) do
      local chunkCenterX = chunk.x
      local chunkCenterY = chunk.y

      -- Check if the chunk is within the render distance
      if math.abs(chunkCenterX - camX) < renderDistance and math.abs(chunkCenterY - camY) < renderDistance then
          table.insert(loadedChunks, chunk)
      end
  end

  -- Render loaded chunks
  for chunkIndex, chunk in ipairs(loadedChunks) do
      for blockIndex, block in ipairs(chunk.blocks) do
          if block.blockType then
              love.graphics.draw(spriteSheet, block.blockType.sprite, block.x, block.y, 0, spriteToBlock, spriteToBlock)
              drawBlockDamage(block)
          end
      end
  end
end

-- Draw Background
function drawBackground()
    local parallaxSpeeds = { 0.1, 0.2, 0.4, 0.7, 1.2 }
    local parallaxImages = { parallax5, parallax4, parallax3, parallax2, parallax1 }

    for i, image in ipairs(parallaxImages) do
        local speed = parallaxSpeeds[i]
        local scale = love.graphics.getHeight() / image:getHeight() * 1.5
        local imageWidth = image:getWidth() * scale
        local imageHeight = image:getHeight() * scale
        local camX, camY = cam:position()
        local offsetX = (camX * speed / 10) % imageWidth
        local offsetY = (camY * speed / 10) % imageHeight

        for x = -1, math.ceil(love.graphics.getWidth() / imageWidth) do
            for y = -1, math.ceil(love.graphics.getHeight() / imageHeight) do
                love.graphics.draw(image, x * imageWidth - offsetX, y * imageHeight - offsetY, 0, scale, scale)
            end
        end
    end
end

-- Draw Pick
function drawPick(x, y)
    love.graphics.draw(spriteSheet, currentPickSprite, x - 15, y - 15)
end


-- Draw Dynamite
function drawDynamite(x,y)
    if dynamiteThrown then
        love.graphics.draw(spriteSheet,currentDynamiteSprite, x, y, 0 , dynamiteScale, dynamiteScale)
    end
end

-- Draw Block Damage
function drawBlockDamage(block)
    if block.blockType.type == 'mineable' then
        if block.health < (9.9 / 10) * block.blockType.durability and block.health >= (6.5 / 10) * block.blockType.durability then
            love.graphics.draw(spriteSheet, break1, block.x, block.y, 0, spriteToBlock, spriteToBlock)
        elseif block.health < (6.5 / 10) * block.blockType.durability and block.health >= (3 / 10) * block.blockType.durability then
            love.graphics.draw(spriteSheet, break2, block.x, block.y, 0, spriteToBlock, spriteToBlock)
        elseif block.health < (3 / 10) * block.blockType.durability and block.health >= 0 then
            love.graphics.draw(spriteSheet, break3, block.x, block.y, 0, spriteToBlock, spriteToBlock)
        end
    end
end

-- Draw Particles
function drawParticles()
    love.graphics.draw(rockParticleSystem)
    love.graphics.draw(ironParticleSystem)
    love.graphics.draw(goldParticleSystem)
    love.graphics.draw(diamondParticleSystem)
    love.graphics.draw(amethystParticleSystem)
    love.graphics.draw(forrestiteParticleSystem)
end

-- Draw Inventory
function drawInventory()
    local slotMargin = 5
    local slotSize = 40
    local inventoryScale = 2

    for slotIndex, slot in ipairs(inventory) do
        local slotX = slotIndex * slotSize - slotSize + slotMargin * slotIndex
        local slotY = love.graphics.getHeight() - slotSize - slotMargin

        love.graphics.setColor(0.7, 0.5, 0.3)
        love.graphics.rectangle('fill', slotX, slotY, slotSize, slotSize)

        if slot.item then
            love.graphics.setColor(1, 1, 1)
            local quad = slot.item.sprite
            local _, _, quadWidth, quadHeight = quad:getViewport()
            local itemWidth = quadWidth * inventoryScale
            local itemHeight = quadHeight * inventoryScale
            local itemX = slotX + (slotSize - itemWidth) / 2
            local itemY = slotY + (slotSize - itemHeight) / 2
            love.graphics.draw(spriteSheet, quad, itemX, itemY, 0, inventoryScale, inventoryScale)
        end

        love.graphics.setColor(0.5, 0.3, 0.1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle('line', slotX, slotY, slotSize, slotSize)
        drawBorderedText(slot.amount, slotX, slotY)
    end
end

-- Draw Chest
function drawChest(chest)
    local itemMargin = 11 * chestMenuScale
    local itemSpacing = 31 * chestMenuScale
    local chestColumns = 7
    local chestRows = 4

    love.graphics.draw(spriteSheet, chestMenu, chestMenuX, chestMenuY, 0, chestMenuScale, chestMenuScale)
    love.graphics.draw(spriteSheet, exitIcon, chestMenuX - exitButtonSize, chestMenuY - exitButtonSize, 0, chestMenuScale, chestMenuScale)

    if not chest then
        print("Error: chest is nil")
        return
    end

    for itemIndex, item in ipairs(chest.items) do
        item.x = chestMenuX + itemIndex * itemMargin

        local row = 1

        if 0 < itemIndex and itemIndex <= 7 then
            item.x = chestMenuX + itemMargin + ((itemIndex - 1) * itemSpacing)
            row = 0
        elseif 7 < itemIndex and itemIndex <= 14 then
            item.x = chestMenuX + ((itemIndex - 1) - 7) * itemSpacing + itemMargin
            row = 1
        elseif 14 < itemIndex and itemIndex <= 21 then
            item.x = chestMenuX + ((itemIndex - 1) - 14) * itemSpacing + itemMargin
            row = 2
        elseif 21 < itemIndex and itemIndex <= 28 then
            item.x = chestMenuX + ((itemIndex - 1) - 21) * itemSpacing + itemMargin
            row = 2
        end

        rowY = row * itemSpacing + itemMargin
        item.y = row * itemSpacing + itemMargin + chestMenuY

        love.graphics.draw(spriteSheet, item.itemType.sprite, item.x, item.y, 0, chestMenuScale, chestMenuScale)
        drawBorderedText(item.amount, item.x, chestMenuY + rowY)
    end
end

-- Draw Bordered Text
function drawBorderedText(text, x, y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x, y + 1)
    love.graphics.print(text, x + 1, y)
    love.graphics.print(text, x + 2, y + 1)
    love.graphics.print(text, x + 1, y + 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + 1, y + 1)
end

-- Update Function
function love.update(dt)
    worldMouseX, worldMouseY = cam:worldCoords(love.mouse.getX(), love.mouse.getY())
    shader:send("time", love.timer.getTime())
    shader:send("textureSize", { love.graphics.getWidth(), love.graphics.getHeight() })
    updateParticles(dt)
    updatePick(dt)
    updateCamera(dt)
    updateDynamite(dt)
    updateExplosion(dt)
end

-- Update Particles
function updateParticles(dt)
    rockParticleSystem:update(dt)
    ironParticleSystem:update(dt)
    goldParticleSystem:update(dt)
    diamondParticleSystem:update(dt)
    amethystParticleSystem:update(dt)
    forrestiteParticleSystem:update(dt)
end

-- Update Pick
function updatePick(dt)
    pick.x, pick.y = love.mouse.getX(), love.mouse.getY()
    local worldPickX, worldPickY = cam:worldCoords(pick.x, pick.y)

    if love.mouse.isDown(1) then
        if not pickSwinging and canMine then
            pickSwinging = true
            particleTriggered = false

            for chunkIndex, chunk in ipairs(loadedChunks) do
                for blockIndex, block in ipairs(chunk.blocks) do
                    if block.blockType then
                        if checkCollision(block.x, block.y, worldPickX, worldPickY, BLOCK_WIDTH, BLOCK_HEIGHT) and block.blockType.type == 'mineable' then
                            if not particleTriggered then
                                particleX, particleY = block.x + BLOCK_WIDTH / 2, block.y + BLOCK_HEIGHT / 2
                                rockParticleSystem:setPosition(particleX, particleY)
                                rockParticleSystem:emit(1)
                                particleTriggered = true
                            end

                            if not block.health then
                                block.health = block.blockType.durability
                            end

                            if block.health <= 0 then
                                breakBlock(block, blockIndex, chunk)
                            else
                                block.health = block.health - pick.type.damage
                                miningSrc:play()
                            end
                        end
                    end
                end
            end
        end
    end

    if pickSwinging then
        pickAnimTimer = pickAnimTimer + dt * 200
        if pickAnimTimer <= 20 then
            currentPickSprite = pick.type.idle
        elseif pickAnimTimer <= 40 then
            currentPickSprite = pick.type.swing
        elseif pickAnimTimer <= 60 then
            currentPickSprite = pick.type.final
        else
            pickSwinging = false
            pickAnimTimer = 0
            currentPickSprite = pick.type.idle
        end
    end
end


-- Update Explosion

function updateExplosion(dt)
    explosionAnimTimer = explosionAnimTimer + dt * 200
    if explosionAnimTimer<= 50 then
        explosionScale = .5
    elseif explosionAnimTimer <= 70 then
        explosionScale = 1
    elseif explosionAnimTimer <= 90 then
        explosionScale = 3
    elseif explosionAnimTimer >= 150 then
        explosion = false
        explosionAnimTimer = 0
        explosionScale = 0
    end
end


-- Kaboom!

function drawExplosion(x,y)
    if explosion then
        love.graphics.draw(spriteSheet, explosionSprite, x, y, 0, explosionScale, explosionScale)
    end
end




-- Kablamo!

function explodeDynamite()
    for chunkIndex, chunk in ipairs(loadedChunks) do
        for blockIndex, block in ipairs(chunk.blocks) do
            if block.blockType then
                if checkCollision(block.x, block.y, targetX, targetY, BLOCK_WIDTH, BLOCK_HEIGHT) and block.blockType.type == 'mineable' then
                    if not particleTriggered then
                        particleX, particleY = block.x + BLOCK_WIDTH / 2, block.y + BLOCK_HEIGHT / 2
                        rockParticleSystem:setPosition(particleX, particleY)
                        rockParticleSystem:emit(1)
                        particleTriggered = true
                    end
                
                    explosion = true
                    breakBlock(block, blockIndex, chunk)
                
                end
            end
        end
    end
end 


-- Update Dynamite
function updateDynamite(dt)
    
    if dynamiteThrown then
        dynamiteAnimTimer = dynamiteAnimTimer + dt * 200
        if dynamiteAnimTimer <= 50 then
            currentDynamiteSprite = dynamite1
            dynamiteScale = 10
        elseif dynamiteAnimTimer <= 70 then
            currentDynamiteSprite = dynamite2
            dynamiteScale = 5
        elseif dynamiteAnimTimer <= 90 then
            currentDynamiteSprite = dynamite3
            dynamiteScale = 1
        elseif dynamiteAnimTimer >= 150 then
            explodeDynamite()
            dynamiteThrown = false
            dynamiteAnimTimer = 0
        end
    end


end



-- Update Camera
function updateCamera(dt)
    local moveX, moveY = 0, 0
    local camX, camY = cam:position()
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local worldWidth, worldHeight = chunksX * (CHUNK_WIDTH * BLOCK_WIDTH), chunksY * (CHUNK_HEIGHT * BLOCK_HEIGHT)

    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
      if camX + screenWidth / 2 < worldWidth then
        moveX = moveX + camSpeed * dt
      end
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
      if camX - screenWidth / 2 > 0 then
        moveX = moveX - camSpeed * dt
      end
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
      if camY + screenHeight / 2 < worldHeight then
        moveY = moveY + camSpeed * dt
      end
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
      if camY - screenHeight / 2 > 0 then
        moveY = moveY - camSpeed * dt
      end
    end
    cam:move(moveX, moveY)
end

-- Input Functions
function love.mousepressed(mx, my, button)
    if button == 1 then
        if checkCollision(fullscreenX, fullscreenY, mx, my, 16, 16) then
            toggleFullscreen()
        elseif checkCollision(chestMenuX, chestMenuY, mx, my, 16 * chestMenuScale, 16 * chestMenuScale) then
            if chestOpen then
                chestOpen = nil
                canMine = true
            end
        end
    elseif button == 2 then
        for chunkIndex, chunk in ipairs(loadedChunks) do
            for blockIndex, block in ipairs(chunk.blocks) do
                if block.blockType == chest then
                    local camBlockX, camBlockY = cam:cameraCoords(block.x, block.y)
                    if checkCollision(camBlockX, camBlockY, mx, my, 32, 32) then
                        chestOpen = block
                        canMine = false
                    end
                end
            end
        end
    end
end

-- Handle Key Presses
function love.keypressed(key)
    if not pickSwinging then
        if key == '1' then
            pick.type = pickaxes.flintPick
        elseif key == '2' then
            pick.type = pickaxes.ironPick
        elseif key == '3' then
            pick.type = pickaxes.goldPick
        elseif key == '4' then
            pick.type = pickaxes.diamondPick
        elseif key == '5' then
            pick.type = pickaxes.amethystPick
        elseif key == '6' then
            pick.type = pickaxes.forrestitePick
        end
        currentPickSprite = pick.type.idle

        if key == 'e' then
            
            if not dynamiteThrown and not explosion and canMine then

                for chunkIndex, chunk in ipairs(loadedChunks) do
                    for blockIndex, block in ipairs(chunk.blocks) do
                        if block.blockType then
                            if checkCollision(block.x, block.y, worldMouseX, worldMouseY, BLOCK_WIDTH, BLOCK_HEIGHT) and block.blockType.type == 'mineable' then
                                targetX, targetY = block.x+10, block.y+10
                            end
                        end
                    end
                end

                dynamiteThrown = true
                particleTriggered = false
            end
        end
    end
end

-- Utility Functions
function checkCollision(x, y, pickX, pickY, width, height)
    return pickX >= x and pickX <= x + width and pickY >= y and pickY <= y + height
end

-- Toggle Fullscreen
function toggleFullscreen()
    if love.window.getFullscreen() then
        love.window.setFullscreen(false)
    else
        love.window.setFullscreen(true, 'exclusive')
    end
end

-- Break Block
function breakBlock(block, blockIndex, chunk)
    table.remove(chunk.blocks, blockIndex)
    breakSrc:play()
    miningSrc:stop()
    rockParticleSystem:setPosition(particleX, particleY)
    rockParticleSystem:emit(5)

    if block.blockType == blockTypes.iron then
        ironParticleSystem:setPosition(particleX, particleY)
        ironParticleSystem:emit(3)
    elseif block.blockType == blockTypes.gold then
        goldParticleSystem:setPosition(particleX, particleY)
        goldParticleSystem:emit(3)
    elseif block.blockType == blockTypes.diamonds then
        diamondParticleSystem:setPosition(particleX, particleY)
        diamondParticleSystem:emit(3)
    elseif block.blockType == blockTypes.amethyst then
        amethystParticleSystem:setPosition(particleX, particleY)
        amethystParticleSystem:emit(3)
    elseif block.blockType == blockTypes.forrestite then
        forrestiteParticleSystem:setPosition(particleX, particleY)
        forrestiteParticleSystem:emit(3)
    end

    local slotFilled = false
    for slotIndex, slot in ipairs(inventory) do
        if not slotFilled then
            if slot.item == block.blockType.item then
                slotFilled = true
                slot.amount = slot.amount + 1
            elseif slot.item == nil then
                slotFilled = true
                slot.item = block.blockType.item
                slot.amount = slot.amount + 1
            end
        end
    end
end