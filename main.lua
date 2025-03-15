-- Required Libraries
require("sprites")
require("map")
require("particles")
require("items")

-- Global Variables
local camera = require("libraries/camera")
local cam
local camSpeed = 350
local miningSrc, breakSrc, musicSrc
local spriteToBlock = 50 / 32
local chestOpen = nil
local fullscreenX, fullscreenY
local particleTriggered = false
local pickaxes = {}
local pick
local cx, cy, cw, ch
local exitButtonSize = 16
local chestMenuScale = 3
local chestMenuX, chestMenuY
local canMine = true
local currentPick = pickaxes.flintPick
local currentPickFrame = 1
local pickSwinging = false
local loadedChunks = {}
local renderDistance = 1000
local inventory = {}

local dynamiteThrown = false
local currentDynamiteFrame = 1
local dynamiteScale = 1

local explosionScale = 1
local explosionTimer = 0

-- Load Function
function love.load()
    cam = camera()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load audio sources
    miningSrc = love.audio.newSource("Assets/mining.wav", "stream")
    breakSrc = love.audio.newSource("Assets/break.wav", "stream")
    musicSrc = love.audio.newSource("Assets/music.mp3", "stream")
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
        flintPick = {
            idle = flintPickIdle,
            swing = flintPickSwing,
            final = flintPickFinal,
            damage = 1,
            frames = flintPickFrames
        },
        ironPick = {
            idle = ironPickIdle,
            swing = ironPickSwing,
            final = ironPickFinal,
            damage = 2.5,
            frames = ironPickFrames
        },
        goldPick = {
            idle = goldPickIdle,
            swing = goldPickSwing,
            final = goldPickFinal,
            damage = 5,
            frames = goldPickFrames
        },
        diamondPick = {
            idle = diamondPickIdle,
            swing = diamondPickSwing,
            final = diamondPickFinal,
            damage = 7.5,
            frames = diamondPickFrames
        },
        amethystPick = {
            idle = amethystPickIdle,
            swing = amethystPickSwing,
            final = amethystPickFinal,
            damage = 10,
            frames = amethystPickFrames
        },
        forrestitePick = {
            idle = forrestitePickIdle,
            swing = forrestitePickSwing,
            final = forrestitePickFinal,
            damage = 15,
            frames = forrestitePickFrames
        }
    }

    pick = {
        type = pickaxes.flintPick,
        x = 100,
        y = 100
    }
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
        local slot = {
            item = nil,
            amount = 0
        }
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
                love.graphics.draw(spriteSheet, block.blockType.sprite, block.x, block.y, 0, spriteToBlock,
                    spriteToBlock)
                drawBlockDamage(block)
            end
        end
    end
end

-- Draw Background
function drawBackground()
    local parallaxSpeeds = {0.1, 0.2, 0.4, 0.7, 1.2}
    local parallaxImages = {parallax5, parallax4, parallax3, parallax2, parallax1}

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
    love.graphics.draw(spriteSheet, pick.type.frames[math.floor(currentPickFrame)], x - 15, y - 15)
end

-- Draw Dynamite
function drawDynamite(x, y)
    if dynamiteThrown then
        x,y = cam:cameraCoords(x, y)

        love.graphics.draw(spriteSheet, dynamiteFrames[math.floor(currentDynamiteFrame)], x, y, 0, dynamiteScale,
            dynamiteScale)
    end
end

function drawExplosion(x, y)
    if explosion then
        -- Get explosion sprite dimensions
        local ex, ey, ew, eh = explosionSprite:getViewport()

        x,y = cam:cameraCoords(x, y)
        
        -- Calculate centered position
        local drawX = x - (ew * explosionScale) / 2
        local drawY = y - (eh * explosionScale) / 2
        
        love.graphics.draw(
            spriteSheet,
            explosionSprite,
            drawX,  -- Already centered via math above
            drawY,
            0,
            explosionScale,
            explosionScale
        )
    end
end

-- Draw Block Damage
function drawBlockDamage(block)
    if block.blockType.type == "mineable" then
        if block.health < (9.9 / 10) * block.blockType.durability and block.health >= (6.5 / 10) *
            block.blockType.durability then
            love.graphics.draw(spriteSheet, break1, block.x, block.y, 0, spriteToBlock, spriteToBlock)
        elseif block.health < (6.5 / 10) * block.blockType.durability and block.health >= (3 / 10) *
            block.blockType.durability then
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
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

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
        love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
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
    love.graphics.draw(spriteSheet, exitIcon, chestMenuX - exitButtonSize, chestMenuY - exitButtonSize, 0,
        chestMenuScale, chestMenuScale)

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
    shader:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    updateParticles(dt)
    updatePick(dt)
    updateCamera(dt)
    updateDynamite(dt)
    updateExplosion(dt)

    if love.keyboard.isDown("e") then
        if not dynamiteThrown and not explosion and canMine then
            for chunkIndex, chunk in ipairs(loadedChunks) do
                for blockIndex, block in ipairs(chunk.blocks) do
                    if block.blockType then
                        if checkCollision(block.x, block.y, worldMouseX, worldMouseY, BLOCK_WIDTH, BLOCK_HEIGHT) and
                            block.blockType.type == "mineable" then
                            dynamiteThrown = true
                            particleTriggered = false

                            targetX, targetY = block.x + BLOCK_WIDTH/2, block.y + BLOCK_HEIGHT/2
                        end
                    end
                end
            end
        end
    end
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
                        if checkCollision(block.x, block.y, worldPickX, worldPickY, BLOCK_WIDTH, BLOCK_HEIGHT) and
                            block.blockType.type == "mineable" then
                            if not particleTriggered then
                                local particleX, particleY = block.x + BLOCK_WIDTH / 2, block.y + BLOCK_HEIGHT / 2
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
        currentPickFrame = currentPickFrame + dt * 10

        if currentPickFrame > 4 then
            pickSwinging = false
            currentPickFrame = 1
        end
    end
end

-- Kablamo!
function explodeDynamite()
    -- Find the target block's grid position
    local targetGridX = math.floor(targetX / BLOCK_WIDTH) * BLOCK_WIDTH
    local targetGridY = math.floor(targetY / BLOCK_HEIGHT) * BLOCK_HEIGHT

    -- Define the explosion radius (in blocks)
    local explosionRadius = 2  -- Adjust this value to change the size of the explosion
    local radiusSquared = explosionRadius * explosionRadius * BLOCK_WIDTH * BLOCK_HEIGHT  -- Squared radius for distance comparison

    -- Break the target block and adjacent blocks within the circular radius
    for dx = -explosionRadius, explosionRadius do
        for dy = -explosionRadius, explosionRadius do
            -- Calculate the position of the block to check
            local checkX = targetGridX + dx * BLOCK_WIDTH
            local checkY = targetGridY + dy * BLOCK_HEIGHT

            -- Calculate the squared distance from the explosion center
            local distanceSquared = (checkX - targetGridX) * (checkX - targetGridX) + (checkY - targetGridY) * (checkY - targetGridY)

            -- Check if the block is within the circular radius
            if distanceSquared <= radiusSquared then
                -- Check all loaded chunks for a block at (checkX, checkY)
                for _, chunk in ipairs(loadedChunks) do
                    for i = #chunk.blocks, 1, -1 do -- Iterate backwards to safely remove
                        local block = chunk.blocks[i]
                        if block.x == checkX and block.y == checkY then
                            breakBlock(block, i, chunk)
                            break -- No need to check further
                        end
                    end
                end
            end
        end
    end

    explosion = true
end

-- Update Dynamite
function updateDynamite(dt)
    if dynamiteThrown then
        currentDynamiteFrame = currentDynamiteFrame + dt * 15
        if currentDynamiteFrame <= 2 then
            dynamiteScale = 15
        elseif currentDynamiteFrame <= 3 then
            dynamiteScale = 10
        elseif currentDynamiteFrame <= 4 then
            dynamiteScale = 5
        elseif currentDynamiteFrame <= 5 then
            dynamiteScale = 2.5
        elseif currentDynamiteFrame <= 6 then
            dynamiteScale = 1
        else
            currentDynamiteFrame = 1
            dynamiteScale = 15
            explodeDynamite()
            dynamiteThrown = false
        end
    end
end

function updateExplosion(dt)
    if explosion then
        explosionTimer = explosionTimer + dt * 200
        explosionScale = explosionScale + 0.25
        if explosionScale >= 3 then
            explosionScale = 3
        end
        if explosionTimer >= 150 then
            explosion = false
            explosionTimer = 0
            explosionScale = 0
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
        -- Left click: Toggle fullscreen or close chest
        if checkCollision(fullscreenX, fullscreenY, mx, my, 16, 16) then
            toggleFullscreen()
        elseif chestOpen and checkCollision(chestMenuX, chestMenuY, mx, my, 16 * chestMenuScale, 16 * chestMenuScale) then
            chestOpen = nil
            canMine = true
        end
    elseif button == 2 then
        -- Right click: Open chest
        for chunkIndex, chunk in ipairs(loadedChunks) do
            for blockIndex, block in ipairs(chunk.blocks) do
                -- Check if the block is a chest
                if block.blockType == blockTypes.chest then
                    -- Convert block world coordinates to screen coordinates
                    local camBlockX, camBlockY = cam:cameraCoords(block.x, block.y)
                    -- Check if the mouse is over the chest
                    if checkCollision(camBlockX, camBlockY, mx, my, BLOCK_WIDTH, BLOCK_HEIGHT) then
                        chestOpen = block
                        canMine = false
                        break -- Exit the loop after opening the chest
                    end
                end
            end
        end
    end
end

-- Handle Key Presses
function love.keypressed(key)
    if not pickSwinging then
        if key == "1" then
            pick.type = pickaxes.flintPick
        elseif key == "2" then
            pick.type = pickaxes.ironPick
        elseif key == "3" then
            pick.type = pickaxes.goldPick
        elseif key == "4" then
            pick.type = pickaxes.diamondPick
        elseif key == "5" then
            pick.type = pickaxes.amethystPick
        elseif key == "6" then
            pick.type = pickaxes.forrestitePick
        end
        currentPickSprite = pick.type.idle
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
        love.window.setFullscreen(true, "exclusive")
    end
end

-- Break Block
function breakBlock(block, blockIndex, chunk)
    if block.blockType.type == "mineable" then
        table.remove(chunk.blocks, blockIndex)
        breakSrc:play()
        miningSrc:stop()

        local particleX, particleY = block.x + BLOCK_WIDTH / 2, block.y + BLOCK_HEIGHT / 2

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
end
